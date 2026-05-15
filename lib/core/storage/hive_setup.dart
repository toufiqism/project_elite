import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const profile = 'box_profile';
  static const study = 'box_study_sessions';
  static const habits = 'box_habits';
  static const habitLogs = 'box_habit_logs';
  static const prayer = 'box_prayer';
  static const settings = 'box_settings';
  static const notifications = 'box_notifications';
  static const exerciseCache = 'box_exercise_cache';
  static const workoutSessions = 'box_workout_sessions';
  static const weightLog = 'box_weight_log';
  static const focusSessions = 'box_focus_sessions';
  static const socialRatings = 'box_social_ratings';
  static const gameResults = 'box_game_results';
  static const tasbih = 'box_tasbih';
}

class HiveSetup {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.profile),
      Hive.openBox(HiveBoxes.study),
      Hive.openBox(HiveBoxes.habits),
      Hive.openBox(HiveBoxes.habitLogs),
      Hive.openBox(HiveBoxes.prayer),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.notifications),
      Hive.openBox(HiveBoxes.exerciseCache),
      Hive.openBox(HiveBoxes.workoutSessions),
      Hive.openBox(HiveBoxes.weightLog),
      Hive.openBox(HiveBoxes.focusSessions),
      Hive.openBox(HiveBoxes.socialRatings),
      Hive.openBox(HiveBoxes.gameResults),
      Hive.openBox(HiveBoxes.tasbih),
    ]);
  }
}
