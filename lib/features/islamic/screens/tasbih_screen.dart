import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../state/tasbih_controller.dart';

class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<TasbihController>();
    final active = ctrl.activePreset;
    final progress = (ctrl.currentCount / active.target).clamp(0.0, 1.0);
    final atTarget = ctrl.atOrPastTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.resetCurrent,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _presetRow(ctrl),
              const SizedBox(height: 12),
              EliteCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(active.arabic,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text('${active.label}  ·  goal ${active.target}',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ctrl.increment();
                  if (ctrl.currentCount == active.target) {
                    HapticFeedback.heavyImpact();
                  }
                },
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: AppColors.surfaceAlt,
                          color: atTarget
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${ctrl.currentCount}',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 88,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                              )),
                          Text(atTarget ? 'Reached' : 'Tap',
                              style: TextStyle(
                                color: atTarget
                                    ? AppColors.success
                                    : AppColors.muted,
                                fontSize: 14,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Today across all phrases: ${ctrl.todayTotalAcrossPresets()}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                'All-time: ${ctrl.totalAllTime()}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetRow(TasbihController ctrl) {
    return Row(
      children: TasbihPresets.all.map((p) {
        final active = p.label == ctrl.activePreset.label;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    active ? AppColors.accent.withValues(alpha: 0.12) : null,
                side: BorderSide(
                  color: active ? AppColors.accent : AppColors.surfaceAlt,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => ctrl.setActive(p),
              child: Text(
                p.label,
                style: TextStyle(
                  color: active ? AppColors.accent : AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
