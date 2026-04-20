import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_service.dart';
import '../models/challenge_model.dart';
import '../models/participation_model.dart';

class ChallengeRepository {
  ChallengeRepository(this._authService);

  final AuthService _authService;

  ApiClient get _apiClient => _authService.apiClient;
  String get _baseUrl => _authService.baseUrl;

  Future<List<ChallengeModel>> fetchChallenges() async {
    final response = await _apiClient.getJson(baseUrl: _baseUrl, path: '/api/challenges');
    final items = response['challenges'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ChallengeModel.fromJson)
        .toList();
  }

  Future<ChallengeModel> fetchChallengeById(String id) async {
    final response = await _apiClient.getJson(baseUrl: _baseUrl, path: '/api/challenges/$id');
    final challenge = response['challenge'] as Map<String, dynamic>?;
    if (challenge == null) {
      throw const FormatException('Challenge payload is missing.');
    }

    return ChallengeModel.fromJson(challenge);
  }

  Future<ChallengeModel> createChallenge({
    required String title,
    required String description,
    required String category,
    required String type,
    required String rarity,
    required int coinReward,
    required String proofType,
    required String conditionsText,
    required String successCriteriaText,
    required String? proofInstructions,
    required String? deadlineLabel,
  }) async {
    final response = await _apiClient.postJson(
      baseUrl: _baseUrl,
      path: '/api/challenges',
      authorized: true,
      body: {
        'title': title,
        'description': description,
        'category': category,
        'type': type,
        'rarity': rarity,
        'coin_reward': coinReward,
        'proof_type': proofType,
        'conditions_text': conditionsText,
        'success_criteria_text': successCriteriaText,
        if (proofInstructions != null && proofInstructions.isNotEmpty) 'proof_instructions': proofInstructions,
        if (deadlineLabel != null && deadlineLabel.isNotEmpty) 'deadline_label': deadlineLabel,
      },
    );

    final challenge = response['challenge'] as Map<String, dynamic>?;
    if (challenge == null) {
      throw const FormatException('Create challenge payload is missing.');
    }

    return ChallengeModel.fromJson(challenge);
  }

  Future<ParticipationModel> acceptChallenge(String challengeId) async {
    final response = await _apiClient.postJson(
      baseUrl: _baseUrl,
      path: '/api/challenges/$challengeId/accept',
      authorized: true,
      body: const {},
    );

    final participation = response['participation'] as Map<String, dynamic>?;
    if (participation == null) {
      throw const FormatException('Participation payload is missing.');
    }

    return ParticipationModel.fromJson(participation);
  }
}
