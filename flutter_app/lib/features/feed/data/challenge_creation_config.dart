import '../domain/feed_challenge.dart';

class ChallengeCreationPlan {
  const ChallengeCreationPlan({
    required this.rarity,
    required this.title,
    required this.creationCost,
    required this.revenueShare,
    required this.highlight,
  });

  final FeedChallengeRarity rarity;
  final String title;
  final int creationCost;
  final int revenueShare;
  final String highlight;
}

const challengeCreationPlans = <ChallengeCreationPlan>[
  ChallengeCreationPlan(
    rarity: FeedChallengeRarity.common,
    title: 'Обычный',
    creationCost: 0,
    revenueShare: 5,
    highlight: 'Быстрый вход в создание без стартовых затрат.',
  ),
  ChallengeCreationPlan(
    rarity: FeedChallengeRarity.rare,
    title: 'Редкий',
    creationCost: 120,
    revenueShare: 12,
    highlight: 'Выше заметность в ленте и сильнее первый отклик.',
  ),
  ChallengeCreationPlan(
    rarity: FeedChallengeRarity.epic,
    title: 'Эпик',
    creationCost: 300,
    revenueShare: 18,
    highlight: 'Подходит для сильных идей с серийной вовлечённостью.',
  ),
  ChallengeCreationPlan(
    rarity: FeedChallengeRarity.legendary,
    title: 'Легендарный',
    creationCost: 800,
    revenueShare: 25,
    highlight: 'Для событийных челленджей с заметным продуктовым весом.',
  ),
  ChallengeCreationPlan(
    rarity: FeedChallengeRarity.mythic,
    title: 'Мифический',
    creationCost: 1800,
    revenueShare: 35,
    highlight: 'Максимальная витрина, статус и creator-экономика.',
  ),
];

ChallengeCreationPlan planForRarity(FeedChallengeRarity rarity) {
  return challengeCreationPlans.firstWhere((item) => item.rarity == rarity);
}
