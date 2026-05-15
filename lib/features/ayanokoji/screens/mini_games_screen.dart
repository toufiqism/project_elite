import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../models/mini_game_result.dart';
import '../state/ayanokoji_controller.dart';
import 'games/digit_span_game.dart';
import 'games/reaction_time_game.dart';
import 'games/stroop_game.dart';

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AyanokojiController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mental development')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          _gameCard(
            context,
            kind: MiniGameKind.digitSpan,
            description:
                'Memorize a growing sequence of digits and recall them in order. Trains working memory → Intelligence.',
            ctrl: ctrl,
            onPlay: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DigitSpanGame()),
            ),
          ),
          const SizedBox(height: 12),
          _gameCard(
            context,
            kind: MiniGameKind.reactionTime,
            description:
                'Tap the moment the screen turns green. Trains attention → Focus.',
            ctrl: ctrl,
            onPlay: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReactionTimeGame()),
            ),
          ),
          const SizedBox(height: 12),
          _gameCard(
            context,
            kind: MiniGameKind.stroop,
            description:
                'The word says one color but is painted another. Tap the color it\'s painted in. Trains executive control → Intelligence.',
            ctrl: ctrl,
            onPlay: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StroopGame()),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent plays'),
          ..._recentPlays(ctrl.gameResults.take(20)),
        ],
      ),
    );
  }

  Widget _gameCard(
    BuildContext context, {
    required MiniGameKind kind,
    required String description,
    required AyanokojiController ctrl,
    required VoidCallback onPlay,
  }) {
    final xp = ctrl.xpFromGames(kind);
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(kind.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              const Spacer(),
              Text('$xp XP earned',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }

  List<Widget> _recentPlays(Iterable<MiniGameResult> results) {
    if (results.isEmpty) {
      return const [
        EliteCard(
          child: Text('No plays yet.',
              style: TextStyle(color: AppColors.muted)),
        ),
      ];
    }
    return results
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EliteCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.kind.label,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          Text(_dateShort(r.playedAt),
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_scoreLabel(r),
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700)),
                        Text('+${r.xpEarned} XP',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  String _scoreLabel(MiniGameResult r) {
    switch (r.kind) {
      case MiniGameKind.digitSpan:
        return 'Span ${r.score}';
      case MiniGameKind.reactionTime:
        return '${r.score} ms';
      case MiniGameKind.stroop:
        return '${r.score} correct';
    }
  }

  String _dateShort(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
