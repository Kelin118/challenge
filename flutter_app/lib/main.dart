import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'features/achievements/data/achievement_service.dart';
import 'features/achievements/presentation/controllers/achievement_controller.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/profile/data/profile_storage.dart';
import 'features/profile/presentation/controllers/profile_controller.dart';
import 'features/sessions/presentation/controllers/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final authController = AuthController(authService);
  final profileController = ProfileController(ProfileStorage());
  final achievementController = AchievementController(
    authController,
    profileController,
    AchievementApiService(authService),
  );
  final sessionController = SessionController(authService);

  await profileController.load();
  await authController.load();
  await achievementController.load();

  runApp(
    AchievementVaultApp(
      authController: authController,
      profileController: profileController,
      achievementController: achievementController,
      sessionController: sessionController,
    ),
  );
}

