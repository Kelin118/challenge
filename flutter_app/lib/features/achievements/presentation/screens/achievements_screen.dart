import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../controllers/achievement_controller.dart';
import '../../domain/achievement.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({
    super.key,
    required this.controller,
    required this.onOpenDetails,
  });

  final AchievementController controller;
  final ValueChanged<Achievement> onOpenDetails;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String query = '';
  AchievementRarity? rarity;
  AchievementCategory? category;
  String status = 'all';

  @override
  Widget build(BuildContext context) {
    final allAchievements = widget.controller.achievements;
    final achievements = allAchievements.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase());
      final matchesRarity = rarity == null || item.rarity == rarity;
      final matchesCategory = category == null || item.category == category;
      final isAvailable = widget.controller.isAchievementAvailable(item);
      final matchesStatus = switch (status) {
        'unlocked' => item.isUnlocked,
        'locked' => !item.isUnlocked && !item.hidden,
        'hidden' => item.hidden,
        _ => true,
      };
      return matchesSearch &&
          matchesRarity &&
          matchesCategory &&
          matchesStatus &&
          (status != 'locked' || isAvailable || !item.isUnlocked);
    }).toList();

    final grouped = <AchievementCategory, List<Achievement>>{};
    for (final item in achievements) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final orderedCategories = category == null
        ? widget.controller.categories.where((item) => grouped[item]?.isNotEmpty ?? false).toList()
        : <AchievementCategory>[category!];

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '��������� ����������',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            '��� ���������� � �������� ������ ���������������� ����� ������.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (widget.controller.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.danger),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('�� ������� ��������� ����������', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(widget.controller.errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: widget.controller.refresh,
                    child: const Text('���������'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: '����� ����������',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          _buildChoiceWrap<AchievementRarity?>(
            current: rarity,
            options: const [null, ...AchievementRarity.values],
            labelBuilder: (value) => value == null ? '��� ��������' : rarityMeta[value]!.label,
            onChanged: (value) => setState(() => rarity = value),
          ),
          const SizedBox(height: 10),
          _buildChoiceWrap<AchievementCategory?>(
            current: category,
            options: [null, ...widget.controller.categories],
            labelBuilder: (value) => value == null ? '��� ���������' : categoryMeta[value]!.label,
            onChanged: (value) => setState(() => category = value),
          ),
          const SizedBox(height: 10),
          _buildChoiceWrap<String>(
            current: status,
            options: const ['all', 'unlocked', 'locked', 'hidden'],
            labelBuilder: (value) => switch (value) {
              'unlocked' => '��������',
              'locked' => '��������',
              'hidden' => '�������',
              _ => '���',
            },
            onChanged: (value) => setState(() => status = value),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('������������� ���������', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(widget.controller.rarityUnlockHint(AchievementRarity.rare), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.controller.rarityUnlockHint(AchievementRarity.epic), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.controller.rarityUnlockHint(AchievementRarity.legendary), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('�������', style: TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text('${achievements.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.controller.isLoading && allAchievements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (achievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardMuted,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Text('?', style: TextStyle(color: AppTheme.accent, fontSize: 28)),
                  SizedBox(height: 10),
                  Text('������ �� �������', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text(
                    '����� ������� ��� �������� ������ ��������� ������.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...orderedCategories.map(
              (group) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        categoryMeta[group]!.label,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        '${grouped[group]?.length ?? 0}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...?grouped[group]?.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AchievementCard(
                        achievement: item,
                        isAvailable: widget.controller.isAchievementAvailable(item),
                        lockedHint: widget.controller.isAchievementAvailable(item)
                            ? null
                            : widget.controller.rarityUnlockHint(item.rarity),
                        onTap: () => widget.onOpenDetails(item),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceWrap<T>({
    required T current,
    required List<T> options,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(labelBuilder(option)),
              selected: current == option,
              onSelected: (_) => onChanged(option),
            ),
          )
          .toList(),
    );
  }
}
