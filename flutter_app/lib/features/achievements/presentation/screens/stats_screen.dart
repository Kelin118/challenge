import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../domain/achievement.dart';
import '../controllers/achievement_controller.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final AchievementController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final rarest = controller.rarestUnlocked;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '����������',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          '��������� XP, �������� � ������ �� ����������� � ����� �����.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatTile(label: '�������', value: '${profile.unlockedCount}')),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: '����� XP', value: '${profile.totalXp}')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatTile(label: '��������', value: '${profile.completionRate.toStringAsFixed(0)}%')),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Legendary',
                value: '${controller.unlockedByRarity[AchievementRarity.legendary] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '�������������� �� ��������',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...AchievementRarity.values.map(
                (rarity) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(rarityMeta[rarity]!.label, style: const TextStyle(color: AppTheme.textSecondary)),
                      const Spacer(),
                      Text(
                        '${controller.unlockedByRarity[rarity] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
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
                '���������',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...controller.categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(categoryMeta[category]!.label, style: const TextStyle(color: AppTheme.textSecondary)),
                      const Spacer(),
                      Text(
                        '${controller.countByCategory[category] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
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
                '����� ������ �������� ������',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (rarest == null)
                const Text(
                  '���� �����. ������ ������� ������ ��� �������.',
                  style: TextStyle(color: AppTheme.textSecondary),
                )
              else ...[
                Text(rarest.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(rarest.description, style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

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
