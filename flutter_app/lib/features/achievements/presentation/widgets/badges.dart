import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/achievement.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity});

  final AchievementRarity rarity;

  @override
  Widget build(BuildContext context) {
    final meta = rarityMeta[rarity]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: meta.color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: meta.color,
            child: Text(
              meta.icon,
              style: const TextStyle(
                color: AppTheme.background,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            meta.label,
            style: TextStyle(
              color: meta.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});

  final AchievementCategory category;

  @override
  Widget build(BuildContext context) {
    final meta = categoryMeta[category]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: meta.color),
      ),
      child: Text(
        meta.label,
        style: TextStyle(
          color: meta.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

