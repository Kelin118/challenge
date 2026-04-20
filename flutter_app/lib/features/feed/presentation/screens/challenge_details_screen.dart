import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/challenge_controller.dart';
import '../controllers/execution_controller.dart';
import '../controllers/feed_controller.dart';
import '../widgets/challenge_details_widgets.dart';
import 'challenge_execution_screen.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  const ChallengeDetailsScreen({
    super.key,
    required this.feedController,
    required this.challengeController,
    required this.executionController,
    required this.challengeId,
  });

  final FeedController feedController;
  final ChallengeController challengeController;
  final ExecutionController executionController;
  final String challengeId;

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.challengeController.loadChallenge(widget.challengeId).catchError((_) => null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.feedController, widget.challengeController]),
      builder: (context, _) {
        final challenge = widget.challengeController.challengeById(widget.challengeId);
        final isLoading = widget.challengeController.isLoading(widget.challengeId) && challenge == null;
        final error = widget.challengeController.errorFor(widget.challengeId);

        if (isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('Челлендж')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (challenge == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: const Text('Челлендж')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Челлендж не найден', style: TextStyle(fontWeight: FontWeight.w800)),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: () => widget.challengeController.loadChallenge(widget.challengeId),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('Челлендж')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(error, style: const TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
              ChallengeHeroCard(challenge: challenge),
              const SizedBox(height: 18),
              DetailSectionCard(
                title: 'Что нужно сделать',
                trailing: Text(
                  challenge.deadlineLabel,
                  style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                ),
                child: Text(challenge.fullDescription, style: const TextStyle(color: AppTheme.textSecondary, height: 1.45)),
              ),
              const SizedBox(height: 14),
              DetailSectionCard(title: 'Правила', child: BulletedList(items: challenge.rules)),
              const SizedBox(height: 14),
              DetailSectionCard(
                title: 'Критерии успешного выполнения',
                child: BulletedList(items: challenge.successCriteria, icon: Icons.task_alt_rounded),
              ),
              const SizedBox(height: 14),
              DetailSectionCard(
                title: 'Ограничения и сроки',
                child: Text(challenge.limitations, style: const TextStyle(color: AppTheme.textSecondary, height: 1.45)),
              ),
              const SizedBox(height: 14),
              DetailSectionCard(title: 'Награда и статус', child: RewardHighlightCard(challenge: challenge)),
              const SizedBox(height: 14),
              DetailSectionCard(
                title: 'Автор',
                child: AuthorCard(
                  challenge: challenge,
                  onFollow: () {
                    widget.feedController.toggleFollowAuthor(challenge.id);
                    _showSnack(context, challenge.isFollowingAuthor ? 'Подписка снята' : 'Подписка оформлена');
                  },
                  onOpenProfile: () => _showSnack(context, 'Профиль автора подключим следующим шагом'),
                ),
              ),
              const SizedBox(height: 14),
              DetailSectionCard(
                title: 'Действия',
                child: ActionPanel(
                  challenge: challenge,
                  onAccept: () async {
                    try {
                      await widget.challengeController.acceptChallenge(challenge.id);
                      if (!context.mounted) return;
                      _showSnack(context, 'Челлендж принят, можно переходить к выполнению');
                      _openExecution(context, challenge.id);
                    } catch (error) {
                      if (!context.mounted) return;
                      _showSnack(context, error.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                  onOpenExecution: () => _openExecution(context, challenge.id),
                  onLike: () => widget.feedController.toggleLike(challenge.id),
                  onSave: () => widget.feedController.toggleSave(challenge.id),
                  onShare: () => _showSnack(context, 'Шеринг подключим следующим шагом'),
                ),
              ),
              const SizedBox(height: 14),
              DetailSectionCard(title: 'Подтверждение выполнения', child: VerificationCard(challenge: challenge)),
              const SizedBox(height: 14),
              DetailSectionCard(title: 'Вовлечённость', child: EngagementCard(challenge: challenge)),
            ],
          ),
        );
      },
    );
  }

  void _openExecution(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeExecutionScreen(
          challengeController: widget.challengeController,
          executionController: widget.executionController,
          challengeId: id,
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

