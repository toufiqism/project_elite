import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../reports/screens/reports_screen.dart';
import '../models/achievement.dart';
import '../models/level_info.dart';
import '../state/gamification_controller.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GamificationController>();
    final unlocked = Achievements.all
        .where((a) => ctrl.unlocked.contains(a.id))
        .toList();
    final locked = Achievements.all
        .where((a) => !ctrl.unlocked.contains(a.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            tooltip: 'Reports',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          _hero(ctrl),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Title ladder'),
          _titleLadder(ctrl.level.level),
          const SizedBox(height: 24),
          SectionHeader(title: 'Unlocked (${unlocked.length})'),
          if (unlocked.isEmpty)
            const EliteCard(
              child: Text('Nothing yet — start building streaks.',
                  style: TextStyle(color: AppColors.muted)),
            )
          else
            ...unlocked.map((a) => _badgeRow(ctrl, a, unlocked: true)),
          const SizedBox(height: 24),
          SectionHeader(title: 'In progress (${locked.length})'),
          ...locked.map((a) => _badgeRow(ctrl, a, unlocked: false)),
        ],
      ),
    );
  }

  Widget _hero(GamificationController ctrl) {
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('${ctrl.level.level}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctrl.title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${ctrl.totalXp} XP',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ctrl.level.progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceAlt,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${ctrl.level.xpToNextLevel} XP to level ${ctrl.level.level + 1}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _titleLadder(int currentLevel) {
    return EliteCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: Titles.ladder.map((band) {
          final reached = currentLevel >= band.minLevel;
          final next = !reached &&
              Titles.nextBandAfter(currentLevel)?.minLevel == band.minLevel;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  reached ? Icons.check_circle : Icons.lock_outline,
                  color: reached ? AppColors.success : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(band.title,
                          style: TextStyle(
                            color: reached ? AppColors.text : AppColors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      Text(
                        'Level ${band.minLevel}+',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (next)
                  const Text('NEXT',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _badgeRow(GamificationController ctrl, Achievement a,
      {required bool unlocked}) {
    final (current, target) = ctrl.progressFor(a);
    final pct = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? a.icon : Icons.lock_outline,
                color: unlocked ? AppColors.success : AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: TextStyle(
                        color: unlocked ? AppColors.text : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(a.description,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceAlt,
                      color: unlocked ? AppColors.success : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$current / $target',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
