import 'package:flutter/foundation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/execution_repository.dart';
import '../../domain/challenge_completion_event.dart';
import '../../domain/feed_challenge.dart';
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

  bool get _isAuthenticated => _authController.isAuthenticated;
  bool isLoading(String challengeId) => _loadingByChallengeId[challengeId] ?? false;
  String? errorFor(String challengeId) => _errorByChallengeId[challengeId];

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
    _feedController.upsertChallenge(challenge.copyWith(submissionImagePath: imagePath));
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
      final result = await _repository.submitExecution(
        participationId: participation.id,
        comment: text,
        proofUrl: imagePath,
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
        ),
      );
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

String _proofTypeName(FeedVerificationType type) {
  switch (type) {
    case FeedVerificationType.text:
      return 'text';
    default:
      return 'photo';
  }
}


