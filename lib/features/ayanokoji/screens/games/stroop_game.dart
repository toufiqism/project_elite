import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/mini_game_result.dart';
import '../../state/ayanokoji_controller.dart';

class StroopGame extends StatefulWidget {
  const StroopGame({super.key});

  @override
  State<StroopGame> createState() => _StroopGameState();
}

class _StroopGameState extends State<StroopGame> {
  static const _totalSeconds = 30;
  static const _colors = <MapEntry<String, Color>>[
    MapEntry('RED', Color(0xFFEF4444)),
    MapEntry('BLUE', Color(0xFF3B82F6)),
    MapEntry('GREEN', Color(0xFF22C55E)),
    MapEntry('YELLOW', Color(0xFFEAB308)),
  ];

  final _rand = Random();
  int _correct = 0;
  int _wrong = 0;
  int _remaining = _totalSeconds;

  late String _wordText;
  late Color _wordColor;
  Timer? _ticker;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _nextWord();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          t.cancel();
          _finish();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _nextWord() {
    // Word and color should disagree most of the time for Stroop interference.
    final wordIdx = _rand.nextInt(_colors.length);
    var colorIdx = _rand.nextInt(_colors.length);
    if (colorIdx == wordIdx && _rand.nextDouble() > 0.2) {
      colorIdx = (colorIdx + 1) % _colors.length;
    }
    _wordText = _colors[wordIdx].key;
    _wordColor = _colors[colorIdx].value;
  }

  void _pickColor(Color picked) {
    if (_finished) return;
    if (picked == _wordColor) {
      _correct += 1;
    } else {
      _wrong += 1;
    }
    setState(_nextWord);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    // XP: 2 per correct minus 1 per wrong, floor 0
    final xp = (_correct * 2 - _wrong).clamp(0, 200);
    await context.read<AyanokojiController>().recordGameResult(
          kind: MiniGameKind.stroop,
          score: _correct,
          xp: xp,
        );
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correct: $_correct',
                style: const TextStyle(color: AppColors.text, fontSize: 18)),
            Text('Wrong: $_wrong',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Text('+$xp Intelligence XP',
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stroop · ${_remaining}s')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Pick the COLOR the word is painted, not what it spells.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Text(
                _wordText,
                style: TextStyle(
                  color: _wordColor,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: _colors
                    .map((c) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.value,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _pickColor(c.value),
                          child: Text(
                            c.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Correct: $_correct  ·  Wrong: $_wrong',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
