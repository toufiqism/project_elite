import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/mini_game_result.dart';
import '../../state/ayanokoji_controller.dart';

enum _Phase { idle, showing, input, result }

class DigitSpanGame extends StatefulWidget {
  const DigitSpanGame({super.key});

  @override
  State<DigitSpanGame> createState() => _DigitSpanGameState();
}

class _DigitSpanGameState extends State<DigitSpanGame> {
  final _rand = Random();
  final _input = TextEditingController();
  _Phase _phase = _Phase.idle;

  int _spanLength = 3;
  List<int> _sequence = [];
  int _showingIndex = -1;
  int _maxSpanReached = 0;
  Timer? _showTimer;

  @override
  void dispose() {
    _showTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _startRound() async {
    _sequence = List.generate(_spanLength, (_) => _rand.nextInt(10));
    _input.clear();
    setState(() {
      _phase = _Phase.showing;
      _showingIndex = -1;
    });
    for (int i = 0; i < _sequence.length; i++) {
      setState(() => _showingIndex = i);
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _showingIndex = -1);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.input);
  }

  void _submit() {
    final answer = _input.text.replaceAll(RegExp(r'\s+'), '');
    final expected = _sequence.join();
    if (answer == expected) {
      _maxSpanReached = _spanLength;
      _spanLength += 1;
      setState(() => _phase = _Phase.idle);
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    final maxSpan = _maxSpanReached;
    final xp = maxSpan * maxSpan; // 5 → 25 XP, 7 → 49 XP, 9 → 81 XP
    await context.read<AyanokojiController>().recordGameResult(
          kind: MiniGameKind.digitSpan,
          score: maxSpan,
          xp: xp,
        );
    if (!mounted) return;
    setState(() => _phase = _Phase.result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digit Span')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_phase) {
            _Phase.idle => _idleView(),
            _Phase.showing => _showingView(),
            _Phase.input => _inputView(),
            _Phase.result => _resultView(),
          },
        ),
      ),
    );
  }

  Widget _idleView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Text(
          _maxSpanReached == 0 ? 'Length' : 'Next span',
          style: const TextStyle(color: AppColors.muted),
        ),
        Text(
          '$_spanLength',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 80,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _maxSpanReached == 0
              ? 'A sequence of $_spanLength digits will flash one at a time. Recall them in order.'
              : 'You\'re on span $_spanLength. Keep going.',
          style: const TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _startRound,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Start round', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _showingView() {
    final digit = _showingIndex >= 0 ? _sequence[_showingIndex] : null;
    return Center(
      child: Text(
        digit == null ? '·' : '$digit',
        style: TextStyle(
          color: digit == null ? AppColors.muted : AppColors.text,
          fontSize: 140,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _inputView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text('Type the digits you saw',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),
        TextField(
          controller: _input,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(hintText: '———'),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Submit', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultView() {
    final xp = _maxSpanReached * _maxSpanReached;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(Icons.psychology, color: AppColors.accent, size: 60),
        const SizedBox(height: 12),
        const Text('Round over',
            style: TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          'Max span: $_maxSpanReached',
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text('+$xp Intelligence XP',
            style: const TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700)),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Done', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
