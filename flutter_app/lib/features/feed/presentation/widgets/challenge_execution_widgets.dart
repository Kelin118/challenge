import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/feed_challenge.dart';
import 'feed_widgets.dart';

class ExecutionStatusBanner extends StatelessWidget {
  const ExecutionStatusBanner({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(challenge.executionStatus);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.18), AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(_statusIcon(challenge.executionStatus), color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feedExecutionStatusLabel(challenge.executionStatus), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(_statusDescription(challenge), style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusDescription(FeedChallenge challenge) {
    switch (challenge.executionStatus) {
      case FeedExecutionStatus.notAccepted:
        return 'Прими челлендж, чтобы начать выполнение и открыть отправку результата.';
      case FeedExecutionStatus.inProgress:
        return 'Ты уже внутри. Доведи выполнение до внятного результата и отправь proof.';
      case FeedExecutionStatus.submitted:
        return 'Результат отправлен. Backend принял proof и ждёт подтверждения.';
      case FeedExecutionStatus.approved:
        return challenge.hasMedal
            ? 'Выполнение подтверждено. Coins начислены, а медаль добавлена в профиль.'
            : 'Выполнение подтверждено. Coins начислены и статус обновлён.';
      case FeedExecutionStatus.rejected:
        return challenge.rejectionReason ?? 'Подтверждение пока не прошло. Можно доработать и отправить заново.';
    }
  }
}

class ProgressSectionCard extends StatelessWidget {
  const ProgressSectionCard({super.key, required this.challenge, required this.onAdvance});

  final FeedChallenge challenge;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Прогресс выполнения', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(challenge.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: challenge.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(FeedPalette.rarityColor(challenge.rarity)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${(challenge.progress * 100).round()}% готовности', style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text('+${challenge.coinReward} coins', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: challenge.executionStatus == FeedExecutionStatus.submitted || challenge.executionStatus == FeedExecutionStatus.approved ? null : onAdvance,
            icon: const Icon(Icons.flag_circle_rounded),
            label: const Text('Отметить шаг выполнения'),
          ),
        ],
      ),
    );
  }
}

class SubmissionComposerCard extends StatelessWidget {
  const SubmissionComposerCard({
    super.key,
    required this.challenge,
    required this.descriptionController,
    required this.onPickImage,
    required this.onSubmit,
    required this.onRetry,
  });

  final FeedChallenge challenge;
  final TextEditingController descriptionController;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isLocked = challenge.executionStatus == FeedExecutionStatus.notAccepted ||
        challenge.executionStatus == FeedExecutionStatus.submitted ||
        challenge.executionStatus == FeedExecutionStatus.approved;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Отправка выполнения', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Добавь фото и короткое объяснение, чтобы proof выглядел убедительно и быстро прошёл проверку.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (challenge.submissionImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildProofImage(challenge.submissionImagePath!),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
              child: const Column(
                children: [
                  Icon(Icons.add_a_photo_outlined, color: AppTheme.textSecondary),
                  SizedBox(height: 8),
                  Text('Фото-доказательство пока не добавлено', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: isLocked ? null : onPickImage, icon: const Icon(Icons.photo_library_outlined), label: const Text('Добавить фото')),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            minLines: 4,
            maxLines: 5,
            enabled: !isLocked,
            decoration: const InputDecoration(
              labelText: 'Что именно ты сделал',
              hintText: 'Опиши результат, детали выполнения и почему proof подтверждает закрытие челленджа.',
            ),
          ),
          const SizedBox(height: 12),
          if (challenge.executionStatus == FeedExecutionStatus.rejected && challenge.rejectionReason != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
              child: Text(challenge.rejectionReason!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLocked ? null : onSubmit,
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: const Text('Отправить выполнение'),
                ),
              ),
              if (challenge.executionStatus == FeedExecutionStatus.rejected) ...[
                const SizedBox(width: 10),
                OutlinedButton(onPressed: onRetry, child: const Text('Заново')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class VerificationResultCard extends StatelessWidget {
  const VerificationResultCard({
    super.key,
    required this.challenge,
    required this.onShare,
    required this.onLikeCompletion,
  });

  final FeedChallenge challenge;
  final VoidCallback onShare;
  final VoidCallback onLikeCompletion;

  @override
  Widget build(BuildContext context) {
    if (challenge.executionStatus != FeedExecutionStatus.submitted &&
        challenge.executionStatus != FeedExecutionStatus.approved &&
        challenge.executionStatus != FeedExecutionStatus.rejected) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статус после отправки', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (challenge.executionStatus == FeedExecutionStatus.submitted)
            const Text(
              'Сейчас идёт ожидание. Backend получил результат и ждёт решения по проверке.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          if (challenge.executionStatus == FeedExecutionStatus.approved) ...[
            Text(
              challenge.hasMedal
                  ? 'Подтверждено. Coins зачислены, а новая медаль уже добавлена в профиль.'
                  : 'Подтверждено. Coins зачислены, а челлендж отмечен как выполненный.',
              style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Поделиться выполнением'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(onPressed: onLikeCompletion, icon: const Icon(Icons.favorite_border_rounded), label: Text('${challenge.completionLikes}')),
              ],
            ),
          ],
          if (challenge.executionStatus == FeedExecutionStatus.rejected && challenge.rejectionReason != null)
            Text('Отклонено: ${challenge.rejectionReason!}', style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
        ],
      ),
    );
  }
}

class MedalCelebrationCard extends StatelessWidget {
  const MedalCelebrationCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    if (!challenge.medalAwarded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0x33FFB347), Color(0x2216233D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x66FFB347)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x26FFB347)),
            child: const Icon(Icons.workspace_premium_rounded, color: AppTheme.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новая медаль', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text(challenge.medalTitle, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildProofImage(String pathOrUrl) {
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return Image.network(pathOrUrl, height: 180, width: double.infinity, fit: BoxFit.cover);
  }
  return Image.file(File(pathOrUrl), height: 180, width: double.infinity, fit: BoxFit.cover);
}

Color _statusColor(FeedExecutionStatus status) {
  switch (status) {
    case FeedExecutionStatus.notAccepted:
      return AppTheme.textSecondary;
    case FeedExecutionStatus.inProgress:
      return AppTheme.accent;
    case FeedExecutionStatus.submitted:
      return AppTheme.warning;
    case FeedExecutionStatus.approved:
      return AppTheme.success;
    case FeedExecutionStatus.rejected:
      return AppTheme.danger;
  }
}

IconData _statusIcon(FeedExecutionStatus status) {
  switch (status) {
    case FeedExecutionStatus.notAccepted:
      return Icons.radio_button_unchecked_rounded;
    case FeedExecutionStatus.inProgress:
      return Icons.play_circle_outline_rounded;
    case FeedExecutionStatus.submitted:
      return Icons.schedule_send_rounded;
    case FeedExecutionStatus.approved:
      return Icons.verified_rounded;
    case FeedExecutionStatus.rejected:
      return Icons.error_outline_rounded;
  }
}
