import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../state/ayanokoji_controller.dart';

class FocusTimerScreen extends StatefulWidget {
  /// Block length in seconds. Default 50 min focus.
  final int durationSeconds;

  const FocusTimerScreen({super.key, this.durationSeconds = 50 * 60});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _ticker;
  int _elapsedSeconds = 0;
  bool _running = false;
  bool _finished = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running || _finished) return;
    _running = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _elapsedSeconds += 1;
        if (_elapsedSeconds >= widget.durationSeconds) {
          _running = false;
          _finished = true;
          t.cancel();
          _recordAndPop(completedFully: true);
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    _running = false;
    setState(() {});
  }

  Future<void> _recordAndPop({required bool completedFully}) async {
    if (_elapsedSeconds == 0) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final ctrl = context.read<AyanokojiController>();
    await ctrl.recordFocusSession(
      completed: Duration(seconds: _elapsedSeconds),
      planned: Duration(seconds: widget.durationSeconds),
      completedFully: completedFully,
    );
    if (!mounted) return;
    final msg = completedFully
        ? 'Focus session complete — ${(_elapsedSeconds / 60).round()} min logged.'
        : 'Session ended early — ${(_elapsedSeconds / 60).round()} min logged (no Focus XP for partial).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop();
  }

  Future<bool> _confirmAbandon() async {
    if (_finished || _elapsedSeconds == 0) return true;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End focus session?'),
        content: Text(
          'You\'ve focused for ${formatDuration(Duration(seconds: _elapsedSeconds))}. '
          'Leaving now logs the session but does NOT award Focus XP — only completed blocks count.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep focusing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.background),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End anyway'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (widget.durationSeconds - _elapsedSeconds)
        .clamp(0, widget.durationSeconds);
    final progress = widget.durationSeconds == 0
        ? 0.0
        : _elapsedSeconds / widget.durationSeconds;

    return PopScope(
      canPop: _finished || _elapsedSeconds == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await _confirmAbandon();
        if (shouldExit && mounted) {
          await _recordAndPop(completedFully: false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Deep work'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'FOCUS LOCK',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.5),
                    fontSize: 12,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: AppColors.surfaceAlt,
                          color: AppColors.accent,
                        ),
                      ),
                      Text(
                        formatHms(Duration(seconds: remaining)),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 44,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(widget.durationSeconds / 60).round()} min planned',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _running ? _pause : _start,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            _running
                                ? 'Pause'
                                : (_elapsedSeconds == 0 ? 'Start' : 'Resume'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _elapsedSeconds == 0
                            ? null
                            : () async {
                                if (await _confirmAbandon() && mounted) {
                                  await _recordAndPop(completedFully: false);
                                }
                              },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child:
                              Text('End', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
