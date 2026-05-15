import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ca_subjects.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../ayanokoji/screens/ayanokoji_home_screen.dart';
import '../../gamification/screens/achievements_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/user_profile.dart';
import '../state/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileController>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Ayanokoji Mode',
            icon: const Icon(Icons.shield_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AyanokojiHomeScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Reports',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: p == null
          ? const Center(child: Text('No profile yet'))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
              children: [
                EliteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text(
                                  p.studyMode == StudyMode.ca
                                      ? '${p.caLevel} · ${p.occupation}'
                                      : p.occupation,
                                  style: const TextStyle(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Subjects',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showEditSubjectsSheet(context),
                            child: const Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      p.caSubjects.isEmpty
                          ? const Text('No subjects yet.',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: p.caSubjects
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: AppColors.surfaceAlt,
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Body & fitness'),
                EliteCard(
                  child: Column(
                    children: [
                      _row('Age', '${p.age}'),
                      _row('Gender', p.gender),
                      _row('Height', '${p.heightCm.toStringAsFixed(0)} cm'),
                      _row('Weight', '${p.weightKg.toStringAsFixed(1)} kg'),
                      _row('Goal', '${p.goalWeightKg.toStringAsFixed(1)} kg'),
                      _row('BMI', p.bmi.toStringAsFixed(1)),
                      _row('Fitness', p.fitnessLevel),
                      _row('Workout style', p.preferredWorkoutType),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Lifestyle goals'),
                EliteCard(
                  child: Column(
                    children: [
                      _row('Free time', '${p.dailyFreeHours} h/day'),
                      _row('Sleep', p.sleepSchedule),
                      _row('Study goal', '${p.studyGoalHoursPerDay} h/day'),
                      _row('Workout goal', '${p.workoutGoalMinutesPerDay} min'),
                      _row('Water goal', '${p.waterGoalLiters} L'),
                      _row('Stress', '${p.stressLevel}/5'),
                      _row('Prayer reminders', p.prayerRemindersOn ? 'On' : 'Off'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, color: AppColors.danger),
                  label: const Text('Reset profile',
                      style: TextStyle(color: AppColors.danger)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditSubjectsSheet(profile: p),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
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
                const Text('Edit subjects',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
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
                decoration:
                    const InputDecoration(labelText: 'CA Level'),
                dropdownColor: AppColors.surfaceAlt,
                items: CALevel.all
                    .map((o) =>
                        DropdownMenuItem(value: o, child: Text(o)))
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
              const Text('Pick subjects',
                  style: TextStyle(color: AppColors.muted)),
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
                    backgroundColor: AppColors.surface,
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceAlt,
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
              style: const TextStyle(color: AppColors.muted),
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
              const Text('Selected',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  return Chip(
                    label: Text(s),
                    onDeleted: () =>
                        setState(() => _subjects.remove(s)),
                    backgroundColor: AppColors.surfaceAlt,
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
