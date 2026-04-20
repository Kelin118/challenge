import 'package:flutter/foundation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/execution_repository.dart';
import '../../domain/challenge_completion_event.dart';
import '../../domain/feed_challenge.dart';
import '../../domain/proof_upload_state.dart';
import 'challenge_controller.dart';
import 'feed_controller.dart';
import 'wallet_controller.dart';

class ExecutionController extends ChangeNotifier {
  ExecutionController(
    this._authController,
    this._repository,
    this._challengeController,
    this._feedController,
    this._walletController,
  ) {
    _authController.addListener(_handleAuthChanged);
    _feedController.addListener(_handleFeedChanged);
  }

  final AuthController _authController;
  final ExecutionRepository _repository;
  final ChallengeController _challengeController;
  final FeedController _feedController;
  final WalletController _walletController;

  final Map<String, bool> _loadingByChallengeId = {};
  final Map<String, String?> _errorByChallengeId = {};
  final Map<String, ProofUploadState> _uploadStates = {};

  bool get _isAuthenticated => _authController.isAuthenticated;
  bool isLoading(String challengeId) => _loadingByChallengeId[challengeId] ?? false;
  String? errorFor(String challengeId) => _errorByChallengeId[challengeId];
  ProofUploadState uploadStateFor(String challengeId) {
    final state = _uploadStates[challengeId];
    if (state != null) return state;

    final challenge = _challengeController.challengeById(challengeId);
    final path = challenge?.submissionImagePath;
    if (path == null || path.isEmpty) {
      return const ProofUploadState.idle();
    }
    if (_isRemoteUrl(path)) {
      return ProofUploadState.uploaded(remoteUrl: path);
    }
    return ProofUploadState.idle(localPath: path);
  }

  Future<void> updateProgress(String challengeId, {int? absoluteProgress, int? progressDelta}) async {
    final participation = _challengeController.participationForChallenge(challengeId);
    if (participation == null) {
      throw StateError('Челлендж ещё не принят.');
    }

    _setLoading(challengeId, true);
    try {
      final updated = await _repository.updateProgress(
        participationId: participation.id,
        absoluteProgress: absoluteProgress,
        progressDelta: progressDelta,
      );
      _challengeController.syncExecutionState(challengeId: challengeId, participation: updated);
    } catch (error) {
      _errorByChallengeId[challengeId] = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(challengeId, false);
    }
  }

  Future<void> attachSubmissionImage(String challengeId, String imagePath) async {
    final challenge = _challengeController.challengeById(challengeId);
    if (challenge == null) return;
    _uploadStates[challengeId] = ProofUploadState.idle(localPath: imagePath);
    _feedController.upsertChallenge(challenge.copyWith(submissionImagePath: imagePath));
    notifyListeners();
  }

  Future<void> retryProofUpload(String challengeId) async {
    await _uploadProofIfNeeded(challengeId, forceRetry: true);
  }

  Future<void> retrySubmission(String challengeId) async {
    final challenge = _challengeController.challengeById(challengeId);
    if (challenge == null) return;
    _feedController.upsertChallenge(
      challenge.copyWith(
        executionStatus: FeedExecutionStatus.inProgress,
        clearRejectionReason: true,
      ),
    );
  }

  Future<void> submitExecution({
    required String challengeId,
    required String text,
    String? imagePath,
  }) async {
    final participation = _challengeController.participationForChallenge(challengeId);
    if (participation == null) {
      throw StateError('Нельзя отправить выполнение без принятого челленджа.');
    }

    final challenge = _challengeController.challengeById(challengeId);
    if (challenge == null) {
      throw StateError('Челлендж не найден.');
    }

    _setLoading(challengeId, true);
    try {
      final proofUrl = await _uploadProofIfNeeded(challengeId, fallbackPath: imagePath);
      final result = await _repository.submitExecution(
        participationId: participation.id,
        comment: text,
        proofUrl: proofUrl,
        proofType: _proofTypeName(challenge.verificationType),
      );
      _challengeController.syncExecutionState(
        challengeId: challengeId,
        participation: result.participation,
        submission: result.submission,
      );
      await _feedController.load();
      _tryPromoteApprovedCompletion(challengeId, result.submission);
      await _walletController.load();
    } catch (error) {
      _errorByChallengeId[challengeId] = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(challengeId, false);
    }
  }

  void likeCompletion(String challengeId) {
    final completion = _feedController.completionByChallengeId(challengeId);
    if (completion != null) {
      _feedController.toggleCompletionEventLike(completion.id);
      final challenge = _challengeController.challengeById(challengeId);
      if (challenge != null) {
        final updated = _feedController.completionByChallengeId(challengeId);
        _feedController.upsertChallenge(challenge.copyWith(completionLikes: updated?.likesCount ?? challenge.completionLikes));
      }
    }
  }

  Future<String?> _uploadProofIfNeeded(
    String challengeId, {
    String? fallbackPath,
    bool forceRetry = false,
  }) async {
    final challenge = _challengeController.challengeById(challengeId);
    final currentPath = challenge?.submissionImagePath ?? fallbackPath;
    if (currentPath == null || currentPath.isEmpty) {
      return null;
    }
    if (_isRemoteUrl(currentPath) && !forceRetry) {
      _uploadStates[challengeId] = ProofUploadState.uploaded(remoteUrl: currentPath);
      notifyListeners();
      return currentPath;
    }

    _uploadStates[challengeId] = ProofUploadState.uploading(localPath: currentPath);
    notifyListeners();

    try {
      final uploaded = await _repository.uploadProof(filePath: currentPath);
      final remoteUrl = uploaded.url;
      _uploadStates[challengeId] = ProofUploadState.uploaded(localPath: currentPath, remoteUrl: remoteUrl);
      if (challenge != null) {
        _feedController.upsertChallenge(challenge.copyWith(submissionImagePath: remoteUrl));
      }
      notifyListeners();
      return remoteUrl;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      _uploadStates[challengeId] = ProofUploadState.failed(localPath: currentPath, errorMessage: message);
      notifyListeners();
      rethrow;
    }
  }

  void _tryPromoteApprovedCompletion(String challengeId, SubmissionModel? submission) {
    if (submission == null || submission.status != 'accepted') {
      return;
    }

    final challenge = _challengeController.challengeById(challengeId);
    final username = _authController.currentUser?.username ?? 'Игрок';
    if (challenge == null) return;

    final event = ChallengeCompletionEvent(
      id: 'local-approved-$challengeId-${DateTime.now().millisecondsSinceEpoch}',
      userId: '${_authController.currentUser?.id ?? ''}',
      username: username,
      challengeId: challengeId,
      challengeTitle: challenge.title,
      coinsEarned: challenge.coinReward,
      medalAwarded: challenge.hasMedal,
      imageProof: submission.proofUrl,
      likesCount: 0,
      isLikedByCurrentUser: false,
      createdAt: DateTime.now(),
    );
    _feedController.prependCompletionEvent(event);
  }

  void _handleFeedChanged() {
    if (!_isAuthenticated) return;
    final username = _authController.currentUser?.username;
    if (username == null || username.isEmpty) return;

    for (final entry in _errorByChallengeId.keys.toList()) {
      if (_errorByChallengeId[entry] != null && !(_loadingByChallengeId[entry] ?? false)) {
        _errorByChallengeId.remove(entry);
      }
    }

    for (final challengeId in _challengeController.participationChallengeIds) {
      final completion = _feedController.completionByChallengeId(challengeId);
      final challenge = _challengeController.challengeById(challengeId);
      if (completion == null || challenge == null) continue;
      if (completion.username != username) continue;
      if (challenge.executionStatus == FeedExecutionStatus.approved) continue;

      _feedController.upsertChallenge(
        challenge.copyWith(
          executionStatus: FeedExecutionStatus.approved,
          medalAwarded: completion.medalAwarded,
          completionLikes: completion.likesCount,
          completedCount: challenge.completedCount + 1,
          submissionImagePath: completion.imageProof ?? challenge.submissionImagePath,
        ),
      );
      if (completion.imageProof != null && completion.imageProof!.isNotEmpty) {
        _uploadStates[challengeId] = ProofUploadState.uploaded(remoteUrl: completion.imageProof);
      }
      _walletController.load();
    }
  }

  void _setLoading(String challengeId, bool value) {
    _loadingByChallengeId[challengeId] = value;
    if (value) {
      _errorByChallengeId[challengeId] = null;
    }
    notifyListeners();
  }

  void _handleAuthChanged() {
    if (!_isAuthenticated) {
      _loadingByChallengeId.clear();
      _errorByChallengeId.clear();
      _uploadStates.clear();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    _feedController.removeListener(_handleFeedChanged);
    super.dispose();
  }
}

bool _isRemoteUrl(String value) => value.startsWith('http://') || value.startsWith('https://');

String _proofTypeName(FeedVerificationType type) {
  switch (type) {
    case FeedVerificationType.text:
      return 'text';
    default:
      return 'photo';
  }
}
