import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileBootstrapScreen extends StatelessWidget {
  const ProfileBootstrapScreen({
    super.key,
    required this.nameController,
    required this.usernameController,
    required this.aboutController,
    required this.contactController,
    required this.onRegister,
  });

  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController aboutController;
  final TextEditingController contactController;
  final Future<void> Function() onRegister;

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
            child: Padding(
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
                      'Игровой профиль',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Собери локальный профиль игрока. Он живёт отдельно от backend-аккаунта и управляет твоими достижениями внутри приложения.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(hintText: 'Имя'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(hintText: 'username', prefixText: '@'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aboutController,
                      decoration: const InputDecoration(hintText: 'Статус / о себе'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Телефон или контакт'),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: AppTheme.background,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Создать профиль'),
                    ),
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
