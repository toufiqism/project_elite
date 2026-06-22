import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';
import '../models/study_draft.dart';
import '../models/study_session.dart';
import '../state/study_controller.dart';
import 'study_history_screen.dart';
import 'study_timer_screen.dart';

class StudyHomeScreen extends StatelessWidget {
  const StudyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final study = context.watch<StudyController>();
    final profile = context.watch<ProfileController>().profile;

    final goalHours = profile?.studyGoalHoursPerDay ?? 5;
    final subjects = profile?.caSubjects ?? const <String>[];

    final weekTotals = study.last7DaysTotals(); // dayKey -> Duration
    final days = DateX.last7Days();
    final weekTotal = study.totalThisWeek();
    final weekGoalH = goalHours * 7;
    final streak = study.currentStreak();
    final subjectWeek = study.subjectTotalsThisWeek();

    // Per-subject totals for today.
    final todayKey = DateX.todayKey();
    final subjectToday = <String, Duration>{};
    for (final s in study.sessions) {
      if (DateX.dayKey(s.startedAt) == todayKey) {
        subjectToday.update(s.subject, (v) => v + s.duration,
            ifAbsent: () => s.duration);
      }
    }
    final maxSubjectWeek = subjectWeek.values
        .map((d) => d.inSeconds)
        .fold<int>(1, (a, b) => b > a ? b : a);

    final draft = study.draft;
    // Quick-start target: resume draft, else most-active subject, else first.
    String? quickSubject;
    if (subjects.isNotEmpty) {
      final ranked = subjects.toList()
        ..sort((a, b) => (subjectWeek[b] ?? Duration.zero)
            .compareTo(subjectWeek[a] ?? Duration.zero));
      quickSubject = ranked.first;
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile != null
                            ? '${profile.caLevel} Level · CA'
                            : 'Focus tracker',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                      const SizedBox(height: 4),
                      Text('Study',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                            color: c.text,
                          )),
                    ],
                  ),
                ),
                EliteIconButton(
                  icon: Icons.history,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StudyHistoryScreen()),
                  ),
                ),
              ],
            ),
          ),

          if (draft != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _resumeBanner(context, draft),
            ),

          // Weekly stat card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: EliteCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('THIS WEEK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.muted,
                              letterSpacing: 0.88,
                            )),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_hm(weekTotal),
                                style: monoStyle(
                                    fontSize: 32, color: c.text)),
                            const SizedBox(width: 6),
                            Text('/ ${weekGoalH.toStringAsFixed(0)}h goal',
                                style:
                                    TextStyle(fontSize: 14, color: c.muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            Pill(
                              tone: PillTone.accent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      size: 11),
                                  const SizedBox(width: 4),
                                  Text('${streak}d streak'),
                                ],
                              ),
                            ),
                            Pill(
                              tone: PillTone.ghost,
                              child: Text(
                                  '${study.sessions.where((s) => DateX.dayKey(s.startedAt) == todayKey).length} today'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Sparkline(
                    values: [for (final d in days) weekTotals[DateX.dayKey(d)] ?? Duration.zero],
                  ),
                ],
              ),
            ),
          ),

          // Start session CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: EliteButton(
              label: draft != null ? 'Resume session' : 'Start focus session',
              full: true,
              size: EliteButtonSize.lg,
              leadingIcon: Icons.play_arrow_rounded,
              onPressed: () {
                if (draft != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyTimerScreen(
                          subject: draft.subject, draft: draft),
                    ),
                  );
                } else if (quickSubject != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyTimerScreen(subject: quickSubject!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Add subjects in your profile to start.')),
                  );
                }
              },
            ),
          ),

          // Subjects
          EliteSection(
            title: 'Subjects',
            action: Text('${subjects.length} active',
                style: TextStyle(
                    fontSize: 12, color: c.muted, fontWeight: FontWeight.w500)),
            child: subjects.isEmpty
                ? EliteCard(
                    child: Text(
                      'Add subjects in your profile to start tracking.',
                      style: TextStyle(color: c.muted),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < subjects.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _SubjectCard(
                          name: subjects[i],
                          weekShare: (subjectWeek[subjects[i]] ?? Duration.zero)
                                  .inSeconds /
                              maxSubjectWeek,
                          weekDur: subjectWeek[subjects[i]] ?? Duration.zero,
                          todayDur:
                              subjectToday[subjects[i]] ?? Duration.zero,
                          active: i == 0 &&
                              (subjectWeek[subjects[i]]?.inSeconds ?? 0) > 0,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudyTimerScreen(subject: subjects[i]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          // Recent sessions
          EliteSection(
            title: 'Recent sessions',
            child: study.sessions.isEmpty
                ? EliteCard(
                    child: Text('No sessions yet.',
                        style: TextStyle(color: c.muted)),
                  )
                : Column(
                    children: [
                      for (var i = 0;
                          i < study.sessions.length && i < 5;
                          i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _SessionRow(session: study.sessions[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resumeBanner(BuildContext context, StudyDraft draft) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudyTimerScreen(subject: draft.subject, draft: draft),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(draft.running ? Icons.timer : Icons.pause_circle_outline,
                    color: c.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          draft.running
                              ? 'Session in progress'
                              : 'Session paused',
                          style: TextStyle(
                              color: c.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${draft.subject} · ${_hm(draft.elapsed)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Discard',
                  icon: Icon(Icons.close, color: c.muted),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Discard session?'),
                        content: Text(
                            'This will delete the in-progress ${draft.subject} session (${_hm(draft.elapsed)}) without saving.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Keep')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Discard')),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<StudyController>().clearDraft();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _hm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }
}

class _Sparkline extends StatelessWidget {
  final List<Duration> values;
  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxSec = values
        .map((d) => d.inSeconds)
        .fold<int>(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 8,
              height: (60 * (values[i].inSeconds / maxSec)).clamp(3.0, 60.0),
              decoration: BoxDecoration(
                color: i == values.length - 1 ? c.accent : c.lineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String name;
  final double weekShare;
  final Duration weekDur;
  final Duration todayDur;
  final bool active;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.name,
    required this.weekShare,
    required this.weekDur,
    required this.todayDur,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? c.accent : c.line, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (active)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                            color: c.accent, shape: BoxShape.circle),
                      ),
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: c.text)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                EliteProgressBar(value: weekShare * 100, height: 4),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_h(weekDur)} this week',
                        style: TextStyle(fontSize: 11, color: c.muted)),
                    Text('${_h(todayDur)} today',
                        style: monoStyle(
                            fontSize: 11,
                            color: c.muted,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _h(Duration d) {
    final h = d.inMinutes / 60.0;
    return '${h.toStringAsFixed(1)}h';
  }
}

class _SessionRow extends StatelessWidget {
  final StudySession session;
  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dur = Duration(seconds: session.durationSeconds);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule, size: 14, color: c.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.text)),
                Text(_relDay(session.startedAt),
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
          ),
          Text(_dur(dur),
              style: monoStyle(
                  fontSize: 13, color: c.text, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  static String _dur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String _relDay(DateTime d) {
    final key = DateX.dayKey(d);
    if (key == DateX.todayKey()) return 'Today';
    if (key == DateX.dayKey(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return '${_months[d.month - 1]} ${d.day}';
  }
}
