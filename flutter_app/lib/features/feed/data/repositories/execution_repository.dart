import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_service.dart';
import '../models/participation_model.dart';
import '../models/proof_upload_result.dart';
import '../models/submission_model.dart';

class ExecutionMutationResult {
  const ExecutionMutationResult({
    required this.participation,
    this.submission,
  });

  final ParticipationModel participation;
  final SubmissionModel? submission;
}

class ExecutionRepository {
  ExecutionRepository(this._authService);

  final AuthService _authService;

  ApiClient get _apiClient => _authService.apiClient;
  String get _baseUrl => _authService.baseUrl;

  Future<ProofUploadResult> uploadProof({required String filePath}) async {
    final response = await _apiClient.postMultipart(
      baseUrl: _baseUrl,
      path: '/api/uploads/proof',
      filePath: filePath,
      authorized: true,
    );

    final upload = response['upload'] as Map<String, dynamic>?;
    if (upload == null) {
      throw const FormatException('Upload payload is missing.');
    }

    return ProofUploadResult.fromJson(upload);
  }

  Future<ParticipationModel> updateProgress({
    required int participationId,
    int? absoluteProgress,
    int? progressDelta,
  }) async {
    final response = await _apiClient.patchJson(
      baseUrl: _baseUrl,
      path: '/api/participations/$participationId/progress',
      authorized: true,
      body: {
        if (absoluteProgress != null) 'absoluteProgress': absoluteProgress,
        if (progressDelta != null) 'progressDelta': progressDelta,
      },
    );

    final participation = response['participation'] as Map<String, dynamic>?;
    if (participation == null) {
      throw const FormatException('Progress payload is missing.');
    }

    return ParticipationModel.fromJson(participation);
  }

  Future<ExecutionMutationResult> submitExecution({
    required int participationId,
    required String comment,
    String? proofUrl,
    required String proofType,
  }) async {
    final response = await _apiClient.postJson(
      baseUrl: _baseUrl,
      path: '/api/participations/$participationId/submit',
      authorized: true,
      body: {
        if (proofUrl != null && proofUrl.isNotEmpty) 'proof_url': proofUrl,
        'proof_type': proofType,
        'comment': comment,
      },
    );

    final participation = response['participation'] as Map<String, dynamic>?;
    final submission = response['submission'] as Map<String, dynamic>?;
    if (participation == null) {
      throw const FormatException('Submit payload is missing.');
    }

    return ExecutionMutationResult(
      participation: ParticipationModel.fromJson(participation),
      submission: submission == null ? null : SubmissionModel.fromJson(submission),
    );
  }
}
