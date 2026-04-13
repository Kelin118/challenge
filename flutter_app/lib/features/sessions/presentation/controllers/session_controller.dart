import 'package:flutter/foundation.dart';

import '../../domain/device_session.dart';
import '../../../auth/data/auth_service.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._authService);

  final AuthService _authService;

  bool _isLoggingOutAll = false;

  bool get isLoggingOutAll => _isLoggingOutAll;

  Future<List<DeviceSession>> fetchActiveSessions() {
    return _authService.fetchActiveSessions();
  }

  Future<void> logoutSession(int sessionId) {
    return _authService.logoutSession(sessionId: sessionId);
  }

  Future<void> logoutAllSessions() async {
    _isLoggingOutAll = true;
    notifyListeners();
    try {
      await _authService.logoutAllSessions();
    } finally {
      _isLoggingOutAll = false;
      notifyListeners();
    }
  }
}
