import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/achievements/domain/achievement.dart';
import '../features/achievements/presentation/controllers/achievement_controller.dart';
import '../features/achievements/presentation/screens/achievement_details_screen.dart';
import '../features/achievements/presentation/screens/achievements_screen.dart';
import '../features/achievements/presentation/screens/home_screen.dart';
import '../features/achievements/presentation/screens/stats_screen.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/auth_screen.dart';
import '../features/profile/presentation/controllers/profile_controller.dart';
import '../features/profile/presentation/screens/profile_bootstrap_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/sessions/presentation/controllers/session_controller.dart';

class AchievementVaultApp extends StatefulWidget {
  const AchievementVaultApp({
    super.key,
    required this.authController,
    required this.profileController,
    required this.achievementController,
    required this.sessionController,
  });

  final AuthController authController;
  final ProfileController profileController;
  final AchievementController achievementController;
  final SessionController sessionController;

  @override
  State<AchievementVaultApp> createState() => _AchievementVaultAppState();
}

class _AchievementVaultAppState extends State<AchievementVaultApp> {
  int _index = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _contactController = TextEditingController();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  late final Listenable _mergedListenable;

  @override
  void initState() {
    super.initState();
    _mergedListenable = Listenable.merge([
      widget.authController,
      widget.profileController,
      widget.achievementController,
      widget.sessionController,
    ]);
    widget.achievementController.addListener(_handleAchievementToast);
  }

  @override
  void dispose() {
    widget.achievementController.removeListener(_handleAchievementToast);
    _nameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  void _handleAchievementToast() {
    final toast = widget.achievementController.toastAchievement;
    if (!mounted || toast == null) {
      return;
    }

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.backgroundSecondary,
        content: Row(
          children: [
            Text(toast.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Достижение открыто',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w800),
                  ),
                  Text(toast.title, style: const TextStyle(color: AppTheme.text)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    widget.achievementController.dismissToast();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: AnimatedBuilder(
        animation: _mergedListenable,
        builder: (context, _) => _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    if (!widget.authController.isReady ||
        !widget.profileController.isReady ||
        !widget.achievementController.isReady) {
      return const _SplashScreen();
    }

    if (!widget.authController.isAuthenticated) {
      return AuthScreen(
        isLoading: widget.authController.isLoading,
        loginController: _loginController,
        passwordController: _passwordController,
        registerEmailController: _registerEmailController,
        registerUsernameController: _registerUsernameController,
        registerPasswordController: _registerPasswordController,
        onLogin: _handleLogin,
        onRegister: _handleRegister,
      );
    }

    if (!widget.profileController.hasProfiles) {
      return ProfileBootstrapScreen(
        nameController: _nameController,
        usernameController: _usernameController,
        aboutController: _aboutController,
        contactController: _contactController,
        onRegister: () async {
          await widget.profileController.registerProfile(
            nickname: _nameController.text,
            username: _usernameController.text,
            about: _aboutController.text,
            contact: _contactController.text,
          );
          await widget.achievementController.unlock('press-start');
          _nameController.clear();
          _usernameController.clear();
          _aboutController.clear();
          _contactController.clear();
        },
      );
    }

    final recentAchievements = [...widget.achievementController.achievements]
      ..retainWhere((item) => item.isUnlocked && item.progress.unlockedAt != null)
      ..sort((a, b) => b.progress.unlockedAt!.compareTo(a.progress.unlockedAt!));

    final screens = [
      HomeScreen(
        achievementController: widget.achievementController,
        profileController: widget.profileController,
        recentAchievements: recentAchievements.take(3).toList(),
        onOpenProfile: _openProfile,
      ),
      AchievementsScreen(
        controller: widget.achievementController,
        onOpenDetails: _openDetails,
      ),
      StatsScreen(controller: widget.achievementController),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (_index) {
            0 => 'Главная',
            1 => 'Достижения',
            _ => 'Статистика',
          },
        ),
        actions: [
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A121A),
              Color(0xFF0A1622),
              Color(0xFF081018),
            ],
          ),
        ),
        child: screens[_index],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: AppTheme.backgroundSecondary,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Достижения'),
          NavigationDestination(icon: Icon(Icons.query_stats_outlined), label: 'Статистика'),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    try {
      await widget.authController.login(
        login: _loginController.text,
        password: _passwordController.text,
      );
      await widget.achievementController.load();
      _passwordController.clear();
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleRegister() async {
    try {
      await widget.authController.register(
        email: _registerEmailController.text,
        username: _registerUsernameController.text,
        password: _registerPasswordController.text,
      );
      _registerPasswordController.clear();
      _showMessage('Аккаунт создан. Теперь можно войти и создать профиль игрока.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openDetails(Achievement achievement) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AchievementDetailsScreen(
          achievement: achievement,
          controller: widget.achievementController,
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(
          authController: widget.authController,
          profileController: widget.profileController,
          achievementController: widget.achievementController,
          sessionController: widget.sessionController,
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF050A10),
              Color(0xFF0D1B28),
              Color(0xFF102235),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: Color.fromRGBO(102, 192, 244, 0.14),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Achievement Vault',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'Загрузка профиля игрока',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
