import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/achievement.dart';
import 'badges.dart';

class AchievementCard extends StatelessWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isAvailable,
    required this.lockedHint,
    required this.onTap,
  });

  final Achievement achievement;
  final bool isAvailable;
  final String? lockedHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rarity = rarityMeta[achievement.rarity]!;
    final progress = achievement.maxProgress == 0
        ? 0.0
        : achievement.progress.current / achievement.maxProgress;
    final title = achievement.hidden && !achievement.isUnlocked
        ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'
        : achievement.title;
    final description = achievement.hidden && !achievement.isUnlocked
        ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ.'
        : achievement.description;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: achievement.isUnlocked ? const Color(0xFF152A3E) : AppTheme.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rarity.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: rarity.color),
              ),
              child: Text(
                achievement.hidden && !achievement.isUnlocked ? '?' : achievement.icon,
                style: TextStyle(
                  color: rarity.color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        achievement.isUnlocked
                            ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ'
                            : isAvailable
                                ? 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅ'
                                : 'пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ',
                        style: TextStyle(
                          color: achievement.isUnlocked
                              ? AppTheme.success
                              : isAvailable
                                  ? AppTheme.textMuted
                                  : AppTheme.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      RarityBadge(rarity: achievement.rarity),
                      const Spacer(),
                      Text(
                        '${achievement.xp} XP',
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CategoryBadge(category: achievement.category),
                  if (!isAvailable && lockedHint != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      lockedHint!,
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(rarity.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${achievement.progress.current}/${achievement.maxProgress}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        achievement.progress.unlockedAt == null
                            ? 'пїЅ пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ'
                            : formatLongDate(achievement.progress.unlockedAt!),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

