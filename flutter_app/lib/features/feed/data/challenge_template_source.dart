import '../domain/feed_challenge.dart';

class ChallengeTemplate {
  const ChallengeTemplate({
    required this.key,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.category,
    required this.type,
    required this.rarity,
    required this.coinReward,
    required this.sourceTag,
    required this.recommendedFor,
    required this.rules,
    required this.successCriteria,
    required this.limitations,
    required this.deadlineLabel,
    required this.hasMedal,
    required this.medalTitle,
    required this.specialStatus,
    required this.verificationType,
    required this.reasonBuilder,
  });

  final String key;
  final String title;
  final String description;
  final String fullDescription;
  final String category;
  final FeedChallengeType type;
  final FeedChallengeRarity rarity;
  final int coinReward;
  final String sourceTag;
  final List<String> recommendedFor;
  final List<String> rules;
  final List<String> successCriteria;
  final String limitations;
  final String deadlineLabel;
  final bool hasMedal;
  final String medalTitle;
  final String specialStatus;
  final FeedVerificationType verificationType;
  final String Function(String interest) reasonBuilder;
}

const systemChallengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    key: 'football-daily-breakdown',
    title: 'Разбор матча дня',
    description: 'Посмотри ключевой матч и собери короткий, но умный разбор для своей ленты.',
    fullDescription: 'Ты выбираешь один актуальный матч, фиксируешь три сильных эпизода и собираешь понятный разбор, которым реально хочется поделиться в группе по интересам.',
    category: 'Футбол',
    type: FeedChallengeType.daily,
    rarity: FeedChallengeRarity.rare,
    coinReward: 45,
    sourceTag: 'Система',
    recommendedFor: ['Футбол', 'Спорт'],
    rules: [
      'Выбери один матч дня или главный матч тура.',
      'Зафиксируй три сильных эпизода: тактика, эмоция, переломный момент.',
      'Собери итог в короткий текст для ленты или группы.',
    ],
    successCriteria: [
      'Есть три содержательных наблюдения.',
      'Понятно, почему матч стоит внимания.',
      'Разбор выглядит полезно для других.',
    ],
    limitations: 'Одна попытка в день. Подходит только для свежих матчей.',
    deadlineLabel: 'Сегодня до 23:59',
    hasMedal: true,
    medalTitle: 'Голос матча',
    specialStatus: 'Попадает в спортивную витрину недели.',
    verificationType: FeedVerificationType.text,
    reasonBuilder: _sportsReason,
  ),
  ChallengeTemplate(
    key: 'csgo-utility-lab',
    title: 'Utility Lab: 15 минут в день',
    description: 'Прокачивай один utility-сценарий и фиксируй заметный micro-progress.',
    fullDescription: 'Каждый день ты берёшь один smoke, flash или retake-сетап, отрабатываешь его 15 минут и описываешь, что стало стабильнее: тайминг, точка или уверенность.',
    category: 'CSGO',
    type: FeedChallengeType.daily,
    rarity: FeedChallengeRarity.rare,
    coinReward: 55,
    sourceTag: 'Для тебя',
    recommendedFor: ['CSGO', 'Киберспорт'],
    rules: [
      'Один utility-сценарий на одну сессию.',
      'Тренируй только один фокус за подход.',
      'После тренировки коротко опиши прогресс.',
    ],
    successCriteria: [
      'Есть серия ежедневных коротких сессий.',
      'Прогресс выглядит конкретно, а не абстрактно.',
      'Результат применим в реальной игре.',
    ],
    limitations: 'Если пропускаешь день, серия обнуляется.',
    deadlineLabel: 'Серия на 7 дней',
    hasMedal: true,
    medalTitle: 'Utility Mindset',
    specialStatus: 'Подходит для витрины киберспортивной дисциплины.',
    verificationType: FeedVerificationType.photo,
    reasonBuilder: _groupReason,
  ),
  ChallengeTemplate(
    key: 'cinema-director-marathon',
    title: 'Марафон одного режиссёра',
    description: 'Собери личную мини-ретроспективу из трёх фильмов одного автора.',
    fullDescription: 'Ты выбираешь одного режиссёра, смотришь три фильма и собираешь личную ретроспективу: как меняется стиль, темы и визуальный язык.',
    category: 'Кино',
    type: FeedChallengeType.yearly,
    rarity: FeedChallengeRarity.rare,
    coinReward: 60,
    sourceTag: 'Система',
    recommendedFor: ['Кино'],
    rules: [
      'Выбери одного режиссёра.',
      'Посмотри минимум три фильма в осмысленной последовательности.',
      'Собери заметки по стилю, темам и любимым сценам.',
    ],
    successCriteria: [
      'Есть единая авторская логика выбора.',
      'Заметки показывают развитие взгляда режиссёра.',
      'Результат можно оформить как персональную подборку.',
    ],
    limitations: 'Желательно не смешивать разных режиссёров в одной ветке.',
    deadlineLabel: 'В течение сезона',
    hasMedal: true,
    medalTitle: 'Куратор взгляда',
    specialStatus: 'Может попасть в тематическую витрину киноклуба.',
    verificationType: FeedVerificationType.text,
    reasonBuilder: _interestReason,
  ),
  ChallengeTemplate(
    key: 'sport-7-day-streak',
    title: '7 дней движения',
    description: 'Собери недельную серию активности: шаги, разминка, пробежка или домашняя тренировка.',
    fullDescription: 'Челлендж помогает вернуть ритм. Ты выбираешь любую форму движения и держишь серию семь дней подряд, не перегружая себя.',
    category: 'Спорт',
    type: FeedChallengeType.daily,
    rarity: FeedChallengeRarity.common,
    coinReward: 35,
    sourceTag: 'Система',
    recommendedFor: ['Спорт', 'Саморазвитие'],
    rules: [
      'Каждый день фиксируй один формат движения.',
      'Поддерживай серию 7 дней подряд.',
      'После каждого дня коротко отмечай самочувствие.',
    ],
    successCriteria: [
      'Серия собрана без пропусков.',
      'Есть понятная динамика по состоянию или нагрузке.',
      'Активность реально встроилась в рутину.',
    ],
    limitations: 'Пропуск дня обнуляет серию.',
    deadlineLabel: '7 дней подряд',
    hasMedal: true,
    medalTitle: 'Ритм тела',
    specialStatus: 'Укрепляет статус дисциплины в профиле.',
    verificationType: FeedVerificationType.photo,
    reasonBuilder: _habitReason,
  ),
  ChallengeTemplate(
    key: 'creator-mythic-run',
    title: 'Собери мифический creator-run',
    description: 'Сконструируй серию из связанных челленджей и доведи одну ветку до сильной вовлечённости.',
    fullDescription: 'Это сценарий для тех, кто хочет играть не только как участник, но и как создатель. Нужно собрать цельную арку из нескольких челленджей и продумать удержание.',
    category: 'Создание',
    type: FeedChallengeType.permanent,
    rarity: FeedChallengeRarity.mythic,
    coinReward: 520,
    sourceTag: 'Для тебя',
    recommendedFor: ['Создание', 'Саморазвитие'],
    rules: [
      'Собери минимум три связанные идеи в одну арку.',
      'У каждой части должна быть своя награда и причина пройти дальше.',
      'Продумай механику возврата в цепочку.',
    ],
    successCriteria: [
      'Арка ощущается цельной.',
      'Пользователю понятно, зачем идти дальше.',
      'Есть признаки вирусного роста или сильной вовлечённости.',
    ],
    limitations: 'Требует высокого входа по coins и продуманной экономики.',
    deadlineLabel: 'Постоянный creator-run',
    hasMedal: true,
    medalTitle: 'Архитектор ранa',
    specialStatus: 'Усиливает витрину автора и creator-экономику.',
    verificationType: FeedVerificationType.moderator,
    reasonBuilder: _creatorReason,
  ),
];

String _interestReason(String interest) => 'На основе твоих интересов: $interest';
String _groupReason(String interest) => 'Популярно в группе $interest';
String _sportsReason(String interest) => 'Подходит для активного ритма: $interest';
String _habitReason(String interest) => 'Подходит для ежедневной активности';
String _creatorReason(String interest) => 'Под твой авторский стиль и creator-экономику';
