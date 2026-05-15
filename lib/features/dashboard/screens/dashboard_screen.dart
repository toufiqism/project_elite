import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
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
    final p = context.watch<ProfileController>().profile;
    final study = context.watch<StudyController>();
    final habits = context.watch<HabitController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();
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
    final fitnessPct = (fitness.totalWorkoutToday().inMinutes / workoutGoalMin)
        .clamp(0.0, 1.0)
        .toDouble();

    // Weights sum to 1.0 — see CLAUDE.md daily-score invariant.
    final dailyScore = ((studyPct * 0.35 +
                habitPct * 0.25 +
                prayerPct * 0.2 +
                fitnessPct * 0.2) *
            100)
        .round();

    final nextSlot = prayer.nextSlot();
    final nextTime = nextSlot == null ? null : prayer.timeOf(nextSlot);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              p?.name ?? 'Elite',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AyanokojiHomeScreen(),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ayano.disciplineMode
                    ? AppColors.accent
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ayano.disciplineMode ? 'AYANOKOJI' : 'NORMAL',
                style: TextStyle(
                  color: ayano.disciplineMode
                      ? AppColors.background
                      : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 10),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  (p?.name.isNotEmpty ?? false) ? p!.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _xpHeroCard(context, gam),
          const SizedBox(height: 14),
          _dailyScoreCard(dailyScore, studyPct, habitPct, prayerPct, fitnessPct),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Today'),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.menu_book,
                  label: 'Study',
                  value:
                      '${(study.totalToday().inMinutes / 60).toStringAsFixed(1)}h',
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.check_circle,
                  label: 'Habits',
                  value: '${habits.doneTodayCount()}/${habits.habits.length}',
                  iconColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.mosque,
                  label: 'Prayers',
                  value: '${prayer.completedToday()}/5',
                  iconColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  icon: Icons.fitness_center,
                  label: 'Workout',
                  value:
                      '${fitness.totalWorkoutToday().inMinutes}m',
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (nextSlot != null && nextTime != null) ...[
            const SectionHeader(title: 'Next prayer'),
            EliteCard(
              onTap: () => widget.onJumpTab?.call(3),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Text(nextSlot.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  Text(DateX.prettyTime(nextTime),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          const SectionHeader(title: 'Today\'s plan'),
          _planList(context, p, study, habits, prayer, fitness),
        ],
      ),
    );
  }

  Widget _xpHeroCard(BuildContext context, GamificationController gam) {
    final unlockedCount = gam.unlocked.length;
    return EliteCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('${gam.level.level}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gam.title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${gam.totalXp} XP',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
              if (gam.newlyUnlocked.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${gam.newlyUnlocked.length} NEW',
                    style: const TextStyle(
                      color: AppColors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                )
              else
                Text(
                  '$unlockedCount badges',
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: gam.level.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${gam.level.xpToNextLevel} XP to level ${gam.level.level + 1}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dailyScoreCard(int score, double sP, double hP, double pP, double fP) {
    String title;
    if (score >= 85) {
      title = 'Elite day';
    } else if (score >= 60) {
      title = 'Disciplined';
    } else if (score >= 30) {
      title = 'Warming up';
    } else {
      title = 'Move with intent';
    }
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily score',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  )),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('/ 100',
                    style: TextStyle(color: AppColors.muted)),
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          _miniBar('Study', sP, AppColors.primary),
          const SizedBox(height: 6),
          _miniBar('Habits', hP, AppColors.success),
          const SizedBox(height: 6),
          _miniBar('Prayer', pP, AppColors.accent),
          const SizedBox(height: 6),
          _miniBar('Fitness', fP, AppColors.warning),
        ],
      ),
    );
  }

  Widget _miniBar(String label, double pct, Color color) {
    return Row(
      children: [
        SizedBox(
            width: 56,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('${(pct * 100).round()}%',
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _planList(
    BuildContext context,
    UserProfile? profile,
    StudyController study,
    HabitController habits,
    PrayerController prayer,
    FitnessController fitness,
  ) {
    final goalHours = profile?.studyGoalHoursPerDay ?? 5;
    final workoutMin = profile?.workoutGoalMinutesPerDay ?? 30;
    final waterL = profile?.waterGoalLiters ?? 3;

    final items = <_PlanItem>[
      _PlanItem(
        icon: Icons.menu_book,
        text: 'Study ${goalHours.toStringAsFixed(1)} hours',
        done: study.totalToday().inMinutes >= goalHours * 60,
        onTap: () => widget.onJumpTab?.call(1),
      ),
      _PlanItem(
        icon: Icons.fitness_center,
        text: 'Workout ${workoutMin.toStringAsFixed(0)} minutes',
        done: fitness.totalWorkoutToday().inMinutes >= workoutMin,
        onTap: () => widget.onJumpTab?.call(4),
      ),
      _PlanItem(
        icon: Icons.water_drop,
        text: 'Drink ${waterL.toStringAsFixed(0)} liters water',
        done: false,
      ),
      _PlanItem(
        icon: Icons.mosque,
        text: 'Pray 5 times',
        done: prayer.completedToday() == 5,
        onTap: () => widget.onJumpTab?.call(3),
      ),
      _PlanItem(
        icon: Icons.bedtime,
        text: 'Sleep before 11 PM',
        done: false,
      ),
      _PlanItem(
        icon: Icons.self_improvement,
        text: 'Meditate 10 minutes',
        done: false,
      ),
      _PlanItem(
        icon: Icons.directions_walk,
        text: 'Walk 6,000 steps',
        done: false,
      ),
    ];
    return EliteCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: items.map((it) {
          return ListTile(
            onTap: it.onTap,
            leading: Icon(it.icon,
                color: it.done ? AppColors.success : AppColors.muted),
            title: Text(it.text,
                style: TextStyle(
                  color: it.done ? AppColors.muted : AppColors.text,
                  decoration:
                      it.done ? TextDecoration.lineThrough : TextDecoration.none,
                  fontWeight: FontWeight.w500,
                )),
            trailing: it.done
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : const Icon(Icons.chevron_right, color: AppColors.muted),
          );
        }).toList(),
      ),
    );
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
  final IconData icon;
  final String text;
  final bool done;
  final VoidCallback? onTap;
  _PlanItem({
    required this.icon,
    required this.text,
    required this.done,
    this.onTap,
  });
}
