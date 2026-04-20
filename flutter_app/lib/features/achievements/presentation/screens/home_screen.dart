import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../feed/presentation/controllers/wallet_controller.dart';
import '../../../profile/domain/profile_models.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/achievement.dart';
import '../controllers/achievement_controller.dart';
import '../widgets/home_dashboard_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.achievementController,
    required this.profileController,
    required this.walletController,
    required this.recentAchievements,
    required this.onOpenProfile,
  });

  final AchievementController achievementController;
  final ProfileController profileController;
  final WalletController walletController;
  final List<Achievement> recentAchievements;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final profile = achievementController.profile;
    final user = profileController.activeProfile!;
    final totalCoins = walletController.totalCoins > 0 ? walletController.totalCoins : profile.totalCoins;
    final activeChallenges = achievementController.achievements
        .where((item) => !item.isUnlocked)
        .toList()
      ..sort((a, b) {
        final progressCompare = b.progress.current.compareTo(a.progress.current);
        if (progressCompare != 0) {
          return progressCompare;
        }
        return b.coins.compareTo(a.coins);
      });
    final featuredChallenges = activeChallenges.take(3).toList();
    final showcase = recentAchievements.isNotEmpty
        ? recentAchievements.take(5).toList()
        : achievementController.achievements.where((item) => item.isUnlocked).take(5).toList();
    final medalsCount = achievementController.achievements
        .where((item) => item.isUnlocked && item.rarity != AchievementRarity.common)
        .length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.background, AppTheme.backgroundSecondary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _HeroCard(
            initials: user.initials,
            nickname: user.nickname,
            username: user.username,
            status: _buildStatusLine(profile, totalCoins),
            about: user.about,
            avatarSeed: user.avatarSeed,
            totalCoins: totalCoins,
            onOpenProfile: onOpenProfile,
          ),
          const SizedBox(height: 22),
          const HomeSectionHeader(
            title: 'Быстрая статистика',
            subtitle: 'Снимок твоей активности, чтобы сразу понимать, где сейчас идёт движение.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 372,
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.12,
              children: [
                HomeMetricCard(
                  label: 'Активные',
                  value: '${activeChallenges.length}',
                  icon: Icons.bolt_rounded,
                  color: AppTheme.accent,
                  hint: 'В работе прямо сейчас',
                ),
                HomeMetricCard(
                  label: 'Выполненные',
                  value: '${profile.unlockedCount}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                  hint: 'Уже принесли награду',
                ),
                HomeMetricCard(
                  label: 'Coins',
                  value: '$totalCoins',
                  icon: Icons.monetization_on_rounded,
                  color: AppTheme.warning,
                  hint: walletController.isLoading ? 'Обновляем с backend' : 'Реальный баланс кошелька',
                ),
                HomeMetricCard(
                  label: 'Медали',
                  value: '$medalsCount',
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFFFB347),
                  hint: 'Редкие и выше',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const HomeSectionHeader(
            title: 'Ближайшие челленджи',
            subtitle: 'Самые живые задачи, к которым проще всего вернуться прямо сейчас.',
          ),
          const SizedBox(height: 14),
          if (featuredChallenges.isEmpty)
            const _EmptyStateCard(
              title: 'Активных челленджей пока нет',
              subtitle: 'Открой новую цель или дождись свежих подборок в ленте рекомендаций.',
              icon: Icons.explore_off_rounded,
            )
          else
            ...featuredChallenges.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FeaturedChallengeCard(
                  achievement: item,
                  onTap: () => _showChallengeHint(context, item.title),
                ),
              ),
            ),
          const SizedBox(height: 22),
          const HomeSectionHeader(
            title: 'Интересы',
            subtitle: 'Сигналы для будущих подборок, групп и рекомендованных челленджей.',
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InterestPill(label: 'Футбол', color: Color(0xFF6EDF88), icon: Icons.sports_soccer_rounded),
              InterestPill(label: 'CSGO', color: Color(0xFFF3B562), icon: Icons.sports_esports_rounded),
              InterestPill(label: 'Кино', color: Color(0xFFFF8FB1), icon: Icons.movie_creation_outlined),
              InterestPill(label: 'Музыка', color: Color(0xFF66C0F4), icon: Icons.graphic_eq_rounded),
              InterestPill(label: 'Путешествия', color: Color(0xFFBB86FF), icon: Icons.flight_takeoff_rounded),
              InterestPill(label: 'Саморазвитие', color: Color(0xFF7EE0D6), icon: Icons.psychology_rounded),
            ],
          ),
          const SizedBox(height: 22),
          const HomeSectionHeader(
            title: 'Витрина медалей',
            subtitle: 'Последние сильные открытия, которые уже работают на твой статус.',
          ),
          const SizedBox(height: 14),
          if (showcase.isEmpty)
            const _EmptyStateCard(
              title: 'Медали ещё впереди',
              subtitle: 'Как только появятся первые открытия, здесь соберётся компактная витрина наград.',
              icon: Icons.military_tech_outlined,
            )
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: showcase.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => MedalShowcaseCard(achievement: showcase[index]),
              ),
            ),
        ],
      ),
    );
  }

  static String _buildStatusLine(PlayerProfile profile, int totalCoins) {
    if (profile.unlockedCount >= 12) {
      return 'Собирает сильную витрину и держит хороший темп.';
    }
    if (profile.unlockedCount >= 5) {
      return 'Уже разогнал прогресс и уверенно копит баланс для новых челленджей.';
    }
    if (totalCoins >= 100) {
      return 'Набрал стартовый банк и готов к редким челленджам.';
    }
    return 'Только набирает обороты, но баланс уже начинает расти.';
  }

  static void _showChallengeHint(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Челлендж "$title" можно продолжить из списка достижений.')),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.initials,
    required this.nickname,
    required this.username,
    required this.status,
    required this.about,
    required this.avatarSeed,
    required this.totalCoins,
    required this.onOpenProfile,
  });

  final String initials;
  final String nickname;
  final String username;
  final String status;
  final String about;
  final int avatarSeed;
  final int totalCoins;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final accent = Colors.primaries[avatarSeed % Colors.primaries.length];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.24), const Color(0xFF102235), const Color(0xFF0C1825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                child: Text(initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(username, style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: onOpenProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Профиль'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(status, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Text(about, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Баланс монет', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        '$totalCoins',
                        style: const TextStyle(fontSize: 42, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.2),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0xFFFFD46B), Color(0xFFF3B562)]),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(243, 181, 98, 0.45),
                        blurRadius: 26,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.monetization_on_rounded, color: AppTheme.background, size: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 30),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
