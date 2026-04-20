import '../../achievements/domain/achievement.dart';
import '../../profile/domain/profile_models.dart';
import '../domain/feed_challenge.dart';
import 'challenge_template_source.dart';

class ChallengeFeedService {
  const ChallengeFeedService();

  FeedSnapshot buildFeed({
    required LocalUserProfile? profile,
    required List<Achievement> achievements,
  }) {
    final interests = _deriveInterests(profile, achievements);
    final generated = _buildGeneratedChallenges(interests: interests, achievements: achievements);
    final editorial = _buildEditorialChallenges(interests);
    final groupChallenges = _buildGroupChallenges(interests);

    return FeedSnapshot(
      challenges: [...generated, ...editorial, ...groupChallenges],
      generatedForYou: generated.take(5).toList(),
      interests: interests,
    );
  }

  List<String> _deriveInterests(LocalUserProfile? profile, List<Achievement> achievements) {
    final about = (profile?.about ?? '').toLowerCase();
    final nickname = (profile?.nickname ?? '').toLowerCase();
    final suggestions = <String>{};
    final haystack = '$about $nickname';

    void addIfMatch(String interest, List<String> keywords) {
      if (keywords.any(haystack.contains)) {
        suggestions.add(interest);
      }
    }

    addIfMatch('Футбол', ['футбол', 'матч', 'лига']);
    addIfMatch('CSGO', ['csgo', 'counter', 'premier', 'faceit']);
    addIfMatch('Кино', ['кино', 'фильм', 'сериал']);
    addIfMatch('Спорт', ['спорт', 'зал', 'бег', 'трен']);
    addIfMatch('Чтение', ['книга', 'чтение', 'читать']);
    addIfMatch('Саморазвитие', ['рост', 'само', 'дисцип']);
    addIfMatch('Создание', ['контент', 'созда', 'автор']);

    final unlockedCategories = achievements.where((item) => item.isUnlocked).map((item) => item.category).toSet();
    if (unlockedCategories.contains(AchievementCategory.exploration)) {
      suggestions.add('Кино');
    }
    if (unlockedCategories.contains(AchievementCategory.discipline)) {
      suggestions.addAll(const ['Саморазвитие', 'Спорт']);
    }
    if (unlockedCategories.contains(AchievementCategory.social)) {
      suggestions.add('CSGO');
    }

    if (suggestions.isEmpty) {
      suggestions.addAll(const ['Футбол', 'CSGO', 'Кино']);
    }

    return suggestions.take(6).toList();
  }

  List<FeedChallenge> _buildGeneratedChallenges({
    required List<String> interests,
    required List<Achievement> achievements,
  }) {
    final activeCount = achievements.where((item) => !item.isUnlocked && item.progress.current > 0).length;
    final unlockedCount = achievements.where((item) => item.isUnlocked).length;

    return systemChallengeTemplates
        .where((template) => template.recommendedFor.any(interests.contains))
        .map((template) {
          final leadingInterest = template.recommendedFor.firstWhere(
            interests.contains,
            orElse: () => template.recommendedFor.first,
          );
          final baseProgress = switch (template.type) {
            FeedChallengeType.daily => activeCount > 0 ? 0.42 : 0.18,
            FeedChallengeType.yearly => unlockedCount > 6 ? 0.24 : 0.08,
            FeedChallengeType.permanent => unlockedCount > 10 ? 0.36 : 0.14,
          };

          return FeedChallenge(
            id: 'generated-${template.key}-$leadingInterest',
            title: template.title,
            description: template.description,
            fullDescription: template.fullDescription,
            category: template.category,
            type: template.type,
            rarity: template.rarity,
            coinReward: template.coinReward,
            authorName: 'Система Achievement Vault',
            authorHandle: '@system',
            source: template.sourceTag == 'Для тебя' ? FeedChallengeSource.recommended : FeedChallengeSource.system,
            sourceTag: template.sourceTag,
            likes: 120 + unlockedCount * 3 + template.coinReward,
            isAccepted: false,
            isLiked: false,
            isSaved: false,
            isFollowingAuthor: false,
            isSystemGenerated: true,
            recommendedFor: [leadingInterest],
            reason: template.reasonBuilder(leadingInterest),
            progress: baseProgress.clamp(0.0, 0.92),
            participants: 180 + activeCount * 14 + unlockedCount * 6,
            acceptedCount: 90 + activeCount * 8,
            completedCount: 26 + unlockedCount * 3,
            rules: template.rules,
            successCriteria: template.successCriteria,
            limitations: template.limitations,
            deadlineLabel: template.deadlineLabel,
            hasMedal: template.hasMedal,
            medalTitle: template.medalTitle,
            specialStatus: template.specialStatus,
            creatorChallengeCount: 0,
            creatorCommissionPercent: 0,
            verificationType: template.verificationType,
            executionStatus: FeedExecutionStatus.notAccepted,
            submissionText: '',
            submissionImagePath: null,
            rejectionReason: null,
            medalAwarded: false,
            completionLikes: 0,
          );
        })
        .take(5)
        .toList();
  }

  List<FeedChallenge> _buildEditorialChallenges(List<String> interests) {
    final hasCinema = interests.contains('Кино');
    final hasFootball = interests.contains('Футбол');
    final primary = interests.first;

    return [
      FeedChallenge(
        id: 'user-curator-cinema-room',
        title: hasCinema ? 'Кураторский киноклуб недели' : 'Клуб визуальных историй',
        description: 'Собери обсуждение, рекомендации и короткую рецензию, чтобы поднять активность в своей подписке.',
        fullDescription: 'Авторский челлендж для тех, кто умеет собирать вокруг себя внимание. Нужно взять одну тему недели, оформить подборку и зажечь обсуждение вокруг неё.',
        category: hasCinema ? 'Кино' : 'Контент',
        type: FeedChallengeType.permanent,
        rarity: FeedChallengeRarity.rare,
        coinReward: 75,
        authorName: 'Лера CineMood',
        authorHandle: '@cinemood',
        source: FeedChallengeSource.user,
        sourceTag: 'Подписки',
        likes: 412,
        isAccepted: false,
        isLiked: true,
        isSaved: true,
        isFollowingAuthor: false,
        isSystemGenerated: false,
        recommendedFor: [if (hasCinema) 'Кино' else primary],
        reason: hasCinema ? 'Популярно среди тех, кто любит киноразборы' : 'Подходит для твоей контентной ленты',
        progress: 0,
        participants: 136,
        acceptedCount: 84,
        completedCount: 19,
        rules: const [
          'Собери одну тему недели или микроподборку.',
          'Добавь личную рекомендацию и повод обсудить.',
          'Вовлеки группу или подписчиков в ответную реакцию.',
        ],
        successCriteria: const [
          'Людям есть что обсудить или сохранить.',
          'Подборка выглядит как авторский выбор.',
          'После публикации появляется заметная вовлечённость.',
        ],
        limitations: 'Чем сильнее кураторская подача, тем выше шанс попасть в рекомендации.',
        deadlineLabel: 'Обновляется каждую неделю',
        hasMedal: true,
        medalTitle: 'Куратор импульса',
        specialStatus: 'Создатель получает процент с выполнений и рост в витрине автора.',
        creatorChallengeCount: 18,
        creatorCommissionPercent: 12,
        verificationType: FeedVerificationType.community,
        executionStatus: FeedExecutionStatus.notAccepted,
        submissionText: '',
        submissionImagePath: null,
        rejectionReason: null,
        medalAwarded: false,
        completionLikes: 0,
      ),
      FeedChallenge(
        id: 'user-football-pulse',
        title: hasFootball ? 'Пульс тура' : 'Горячая тема недели',
        description: 'Следи за ключевым событием недели и собирай реакции команды или группы по интересам.',
        fullDescription: 'Это сценарий на быстрый захват внимания. Ты выбираешь самый обсуждаемый сюжет недели и превращаешь его в точку входа для обсуждения внутри группы.',
        category: hasFootball ? 'Футбол' : 'Группы',
        type: FeedChallengeType.daily,
        rarity: FeedChallengeRarity.common,
        coinReward: 36,
        authorName: 'Макс MatchDay',
        authorHandle: '@matchday',
        source: FeedChallengeSource.user,
        sourceTag: 'Группы',
        likes: 288,
        isAccepted: false,
        isLiked: false,
        isSaved: false,
        isFollowingAuthor: false,
        isSystemGenerated: false,
        recommendedFor: [if (hasFootball) 'Футбол' else primary],
        reason: hasFootball ? 'Популярно в группе Футбол' : 'Оживляет твою группу по интересам',
        progress: 0,
        participants: 92,
        acceptedCount: 64,
        completedCount: 14,
        rules: const [
          'Выбери главный инфоповод недели.',
          'Оформи короткий вход в обсуждение.',
          'Подведи людей к реакции или своей позиции.',
        ],
        successCriteria: const [
          'Тема действительно вызывает реакцию.',
          'Есть личная точка зрения или ценность для группы.',
          'Вокруг поста появляется движение.',
        ],
        limitations: 'Лучше всего работает на свежих сюжетах, пока тема ещё горячая.',
        deadlineLabel: 'Пока инфоповод жив',
        hasMedal: false,
        medalTitle: '',
        specialStatus: 'Хороший формат для лёгкого social-роста.',
        creatorChallengeCount: 9,
        creatorCommissionPercent: 8,
        verificationType: FeedVerificationType.community,
        executionStatus: FeedExecutionStatus.notAccepted,
        submissionText: '',
        submissionImagePath: null,
        rejectionReason: null,
        medalAwarded: false,
        completionLikes: 0,
      ),
    ];
  }

  List<FeedChallenge> _buildGroupChallenges(List<String> interests) {
    final primary = interests.first;
    return [
      FeedChallenge(
        id: 'group-$primary-top-pick',
        title: 'Топ-челлендж в группе "$primary"',
        description: 'Вступай в обсуждение, принимай челлендж и получай быстрые coins за активность в своей группе.',
        fullDescription: 'Это витринный групповой сценарий. Он создан, чтобы быстро включить тебя в сообщество, дать повод проявиться и превратить интерес в заметное действие внутри группы.',
        category: primary,
        type: FeedChallengeType.daily,
        rarity: FeedChallengeRarity.epic,
        coinReward: 95,
        authorName: 'Группа $primary',
        authorHandle: '@group_${primary.toLowerCase()}',
        source: FeedChallengeSource.recommended,
        sourceTag: 'Для тебя',
        likes: 640,
        isAccepted: false,
        isLiked: false,
        isSaved: true,
        isFollowingAuthor: false,
        isSystemGenerated: false,
        recommendedFor: [primary],
        reason: 'Популярно в группе $primary',
        progress: 0,
        participants: 420,
        acceptedCount: 210,
        completedCount: 61,
        rules: const [
          'Подключись к обсуждению или общему сценарию группы.',
          'Сделай один видимый вклад: мнение, результат или реакцию.',
          'Подтверди участие и вернись за продолжением.',
        ],
        successCriteria: const [
          'Ты реально появился внутри групповой динамики.',
          'Есть вклад, который видят другие.',
          'Челлендж стимулирует вернуться в группу снова.',
        ],
        limitations: 'Лучше всего работает внутри активной группы по интересам.',
        deadlineLabel: 'До конца текущего цикла группы',
        hasMedal: true,
        medalTitle: 'Свой в группе',
        specialStatus: 'Помогает быстрее закрепиться внутри тематического круга.',
        creatorChallengeCount: 24,
        creatorCommissionPercent: 10,
        verificationType: FeedVerificationType.community,
        executionStatus: FeedExecutionStatus.notAccepted,
        submissionText: '',
        submissionImagePath: null,
        rejectionReason: null,
        medalAwarded: false,
        completionLikes: 0,
      ),
    ];
  }
}
