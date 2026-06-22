import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../ayanokoji/screens/ayanokoji_home_screen.dart';
import '../../ayanokoji/state/ayanokoji_controller.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../gamification/state/gamification_controller.dart';
import '../../gamification/widgets/celebration_overlay.dart';
import '../../habits/state/habit_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/state/profile_controller.dart';
import '../../steps/screens/steps_screen.dart';
import '../../steps/state/step_controller.dart';
import '../../study/state/study_controller.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onJumpTab;
  const DashboardScreen({super.key, this.onJumpTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _celebrationChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_celebrationChecked) return;
    _celebrationChecked = true;
    // Wait one frame so the dependent providers have settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CelebrationOverlay.showIfPending(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = context.watch<ProfileController>().profile;
    final study = context.watch<StudyController>();
    final habits = context.watch<HabitController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();
    final steps = context.watch<StepController>();
    final gam = context.watch<GamificationController>();
    final ayano = context.watch<AyanokojiController>();

    final goalHours = p?.studyGoalHoursPerDay ?? 5;
    final studySeconds = study.totalToday().inSeconds;
    final studyPct =
        (studySeconds / (goalHours * 3600)).clamp(0.0, 1.0).toDouble();

    final habitPct = habits.habits.isEmpty
        ? 0.0
        : habits.doneTodayCount() / habits.habits.length;

    final prayerPct = prayer.completedToday() / 5;

    final workoutGoalMin = p?.workoutGoalMinutesPerDay ?? 30;
    final workoutMin = fitness.totalWorkoutToday().inMinutes;
    final fitnessPct =
        (workoutMin / workoutGoalMin).clamp(0.0, 1.0).toDouble();

    final stepGoal = p?.stepGoalPerDay ?? 10000;
    final todaySteps = steps.todaySteps;
    final stepsAvailable = steps.available;
    final stepPct = (todaySteps / stepGoal).clamp(0.0, 1.0).toDouble();

    // Weighted pillars (sum to 1.0 with steps available). When the step sensor
    // is unavailable we drop the steps pillar and renormalize the rest, so a
    // user without the permission/sensor isn't penalized. See CLAUDE.md.
    final pillars = <(double, double)>[
      (0.30, studyPct),
      (0.20, habitPct),
      (0.20, prayerPct),
      (0.15, fitnessPct),
      if (stepsAvailable) (0.15, stepPct),
    ];
    final weightSum = pillars.fold<double>(0, (a, e) => a + e.$1);
    final dailyScore =
        (pillars.fold<double>(0, (a, e) => a + e.$1 * e.$2) / weightSum * 100)
            .round();

    final nextSlot = prayer.nextSlot();
    final nextTime = nextSlot == null ? null : prayer.timeOf(nextSlot);

    final plan = _planItems(p, study, habits, prayer, fitness, todaySteps,
        stepGoal, nextSlot != null);
    final planDone = plan.where((e) => e.done).length;

    final studyDur = study.totalToday();
    final studyLabel =
        '${studyDur.inHours}:${(studyDur.inMinutes % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.of(context).padding.bottom),
        children: [
          _header(context, p, gam),
          // Daily score hero — the single focal point.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: EliteCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DAILY SCORE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: c.muted,
                                  letterSpacing: 0.88,
                                )),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('$dailyScore',
                                    style: monoStyle(
                                        fontSize: 48,
                                        color: c.text,
                                        letterSpacing: -1.9)),
                                const SizedBox(width: 6),
                                Text('/ 100',
                                    style: TextStyle(
                                        fontSize: 18, color: c.muted)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('$planDone of ${plan.length} tasks complete',
                                style:
                                    TextStyle(fontSize: 13, color: c.muted)),
                          ],
                        ),
                      ),
                      EliteRing(
                        value: dailyScore.toDouble(),
                        size: 88,
                        stroke: 7,
                        label: '$dailyScore',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 18),
                    child: Divider(height: 1, color: c.line),
                  ),
                  Row(
                    children: [
                      _microStat(context, Icons.menu_book_outlined, studyLabel,
                          'Study'),
                      _microStat(context, Icons.fitness_center, '${workoutMin}m',
                          'Train'),
                      _microStat(
                          context,
                          Icons.directions_walk,
                          stepsAvailable ? _compact(todaySteps) : '—',
                          'Steps'),
                      _microStat(context, Icons.mosque_outlined,
                          '${prayer.completedToday()}/5', 'Prayer'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Today
          EliteSection(
            title: 'Today',
            child: Column(
              children: [
                for (var i = 0; i < plan.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _TaskRow(
                    done: plan[i].done,
                    title: plan[i].text,
                    upNext: !plan[i].done &&
                        plan.indexWhere((e) => !e.done) == i,
                    onTap: plan[i].onTap,
                  ),
                ],
              ],
            ),
          ),
          // More — one quiet grouped list of every entry point.
          EliteSection(
            title: 'More',
            child: EliteCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _NavRow(
                    icon: Icons.menu_book_outlined,
                    label: 'Study',
                    detail: '$studyLabel of ${goalHours.toStringAsFixed(0)}h',
                    onTap: () => widget.onJumpTab?.call(1),
                  ),
                  _NavRow(
                    icon: Icons.fitness_center,
                    label: 'Fitness',
                    detail: workoutMin > 0 ? 'Done · ${workoutMin}m' : '${workoutGoalMin}m goal',
                    onTap: () => widget.onJumpTab?.call(4),
                  ),
                  _NavRow(
                    icon: Icons.check_circle_outline,
                    label: 'Habits',
                    detail: '${habits.doneTodayCount()} of ${habits.habits.length}',
                    onTap: () => widget.onJumpTab?.call(2),
                  ),
                  _NavRow(
                    icon: Icons.mosque_outlined,
                    label: 'Prayer',
                    detail: nextSlot != null && nextTime != null
                        ? '${nextSlot.labelOn(nextTime)} · ${DateX.prettyTime(nextTime)}'
                        : '5 daily',
                    onTap: () => widget.onJumpTab?.call(3),
                  ),
                  _NavRow(
                    icon: Icons.directions_walk,
                    label: 'Steps',
                    detail: stepsAvailable
                        ? '${_compact(todaySteps)} / ${_compact(stepGoal)}'
                        : 'Enable',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StepsScreen()),
                    ),
                  ),
                  _NavRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements',
                    detail: gam.newlyUnlocked.isNotEmpty
                        ? '${gam.newlyUnlocked.length} new'
                        : 'Lv. ${gam.level.level} · ${gam.totalXp} XP',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                    ),
                  ),
                  _NavRow(
                    icon: Icons.bolt_outlined,
                    label: 'Elite Mode',
                    detail: ayano.disciplineMode ? 'Ayanokoji' : 'Normal',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AyanokojiHomeScreen()),
                    ),
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(
      BuildContext context, UserProfile? p, GamificationController gam) {
    final c = context.colors;
    final initial =
        (p?.name.isNotEmpty ?? false) ? p!.name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_greeting()},',
                    style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 4),
                Text(p?.name ?? 'Elite',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.56,
                      color: c.text,
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 13, color: c.muted),
                    const SizedBox(width: 4),
                    Text('Lv. ${gam.level.level} · ${_today()}',
                        style: TextStyle(fontSize: 13, color: c.muted)),
                  ],
                ),
              ],
            ),
          ),
          _themeToggle(context),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: c.accentSoft,
              child: Text(initial,
                  style: TextStyle(
                      color: c.accent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick light↔dark flip. Reads the *resolved* brightness so it behaves
  /// correctly even when the mode is `System`; the glyph shows the target mode
  /// (sun when dark, moon when light). System remains selectable in Settings.
  Widget _themeToggle(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: c.muted),
      onPressed: () => context
          .read<ThemeController>()
          .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }

  Widget _microStat(
      BuildContext context, IconData icon, String value, String label) {
    final c = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: c.muted),
              const SizedBox(width: 5),
              Text(label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: c.muted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: monoStyle(fontSize: 15, color: c.text)),
        ],
      ),
    );
  }

  List<_PlanItem> _planItems(
    UserProfile? profile,
    StudyController study,
    HabitController habits,
    PrayerController prayer,
    FitnessController fitness,
    int todaySteps,
    int stepGoal,
    bool hasPrayerTimes,
  ) {
    final goalHours = profile?.studyGoalHoursPerDay ?? 5;
    final workoutMin = profile?.workoutGoalMinutesPerDay ?? 30;
    return [
      _PlanItem(
        text: 'Study ${goalHours.toStringAsFixed(1)} hours',
        done: study.totalToday().inMinutes >= goalHours * 60,
        onTap: () => widget.onJumpTab?.call(1),
      ),
      _PlanItem(
        text: 'Workout ${workoutMin.toStringAsFixed(0)} minutes',
        done: fitness.totalWorkoutToday().inMinutes >= workoutMin,
        onTap: () => widget.onJumpTab?.call(4),
      ),
      _PlanItem(
        text: 'Pray 5 times',
        done: prayer.completedToday() == 5,
        onTap: () => widget.onJumpTab?.call(3),
      ),
      _PlanItem(
        text: 'Walk ${_compact(stepGoal)} steps',
        done: todaySteps >= stepGoal,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StepsScreen()),
        ),
      ),
      _PlanItem(
        text: 'Complete all habits',
        done: habits.habits.isNotEmpty &&
            habits.doneTodayCount() == habits.habits.length,
        onTap: () => widget.onJumpTab?.call(2),
      ),
    ];
  }

  static String _compact(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '$n';
  }

  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _today() {
    final d = DateTime.now();
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late night, warrior';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Wind down';
  }
}

class _PlanItem {
  final String text;
  final bool done;
  final VoidCallback? onTap;
  _PlanItem({required this.text, required this.done, this.onTap});
}

class _TaskRow extends StatelessWidget {
  final bool done;
  final bool upNext;
  final String title;
  final VoidCallback? onTap;

  const _TaskRow({
    required this.done,
    required this.title,
    this.upNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: upNext ? c.accent : c.line,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.success : Colors.transparent,
                    border: Border.all(
                      color: done ? c.success : c.lineStrong,
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check, size: 13, color: c.background)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.text,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          )),
                    ],
                  ),
                ),
                if (upNext)
                  Text('UP NEXT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                        letterSpacing: 0.4,
                      ))
                else if (!done)
                  Icon(Icons.chevron_right, size: 18, color: c.mutedSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback? onTap;
  final bool last;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.detail,
    this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: c.line, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.muted),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: c.text)),
            ),
            Text(detail, style: TextStyle(fontSize: 12.5, color: c.muted)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: c.mutedSoft),
          ],
        ),
      ),
    );
  }
}
