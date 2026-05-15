import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../state/study_controller.dart';

class StudyHistoryScreen extends StatelessWidget {
  const StudyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<StudyController>().sessions;
    return Scaffold(
      appBar: AppBar(title: const Text('Session history')),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No sessions yet.',
                  style: TextStyle(color: AppColors.muted)),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final s = sessions[i];
                return EliteCard(
                  child: Row(
                    children: [
                      const Icon(Icons.book, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.subject,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(
                              '${DateX.monthDay(s.startedAt)} · ${DateX.prettyTime(s.startedAt)}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                            if (s.note != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(s.note!,
                                    style: const TextStyle(
                                        color: AppColors.muted)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(formatDuration(s.duration),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          )),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.muted),
                        onPressed: () => context
                            .read<StudyController>()
                            .deleteSession(s.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
