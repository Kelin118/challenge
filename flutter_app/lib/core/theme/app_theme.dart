import 'package:flutter/material.dart';

import '../../features/achievements/domain/achievement.dart';

class AppTheme {
  static const background = Color(0xFF081018);
  static const backgroundSecondary = Color(0xFF0D1823);
  static const panel = Color(0xFF101F2D);
  static const card = Color(0xFF132536);
  static const cardMuted = Color(0xFF102031);
  static const border = Color.fromRGBO(138, 166, 194, 0.18);
  static const text = Color(0xFFE7F1FF);
  static const textSecondary = Color(0xFF95ABC4);
  static const textMuted = Color(0xFF6D8297);
  static const accent = Color(0xFF66C0F4);
  static const success = Color(0xFF6EDF88);
  static const warning = Color(0xFFF3B562);
  static const danger = Color(0xFFFF6B7D);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: panel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundSecondary,
        foregroundColor: text,
        elevation: 0,
      ),
      cardColor: card,
      dividerColor: border,
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardMuted,
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accent),
        ),
      ),
    );
  }
}

class RarityMeta {
  const RarityMeta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final String icon;
}

const rarityMeta = <AchievementRarity, RarityMeta>{
  AchievementRarity.common: RarityMeta(label: 'Common', color: Color(0xFF9FB3C8), icon: 'C'),
  AchievementRarity.rare: RarityMeta(label: 'Rare', color: Color(0xFF66C0F4), icon: 'R'),
  AchievementRarity.epic: RarityMeta(label: 'Epic', color: Color(0xFFBB86FF), icon: 'E'),
  AchievementRarity.legendary: RarityMeta(label: 'Legendary', color: Color(0xFFFFB347), icon: 'L'),
};

class CategoryMeta {
  const CategoryMeta({required this.label, required this.color});

  final String label;
  final Color color;
}

const categoryMeta = <AchievementCategory, CategoryMeta>{
  AchievementCategory.story: CategoryMeta(label: 'Сюжет', color: Color(0xFF66C0F4)),
  AchievementCategory.social: CategoryMeta(label: 'Социалка', color: Color(0xFF8EE38F)),
  AchievementCategory.exploration: CategoryMeta(label: 'Исследование', color: Color(0xFFF3B562)),
  AchievementCategory.discipline: CategoryMeta(label: 'Дисциплина', color: Color(0xFFFF8FB1)),
  AchievementCategory.chaos: CategoryMeta(label: 'Хаос', color: Color(0xFFBB86FF)),
  AchievementCategory.secret: CategoryMeta(label: 'Секретные', color: Color(0xFFF87070)),
  AchievementCategory.custom: CategoryMeta(label: 'Свои', color: Color(0xFF7DD3FC)),
};
