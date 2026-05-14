import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../state/study_controller.dart';

class StudyTimerScreen extends StatefulWidget {
  final String subject;
  const StudyTimerScreen({super.key, required this.subject});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;
  bool _running = false;
  bool _focusMode = true;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _note.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _start() {
    if (_running) return;
    _startedAt ??= DateTime.now();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _running = false;
    setState(() {});
  }

  Future<void> _finish() async {
    _timer?.cancel();
    _running = false;
    if (_elapsed.inSeconds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session too short to save.')),
      );
      if (mounted) Navigator.pop(context);
      return;
    }
    await context.read<StudyController>().addSession(
          subject: widget.subject,
          startedAt: _startedAt ?? DateTime.now().subtract(_elapsed),
          duration: _elapsed,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${formatDuration(_elapsed)} on ${widget.subject}')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _focusMode ? Colors.black : AppColors.background,
      appBar: AppBar(
        backgroundColor: _focusMode ? Colors.black : AppColors.background,
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
                  color: AppColors.muted.withValues(alpha: 0.5),
                  fontSize: 14,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                formatHms(_elapsed),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.subject,
                  style: const TextStyle(color: AppColors.muted)),
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
