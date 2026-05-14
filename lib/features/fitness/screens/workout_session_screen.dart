import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../state/fitness_controller.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutPlan plan;
  const WorkoutSessionScreen({super.key, required this.plan});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _currentIndex = 0;
  int _setsDone = 0;
  bool _resting = false;
  int _restRemaining = 0;
  Timer? _restTimer;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _tickTimer;

  final List<CompletedExercise> _completed = [];

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  PlannedExercise get _current => widget.plan.exercises[_currentIndex];
  bool get _isLast => _currentIndex >= widget.plan.exercises.length - 1;

  void _completeSet() {
    final pe = _current;
    if (_setsDone + 1 >= pe.sets) {
      // Finished all sets for this exercise.
      _completed.add(CompletedExercise(
        exerciseId: pe.exercise.id,
        exerciseName: pe.exercise.name,
        setsCompleted: pe.sets,
        repsPerSet: pe.reps,
        durationSeconds: pe.estimatedDurationSeconds(),
        kcal: pe.estimatedKcal(),
      ));
      _setsDone = 0;
      if (_isLast) {
        _finish();
        return;
      }
      setState(() => _currentIndex += 1);
      return;
    }
    setState(() {
      _setsDone += 1;
      _startRest(pe.restSeconds);
    });
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    _resting = true;
    _restRemaining = seconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _restRemaining -= 1;
        if (_restRemaining <= 0) {
          _resting = false;
          t.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _resting = false;
      _restRemaining = 0;
    });
  }

  Future<void> _finish() async {
    _tickTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    final fc = context.read<FitnessController>();
    final kcal = _completed.fold<double>(0, (a, c) => a + (c.kcal ?? 0));
    await fc.saveSession(
      duration: _stopwatch.elapsed,
      exercises: _completed,
      kcal: kcal,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workout saved · ${formatDuration(_stopwatch.elapsed)}')),
    );
    Navigator.pop(context);
  }

  Future<void> _abandon() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End workout?'),
        content: Text(_completed.isEmpty
            ? 'Nothing saved yet. End now?'
            : '${_completed.length} exercise(s) will be saved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End')),
        ],
      ),
    );
    if (ok == true) {
      if (_completed.isEmpty) {
        if (mounted) Navigator.pop(context);
      } else {
        await _finish();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final pe = _current;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${widget.plan.exercises.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _abandon,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + _setsDone / pe.sets) /
                    widget.plan.exercises.length,
                backgroundColor: AppColors.surfaceAlt,
                color: AppColors.primary,
                minHeight: 6,
              ),
              const SizedBox(height: 18),
              EliteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (pe.exercise.gifUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            pe.exercise.gifUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceAlt,
                              alignment: Alignment.center,
                              child: const Icon(Icons.fitness_center,
                                  size: 48, color: AppColors.muted),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      _toTitle(pe.exercise.name),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pe.exercise.target} · ${pe.exercise.equipment}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _resting
                    ? _restView(pe.restSeconds)
                    : _setView(pe, profile?.weightKg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setView(PlannedExercise pe, double? bodyWeight) {
    final target =
        pe.holdSeconds != null ? '${pe.holdSeconds}s hold' : '${pe.reps} reps';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Set ${_setsDone + 1} of ${pe.sets}',
            style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 6),
        Text(target,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _completeSet,
            child: Text(
              _setsDone + 1 >= pe.sets
                  ? (_isLast ? 'Finish workout' : 'Next exercise')
                  : 'Set done',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            _completed.add(CompletedExercise(
              exerciseId: pe.exercise.id,
              exerciseName: pe.exercise.name,
              setsCompleted: _setsDone,
              repsPerSet: pe.reps,
              durationSeconds: pe.estimatedDurationSeconds() * _setsDone ~/ pe.sets,
              kcal: pe.estimatedKcal() * _setsDone / pe.sets,
            ));
            _setsDone = 0;
            if (_isLast) {
              _finish();
            } else {
              setState(() => _currentIndex += 1);
            }
          },
          child: const Text('Skip exercise'),
        ),
      ],
    );
  }

  Widget _restView(int total) {
    final progress = total == 0 ? 0.0 : (_restRemaining / total).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Rest', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 6),
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.surfaceAlt,
                  color: AppColors.accent,
                ),
              ),
              Text('${_restRemaining}s',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _skipRest,
          child: const Text('Skip rest'),
        ),
      ],
    );
  }

  String _toTitle(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
