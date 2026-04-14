import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/achievement.dart';
import '../controllers/achievement_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.achievementController,
    required this.profileController,
    required this.recentAchievements,
    required this.onOpenProfile,
  });

  final AchievementController achievementController;
  final ProfileController profileController;
  final List<Achievement> recentAchievements;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final profile = achievementController.profile;
    final user = profileController.activeProfile!;
    final level = achievementController.levelData;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InkWell(
          onTap: onOpenProfile,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.primaries[
                      user.avatarSeed % Colors.primaries.length]
                      .withValues(alpha: 0.24),
                  child: Text(
                    user.initials,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.about,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${profile.totalXp} XP',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  _TinyStat(label: 'LVL', value: '${profile.level}'),
                  _TinyStat(label: 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ', value: '${profile.unlockedCount}'),
                  _TinyStat(label: 'пїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ', value: '${profile.pendingProofCount}'),
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
              const Text(
                'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _rarityStep(
                label: 'Common',
                hint: 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ',
                active: true,
                color: rarityMeta[AchievementRarity.common]!.color,
              ),
              _rarityStep(
                label: 'Rare',
                hint: '${achievementController.unlockedCommonCount}/1 Common',
                active: achievementController.isRarityAvailable(AchievementRarity.rare),
                color: rarityMeta[AchievementRarity.rare]!.color,
              ),
              _rarityStep(
                label: 'Epic',
                hint: '${achievementController.unlockedRareCount}/3 Rare',
                active: achievementController.isRarityAvailable(AchievementRarity.epic),
                color: rarityMeta[AchievementRarity.epic]!.color,
              ),
              _rarityStep(
                label: 'Legendary',
                hint: '${achievementController.unlockedEpicCount}/5 Epic',
                active: achievementController.isRarityAvailable(AchievementRarity.legendary),
                color: rarityMeta[AchievementRarity.legendary]!.color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (recentAchievements.isEmpty)
                const Text(
                  'пїЅпїЅпїЅпїЅ пїЅ пїЅпїЅпїЅпїЅ пїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ. пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅ пїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              else
                ...recentAchievements.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rarityMeta[item.rarity]!.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            item.icon,
                            style: TextStyle(
                              color: rarityMeta[item.rarity]!.color,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rarityStep({
    required String label,
    required String hint,
    required bool active,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            active ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: active ? color : AppTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(
            hint,
            style: TextStyle(
              color: active ? color : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

