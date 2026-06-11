import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/achievement.dart';
import '../state/gamification_controller.dart';

/// Push this on top of the navigator stack when [GamificationController]
/// reports `hasPendingCelebration`. Tap-anywhere to dismiss; dismiss marks
/// the pending state seen.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key});

  /// Convenience: shows the overlay as a fullscreen modal if anything is
  /// pending. Safe to call from `didChangeDependencies` / post-frame.
  static Future<void> showIfPending(BuildContext context) async {
    final ctrl = context.read<GamificationController>();
    if (!ctrl.hasPendingCelebration) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const CelebrationOverlay(),
    );
    await ctrl.markCelebrationSeen();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GamificationController>();
    final levelUp = ctrl.hasLevelUp;
    final unlocked = ctrl.newlyUnlocked;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        builder: (_, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: context.colors.accent.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  color: context.colors.accent, size: 48),
              const SizedBox(height: 12),
              Text(
                levelUp ? 'Level ${ctrl.level.level}' : 'Unlocked',
                style: TextStyle(
                  color: context.colors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (levelUp) ...[
                const SizedBox(height: 4),
                Text(
                  ctrl.title.toUpperCase(),
                  style: TextStyle(
                    color: context.colors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (unlocked.isNotEmpty)
                ...unlocked.map((a) => _badgeTile(context, a)),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.accent,
                  foregroundColor: context.colors.background,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeTile(BuildContext context, Achievement a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(a.icon, color: context.colors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    style: TextStyle(
                      color: context.colors.text,
                      fontWeight: FontWeight.w700,
                    )),
                Text(a.description,
                    style: TextStyle(
                        color: context.colors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
