import 'package:flutter/foundation.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/participation_model.dart';
import '../../data/models/submission_model.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../domain/feed_challenge.dart';
import 'feed_controller.dart';

class ChallengeController extends ChangeNotifier {
  ChallengeController(
    this._authController,
    this._repository,
    this._feedController,
  ) {
    _authController.addListener(_handleAuthChanged);
  }

  final AuthController _authController;
  final ChallengeRepository _repository;
  final FeedController _feedController;

  final Map<String, bool> _loadingById = {};
  final Map<String, String?> _errorById = {};
  final Map<String, ParticipationModel> _participations = {};
  final Map<String, SubmissionModel> _submissions = {};
  bool _isCreating = false;
  String? _createError;

  bool get isCreating => _isCreating;
  String? get createError => _createError;

  FeedChallenge? challengeById(String id) => _feedController.challengeById(id);
  ParticipationModel? participationForChallenge(String challengeId) => _participations[challengeId];
  SubmissionModel? submissionForChallenge(String challengeId) => _submissions[challengeId];
  Iterable<String> get participationChallengeIds => _participations.keys;
  bool isLoading(String challengeId) => _loadingById[challengeId] ?? false;
  String? errorFor(String challengeId) => _errorById[challengeId] ?? _createError;

  Future<FeedChallenge?> loadChallenge(String id) async {
    if (_loadingById[id] == true) {
      return challengeById(id);
    }

    _loadingById[id] = true;
    _errorById[id] = null;
    notifyListeners();

    try {
      final model = await _repository.fetchChallengeById(id);
      final challenge = _toChallenge(model, challengeById('${model.id}'));
      _feedController.upsertChallenge(challenge);
      return challenge;
    } catch (error) {
      _errorById[id] = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _loadingById[id] = false;
      notifyListeners();
    }
  }

  Future<FeedChallenge> createChallenge(ChallengeDraft draft) async {
    _isCreating = true;
    _createError = null;
    notifyListeners();

    try {
      final model = await _repository.createChallenge(
        title: draft.title,
        description: draft.description,
        category: draft.category,
        type: _typeName(draft.type),
        rarity: _rarityName(draft.rarity),
        coinReward: draft.coinReward,
        proofType: _proofTypeName(draft.verificationType),
        conditionsText: draft.conditions,
        successCriteriaText: draft.conditions,
        proofInstructions: draft.conditions,
        deadlineLabel: null,
      );
      final challenge = _toChallenge(model, null).copyWith(
        sourceTag: 'Авторский',
        specialStatus: 'Создатель получает ${draft.revenueShare}% с подтверждённых выполнений.',
      );
      _feedController.upsertChallenge(challenge, prepend: true);
      return challenge;
    } catch (error) {
      _createError = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<ParticipationModel> acceptChallenge(String challengeId) async {
    final hadParticipation = _participations.containsKey(challengeId);
    final participation = await _repository.acceptChallenge(challengeId);
    _participations[challengeId] = participation;
    final existing = challengeById(challengeId);
    if (existing != null) {
      _feedController.upsertChallenge(
        existing.copyWith(
          isAccepted: true,
          executionStatus: FeedExecutionStatus.inProgress,
          progress: (participation.progressValue / 100).clamp(0, 1),
          acceptedCount: hadParticipation ? existing.acceptedCount : existing.acceptedCount + 1,
          participants: hadParticipation ? existing.participants : existing.participants + 1,
        ),
      );
    }
    notifyListeners();
    return participation;
  }

  void syncExecutionState({
    required String challengeId,
    ParticipationModel? participation,
    SubmissionModel? submission,
  }) {
    if (participation != null) {
      _participations[challengeId] = participation;
    }
    if (submission != null) {
      _submissions[challengeId] = submission;
    }

    final challenge = challengeById(challengeId);
    if (challenge == null) {
      notifyListeners();
      return;
    }

    final effectiveParticipation = participation ?? _participations[challengeId];
    final effectiveSubmission = submission ?? _submissions[challengeId];
    _feedController.upsertChallenge(_applyExecution(challenge, effectiveParticipation, effectiveSubmission));
    notifyListeners();
  }

  FeedChallenge _toChallenge(ChallengeModel model, FeedChallenge? existing) {
    final participation = _participations['${model.id}'];
    final submission = _submissions['${model.id}'];
    final base = model.toFeedChallenge(
      participation: participation,
      submission: submission,
      isLiked: existing?.isLiked ?? false,
      isSaved: existing?.isSaved ?? false,
      isFollowingAuthor: existing?.isFollowingAuthor ?? false,
    );

    if (existing == null) {
      return base;
    }

    return base.copyWith(
      isLiked: existing.isLiked,
      isSaved: existing.isSaved,
      isFollowingAuthor: existing.isFollowingAuthor,
      likes: existing.likes,
      completionLikes: existing.completionLikes,
    );
  }

  FeedChallenge _applyExecution(
    FeedChallenge challenge,
    ParticipationModel? participation,
    SubmissionModel? submission,
  ) {
    final status = switch (submission?.status ?? participation?.status) {
      'accepted' || 'approved' => FeedExecutionStatus.approved,
      'rejected' => FeedExecutionStatus.rejected,
      'pending' || 'submitted' => FeedExecutionStatus.submitted,
      'in_progress' => FeedExecutionStatus.inProgress,
      _ => FeedExecutionStatus.notAccepted,
    };

    return challenge.copyWith(
      isAccepted: participation != null,
      executionStatus: status,
      progress: (((participation?.progressValue ?? 0) / 100).clamp(0, 1)).toDouble(),
      submissionText: submission?.comment ?? challenge.submissionText,
      submissionImagePath: submission?.proofUrl ?? challenge.submissionImagePath,
      rejectionReason: submission?.rejectionReason,
      medalAwarded: status == FeedExecutionStatus.approved && challenge.hasMedal,
      completedCount: status == FeedExecutionStatus.approved && challenge.executionStatus != FeedExecutionStatus.approved
          ? challenge.completedCount + 1
          : challenge.completedCount,
    );
  }

  void _handleAuthChanged() {
    if (!_authController.isAuthenticated) {
      _participations.clear();
      _submissions.clear();
      _loadingById.clear();
      _errorById.clear();
      _createError = null;
      _isCreating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    super.dispose();
  }
}

String _typeName(FeedChallengeType type) {
  switch (type) {
    case FeedChallengeType.daily:
      return 'daily';
    case FeedChallengeType.yearly:
      return 'yearly';
    case FeedChallengeType.permanent:
      return 'permanent';
  }
}

String _rarityName(FeedChallengeRarity rarity) {
  switch (rarity) {
    case FeedChallengeRarity.common:
      return 'common';
    case FeedChallengeRarity.rare:
      return 'rare';
    case FeedChallengeRarity.epic:
      return 'epic';
    case FeedChallengeRarity.legendary:
      return 'legendary';
    case FeedChallengeRarity.mythic:
      return 'mythic';
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



