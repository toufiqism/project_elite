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
          _hero(context, ctrl),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Title ladder'),
          _titleLadder(context, ctrl.level.level),
          const SizedBox(height: 24),
          SectionHeader(title: 'Unlocked (${unlocked.length})'),
          if (unlocked.isEmpty)
            EliteCard(
              child: Text('Nothing yet — start building streaks.',
                  style: TextStyle(color: context.colors.muted)),
            )
          else
            ...unlocked.map((a) => _badgeRow(context, ctrl, a, unlocked: true)),
          const SizedBox(height: 24),
          SectionHeader(title: 'In progress (${locked.length})'),
          ...locked.map((a) => _badgeRow(context, ctrl, a, unlocked: false)),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, GamificationController ctrl) {
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
                  color: context.colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('${ctrl.level.level}',
                    style: TextStyle(
                      color: context.colors.accent,
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
                      style: TextStyle(
                        color: context.colors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${ctrl.totalXp} XP',
                        style: TextStyle(
                          color: context.colors.text,
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
              backgroundColor: context.colors.surfaceAlt,
              color: context.colors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${ctrl.level.xpToNextLevel} XP to level ${ctrl.level.level + 1}',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _titleLadder(BuildContext context, int currentLevel) {
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
                  color: reached ? context.colors.success : context.colors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(band.title,
                          style: TextStyle(
                            color: reached ? context.colors.text : context.colors.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      Text(
                        'Level ${band.minLevel}+',
                        style: TextStyle(
                            color: context.colors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (next)
                  Text('NEXT',
                      style: TextStyle(
                        color: context.colors.accent,
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

  Widget _badgeRow(BuildContext context, GamificationController ctrl,
      Achievement a,
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
                    ? context.colors.success.withValues(alpha: 0.15)
                    : context.colors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                unlocked ? a.icon : Icons.lock_outline,
                color: unlocked ? context.colors.success : context.colors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: TextStyle(
                        color: unlocked ? context.colors.text : context.colors.muted,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(a.description,
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: context.colors.surfaceAlt,
                      color: unlocked ? context.colors.success : context.colors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$current / $target',
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
