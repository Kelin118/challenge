import 'package:flutter/material.dart';

import 'package:achievement_vault_flutter/core/theme/app_theme.dart';
import 'package:achievement_vault_flutter/core/widgets/app_panel.dart';
import 'package:achievement_vault_flutter/features/achievements/presentation/controllers/achievement_controller.dart';
import 'package:achievement_vault_flutter/features/auth/presentation/controllers/auth_controller.dart';
import 'package:achievement_vault_flutter/features/profile/presentation/controllers/profile_controller.dart';
import 'package:achievement_vault_flutter/features/sessions/presentation/controllers/session_controller.dart';
import 'package:achievement_vault_flutter/features/sessions/presentation/screens/active_sessions_screen.dart';

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
    final level = widget.achievementController.levelData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('�������'),
        actions: [
          IconButton(
            onPressed: () async {
              await widget.authController.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: '�����',
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
                Column(
                  children: [
                    const Text('LVL', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                    Text('${profile.level}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('����������', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  '�������� �������� ���������� � ������� ������ ������.',
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
                  child: const Text('�������� ����������'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('�������� ��������', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: level.levelProgress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${profile.totalXp} XP', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(
                      '�������: ${profile.unlockedCount}/${profile.totalCount}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('�������������� �������', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: _nameController, decoration: const InputDecoration(hintText: '���')),
                const SizedBox(height: 12),
                TextField(controller: _usernameController, decoration: const InputDecoration(hintText: 'username', prefixText: '@')),
                const SizedBox(height: 12),
                TextField(controller: _aboutController, decoration: const InputDecoration(hintText: '������ / � ����')),
                const SizedBox(height: 12),
                TextField(controller: _contactController, decoration: const InputDecoration(hintText: '�������')),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('������� �������')));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.background,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('��������� ���������'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('�������', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                                  title: const Text('������� �������?'),
                                  content: Text('������� "${item.profile.nickname}" ����� ����� ������ � ���������� �����������.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('������')),
                                    TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('�������')),
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
