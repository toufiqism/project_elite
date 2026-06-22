import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../../settings/screens/settings_screen.dart';
import '../../steps/screens/steps_screen.dart';
import '../models/workout_plan.dart';
import '../state/fitness_controller.dart';
import 'weight_screen.dart';
import 'workout_history_screen.dart';
import 'workout_session_screen.dart';

class FitnessHomeScreen extends StatefulWidget {
  const FitnessHomeScreen({super.key});

  @override
  State<FitnessHomeScreen> createState() => _FitnessHomeScreenState();
}

class _FitnessHomeScreenState extends State<FitnessHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePlan());
  }

  Future<void> _ensurePlan() async {
    final profile = context.read<ProfileController>().profile;
    if (profile == null) return;
    final fc = context.read<FitnessController>();
    if (fc.todayPlan == null && fc.hasApiKey) {
      await fc.buildTodayPlan(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fc = context.watch<FitnessController>();
    final profile = context.watch<ProfileController>().profile;

    final weight = fc.latestWeight ?? profile?.weightKg;
    final height = profile?.heightCm ?? 0;
    final bmi = (weight != null && height > 0)
        ? weight / ((height / 100) * (height / 100))
        : null;
    String? weightTrend;
    if (fc.weights.length >= 2) {
      final diff = fc.weights.last.weightKg -
          fc.weights[fc.weights.length - 2].weightKg;
      weightTrend = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (profile != null) await fc.buildTodayPlan(profile);
        },
        child: ListView(
          padding: EdgeInsets.only(
              bottom: 32 + MediaQuery.of(context).padding.bottom),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fc.sessions.length} workouts · ${profile?.preferredWorkoutType ?? 'Training'}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                        const SizedBox(height: 2),
                        Text('Fitness',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.6,
                              color: c.text,
                            )),
                      ],
                    ),
                  ),
                  EliteIconButton(
                    icon: Icons.directions_walk,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StepsScreen())),
                  ),
                  const SizedBox(width: 8),
                  EliteIconButton(
                    icon: Icons.monitor_weight_outlined,
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WeightScreen())),
                  ),
                  const SizedBox(width: 8),
                  EliteIconButton(
                    icon: Icons.history,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WorkoutHistoryScreen())),
                  ),
                ],
              ),
            ),

            // Body stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _bigStat(
                      context,
                      'Weight',
                      weight != null ? weight.toStringAsFixed(1) : '—',
                      'kg',
                      weightTrend,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _bigStat(context, 'BMI',
                        bmi != null ? bmi.toStringAsFixed(1) : '—', '', null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _bigStat(context, 'Workouts', '${fc.sessions.length}',
                        '', fc.didWorkoutToday() ? '+1' : null),
                  ),
                ],
              ),
            ),

            // Today
            EliteSection(
              title: 'Today',
              child: !fc.hasApiKey
                  ? _apiKeyPrompt(context)
                  : fc.loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : fc.planError != null
                          ? _errorCard(fc.planError!, () {
                              if (profile != null) fc.buildTodayPlan(profile);
                            })
                          : (fc.todayPlan == null ||
                                  fc.todayPlan!.exercises.isEmpty)
                              ? _emptyPlanCard(
                                  context, fc, profile?.preferredWorkoutType)
                              : _todayHero(context, fc.todayPlan!),
            ),

            // This week
            EliteSection(
              title: 'This week',
              child: _thisWeek(context, fc),
            ),

            // Browse
            EliteSection(
              title: 'Browse',
              child: Column(
                children: [
                  _browseRow(context, 'Cardio · HIIT', '20 min · 4 levels'),
                  const SizedBox(height: 8),
                  _browseRow(
                      context, 'Home — bodyweight', '30 min · No equipment'),
                  const SizedBox(height: 8),
                  _browseRow(context, 'Stretching', '15 min · Recovery'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigStat(BuildContext context, String label, String value, String unit,
      String? trend) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: c.muted,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: monoStyle(fontSize: 22, color: c.text)),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(unit,
                      style: TextStyle(fontSize: 11, color: c.muted)),
                ),
            ],
          ),
          if (trend != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(trend,
                  style: monoStyle(
                    fontSize: 11,
                    color: trend.startsWith('-') ? c.success : c.accent,
                    fontWeight: FontWeight.w500,
                  )),
            ),
        ],
      ),
    );
  }

  Widget _todayHero(BuildContext context, WorkoutPlan plan) {
    final c = context.colors;
    final est = plan.estimatedDuration();
    final kcal = plan.estimatedKcal();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroBg = isDark ? c.surfaceAlt : const Color(0xFF0A0A0A);
    const heroText = Color(0xFFFAFAFA);
    return EliteCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: c.accent),
                  Expanded(
                    child: Container(
                      color: heroBg,
                      padding: const EdgeInsets.fromLTRB(16, 20, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Text(plan.label.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: heroText,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                          const SizedBox(height: 12),
                          Text('Today\'s session',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: heroText,
                              )),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _heroStat('${plan.exercises.length}', 'exercises'),
                              const SizedBox(width: 16),
                              _heroStat('${est.inMinutes}', 'min'),
                              const SizedBox(width: 16),
                              _heroStat('${kcal.round()}', 'cal'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.line, width: 1)),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                EliteButton(
                  label: 'Preview',
                  variant: EliteButtonVariant.secondary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WorkoutSessionScreen(plan: plan)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: EliteButton(
                    label: 'Start workout',
                    full: true,
                    leadingIcon: Icons.play_arrow_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkoutSessionScreen(plan: plan)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value,
            style: monoStyle(
                fontSize: 13,
                color: const Color(0xFFFAFAFA),
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1AA))),
      ],
    );
  }

  Widget _thisWeek(BuildContext context, FitnessController fc) {
    final c = context.colors;
    final now = DateTime.now();
    final weekStart = DateX.startOfWeek(now);
    final doneKeys = fc.sessions.map((s) => DateX.dayKey(s.startedAt)).toSet();
    var doneCount = 0;
    for (var i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      if (!d.isAfter(now) && doneKeys.contains(DateX.dayKey(d))) doneCount++;
    }
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return EliteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$doneCount of 7 days',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.text)),
              Text('${(doneCount / 7 * 100).round()}%',
                  style: monoStyle(fontSize: 13, color: c.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _weekCell(
                    context,
                    letters[i],
                    weekStart.add(Duration(days: i)),
                    now,
                    doneKeys,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekCell(BuildContext context, String letter, DateTime day,
      DateTime now, Set<String> doneKeys) {
    final c = context.colors;
    final isToday = DateX.dayKey(day) == DateX.dayKey(now);
    final done = doneKeys.contains(DateX.dayKey(day)) && !day.isAfter(now);
    return Column(
      children: [
        Text(letter, style: TextStyle(fontSize: 10, color: c.muted)),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: done
                  ? c.accent
                  : isToday
                      ? c.accentSoft
                      : c.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !done
                  ? Border.all(color: c.accent, width: 1)
                  : null,
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _browseRow(BuildContext context, String title, String sub) {
    final c = context.colors;
    return EliteCard(
      padding: const EdgeInsets.all(12),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout library coming soon.')),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: c.surfaceAlt, borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.fitness_center, size: 18, color: c.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: c.text)),
                Text(sub, style: TextStyle(fontSize: 11.5, color: c.muted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 15, color: c.muted),
        ],
      ),
    );
  }

  Widget _apiKeyPrompt(BuildContext context) {
    final c = context.colors;
    return EliteCard(
      child: Column(
        children: [
          Icon(Icons.vpn_key, color: c.accent, size: 36),
          const SizedBox(height: 10),
          Text('Set up your ExerciseDB API key',
              style: TextStyle(
                  color: c.text, fontSize: 17, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            'Fitness uses the ExerciseDB API on RapidAPI to fetch the exercise catalog. '
            'Free tier ~50 requests/day. Paste your key in Settings to start.',
            style: TextStyle(color: c.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open settings'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String msg, VoidCallback retry) {
    final c = context.colors;
    return EliteCard(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: c.danger, size: 32),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: c.muted), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlanCard(
      BuildContext context, FitnessController fc, String? type) {
    final c = context.colors;
    return EliteCard(
      child: Column(
        children: [
          Icon(Icons.inbox, color: c.muted, size: 32),
          const SizedBox(height: 10),
          Text(
            type == 'Walking'
                ? 'No cardio exercises cached yet.\nPull down to refresh.'
                : 'No exercises matched today\'s plan.\nPull down to refresh.',
            style: TextStyle(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
