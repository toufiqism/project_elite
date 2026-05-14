import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/storage/hive_setup.dart';
import 'core/theme/app_theme.dart';
import 'features/fitness/state/fitness_controller.dart';
import 'features/habits/state/habit_controller.dart';
import 'features/notifications/service/notification_service.dart';
import 'features/notifications/state/notification_controller.dart';
import 'features/prayer/state/prayer_controller.dart';
import 'features/profile/screens/onboarding_screen.dart';
import 'features/profile/state/profile_controller.dart';
import 'features/study/state/study_controller.dart';
import 'main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await HiveSetup.init();
  await NotificationService.instance.init();
  runApp(const ProjectEliteApp());
}

class ProjectEliteApp extends StatelessWidget {
  const ProjectEliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => StudyController()),
        ChangeNotifierProvider(create: (_) => HabitController()),
        ChangeNotifierProvider(create: (_) => FitnessController()),
        ChangeNotifierProxyProvider<ProfileController, PrayerController>(
          create: (_) => PrayerController(),
          update: (_, profile, prayer) {
            final p = profile.profile;
            final ctrl = prayer ?? PrayerController();
            if (p?.latitude != null &&
                p?.longitude != null &&
                ctrl.times == null) {
              ctrl.setLocation(p!.latitude!, p.longitude!);
            }
            return ctrl;
          },
        ),
        ChangeNotifierProxyProvider<PrayerController, NotificationController>(
          create: (_) => NotificationController(),
          update: (_, prayer, notif) {
            final ctrl = notif ?? NotificationController();
            // Reschedule whenever prayer times become available or change.
            // Fire-and-forget; controller guards against concurrent inits.
            ctrl.reschedule(prayerTimes: prayer.times);
            return ctrl;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Project Elite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    if (!profile.hasProfile) {
      return const OnboardingScreen();
    }
    return const MainShell();
  }
}
