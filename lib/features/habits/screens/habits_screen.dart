import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/atoms.dart';
import '../../../shared/widgets/elite_card.dart';
import '../models/habit.dart';
import '../state/habit_controller.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _focusMonth = DateTime(DateTime.now().year, DateTime.now().month);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ctrl = context.watch<HabitController>();
    final habits = ctrl.habits;
    final today = DateTime.now();
    final completed = habits.where((h) => ctrl.isDone(h.id, today)).length;

    // Month-to-date overall success + active-day count.
    final now = DateTime.now();
    int countedCells = 0, doneCells = 0, activeDays = 0;
    for (var i = 1; i <= now.day; i++) {
      final d = DateTime(now.year, now.month, i);
      var dayDone = 0;
      for (final h in habits) {
        countedCells++;
        if (ctrl.isDone(h.id, d)) {
          doneCells++;
          dayDone++;
        }
      }
      if (dayDone > 0) activeDays++;
    }
    final monthlyRate = countedCells == 0 ? 0.0 : doneCells / countedCells;
    final headline = monthlyRate >= 0.8
        ? 'Elite consistency'
        : monthlyRate >= 0.6
            ? 'Solid consistency'
            : monthlyRate >= 0.4
                ? 'Building momentum'
                : 'Just getting started';

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
                      Text('${_months[now.month - 1]} · $activeDays days tracked',
                          style: TextStyle(fontSize: 12, color: c.muted)),
                      const SizedBox(height: 2),
                      Text('Habits',
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
                  icon: Icons.add,
                  tone: IconButtonTone.accent,
                  onPressed: () => _addHabitDialog(context),
                ),
              ],
            ),
          ),

          // Success ring
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: EliteCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  EliteRing(
                    value: monthlyRate * 100,
                    size: 90,
                    stroke: 7,
                    label: '${(monthlyRate * 100).round()}%',
                    sublabel: 'success',
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY SUCCESS',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.muted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.48,
                            )),
                        const SizedBox(height: 6),
                        Text(headline,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.text)),
                        const SizedBox(height: 4),
                        Text('$completed of ${habits.length} done today',
                            style: TextStyle(fontSize: 12, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Monthly calendar
          EliteSection(
            title: _months[_focusMonth.month - 1],
            action: Row(
              children: [
                _navArrow(Icons.chevron_left, () => setState(() {
                      _focusMonth =
                          DateTime(_focusMonth.year, _focusMonth.month - 1);
                    })),
                _navArrow(Icons.chevron_right, () => setState(() {
                      _focusMonth =
                          DateTime(_focusMonth.year, _focusMonth.month + 1);
                    })),
              ],
            ),
            child: EliteCard(
              padding: const EdgeInsets.all(14),
              child: _calendar(ctrl, habits),
            ),
          ),

          // Today's checklist
          EliteSection(
            title: "Today's checklist",
            child: habits.isEmpty
                ? EliteCard(
                    child: Text('No habits yet. Tap + to add one.',
                        style: TextStyle(color: c.muted)),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < habits.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _habitRow(ctrl, habits[i], today),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: c.muted),
      ),
    );
  }

  Widget _habitRow(HabitController ctrl, Habit h, DateTime today) {
    final c = context.colors;
    final done = ctrl.isDone(h.id, today);
    final streak = ctrl.streak(h.id);
    return GestureDetector(
      onLongPress: () => _showHabitMenu(context, ctrl, h),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ctrl.toggle(h.id, today),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: done ? c.success : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: done ? c.success : c.lineStrong,
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? Icon(Icons.check, size: 15, color: c.background)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: c.text,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            )),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 11, color: c.warning),
                            const SizedBox(width: 4),
                            Text('$streak day streak',
                                style:
                                    TextStyle(fontSize: 11.5, color: c.muted)),
                            const SizedBox(width: 8),
                            Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                    color: c.lineStrong,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                                '${(ctrl.monthSuccessRate(h.id) * 100).round()}% this month',
                                style: monoStyle(
                                    fontSize: 11.5,
                                    color: c.muted,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar(HabitController ctrl, List<Habit> habits) {
    final c = context.colors;
    final year = _focusMonth.year;
    final month = _focusMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final first = DateTime(year, month, 1);
    final lead = first.weekday - 1;
    final todayKey = DateTime.now();

    Color cellColor(double pct, bool past) {
      if (!past || pct == 0) return c.surfaceAlt;
      if (pct >= 0.9) return c.accent;
      if (pct >= 0.5) return c.accent.withValues(alpha: 0.5);
      return c.accentSoft;
    }

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Each cell = % complete',
                style: TextStyle(fontSize: 12, color: c.muted)),
            Row(
              children: [
                _legend(c.surfaceAlt),
                _legend(c.accentSoft),
                _legend(c.accent.withValues(alpha: 0.5)),
                _legend(c.accent),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: lead + daysInMonth,
          itemBuilder: (_, i) {
            if (i < lead) return const SizedBox.shrink();
            final dayNum = i - lead + 1;
            final day = DateTime(year, month, dayNum);
            final isFuture = day.isAfter(todayKey);
            final isToday = day.year == todayKey.year &&
                day.month == todayKey.month &&
                day.day == todayKey.day;
            final doneCount =
                habits.where((h) => ctrl.isDone(h.id, day)).length;
            final pct = habits.isEmpty ? 0.0 : doneCount / habits.length;
            final bg = cellColor(pct, !isFuture);
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(5),
                border: isToday
                    ? Border.all(color: c.text, width: 1.5)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text('$dayNum',
                  style: monoStyle(
                    fontSize: 9,
                    color: pct >= 0.5 ? Colors.white : c.muted,
                    fontWeight: FontWeight.w400,
                  )),
            );
          },
        ),
      ],
    );
  }

  Widget _legend(Color color) => Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(left: 4),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );

  void _showHabitMenu(BuildContext context, HabitController ctrl, Habit h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.colors.danger),
              title: const Text('Delete habit'),
              onTap: () {
                Navigator.pop(context);
                ctrl.remove(h.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addHabitDialog(BuildContext context) {
    final name = TextEditingController();
    bool negative = false;
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: const Text('New habit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(hintText: 'Habit name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: negative,
                onChanged: (v) => setLocal(() => negative = v),
                title: const Text('This is a habit to avoid'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v = name.text.trim();
                if (v.isEmpty) return;
                context.read<HabitController>().add(name: v, negative: negative);
                Navigator.pop(dctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
