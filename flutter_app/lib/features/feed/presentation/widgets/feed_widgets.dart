import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/challenge_completion_event.dart';
import '../../domain/feed_challenge.dart';

class FeedPalette {
  static Color rarityColor(FeedChallengeRarity rarity) {
    switch (rarity) {
      case FeedChallengeRarity.common:
        return const Color(0xFF9FB3C8);
      case FeedChallengeRarity.rare:
        return const Color(0xFF66C0F4);
      case FeedChallengeRarity.epic:
        return const Color(0xFFBB86FF);
      case FeedChallengeRarity.legendary:
        return const Color(0xFFFFB347);
      case FeedChallengeRarity.mythic:
        return const Color(0xFFFF6AD5);
    }
  }

  static Color sourceColor(FeedChallenge challenge) {
    switch (challenge.source) {
      case FeedChallengeSource.user:
        return AppTheme.accent;
      case FeedChallengeSource.system:
        return AppTheme.warning;
      case FeedChallengeSource.recommended:
        return AppTheme.success;
    }
  }
}

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({super.key, required this.current, required this.onChanged});

  final FeedFilter current;
  final ValueChanged<FeedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FeedFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = FeedFilter.values[index];
          return ChoiceChip(
            label: Text(feedFilterLabel(filter)),
            selected: filter == current,
            onSelected: (_) => onChanged(filter),
          );
        },
      ),
    );
  }
}

class InterestBar extends StatelessWidget {
  const InterestBar({super.key, required this.interests, required this.selectedInterest, required this.onChanged});

  final List<String> interests;
  final String? selectedInterest;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(label: const Text('Все темы'), selected: selectedInterest == null, onSelected: (_) => onChanged(null)),
        ...interests.map((interest) => ChoiceChip(label: Text(interest), selected: selectedInterest == interest, onSelected: (_) => onChanged(interest))),
      ],
    );
  }
}

class FeedChallengeCard extends StatelessWidget {
  const FeedChallengeCard({
    super.key,
    required this.challenge,
    required this.onOpen,
    required this.onAccept,
    required this.onLike,
    required this.onSave,
  });

  final FeedChallenge challenge;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onLike;
  final VoidCallback onSave;

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
        boxShadow: [BoxShadow(color: rarityColor.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FeedTag(label: feedChallengeRarityLabel(challenge.rarity), color: rarityColor),
              const SizedBox(width: 8),
              _FeedTag(label: challenge.sourceTag, color: sourceColor),
              const Spacer(),
              Text('+${challenge.coinReward} coins', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          _FeedTag(label: feedExecutionStatusLabel(challenge.executionStatus), color: _statusColor(challenge.executionStatus)),
          const SizedBox(height: 14),
          Text(challenge.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(challenge.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.38)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.sell_outlined, label: challenge.category),
              _MetaChip(icon: Icons.schedule_rounded, label: feedChallengeTypeLabel(challenge.type)),
              _MetaChip(icon: Icons.person_outline_rounded, label: challenge.authorName),
            ],
          ),
          const SizedBox(height: 14),
          if (challenge.reason.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: sourceColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: sourceColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(challenge.reason, style: TextStyle(color: sourceColor, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: challenge.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${(challenge.progress * 100).round()}% готовности', style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text('${challenge.participants} участников', style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: challenge.isAccepted ? AppTheme.success : Colors.white,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(challenge.isAccepted ? Icons.check_rounded : Icons.add_task_rounded),
                  label: Text(challenge.isAccepted ? 'Уже в работе' : 'Принять'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Открыть'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(onPressed: onLike, icon: Icon(challenge.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: onSave, icon: Icon(challenge.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
              const SizedBox(width: 10),
              Icon(Icons.favorite_rounded, size: 16, color: sourceColor),
              const SizedBox(width: 6),
              Text('${challenge.likes}', style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class CompletionEventCard extends StatelessWidget {
  const CompletionEventCard({
    super.key,
    required this.event,
    required this.onLike,
    required this.onShare,
  });

  final ChallengeCompletionEvent event;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final accent = event.medalAwarded ? const Color(0xFFFFB347) : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.18), AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(Icons.verified_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${event.username} выполнил челлендж', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(_relativeTime(event.createdAt), style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              _FeedTag(label: 'Выполнение', color: accent),
            ],
          ),
          const SizedBox(height: 14),
          Text(event.challengeTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeedTag(label: '+${event.coinsEarned} coins', color: AppTheme.warning),
              if (event.medalAwarded) _FeedTag(label: 'Новая медаль', color: accent),
            ],
          ),
          const SizedBox(height: 14),
          if (event.imageProof != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildProofImage(event.imageProof!),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Выполнение уже в ленте и может вдохновить других повторить челлендж.',
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onLike,
                icon: Icon(event.isLikedByCurrentUser ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                label: Text('${event.likesCount}'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.share_outlined), label: const Text('Поделиться')),
              const Spacer(),
              const Text('Комментарии скоро', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class GeneratedShowcaseCard extends StatelessWidget {
  const GeneratedShowcaseCard({super.key, required this.challenge, required this.onOpen, required this.onAccept});

  final FeedChallenge challenge;
  final VoidCallback onOpen;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final rarityColor = FeedPalette.rarityColor(challenge.rarity);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [rarityColor.withValues(alpha: 0.22), AppTheme.card], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rarityColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeedTag(label: 'Для тебя', color: FeedPalette.sourceColor(challenge)),
          const SizedBox(height: 12),
          Text(challenge.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(challenge.reason, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
          const Spacer(),
          Text('+${challenge.coinReward} coins', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: onAccept, child: Text(challenge.isAccepted ? 'Уже принят' : 'Принять'))),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: onOpen, icon: const Icon(Icons.arrow_outward_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedTag extends StatelessWidget {
  const _FeedTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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

String _relativeTime(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 60) return '${diff.inMinutes.max(1)} мин назад';
  if (diff.inHours < 24) return '${diff.inHours} ч назад';
  return '${diff.inDays} д назад';
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

extension on int {
  int max(int minValue) => this < minValue ? minValue : this;
}
