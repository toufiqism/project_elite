import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../models/character_stats.dart';
import '../state/ayanokoji_controller.dart';
import 'character_stats_screen.dart';
import 'focus_timer_screen.dart';
import 'mini_games_screen.dart';

class AyanokojiHomeScreen extends StatelessWidget {
  const AyanokojiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AyanokojiController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayanokoji Mode')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          _modeToggleCard(context, ctrl),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Character stats'),
          EliteCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CharacterStatsScreen(),
              ),
            ),
            child: Column(
              children:
                  ctrl.allStats.map((sv) => _miniStat(context, sv)).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Focus training'),
          EliteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: context.colors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Deep work timer',
                      style: TextStyle(
                          color: context.colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    const Spacer(),
                    Text('${ctrl.focusMinutesToday}m today',
                        style:
                            TextStyle(color: context.colors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '50-minute focus block. App locks back navigation — exit early forfeits Focus XP.',
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start deep work block'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FocusTimerScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Mental development'),
          EliteCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MiniGamesScreen()),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined,
                    color: context.colors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mini-games',
                          style: TextStyle(
                              color: context.colors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      Text(
                        'Digit Span · Reaction Time · Stroop',
                        style: TextStyle(color: context.colors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.colors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggleCard(BuildContext context, AyanokojiController ctrl) {
    final on = ctrl.disciplineMode;
    return EliteCard(
      color: on
          ? context.colors.accent.withValues(alpha: 0.08)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on ? Icons.shield : Icons.shield_outlined,
                color: on ? context.colors.accent : context.colors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                on ? 'DISCIPLINE MODE — ON' : 'Discipline mode — off',
                style: TextStyle(
                  color: on ? context.colors.accent : context.colors.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Switch(
                value: on,
                onChanged: (v) => ctrl.setDisciplineMode(v),
                activeThumbColor: context.colors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            on
                ? 'Notifications use the Discipline tone. Dashboard surfaces a penalty when goals are missed. You\'ve been warned.'
                : 'Flip to enter strict scheduling — sharper notifications, penalty surfacing on the dashboard, no soft touch.',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, StatValue sv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(sv.stat.code,
                style: TextStyle(
                  color: context.colors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                )),
          ),
          SizedBox(
            width: 24,
            child: Text('${sv.level}',
                style: TextStyle(
                    color: context.colors.text, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: sv.progress,
                minHeight: 6,
                backgroundColor: context.colors.surfaceAlt,
                color: context.colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
