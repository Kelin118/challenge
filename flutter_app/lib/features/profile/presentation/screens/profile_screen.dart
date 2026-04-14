import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../../achievements/presentation/controllers/achievement_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/profile_controller.dart';
import '../../../sessions/presentation/controllers/session_controller.dart';
import '../../../sessions/presentation/screens/active_sessions_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
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
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _aboutController;
  late final TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    final profile = widget.profileController.activeProfile!;
    _nameController = TextEditingController(text: profile.nickname);
    _usernameController = TextEditingController(text: profile.username.replaceFirst('@', ''));
    _aboutController = TextEditingController(text: profile.about);
    _contactController = TextEditingController(text: profile.contact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.achievementController.profile;
    final active = widget.profileController.activeProfile!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.authController.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.primaries[active.avatarSeed % Colors.primaries.length].withValues(alpha: 0.22),
                  child: Text(
                    active.initials,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active.nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(active.username, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(active.about, style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Row(
              children: [
                Expanded(child: _MetricTile(label: 'Монеты', value: '${profile.totalCoins}')),
                const SizedBox(width: 12),
                Expanded(child: _MetricTile(label: 'Открыто', value: '${profile.unlockedCount}/${profile.totalCount}')),
                const SizedBox(width: 12),
                Expanded(child: _MetricTile(label: 'В процессе', value: '${widget.achievementController.inProgressCount}')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Устройства', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  'Просмотри активные устройства и заверши лишние сессии.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ActiveSessionsScreen(controller: widget.sessionController),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Активные устройства'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Редактирование профиля', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Имя')),
                const SizedBox(height: 12),
                TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'username', prefixText: '@')),
                const SizedBox(height: 12),
                TextField(controller: _aboutController, decoration: const InputDecoration(hintText: 'Статус / о себе')),
                const SizedBox(height: 12),
                TextField(controller: _contactController, decoration: const InputDecoration(hintText: 'Контакт')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await widget.profileController.updateActiveProfile(
                      nickname: _nameController.text,
                      username: _usernameController.text,
                      about: _aboutController.text,
                      contact: _contactController.text,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Сохранить изменения'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Профили', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...widget.profileController.profiles.map((item) {
                  final isActive = item.profile.id == active.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.cardMuted,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.primaries[item.profile.avatarSeed % Colors.primaries.length].withValues(alpha: 0.22),
                            child: Text(item.profile.initials),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.profile.nickname, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(item.profile.username, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (!isActive)
                            IconButton(
                              onPressed: () async {
                                await widget.profileController.switchProfile(item.profile.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.switch_account_outlined),
                            ),
                          IconButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Удалить профиль?'),
                                  content: Text('Профиль "${item.profile.nickname}" будет удалён вместе с сохранённым прогрессом.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
                                    TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Удалить')),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await widget.profileController.deleteProfile(item.profile.id);
                                if (context.mounted && !widget.profileController.hasProfiles) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
