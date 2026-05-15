import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HabitController>();
    final habits = ctrl.habits;
    final today = DateTime.now();
    final completed = habits.where((h) => ctrl.isDone(h.id, today)).length;
    final pct = habits.isEmpty ? 0.0 : completed / habits.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addHabitDialog(context),
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          EliteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Today',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$completed / ${habits.length}',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceAlt,
                    color: pct >= 1 ? AppColors.success : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Daily checklist'),
          ...habits.map((h) => _habitTile(ctrl, h, today)),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Monthly view'),
          _monthCalendar(ctrl, habits),
        ],
      ),
    );
  }

  Widget _habitTile(HabitController ctrl, Habit h, DateTime today) {
    final done = ctrl.isDone(h.id, today);
    final streak = ctrl.streak(h.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: () => ctrl.toggle(h.id, today),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(h.icon),
                color: done ? AppColors.success : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                      )),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('$streak day streak',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${(ctrl.monthSuccessRate(h.id) * 100).toStringAsFixed(0)}% this month',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Checkbox(
              value: done,
              onChanged: (_) => ctrl.toggle(h.id, today),
              activeColor: AppColors.success,
              shape: const CircleBorder(),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.muted),
              onPressed: () => _showHabitMenu(context, ctrl, h),
            ),
          ],
        ),
      ),
    );
  }

  void _showHabitMenu(BuildContext context, HabitController ctrl, Habit h) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
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

  Widget _monthCalendar(HabitController ctrl, List<Habit> habits) {
    final year = _focusMonth.year;
    final month = _focusMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final first = DateTime(year, month, 1);
    final lead = first.weekday - 1;

    return EliteCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _focusMonth = DateTime(year, month - 1);
                }),
                icon: const Icon(Icons.chevron_left, color: AppColors.muted),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthName(month)} $year',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _focusMonth = DateTime(year, month + 1);
                }),
                icon: const Icon(Icons.chevron_right, color: AppColors.muted),
              ),
            ],
          ),
          Row(
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: lead + daysInMonth,
            itemBuilder: (_, i) {
              if (i < lead) return const SizedBox.shrink();
              final day = DateTime(year, month, i - lead + 1);
              if (day.isAfter(DateTime.now())) {
                return _dayCell(day.day, 0, false);
              }
              final doneCount = habits.where((h) => ctrl.isDone(h.id, day)).length;
              final pct = habits.isEmpty ? 0.0 : doneCount / habits.length;
              return _dayCell(day.day, pct, true);
            },
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int day, double pct, bool active) {
    final color = !active
        ? AppColors.surfaceAlt
        : Color.lerp(AppColors.surfaceAlt, AppColors.success, pct)!;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('$day',
            style: TextStyle(
              color: pct > 0.5 ? Colors.black : AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  String _monthName(int m) {
    const n = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return n[m - 1];
  }

  IconData _icon(String name) {
    const map = {
      'water_drop': Icons.water_drop,
      'menu_book': Icons.menu_book,
      'self_improvement': Icons.self_improvement,
      'edit_note': Icons.edit_note,
      'bedtime': Icons.bedtime,
      'do_not_disturb_on': Icons.do_not_disturb_on,
      'shield_moon': Icons.shield_moon,
      'check_circle': Icons.check_circle,
      'fitness_center': Icons.fitness_center,
      'directions_run': Icons.directions_run,
    };
    return map[name] ?? Icons.check_circle;
  }

  void _addHabitDialog(BuildContext context) {
    final name = TextEditingController();
    bool negative = false;
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
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
                context
                    .read<HabitController>()
                    .add(name: v, negative: negative);
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

