import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/challenge_creation_config.dart';
import '../../domain/feed_challenge.dart';
import 'feed_widgets.dart';

class CreationHeroCard extends StatelessWidget {
  const CreationHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2334), Color(0xFF122B3B), Color(0xFF101722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(243, 181, 98, 0.12),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Создай челлендж', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text(
            'Зарабатывай coins, когда другие выполняют твой челлендж.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              _TopBadge(label: 'Creator economy'),
              SizedBox(width: 8),
              _TopBadge(label: 'Доход с выполнений'),
              SizedBox(width: 8),
              _TopBadge(label: 'Витрина автора'),
            ],
          ),
        ],
      ),
    );
  }
}

class RarityPlanSelector extends StatelessWidget {
  const RarityPlanSelector({
    super.key,
    required this.selectedPlan,
    required this.onChanged,
  });

  final ChallengeCreationPlan selectedPlan;
  final ValueChanged<ChallengeCreationPlan> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: challengeCreationPlans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final plan = challengeCreationPlans[index];
          final selected = plan.rarity == selectedPlan.rarity;
          final rarityColor = FeedPalette.rarityColor(plan.rarity);
          return GestureDetector(
            onTap: () => onChanged(plan),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 220,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rarityColor.withValues(alpha: selected ? 0.26 : 0.16), AppTheme.card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? rarityColor : rarityColor.withValues(alpha: 0.22),
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: rarityColor.withValues(alpha: 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(plan.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                      if (selected) Icon(Icons.check_circle_rounded, color: rarityColor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(plan.highlight, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
                  const Spacer(),
                  Text(
                    plan.creationCost == 0 ? 'Бесплатно' : '${plan.creationCost} coins',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.warning),
                  ),
                  const SizedBox(height: 6),
                  Text('Доход автора: ${plan.revenueShare}%', style: TextStyle(color: rarityColor, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class EconomySummaryCard extends StatelessWidget {
  const EconomySummaryCard({super.key, required this.plan, required this.coinReward});

  final ChallengeCreationPlan plan;
  final int coinReward;

  @override
  Widget build(BuildContext context) {
    final projectedCompletions = switch (plan.rarity) {
      FeedChallengeRarity.common => 18,
      FeedChallengeRarity.rare => 22,
      FeedChallengeRarity.epic => 28,
      FeedChallengeRarity.legendary => 34,
      FeedChallengeRarity.mythic => 42,
    };
    final projectedGross = (projectedCompletions * coinReward * plan.revenueShare / 100).round();
    final projectedNet = projectedGross - plan.creationCost;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Экономика', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _EconomyMetric(label: 'Стоимость создания', value: '${plan.creationCost}', suffix: 'coins')),
              const SizedBox(width: 10),
              Expanded(child: _EconomyMetric(label: 'Доход автора', value: '${plan.revenueShare}', suffix: '%')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _EconomyMetric(label: 'Награда исполнителю', value: '$coinReward', suffix: 'coins')),
              const SizedBox(width: 10),
              Expanded(child: _EconomyMetric(label: 'Примерный net', value: '$projectedNet', suffix: 'coins')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Если челлендж пройдут около $projectedCompletions человек, ты можешь заработать примерно $projectedGross coins до вычета стоимости создания.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class ChallengeLivePreviewCard extends StatelessWidget {
  const ChallengeLivePreviewCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final rarityColor = FeedPalette.rarityColor(challenge.rarity);
    final sourceColor = FeedPalette.sourceColor(challenge);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rarityColor.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PreviewTag(label: feedChallengeRarityLabel(challenge.rarity), color: rarityColor),
              const SizedBox(width: 8),
              _PreviewTag(label: challenge.sourceTag, color: sourceColor),
              const Spacer(),
              Text('+${challenge.coinReward} coins', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Text(challenge.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.38)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMeta(label: challenge.category),
              _MiniMeta(label: feedChallengeTypeLabel(challenge.type)),
              _MiniMeta(label: feedVerificationTypeLabel(challenge.verificationType)),
            ],
          ),
        ],
      ),
    );
  }
}

class CreatorHintList extends StatelessWidget {
  const CreatorHintList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Что делает челлендж сильным', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          SizedBox(height: 14),
          _HintRow(text: 'Одна понятная задача без перегруженных условий.'),
          _HintRow(text: 'Награда соответствует усилию и редкости.'),
          _HintRow(text: 'Подтверждение легко показать: фото, текст или короткий proof.'),
          _HintRow(text: 'Название цепляет, а описание сразу объясняет выгоду.'),
        ],
      ),
    );
  }
}

class _EconomyMetric extends StatelessWidget {
  const _EconomyMetric({required this.label, required this.value, required this.suffix});

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
              children: [
                TextSpan(text: ' $suffix', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.tips_and_updates_outlined, size: 18, color: AppTheme.accent),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4))),
        ],
      ),
    );
  }
}
