import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/challenge_controller.dart';
import '../controllers/execution_controller.dart';
import '../controllers/feed_controller.dart';
import '../../domain/feed_content_item.dart';
import '../widgets/feed_widgets.dart';
import 'challenge_details_screen.dart';
import 'create_challenge_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.controller,
    required this.challengeController,
    required this.executionController,
  });

  final FeedController controller;
  final ChallengeController challengeController;
  final ExecutionController executionController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, challengeController, executionController]),
      builder: (context, _) {
        final visible = controller.visibleItems;
        final generated = controller.generatedForYou;

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Лента челленджей', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                        SizedBox(height: 6),
                        Text(
                          'Живой поток челленджей, подтверждённых выполнений и creator-экономики.',
                          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openCreate(context),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Создать'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FeedFilterBar(current: controller.filter, onChanged: controller.setFilter),
              const SizedBox(height: 14),
              InterestBar(interests: controller.interests, selectedInterest: controller.selectedInterest, onChanged: controller.setInterest),
              const SizedBox(height: 18),
              if (controller.isLoading && !controller.isReady)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (controller.errorMessage != null)
                  _InlineStatusCard(
                    icon: controller.usingFallback ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                    title: controller.usingFallback ? 'Показываем fallback-ленту' : 'Не удалось обновить ленту',
                    subtitle: controller.errorMessage!,
                    actionLabel: 'Повторить',
                    onAction: controller.load,
                  ),
                if (generated.isNotEmpty) ...[
                  const Text('Сгенерировано для тебя', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    controller.usingFallback
                        ? 'Эти сценарии собраны локально, пока backend недоступен.'
                        : 'Выбрали живые челленджи по твоим категориям и текущему интересу.',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: generated.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final challenge = generated[index];
                        return GeneratedShowcaseCard(
                          challenge: challenge,
                          onOpen: () => _openDetails(context, challenge.id),
                          onAccept: () => _accept(context, challenge.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                Row(
                  children: [
                    const Text('Лента', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text('${controller.visibleCount} карточек', style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  const _InlineStatusCard(
                    icon: Icons.stream_outlined,
                    title: 'Ничего не найдено',
                    subtitle: 'Попробуй переключить фильтр или выбрать другую тему, чтобы увидеть новые события.',
                  )
                else
                  ...visible.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: switch (item.type) {
                          FeedContentType.challenge => FeedChallengeCard(
                              challenge: item.challenge!,
                              onOpen: () => _openDetails(context, item.challenge!.id),
                              onAccept: () => _accept(context, item.challenge!.id),
                              onLike: () => controller.toggleLike(item.challenge!.id),
                              onSave: () => controller.toggleSave(item.challenge!.id),
                            ),
                          FeedContentType.completion => CompletionEventCard(
                              event: item.completion!,
                              onLike: () => controller.toggleCompletionEventLike(item.completion!.id),
                              onShare: () => _showShareSnack(context, controller.buildCompletionShareText(item.completion!)),
                            ),
                        },
                      )),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _accept(BuildContext context, String challengeId) async {
    try {
      await challengeController.acceptChallenge(challengeId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Челлендж принят. Можно переходить к выполнению.')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _openDetails(BuildContext context, String challengeId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeDetailsScreen(
          feedController: controller,
          challengeController: challengeController,
          executionController: executionController,
          challengeId: challengeId,
        ),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateChallengeScreen(
          feedController: controller,
          challengeController: challengeController,
          executionController: executionController,
        ),
      ),
    );
  }

  void _showShareSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

