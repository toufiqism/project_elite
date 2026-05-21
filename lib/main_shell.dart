import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/fitness/screens/fitness_home_screen.dart';
import 'features/habits/screens/habits_screen.dart';
import 'features/news/screens/news_screen.dart';
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
    const NewsScreen(),
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
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Study'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Habits'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mosque_outlined),
              activeIcon: Icon(Icons.mosque),
              label: 'Prayer'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Fitness'),
          BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News'),
        ],
      ),
    );
  }
}
