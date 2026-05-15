import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/mini_game_result.dart';
import '../../state/ayanokoji_controller.dart';

enum _Phase { idle, waiting, go, tooEarly, result, finished }

class ReactionTimeGame extends StatefulWidget {
  const ReactionTimeGame({super.key});

  @override
  State<ReactionTimeGame> createState() => _ReactionTimeGameState();
}

class _ReactionTimeGameState extends State<ReactionTimeGame> {
  static const _totalRounds = 5;

  final _rand = Random();
  _Phase _phase = _Phase.idle;
  int _round = 0;
  bool _gameOver = false;
  final List<int> _times = [];
  Timer? _scheduler;
  Stopwatch? _stopwatch;
  int? _lastMs;

  @override
  void dispose() {
    _scheduler?.cancel();
    super.dispose();
  }

  void _startRound() {
    setState(() {
      _phase = _Phase.waiting;
      _lastMs = null;
    });
    final delayMs = 1500 + _rand.nextInt(3000);
    _scheduler = Timer(Duration(milliseconds: delayMs), () {
      _stopwatch = Stopwatch()..start();
      if (mounted) setState(() => _phase = _Phase.go);
    });
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.tooEarly:
      case _Phase.result:
        _startRound();
        break;
      case _Phase.waiting:
        _scheduler?.cancel();
        setState(() => _phase = _Phase.tooEarly);
        break;
      case _Phase.go:
        if (_gameOver) return;
        final ms = _stopwatch?.elapsedMilliseconds ?? 1000;
        _times.add(ms);
        _lastMs = ms;
        _round += 1;
        if (_round >= _totalRounds) {
          _gameOver = true;
          setState(() => _phase = _Phase.result);
          _finish();
        } else {
          setState(() => _phase = _Phase.result);
        }
        break;
      case _Phase.finished:
        Navigator.of(context).pop();
        break;
    }
  }

  Future<void> _finish() async {
    final avg = _times.reduce((a, b) => a + b) ~/ _times.length;
    // XP: 30 if <=200ms, scale down to ~5 at 600ms.
    final xp = ((600 - avg.clamp(150, 600)) / 15).round().clamp(0, 40);
    await context.read<AyanokojiController>().recordGameResult(
          kind: MiniGameKind.reactionTime,
          score: avg,
          xp: xp,
        );
    if (!mounted) return;
    setState(() => _phase = _Phase.finished);
  }

  Color _bg() {
    switch (_phase) {
      case _Phase.waiting:
        return AppColors.danger;
      case _Phase.go:
        return AppColors.success;
      case _Phase.tooEarly:
        return AppColors.warning;
      default:
        return AppColors.background;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reaction Time')),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _bg(),
          child: SafeArea(
            child: Center(child: _content()),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final textStyle = TextStyle(
      color: _phase == _Phase.go || _phase == _Phase.waiting
          ? Colors.white
          : AppColors.text,
      fontSize: 28,
      fontWeight: FontWeight.w800,
    );
    switch (_phase) {
      case _Phase.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: AppColors.accent, size: 60),
            const SizedBox(height: 12),
            Text('Tap to start', style: textStyle),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'When the screen turns green, tap as fast as you can. 5 rounds. Tap too early and the round is voided.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      case _Phase.waiting:
        return Text('Wait for green…', style: textStyle);
      case _Phase.go:
        return Text('TAP!', style: textStyle.copyWith(fontSize: 48));
      case _Phase.tooEarly:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Too early', style: textStyle),
            const SizedBox(height: 6),
            const Text('Tap to retry', style: TextStyle(color: AppColors.muted)),
          ],
        );
      case _Phase.result:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_lastMs ?? 0} ms', style: textStyle),
            const SizedBox(height: 6),
            Text('${_round}/$_totalRounds rounds — tap to continue',
                style: const TextStyle(color: AppColors.muted)),
          ],
        );
      case _Phase.finished:
        final avg = _times.isEmpty
            ? 0
            : _times.reduce((a, b) => a + b) ~/ _times.length;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, color: AppColors.accent, size: 60),
            const SizedBox(height: 12),
            Text('Average: $avg ms', style: textStyle),
            const SizedBox(height: 6),
            const Text('Tap to exit', style: TextStyle(color: AppColors.muted)),
          ],
        );
    }
  }
}
