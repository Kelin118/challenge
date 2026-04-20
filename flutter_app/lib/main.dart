import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'features/achievements/data/achievement_service.dart';
import 'features/achievements/presentation/controllers/achievement_controller.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/feed/data/challenge_feed_service.dart';
import 'features/feed/data/repositories/challenge_repository.dart';
import 'features/feed/data/repositories/execution_repository.dart';
import 'features/feed/data/repositories/feed_repository.dart';
import 'features/feed/data/repositories/wallet_repository.dart';
import 'features/feed/presentation/controllers/challenge_controller.dart';
import 'features/feed/presentation/controllers/execution_controller.dart';
import 'features/feed/presentation/controllers/feed_controller.dart';
import 'features/feed/presentation/controllers/wallet_controller.dart';
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
  final feedController = FeedController(
    authController,
    profileController,
    achievementController,
    FeedRepository(authService),
    const ChallengeFeedService(),
  );
  final challengeController = ChallengeController(
    authController,
    ChallengeRepository(authService),
    feedController,
  );
  final walletController = WalletController(
    authController,
    WalletRepository(authService),
  );
  final executionController = ExecutionController(
    authController,
    ExecutionRepository(authService),
    challengeController,
    feedController,
    walletController,
  );

  runApp(
    AchievementVaultApp(
      authController: authController,
      profileController: profileController,
      achievementController: achievementController,
      sessionController: sessionController,
      feedController: feedController,
      challengeController: challengeController,
      executionController: executionController,
      walletController: walletController,
    ),
  );

  unawaited(_safeLoad(profileController.load));
  unawaited(_safeLoad(authController.load));
  unawaited(_safeLoad(achievementController.load));
  unawaited(_safeLoad(feedController.load));
  unawaited(_safeLoad(walletController.load));
}

Future<void> _safeLoad(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Controllers manage their own fallback state.
  }
}
