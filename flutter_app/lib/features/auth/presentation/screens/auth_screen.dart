import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.isLoading,
    required this.loginController,
    required this.passwordController,
    required this.registerEmailController,
    required this.registerUsernameController,
    required this.registerPasswordController,
    required this.onLogin,
    required this.onRegister,
  });

  final bool isLoading;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final TextEditingController registerEmailController;
  final TextEditingController registerUsernameController;
  final TextEditingController registerPasswordController;
  final Future<void> Function() onLogin;
  final Future<void> Function() onRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Авторизация',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Токены хранятся безопасно, защищённые запросы уходят с Bearer token, а при 401 сессия сбрасывается автоматически.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: true, label: Text('Вход')),
                        ButtonSegment<bool>(value: false, label: Text('Регистрация')),
                      ],
                      selected: {_isLoginMode},
                      onSelectionChanged: (value) {
                        setState(() => _isLoginMode = value.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isLoginMode) ...[
                      TextField(
                        controller: widget.loginController,
                        decoration: const InputDecoration(hintText: 'Email или username'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: 'Пароль'),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: widget.isLoading ? null : widget.onLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.background,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(widget.isLoading ? 'Входим...' : 'Войти'),
                      ),
                    ] else ...[
                      TextField(
                        controller: widget.registerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.registerUsernameController,
                        decoration: const InputDecoration(hintText: 'Username'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.registerPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(hintText: 'Пароль'),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: widget.isLoading ? null : widget.onRegister,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.background,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(
                          widget.isLoading ? 'Создаём аккаунт...' : 'Зарегистрироваться',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
