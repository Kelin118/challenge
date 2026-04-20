import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/feed_challenge.dart';
import 'feed_widgets.dart';

class ChallengeHeroCard extends StatelessWidget {
  const ChallengeHeroCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final rarityColor = FeedPalette.rarityColor(challenge.rarity);
    final sourceColor = FeedPalette.sourceColor(challenge);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [rarityColor.withValues(alpha: 0.22), const Color(0xFF111C2C), AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: rarityColor.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroTag(label: challenge.sourceTag, color: sourceColor),
              _HeroTag(label: challenge.category, color: Colors.white.withValues(alpha: 0.72)),
              _HeroTag(label: feedChallengeTypeLabel(challenge.type), color: Colors.white.withValues(alpha: 0.72)),
              _HeroTag(label: feedChallengeRarityLabel(challenge.rarity), color: rarityColor),
              _HeroTag(label: feedExecutionStatusLabel(challenge.executionStatus), color: _statusColor(challenge.executionStatus)),
            ],
          ),
          const SizedBox(height: 18),
          Text(challenge.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.05)),
          const SizedBox(height: 10),
          Text(challenge.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 15)),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
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
                      const Text('Награда', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        '+${challenge.coinReward} coins',
                        style: const TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w900, color: AppTheme.warning),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rarityColor.withValues(alpha: 0.18),
                    border: Border.all(color: rarityColor.withValues(alpha: 0.28)),
                  ),
                  child: Icon(Icons.monetization_on_rounded, color: rarityColor, size: 34),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({super.key, required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class BulletedList extends StatelessWidget {
  const BulletedList({super.key, required this.items, this.icon = Icons.check_circle_outline_rounded});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 18, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class RewardHighlightCard extends StatelessWidget {
  const RewardHighlightCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.monetization_on_rounded,
                label: 'Coins',
                value: '+${challenge.coinReward}',
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: challenge.hasMedal ? Icons.workspace_premium_rounded : Icons.visibility_outlined,
                label: challenge.hasMedal ? 'Медаль' : 'Статус',
                value: challenge.hasMedal ? challenge.medalTitle : 'Без медали',
                color: challenge.hasMedal ? const Color(0xFFFFB347) : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
          child: Text(
            challenge.isSystemGenerated
                ? challenge.specialStatus
                : 'Создатель получает ${challenge.creatorCommissionPercent}% с выполнений. ${challenge.specialStatus}',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class AuthorCard extends StatelessWidget {
  const AuthorCard({
    super.key,
    required this.challenge,
    required this.onFollow,
    required this.onOpenProfile,
  });

  final FeedChallenge challenge;
  final VoidCallback onFollow;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    if (challenge.isSystemGenerated) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(20)),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0x26F3B562),
              child: Icon(Icons.auto_awesome_rounded, color: AppTheme.warning),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Системный источник', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text(
                    'Челлендж создан системой и входит в продуктовые подборки рекомендаций.',
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final initials = _initialsFor(challenge.authorName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.18),
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.authorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                      '${challenge.authorHandle} · ${challenge.creatorChallengeCount} созданных челленджей',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: onFollow,
                  child: Text(challenge.isFollowingAuthor ? 'Подписка оформлена' : 'Подписаться'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(onPressed: onOpenProfile, child: const Text('Профиль автора')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.challenge,
    required this.onAccept,
    required this.onOpenExecution,
    required this.onLike,
    required this.onSave,
    required this.onShare,
  });

  final FeedChallenge challenge;
  final VoidCallback onAccept;
  final VoidCallback onOpenExecution;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final primaryLabel = switch (challenge.executionStatus) {
      FeedExecutionStatus.notAccepted => 'Принять челлендж',
      FeedExecutionStatus.inProgress => 'Продолжить выполнение',
      FeedExecutionStatus.submitted => 'Открыть статус проверки',
      FeedExecutionStatus.approved => 'Посмотреть результат',
      FeedExecutionStatus.rejected => 'Исправить и отправить заново',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: challenge.executionStatus == FeedExecutionStatus.notAccepted ? onAccept : onOpenExecution,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: challenge.executionStatus == FeedExecutionStatus.approved ? AppTheme.success : Colors.white,
            foregroundColor: AppTheme.background,
          ),
          icon: Icon(challenge.executionStatus == FeedExecutionStatus.notAccepted
              ? Icons.add_task_rounded
              : Icons.play_circle_fill_rounded),
          label: Text(primaryLabel),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MiniActionButton(icon: challenge.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: challenge.isLiked ? 'Нравится' : 'Лайк', onTap: onLike)),
            const SizedBox(width: 10),
            Expanded(child: _MiniActionButton(icon: challenge.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: challenge.isSaved ? 'Сохранён' : 'Сохранить', onTap: onSave)),
            const SizedBox(width: 10),
            Expanded(child: _MiniActionButton(icon: Icons.share_outlined, label: 'Поделиться', onTap: onShare)),
          ],
        ),
      ],
    );
  }
}

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusLine(label: 'Как подтверждается выполнение', value: feedVerificationTypeLabel(challenge.verificationType)),
        const SizedBox(height: 10),
        _StatusLine(label: 'Текущий статус', value: feedExecutionStatusLabel(challenge.executionStatus)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
          child: Text(_verificationDescription(challenge), style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
        ),
      ],
    );
  }

  static String _verificationDescription(FeedChallenge challenge) {
    switch (challenge.verificationType) {
      case FeedVerificationType.photo:
        return 'Подойдёт фото, скриншот или другой наглядный результат. После отправки он уходит на проверку.';
      case FeedVerificationType.text:
        return 'Достаточно короткого текстового отчёта с понятным итогом и объяснением результата.';
      case FeedVerificationType.community:
        return 'Результат проходит через сообщество: группу, обсуждение или реакцию других участников.';
      case FeedVerificationType.moderator:
        return 'Челлендж требует более строгой проверки. После отправки результат смотрит модератор.';
      case FeedVerificationType.system:
        return 'Подтверждение идёт через системный сценарий и короткий след результата.';
    }
  }
}

class EngagementCard extends StatelessWidget {
  const EngagementCard({super.key, required this.challenge});

  final FeedChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricTile(icon: Icons.favorite_rounded, label: 'Лайки', value: '${challenge.likes}', color: AppTheme.danger)),
            const SizedBox(width: 12),
            Expanded(child: _MetricTile(icon: Icons.group_rounded, label: 'Приняли', value: '${challenge.acceptedCount}', color: AppTheme.accent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _MetricTile(icon: Icons.verified_rounded, label: 'Завершили', value: '${challenge.completedCount}', color: AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _MetricTile(icon: Icons.forum_outlined, label: 'Обсуждение', value: challenge.isSystemGenerated ? 'Лента' : 'Группа / чат', color: AppTheme.warning)),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textSecondary))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.cardMuted, borderRadius: BorderRadius.circular(18)),
        child: Column(
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(' ').where((part) => part.isNotEmpty).take(2).map((part) => part.substring(0, 1).toUpperCase()).toList();
  if (parts.isEmpty) return 'AV';
  return parts.join();
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
