import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/challenge_creation_config.dart';
import '../../domain/feed_challenge.dart';
import '../controllers/challenge_controller.dart';
import '../controllers/execution_controller.dart';
import '../controllers/feed_controller.dart';
import '../widgets/create_challenge_widgets.dart';
import 'challenge_details_screen.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({
    super.key,
    required this.feedController,
    required this.challengeController,
    required this.executionController,
  });

  final FeedController feedController;
  final ChallengeController challengeController;
  final ExecutionController executionController;

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conditionsController = TextEditingController();

  ChallengeCreationPlan _selectedPlan = challengeCreationPlans.first;
  FeedChallengeType _selectedType = FeedChallengeType.daily;
  FeedVerificationType _selectedVerification = FeedVerificationType.photo;
  String _selectedCategory = _categories.first;
  double _coinReward = 60;

  static const _categories = <String>['Футбол', 'CSGO', 'Кино', 'Спорт', 'Чтение', 'Саморазвитие', 'Создание', 'Группы'];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_handleDraftChanged);
    _descriptionController.addListener(_handleDraftChanged);
    _conditionsController.addListener(_handleDraftChanged);
    _titleController.text = 'Новый челлендж недели';
    _descriptionController.text = 'Сделай сильное действие, которое реально захочется повторить и обсудить в ленте.';
    _conditionsController.text = 'Покажи результат и коротко объясни, почему задача действительно выполнена.';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();

    return AnimatedBuilder(
      animation: widget.challengeController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('Создать челлендж')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const CreationHeroCard(),
              const SizedBox(height: 18),
              const Text('Выбор редкости', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Чем выше редкость, тем сильнее витрина и выше доля автора, но растёт вход по coins.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              RarityPlanSelector(selectedPlan: _selectedPlan, onChanged: (plan) => setState(() => _selectedPlan = plan)),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Основные поля',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название', hintText: 'Например: 7 дней движения')),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        hintText: 'Что получит исполнитель и почему этот челлендж хочется взять?',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Категория', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map((category) => ChoiceChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (_) => setState(() => _selectedCategory = category),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Тип', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    SegmentedButton<FeedChallengeType>(
                      segments: const [
                        ButtonSegment(value: FeedChallengeType.daily, label: Text('Дневной')),
                        ButtonSegment(value: FeedChallengeType.yearly, label: Text('Годовой')),
                        ButtonSegment(value: FeedChallengeType.permanent, label: Text('Постоянный')),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (value) => setState(() => _selectedType = value.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Награда',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Награда исполнителю', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${_coinReward.round()} coins', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Slider(
                      value: _coinReward,
                      min: 20,
                      max: 500,
                      divisions: 24,
                      label: '${_coinReward.round()}',
                      onChanged: (value) => setState(() => _coinReward = value),
                    ),
                    const Text(
                      'Сильный диапазон: 40-120 coins для everyday-челленджей, выше — для редких и легендарных сценариев.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              EconomySummaryCard(plan: _selectedPlan, coinReward: _coinReward.round()),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Условия выполнения',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _conditionsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Что нужно сделать',
                        hintText: 'Опиши финальный результат и критерий, по которому его можно подтвердить.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Как подтверждается выполнение', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    SegmentedButton<FeedVerificationType>(
                      segments: const [
                        ButtonSegment(value: FeedVerificationType.photo, label: Text('Фото / proof')),
                        ButtonSegment(value: FeedVerificationType.text, label: Text('Текст')),
                      ],
                      selected: {_selectedVerification},
                      onSelectionChanged: (value) => setState(() => _selectedVerification = value.first),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (widget.challengeController.createError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(widget.challengeController.createError!, style: const TextStyle(color: AppTheme.warning)),
                ),
              const CreatorHintList(),
              const SizedBox(height: 14),
              _SectionCard(title: 'Превью', child: ChallengeLivePreviewCard(challenge: preview)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.challengeController.isCreating ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: Colors.white, foregroundColor: AppTheme.background),
                icon: widget.challengeController.isCreating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_selectedPlan.creationCost == 0 ? 'Создать челлендж' : 'Создать и списать ${_selectedPlan.creationCost} coins'),
              ),
              const SizedBox(height: 10),
              Text(
                _selectedPlan.creationCost == 0
                    ? 'Обычный челлендж создаётся бесплатно. Доход автора будет ниже, но вход без риска.'
                    : 'При создании спишется ${_selectedPlan.creationCost} coins. Ты начнёшь зарабатывать обратно, когда другие будут проходить твой челлендж.',
                style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  FeedChallenge _buildPreview() {
    return FeedChallenge(
      id: 'preview',
      title: _titleController.text.trim().isEmpty ? 'Новый челлендж недели' : _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Сделай сильное действие, которое реально захочется повторить и обсудить в ленте.'
          : _descriptionController.text.trim(),
      fullDescription: _descriptionController.text.trim().isEmpty
          ? 'Сделай сильное действие, которое реально захочется повторить и обсудить в ленте.'
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      type: _selectedType,
      rarity: _selectedPlan.rarity,
      coinReward: _coinReward.round(),
      authorName: 'Ты',
      authorHandle: '@creator',
      source: FeedChallengeSource.user,
      sourceTag: 'Создан тобой',
      likes: 0,
      isAccepted: false,
      isLiked: false,
      isSaved: true,
      isFollowingAuthor: true,
      isSystemGenerated: false,
      recommendedFor: [_selectedCategory],
      reason: 'Превью будущего челленджа в ленте.',
      progress: 0,
      participants: 0,
      acceptedCount: 0,
      completedCount: 0,
      rules: const [],
      successCriteria: const [],
      limitations: '',
      deadlineLabel: '',
      hasMedal: _selectedPlan.rarity.index >= FeedChallengeRarity.rare.index,
      medalTitle: _selectedPlan.rarity.index >= FeedChallengeRarity.rare.index ? 'Медаль автора' : '',
      specialStatus: 'Создатель получает ${_selectedPlan.revenueShare}% с выполнений.',
      creatorChallengeCount: 1,
      creatorCommissionPercent: _selectedPlan.revenueShare,
      verificationType: _selectedVerification,
      executionStatus: FeedExecutionStatus.notAccepted,
      submissionText: '',
      submissionImagePath: null,
      rejectionReason: null,
      medalAwarded: false,
      completionLikes: 0,
    );
  }

  void _handleDraftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final conditions = _conditionsController.text.trim();

    if (title.isEmpty || description.isEmpty || conditions.isEmpty) {
      _showSnack('Заполни название, описание и условия выполнения.');
      return;
    }

    try {
      final challenge = await widget.challengeController.createChallenge(
        ChallengeDraft(
          title: title,
          description: description,
          category: _selectedCategory,
          type: _selectedType,
          rarity: _selectedPlan.rarity,
          coinReward: _coinReward.round(),
          conditions: conditions,
          verificationType: _selectedVerification,
          creationCost: _selectedPlan.creationCost,
          revenueShare: _selectedPlan.revenueShare,
        ),
      );

      await widget.feedController.load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDetailsScreen(
            feedController: widget.feedController,
            challengeController: widget.challengeController,
            executionController: widget.executionController,
            challengeId: challenge.id,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
