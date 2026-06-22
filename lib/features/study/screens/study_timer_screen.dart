import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/atoms.dart';
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
  bool _showNote = false;
  final _note = TextEditingController();

  // Visual focus-block target (no enforcement) — fills the ring and matches the
  // design's "of 1:30:00 goal" treatment.
  static const _targetSeconds = 90 * 60;

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

  String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final elapsed = _elapsed;
    final pct = (elapsed.inSeconds / _targetSeconds * 100).clamp(0.0, 100.0);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EliteIconButton(
                    icon: Icons.chevron_left,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Pill(
                    tone: _running ? PillTone.danger : PillTone.neutral,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 8,
                            color: _running ? c.danger : c.muted),
                        const SizedBox(width: 5),
                        Text(_running ? 'FOCUS MODE' : 'PAUSED'),
                      ],
                    ),
                  ),
                  EliteIconButton(
                    icon: Icons.more_horiz,
                    onPressed: () => setState(() => _showNote = !_showNote),
                  ),
                ],
              ),
            ),

            // Subject
            Column(
              children: [
                Text('Studying',
                    style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.subject,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: c.text),
                  ),
                ),
              ],
            ),

            // Big timer ring
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      EliteRing(value: pct, size: 260, stroke: 3),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ELAPSED',
                              style: TextStyle(
                                fontSize: 11,
                                color: c.muted,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 6),
                          Text(_fmtElapsed(elapsed),
                              style: monoStyle(
                                  fontSize: 56,
                                  color: c.text,
                                  fontWeight: FontWeight.w400)),
                          const SizedBox(height: 10),
                          Text('of 1:30:00 goal',
                              style:
                                  TextStyle(fontSize: 12, color: c.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_showNote)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(hintText: 'Note (optional)'),
                ),
              ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EliteIconButton(
                    icon: Icons.close,
                    size: 56,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  _PlayPause(
                    running: _running,
                    onTap: _running ? _pause : _start,
                  ),
                  const SizedBox(width: 16),
                  EliteIconButton(
                    icon: Icons.check,
                    size: 56,
                    tone: IconButtonTone.accent,
                    onPressed: elapsed.inSeconds == 0 ? null : _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPause extends StatelessWidget {
  final bool running;
  final VoidCallback onTap;
  const _PlayPause({required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: c.text,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(running ? Icons.pause : Icons.play_arrow,
              size: 30, color: c.background),
        ),
      ),
    );
  }
}
