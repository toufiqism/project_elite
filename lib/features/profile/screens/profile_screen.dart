import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ca_subjects.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../ayanokoji/screens/ayanokoji_home_screen.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../gamification/state/gamification_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../study/state/study_controller.dart';
import '../models/user_profile.dart';
import '../state/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = context.watch<ProfileController>().profile;
    final gam = context.watch<GamificationController>();
    final study = context.watch<StudyController>();
    final fitness = context.watch<FitnessController>();
    final habits = context.watch<HabitController>();

    if (p == null) {
      return const Scaffold(body: Center(child: Text('No profile yet')));
    }

    final studiedH =
        (study.sessions.fold<int>(0, (a, s) => a + s.durationSeconds) / 3600)
            .toStringAsFixed(0);
    final habitAvg = habits.habits.isEmpty
        ? 0
        : (habits.habits
                    .map((h) => habits.monthSuccessRate(h.id))
                    .fold<double>(0, (a, b) => a + b) /
                habits.habits.length *
                100)
            .round();

    return Scaffold(
      body: ListView(
        padding:
            EdgeInsets.only(bottom: 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('Profile',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: c.text,
                      )),
                ),
                EliteIconButton(
                  icon: Icons.settings_outlined,
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),

          // User card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: EliteCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: c.text, borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: Text(p.name.isEmpty ? 'U' : p.name[0].toUpperCase(),
                        style: TextStyle(
                            color: c.background,
                            fontSize: 22,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: c.text)),
                        const SizedBox(height: 2),
                        Text('${p.caLevel} · ${p.age} · ${p.fitnessLevel}',
                            style: TextStyle(fontSize: 12.5, color: c.muted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            Pill(
                              tone: PillTone.accent,
                              child: Text('◆ ${gam.title}'),
                            ),
                            Pill(
                              tone: PillTone.ghost,
                              child: Text('Lv. ${gam.level.level}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lifetime grid
          EliteSection(
            title: 'Lifetime',
            child: Column(
              children: [
                Row(
                  children: [
                    _stat(context, '${gam.totalXp}', 'XP'),
                    const SizedBox(width: 10),
                    _stat(context, '${study.currentStreak()}', 'Day streak'),
                    const SizedBox(width: 10),
                    _stat(context, '${studiedH}h', 'Studied'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _stat(context, '${fitness.sessions.length}', 'Workouts'),
                    const SizedBox(width: 10),
                    _stat(context, '$habitAvg%', 'Habits'),
                    const SizedBox(width: 10),
                    _stat(context, '${gam.level.level}', 'Level'),
                  ],
                ),
              ],
            ),
          ),

          // Account
          EliteSection(
            title: 'Account',
            child: EliteCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row(context, Icons.menu_book_outlined, 'Subjects',
                      '${p.caSubjects.length} active',
                      onTap: () => _showEditSubjectsSheet(context)),
                  _row(context, Icons.notifications_outlined, 'Notifications',
                      p.prayerRemindersOn ? 'On' : 'Off',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()))),
                  _row(context, Icons.mosque_outlined, 'Prayer settings',
                      p.prayerAddress ?? 'Not set',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen())),
                      last: true),
                ],
              ),
            ),
          ),

          // Discipline
          EliteSection(
            title: 'Discipline',
            child: EliteCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row(context, Icons.bolt_outlined, 'Elite Mode', 'Ayanokoji',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AyanokojiHomeScreen()))),
                  _row(context, Icons.emoji_events_outlined, 'Achievements',
                      '${gam.unlocked.length} unlocked',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AchievementsScreen()))),
                  _row(context, Icons.bar_chart, 'Stats', 'Reports',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen())),
                      last: true),
                ],
              ),
            ),
          ),

          // Body & fitness
          EliteSection(
            title: 'Body & fitness',
            child: EliteCard(
              child: Column(
                children: [
                  _display(context, 'Gender', p.gender),
                  _display(context, 'Height',
                      '${p.heightCm.toStringAsFixed(0)} cm'),
                  _display(context, 'Weight',
                      '${p.weightKg.toStringAsFixed(1)} kg'),
                  _display(context, 'Goal',
                      '${p.goalWeightKg.toStringAsFixed(1)} kg'),
                  _display(context, 'BMI', p.bmi.toStringAsFixed(1)),
                  _display(context, 'Workout style', p.preferredWorkoutType),
                ],
              ),
            ),
          ),

          // Lifestyle goals
          EliteSection(
            title: 'Lifestyle goals',
            child: EliteCard(
              child: Column(
                children: [
                  _display(context, 'Free time', '${p.dailyFreeHours} h/day'),
                  _display(context, 'Sleep', p.sleepSchedule),
                  _display(
                      context, 'Study goal', '${p.studyGoalHoursPerDay} h/day'),
                  _display(context, 'Workout goal',
                      '${p.workoutGoalMinutesPerDay} min'),
                  _display(context, 'Water goal', '${p.waterGoalLiters} L'),
                  _display(context, 'Stress', '${p.stressLevel}/5'),
                ],
              ),
            ),
          ),

          // Reset
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: EliteButton(
              label: 'Reset profile',
              variant: EliteButtonVariant.secondary,
              full: true,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: context.colors.surface,
                    title: const Text('Reset profile?'),
                    content: const Text(
                        'This will return you to onboarding. Study, habits, and prayer history are kept.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<ProfileController>().clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: monoStyle(fontSize: 18, color: c.text)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: c.muted)),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String detail,
      {VoidCallback? onTap, bool last = false}) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: c.line, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.text)),
            ),
            Flexible(
              child: Text(detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, color: c.muted)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 15, color: c.mutedSoft),
          ],
        ),
      ),
    );
  }

  Widget _display(BuildContext context, String label, String value) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: c.muted)),
          ),
          Text(value,
              style:
                  TextStyle(color: c.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showEditSubjectsSheet(BuildContext context) {
    final p = context.read<ProfileController>().profile;
    if (p == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditSubjectsSheet(profile: p),
    );
  }
}

// ── Edit subjects bottom sheet ────────────────────────────────────────────────

class _EditSubjectsSheet extends StatefulWidget {
  final UserProfile profile;
  const _EditSubjectsSheet({required this.profile});

  @override
  State<_EditSubjectsSheet> createState() => _EditSubjectsSheetState();
}

class _EditSubjectsSheetState extends State<_EditSubjectsSheet> {
  late String _studyMode;
  late String _caLevel;
  late Set<String> _subjects;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studyMode = widget.profile.studyMode;
    _caLevel = widget.profile.caLevel.isNotEmpty
        ? widget.profile.caLevel
        : CALevel.certificate;
    _subjects = Set.from(widget.profile.caSubjects);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addInput() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _subjects.add(v);
      _input.clear();
    });
  }

  Future<void> _save() async {
    await context.read<ProfileController>().update(
          (p) => p.copyWith(
            studyMode: _studyMode,
            caLevel: _caLevel,
            caSubjects: _subjects.toList(),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final stockSubjects = CASubjects.subjectsFor(_caLevel);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit subjects',
                    style: TextStyle(
                      color: context.colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: context.colors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: StudyMode.ca, label: Text('CA')),
                ButtonSegment(value: StudyMode.custom, label: Text('Custom')),
              ],
              selected: {_studyMode},
              onSelectionChanged: (v) => setState(() {
                _studyMode = v.first;
                _subjects.clear();
              }),
            ),
            const SizedBox(height: 20),
            if (_studyMode == StudyMode.ca) ...[
              DropdownButtonFormField<String>(
                initialValue: _caLevel,
                decoration: const InputDecoration(labelText: 'CA Level'),
                dropdownColor: context.colors.surfaceAlt,
                items: CALevel.all
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _caLevel = v;
                    _subjects.removeWhere(
                        (s) => !CASubjects.subjectsFor(v).contains(s));
                  });
                },
              ),
              const SizedBox(height: 16),
              Text('Pick subjects',
                  style: TextStyle(color: context.colors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stockSubjects.map((s) {
                  final selected = _subjects.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _subjects.add(s);
                      } else {
                        _subjects.remove(s);
                      }
                    }),
                    backgroundColor: context.colors.surface,
                    selectedColor: context.colors.primary.withValues(alpha: 0.2),
                    checkmarkColor: context.colors.primary,
                    labelStyle: TextStyle(
                      color: selected
                          ? context.colors.primary
                          : context.colors.text,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected
                            ? context.colors.primary
                            : context.colors.surfaceAlt,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              _studyMode == StudyMode.ca
                  ? 'Add a custom subject / chapter'
                  : 'Add your subjects',
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: _studyMode == StudyMode.ca
                        ? 'e.g. Cost Accounting'
                        : 'e.g. Physics, Chapter 3',
                  ),
                  onSubmitted: (_) => _addInput(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _addInput,
                child: const Text('Add'),
              ),
            ]),
            if (_subjects.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Selected', style: TextStyle(color: context.colors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  return Chip(
                    label: Text(s),
                    onDeleted: () => setState(() => _subjects.remove(s)),
                    backgroundColor: context.colors.surfaceAlt,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
