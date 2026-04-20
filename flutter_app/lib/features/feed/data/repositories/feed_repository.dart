import '../../../../core/network/api_client.dart';
import '../../../auth/data/auth_service.dart';
import '../models/feed_item_model.dart';

class FeedRepository {
  FeedRepository(this._authService);

  final AuthService _authService;

  ApiClient get _apiClient => _authService.apiClient;
  String get _baseUrl => _authService.baseUrl;

  Future<List<FeedItemModel>> fetchFeed() async {
    final response = await _apiClient.getJson(baseUrl: _baseUrl, path: '/api/feed');
    final items = response['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FeedItemModel.fromJson)
        .toList();
  }
}
