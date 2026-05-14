import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ca_subjects.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user_profile.dart';
import '../state/profile_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  static const _totalPages = 4;

  // Personal
  final _name = TextEditingController();
  final _age = TextEditingController();
  String _gender = Gender.male;
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  String _fitness = FitnessLevel.beginner;

  // CA
  String _caLevel = CALevel.certificate;
  final Set<String> _selectedSubjects = {};
  final _customSubject = TextEditingController();

  // Lifestyle
  String _occupation = OccupationType.student;
  final _freeHours = TextEditingController(text: '4');
  final _sleep = TextEditingController(text: '11 PM - 6 AM');
  final _studyGoal = TextEditingController(text: '5');
  final _workoutGoal = TextEditingController(text: '30');
  int _stress = 3;
  final _water = TextEditingController(text: '3');
  bool _prayerOn = true;
  String _workoutType = WorkoutType.home;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _customSubject.dispose();
    _freeHours.dispose();
    _sleep.dispose();
    _studyGoal.dispose();
    _workoutGoal.dispose();
    _water.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page == 0) return;
    _pageCtrl.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_page) {
      case 0:
        if (_name.text.trim().isEmpty ||
            int.tryParse(_age.text) == null ||
            double.tryParse(_height.text) == null ||
            double.tryParse(_weight.text) == null ||
            double.tryParse(_goalWeight.text) == null) {
          _snack('Fill in all personal info');
          return false;
        }
        return true;
      case 1:
        if (_selectedSubjects.isEmpty) {
          _snack('Add at least one CA subject');
          return false;
        }
        return true;
      case 2:
      case 3:
        return true;
    }
    return true;
  }

  void _snack(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _finish() async {
    if (!_validateCurrentPage()) return;
    final profile = UserProfile(
      name: _name.text.trim(),
      age: int.parse(_age.text),
      gender: _gender,
      heightCm: double.parse(_height.text),
      weightKg: double.parse(_weight.text),
      goalWeightKg: double.parse(_goalWeight.text),
      fitnessLevel: _fitness,
      caLevel: _caLevel,
      caSubjects: _selectedSubjects.toList(),
      occupation: _occupation,
      dailyFreeHours: double.tryParse(_freeHours.text) ?? 4,
      sleepSchedule: _sleep.text.trim(),
      studyGoalHoursPerDay: double.tryParse(_studyGoal.text) ?? 5,
      workoutGoalMinutesPerDay: double.tryParse(_workoutGoal.text) ?? 30,
      stressLevel: _stress,
      waterGoalLiters: double.tryParse(_water.text) ?? 3,
      prayerRemindersOn: _prayerOn,
      preferredWorkoutType: _workoutType,
      createdAt: DateTime.now(),
    );
    await context.read<ProfileController>().save(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('Project Elite',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      )),
                  const Spacer(),
                  Text('${_page + 1} / $_totalPages',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: (_page + 1) / _totalPages,
                backgroundColor: AppColors.surfaceAlt,
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _personalPage(),
                  _caPage(),
                  _lifestylePage(),
                  _finalPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    OutlinedButton(
                      onPressed: _back,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_validateCurrentPage()) _next();
                    },
                    child: Text(_page == _totalPages - 1 ? 'Begin' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageWrap({required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              )),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _personalPage() {
    return _pageWrap(
      title: 'Tell us who you are',
      subtitle: 'We tailor everything to your body and goals.',
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _dropdown('Gender', _gender, Gender.all, (v) => setState(() => _gender = v))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _height,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _goalWeight,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Goal weight (kg)'),
        ),
        const SizedBox(height: 12),
        _dropdown('Fitness level', _fitness, FitnessLevel.all,
            (v) => setState(() => _fitness = v)),
      ],
    );
  }

  Widget _caPage() {
    final stockSubjects = CASubjects.subjectsFor(_caLevel);
    return _pageWrap(
      title: 'CA path',
      subtitle: 'Pick your level and the subjects you study.',
      children: [
        _dropdown('CA Level', _caLevel, CALevel.all, (v) {
          setState(() {
            _caLevel = v;
          });
        }),
        const SizedBox(height: 16),
        const Text('Pick subjects (tap to add)',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stockSubjects.map((s) {
            final selected = _selectedSubjects.contains(s);
            return FilterChip(
              label: Text(s),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedSubjects.add(s);
                } else {
                  _selectedSubjects.remove(s);
                }
              }),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.surfaceAlt,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Add a custom subject / chapter',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _customSubject,
              decoration: const InputDecoration(hintText: 'e.g. Cost Accounting'),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              final v = _customSubject.text.trim();
              if (v.isEmpty) return;
              setState(() {
                _selectedSubjects.add(v);
                _customSubject.clear();
              });
            },
            child: const Text('Add'),
          ),
        ]),
        if (_selectedSubjects.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Selected', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSubjects.map((s) {
              return Chip(
                label: Text(s),
                onDeleted: () => setState(() => _selectedSubjects.remove(s)),
                backgroundColor: AppColors.surfaceAlt,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _lifestylePage() {
    return _pageWrap(
      title: 'Your lifestyle',
      subtitle: 'Helps the planner shape realistic days.',
      children: [
        _dropdown('Occupation', _occupation, OccupationType.all,
            (v) => setState(() => _occupation = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _freeHours,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Daily free time (hours)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _sleep,
          decoration: const InputDecoration(labelText: 'Sleep schedule'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _studyGoal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Study goal (hrs/day)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _workoutGoal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Workout (min/day)'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _water,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Water goal (liters)'),
        ),
        const SizedBox(height: 16),
        const Text('Stress level', style: TextStyle(color: AppColors.muted)),
        Slider(
          value: _stress.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$_stress',
          onChanged: (v) => setState(() => _stress = v.toInt()),
        ),
        SwitchListTile(
          value: _prayerOn,
          onChanged: (v) => setState(() => _prayerOn = v),
          title: const Text('Prayer reminders'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        _dropdown('Preferred workout', _workoutType, WorkoutType.all,
            (v) => setState(() => _workoutType = v)),
      ],
    );
  }

  Widget _finalPage() {
    return _pageWrap(
      title: 'You\'re ready, ${_name.text.isEmpty ? 'Elite' : _name.text}',
      subtitle:
          'Discipline, consistency, intelligence, fitness, focus. The app is calibrated to your profile. Press "Begin" to enter Project Elite.',
      children: [
        const SizedBox(height: 8),
        _bulletPoint('Daily plan generated from your goals'),
        _bulletPoint('Study tracker tuned for ${_caLevel} level'),
        _bulletPoint('Habit checklist seeded with 7 disciplines'),
        _bulletPoint(_prayerOn
            ? 'Prayer times calculated from your location'
            : 'Prayer module available when you turn it on'),
      ],
    );
  }

  Widget _bulletPoint(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(s, style: const TextStyle(color: AppColors.text))),
          ],
        ),
      );

  Widget _dropdown(String label, String value, List<String> opts, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: AppColors.surfaceAlt,
      items: opts
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
