import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_panel.dart';
import '../../domain/achievement.dart';
import '../controllers/achievement_controller.dart';
import '../widgets/badges.dart';

class AchievementDetailsScreen extends StatefulWidget {
  const AchievementDetailsScreen({
    super.key,
    required this.achievement,
    required this.controller,
  });

  final Achievement achievement;
  final AchievementController controller;

  @override
  State<AchievementDetailsScreen> createState() => _AchievementDetailsScreenState();
}

class _AchievementDetailsScreenState extends State<AchievementDetailsScreen> {
  late final TextEditingController _evidenceController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _evidenceController = TextEditingController(
      text: widget.achievement.progress.lastEvidenceText ?? '',
    );
  }

  @override
  void dispose() {
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAchievement = widget.controller.achievements
            .where((item) => item.id == widget.achievement.id)
            .firstOrNull ??
        widget.achievement;
    final rarity = rarityMeta[currentAchievement.rarity]!;
    final isAvailable = widget.controller.isAchievementAvailable(currentAchievement);
    final title = currentAchievement.hidden && !currentAchievement.isUnlocked
        ? 'Скрытое достижение'
        : currentAchievement.title;
    final description = currentAchievement.hidden && !currentAchievement.isUnlocked
        ? 'Описание станет доступно после выполнения условия и открытия достижения.'
        : currentAchievement.description;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: rarity.color),
            ),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rarity.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: rarity.color),
                  ),
                  child: Text(
                    currentAchievement.hidden && !currentAchievement.isUnlocked ? '?' : currentAchievement.icon,
                    style: TextStyle(
                      color: rarity.color,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    RarityBadge(rarity: currentAchievement.rarity),
                    CategoryBadge(category: currentAchievement.category),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoPanel(achievement: currentAchievement),
          const SizedBox(height: 16),
          if (!isAvailable)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Редкость пока не разблокирована', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    widget.controller.rarityUnlockHint(currentAchievement.rarity),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          if (currentAchievement.verificationType != 'none') ...[
            _VerifyPanel(
              controller: _evidenceController,
              achievement: currentAchievement,
              isSubmitting: _isSubmitting,
              onSubmit: () => _submitVerification(currentAchievement),
            ),
            const SizedBox(height: 16),
          ],
          if (isAvailable && !currentAchievement.isUnlocked && currentAchievement.maxProgress > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _incrementProgress(currentAchievement),
                child: const Text('+1 к прогрессу'),
              ),
            ),
          if (isAvailable && !currentAchievement.isUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FilledButton(
                onPressed: _isSubmitting ? null : () => _markCompleted(currentAchievement),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.background,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Отметить как выполненное'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _incrementProgress(Achievement achievement) async {
    setState(() => _isSubmitting = true);
    try {
      await widget.controller.incrementProgress(achievement.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _markCompleted(Achievement achievement) async {
    setState(() => _isSubmitting = true);
    try {
      await widget.controller.unlock(achievement.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitVerification(Achievement achievement) async {
    final evidenceText = _evidenceController.text.trim();
    if (evidenceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Опиши доказательство перед отправкой.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await widget.controller.verify(
        id: achievement.id,
        evidenceText: evidenceText,
      );
      if (!mounted || result == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.reason)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final progress = achievement.maxProgress == 0
        ? 0.0
        : achievement.progress.current / achievement.maxProgress;

    return AppPanel(
      child: Column(
        children: [
          _row('Статус', achievement.isUnlocked ? 'Открыто' : 'Закрыто'),
          _row('Скрытое', achievement.hidden ? 'Да' : 'Нет'),
          _row('Награда', '+${achievement.coins} coins'),
          _row('Проверка', _verificationLabel(achievement.progress.verificationStatus)),
          const SizedBox(height: 14),
          _block('Условие получения', achievement.unlockCondition),
          const SizedBox(height: 14),
          _block('Прогресс', '${achievement.progress.current} / ${achievement.maxProgress}', progress: progress),
          const SizedBox(height: 14),
          _block(
            'Дата открытия',
            achievement.progress.unlockedAt == null ? 'Ещё не открыто' : formatLongDate(achievement.progress.unlockedAt!),
          ),
        ],
      ),
    );
  }

  String _verificationLabel(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'На проверке';
      case VerificationStatus.approved:
        return 'Подтверждено';
      case VerificationStatus.rejected:
        return 'Отклонено';
      case VerificationStatus.none:
        return 'Не требуется';
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _block(String label, String value, {double? progress}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (progress != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(rarityMeta[achievement.rarity]!.color),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(value, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
      ],
    );
  }
}

class _VerifyPanel extends StatelessWidget {
  const _VerifyPanel({
    required this.controller,
    required this.achievement,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final Achievement achievement;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Отправка доказательства',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.verificationType == 'ai_text'
                ? 'Опиши выполненное действие. Текст будет проверен AI-модулем и обновит статус достижения после проверки.'
                : 'Опиши выполненное действие. Текст будет отправлен в систему подтверждения и обновит статус достижения после проверки.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Например: что именно ты сделал, когда и какой был результат',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.background,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(isSubmitting ? 'Отправляем...' : 'Отправить на проверку'),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}


