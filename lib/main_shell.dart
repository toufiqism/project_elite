import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/fitness/screens/fitness_home_screen.dart';
import 'features/habits/screens/habits_screen.dart';
import 'features/notifications/state/notification_controller.dart';
import 'features/prayer/screens/prayer_screen.dart';
import 'features/prayer/state/prayer_controller.dart';
import 'features/study/screens/study_home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  late final List<Widget> _pages = [
    DashboardScreen(onJumpTab: (i) => setState(() => _index = i)),
    const StudyHomeScreen(),
    const HabitsScreen(),
    const PrayerScreen(),
    const FitnessHomeScreen(),
  ];

  static const _tabs = [
    (Icons.grid_view_outlined, Icons.grid_view, 'Home'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Study'),
    (Icons.check_circle_outline, Icons.check_circle, 'Habits'),
    (Icons.mosque_outlined, Icons.mosque, 'Prayer'),
    (Icons.fitness_center_outlined, Icons.fitness_center, 'Fitness'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-arm scheduled notifications whenever the app comes back to the
  // foreground. Aggressive OEMs (MIUI/OPPO/Vivo) can drop AlarmManager entries
  // after swipe-kill, and our 7-day prayer window naturally shifts every day —
  // so a resume is a good cue to refill any missing schedules. We deliberately
  // skip the multi-day cache top-up here; that fetch happens lazily inside
  // `PrayerController.fetchByAddress` after today's times land, so it can't
  // race with the prayer screen's own fetch on cold start.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final prayer = context.read<PrayerController>();
      final notif = context.read<NotificationController>();
      notif.reschedule(prayerTimesByDay: prayer.timesForUpcomingDays(days: 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _GlassTabBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        tabs: _tabs,
      ),
    );
  }
}

/// Frosted bottom tab bar matching the design's `TabBar` atom: translucent
/// surface, top hairline, blur+saturation backdrop, accent active state.
class _GlassTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, IconData, String)> tabs;

  const _GlassTabBar({
    required this.index,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: c.line, width: 1)),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottomInset),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabItem(
                    icon: index == i ? tabs[i].$2 : tabs[i].$1,
                    label: tabs[i].$3,
                    selected: index == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.mutedSoft;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}
