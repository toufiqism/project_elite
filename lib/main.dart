import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'core/storage/hive_setup.dart';
import 'features/sync/service/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/ayanokoji/state/ayanokoji_controller.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/fitness/state/fitness_controller.dart';
import 'features/gamification/state/gamification_controller.dart';
import 'features/habits/state/habit_controller.dart';
import 'features/islamic/data/dua_service.dart';
import 'features/islamic/state/tasbih_controller.dart';
import 'features/notifications/service/notification_service.dart';
import 'features/notifications/state/notification_controller.dart';
import 'features/prayer/state/prayer_controller.dart';
import 'features/profile/screens/onboarding_screen.dart';
import 'features/profile/state/profile_controller.dart';
import 'features/study/state/study_controller.dart';
import 'firebase_options.dart';
import 'main_shell.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  unawaited(FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(kReleaseMode));
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await HiveSetup.init();
  await DuaService.instance.load();
  runApp(const ProjectEliteApp());
  // Notifications init is deferred to post-frame: awaiting
  // flutter_local_notifications' initialize() before runApp on Realme/Android 15
  // release AOT builds blocks the splash indefinitely. Schedules attempted
  // before init resolves are queued internally by the plugin.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
    unawaited(() async {
      await NotificationService.instance.init();
      // Fire POST_NOTIFICATIONS dialog on first launch. SCHEDULE_EXACT_ALARM
      // is requested later by reschedule (it launches Settings, jarring at boot).
      await NotificationService.instance.requestNotificationsOnly();
    }());
  });
}

class ProjectEliteApp extends StatelessWidget {
  const ProjectEliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => StudyController()),
        ChangeNotifierProvider(create: (_) => HabitController()),
        ChangeNotifierProvider(create: (_) => FitnessController()),
        ChangeNotifierProvider(create: (_) => TasbihController()),
        ChangeNotifierProxyProvider<ProfileController, PrayerController>(
          create: (_) => PrayerController(),
          update: (_, profile, prayer) {
            final ctrl = prayer ?? PrayerController();
            ctrl.setAddress(profile.profile?.prayerAddress);
            return ctrl;
          },
        ),
        ChangeNotifierProxyProvider4<StudyController, HabitController,
            PrayerController, FitnessController, AyanokojiController>(
          create: (_) => AyanokojiController(),
          update: (_, study, habits, prayer, fitness, ayano) {
            final ctrl = ayano ?? AyanokojiController();
            ctrl.recompute(
              study: study,
              habits: habits,
              prayer: prayer,
              fitness: fitness,
            );
            return ctrl;
          },
        ),
        ChangeNotifierProxyProvider2<PrayerController, AyanokojiController,
            NotificationController>(
          create: (_) => NotificationController(),
          update: (_, prayer, ayano, notif) {
            final ctrl = notif ?? NotificationController();
            // Cheaply guarded by scheduleVersion: only reschedules when the
            // prayer cache or discipline mode actually changed.
            ctrl.applyContext(
              prayerTimesByDay: prayer.timesForUpcomingDays(days: 7),
              prayerVersion: prayer.scheduleVersion,
              disciplineMode: ayano.disciplineMode,
            );
            return ctrl;
          },
        ),
        ChangeNotifierProxyProvider5<StudyController, HabitController,
            PrayerController, FitnessController, AyanokojiController,
            GamificationController>(
          create: (_) => GamificationController(),
          update: (_, study, habits, prayer, fitness, ayano, gam) {
            final ctrl = gam ?? GamificationController();
            ctrl.recompute(
              study: study,
              habits: habits,
              prayer: prayer,
              fitness: fitness,
              ayanokoji: ayano,
            );
            return ctrl;
          },
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) => MaterialApp(
          title: 'Project Elite',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeCtrl.mode,
          // Drive the status/nav bar icon brightness from the resolved theme so
          // they stay legible in light mode (white icons vanish on a light bg).
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _Root(),
        ),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _sessionReady = false;
  String? _handledUid;

  @override
  void initState() {
    super.initState();
    context.read<AuthController>().addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    context.read<AuthController>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) {
      if (mounted) setState(() { _sessionReady = false; _handledUid = null; });
      return;
    }
    if (uid == _handledUid) return;
    _handleLogin(uid);
  }

  Future<void> _handleLogin(String uid) async {
    if (!mounted) return;
    setState(() => _sessionReady = false);

    final settings = Hive.box(HiveBoxes.settings);
    final lastUid = settings.get('last_uid') as String?;

    if (lastUid != uid) {
      const userBoxes = [
        HiveBoxes.profile,
        HiveBoxes.study,
        HiveBoxes.habits,
        HiveBoxes.habitLogs,
        HiveBoxes.prayer,
        HiveBoxes.workoutSessions,
        HiveBoxes.weightLog,
        HiveBoxes.focusSessions,
        HiveBoxes.socialRatings,
        HiveBoxes.gameResults,
        HiveBoxes.tasbih,
      ];
      for (final name in userBoxes) {
        await Hive.box(name).clear();
      }

      try {
        final cloudTs = await SyncService.cloudTimestamp(uid);
        if (cloudTs != null) {
          await SyncService.restore(uid);
        }
      } catch (_) {}

      await settings.put('last_uid', uid);
    }

    if (!mounted) return;
    context.read<ProfileController>().reload();
    context.read<StudyController>().reload();
    context.read<HabitController>().reload();
    context.read<FitnessController>().reload();
    context.read<TasbihController>().reload();

    if (mounted) setState(() { _sessionReady = true; _handledUid = uid; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isAuthenticated) return const AuthScreen();
    if (!_sessionReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!context.watch<ProfileController>().hasProfile) return const OnboardingScreen();
    return const MainShell();
  }
}
