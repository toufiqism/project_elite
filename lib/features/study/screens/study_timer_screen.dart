import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../models/study_draft.dart';
import '../state/study_controller.dart';

class StudyTimerScreen extends StatefulWidget {
  final String subject;

  /// When set, the screen restores an in-progress session persisted to disk
  /// (e.g. after the app was killed) instead of starting fresh.
  final StudyDraft? draft;

  const StudyTimerScreen({super.key, required this.subject, this.draft});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  // Elapsed time is derived from wall-clock timestamps so it stays accurate
  // even when the app is backgrounded or the phone is locked and the periodic
  // timer's ticks are suspended by the OS. The timer only drives UI refreshes.
  Duration _accumulated = Duration.zero; // total from finished (paused) segments
  DateTime? _segmentStart; // wall-clock start of the current running segment
  DateTime? _startedAt; // first-ever start, used for the saved session record
  bool _running = false;
  bool _focusMode = true;
  final _note = TextEditingController();

  Duration get _elapsed {
    if (_running && _segmentStart != null) {
      return _accumulated + DateTime.now().difference(_segmentStart!);
    }
    return _accumulated;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    final draft = widget.draft;
    if (draft != null) {
      _startedAt = draft.startedAt;
      _accumulated = Duration(seconds: draft.accumulatedSeconds);
      _segmentStart = draft.segmentStart;
      _running = draft.running;
      if (draft.note != null) _note.text = draft.note!;
      if (_running) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {});
        });
      }
    }
  }

  StudyDraft _draftSnapshot() => StudyDraft(
        subject: widget.subject,
        startedAt: _startedAt ?? DateTime.now(),
        accumulatedSeconds: _accumulated.inSeconds,
        segmentStart: _segmentStart,
        running: _running,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );

  void _persistDraft() =>
      context.read<StudyController>().saveDraft(_draftSnapshot());

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _note.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Snap the display back to the correct value the moment we return to the
      // foreground, rather than waiting for the next 1s tick.
      setState(() {});
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Flush the latest state to disk before the OS may kill us, so an
      // in-progress session can be restored on next launch.
      if (_startedAt != null) _persistDraft();
    }
  }

  void _start() {
    if (_running) return;
    final now = DateTime.now();
    _startedAt ??= now;
    _segmentStart = now;
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
    _persistDraft();
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    if (_segmentStart != null) {
      _accumulated += DateTime.now().difference(_segmentStart!);
      _segmentStart = null;
    }
    _running = false;
    _persistDraft();
    setState(() {});
  }

  Future<void> _finish() async {
    final elapsed = _elapsed; // capture before mutating running state
    _timer?.cancel();
    _running = false;
    final controller = context.read<StudyController>();
    await controller.clearDraft();
    if (!mounted) return;
    if (elapsed.inSeconds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session too short to save.')),
      );
      Navigator.pop(context);
      return;
    }
    await controller.addSession(
          subject: widget.subject,
          startedAt: _startedAt ?? DateTime.now().subtract(elapsed),
          duration: elapsed,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${formatDuration(elapsed)} on ${widget.subject}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _focusMode ? Colors.black : context.colors.background,
      appBar: AppBar(
        backgroundColor: _focusMode ? Colors.black : context.colors.background,
        title: Text(widget.subject),
        actions: [
          IconButton(
            tooltip: _focusMode ? 'Exit focus' : 'Focus mode',
            icon: Icon(_focusMode ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _focusMode = !_focusMode),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'FOCUS',
                style: TextStyle(
                  color: context.colors.muted.withValues(alpha: 0.5),
                  fontSize: 14,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                formatHms(_elapsed),
                style: TextStyle(
                  color: context.colors.text,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.subject,
                  style: TextStyle(color: context.colors.muted)),
              const Spacer(),
              if (!_focusMode)
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    hintText: 'Note (optional)',
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _running ? _pause : _start,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(_running ? 'Pause' : (_elapsed.inSeconds == 0 ? 'Start' : 'Resume'),
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _elapsed.inSeconds == 0 ? null : _finish,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Finish', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
