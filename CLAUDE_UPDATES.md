# CLAUDE_UPDATES

Running log of changes made by Claude across sessions. Newest entries at top.

---

## 2026-05-15

### Hardcoded the ExerciseDB API key (per explicit user request)

User pasted their RapidAPI key in chat and explicitly chose "Hardcode in source for now, remove later" over the recommended Settings-dialog flow and over rotating the key. I flagged the chat exposure; user accepted the risk.

Implementation (minimised blast radius without overriding the user's choice):

- `lib/core/config/api_keys.dart` — new file with `const kExerciseDbApiKey`. **Carries a FIXME** marking it for removal before any git push / external build / pair session, and instructing key rotation after removal.
- `.gitignore` — added `lib/core/config/api_keys.dart` so the key never enters a future git history.
- `lib/core/config/api_keys.example.dart` — template (tracked) showing the file shape for anyone setting up a fresh clone.
- `lib/features/fitness/data/fitness_repository.dart` — `apiKey` getter now: Hive-stored key first (Settings dialog), then `kExerciseDbApiKey` fallback. So the in-app dialog still works and can override the hardcoded value at runtime.

**For future Claude sessions:** if you're about to help with `git init`/`git push`, a release build, or anything that distributes the codebase, blank out `kExerciseDbApiKey` first and remind the user to rotate. The gitignore prevents accidental commit but not deliberate distribution.

### Phase 2: Fitness

Built the Fitness system per PDF section 3. User picked: ExerciseDB via RapidAPI, rule-based plan generator from profile, no body progress photos. Workouts get a dedicated bottom-nav tab (replacing the Profile tab) — Profile is now reached via a tappable avatar on the Dashboard AppBar.

Implementation:

- `lib/features/fitness/models/exercise.dart` — `Exercise` matching ExerciseDB shape (id, name, bodyPart, equipment, target, gifUrl, secondaryMuscles, instructions) + `isBodyweight`/`isCardio` derived flags.
- `lib/features/fitness/models/workout_plan.dart` — `PlannedExercise` (exercise + sets/reps/rest/hold) and `WorkoutPlan` (list + duration/kcal estimates).
- `lib/features/fitness/models/workout_session.dart` — `WorkoutSession` (completed) + `CompletedExercise` history records.
- `lib/features/fitness/models/weight_entry.dart` — `WeightEntry` for weight log timeline.
- `lib/features/fitness/data/exercise_db_client.dart` — thin HTTP client for the RapidAPI ExerciseDB endpoints (bodyPart/equipment/target/list). Headers `x-rapidapi-key` + `x-rapidapi-host`. Throws `ExerciseDbException` for non-200 / missing-key.
- `lib/features/fitness/data/fitness_repository.dart` — caches API results in Hive (`box_exercise_cache`, keyed `bodyPart:<x>` / `equipment:<x>` / `target:<x>`). Stores the API key in `box_settings` under `fitness_api_key`. Serves from cache unless `forceRefresh`.
- `lib/features/fitness/services/workout_planner.dart` — rule-based: `fitnessLevel` → sets/reps/rest; `preferredWorkoutType` filters exercises (Home/Bodyweight → bodyweight only; Walking → cardio; Gym → all). Day-of-week rotates body parts (Sun = active recovery, otherwise push/pull/legs split for gym-intermediate+ or full-body rotation for everyone else). Target count scales with `workoutGoalMinutesPerDay`.
- `lib/features/fitness/state/fitness_controller.dart` — Hive-backed plan + sessions + weight log. `buildTodayPlan(profile)` runs the planner; `saveSession(...)` persists a workout; weight logging + delete; `currentWorkoutStreak()` and `totalWorkoutToday()` powering Dashboard.
- `lib/features/fitness/screens/fitness_home_screen.dart` — today's plan card, exercise list, "set up API key" prompt when missing, RefreshIndicator + error retry.
- `lib/features/fitness/screens/workout_session_screen.dart` — full session UX: per-exercise GIF preview, set counter, completion button, circular rest timer with skip, skip-exercise option, abandon-with-confirm dialog, auto-save on finish.
- `lib/features/fitness/screens/workout_history_screen.dart` — list with duration + kcal + delete.
- `lib/features/fitness/screens/weight_screen.dart` — current weight + goal, fl_chart line graph (>=2 entries), entry list, log-weight dialog.

Wiring:

- `pubspec.yaml` — added `http ^1.2.2`.
- `lib/core/storage/hive_setup.dart` — three new boxes: `exerciseCache`, `workoutSessions`, `weightLog`.
- `lib/main.dart` — registered `FitnessController` in `MultiProvider`.
- `lib/main_shell.dart` — swapped Profile tab for Fitness tab (5 tabs: Home/Study/Habits/Prayer/Fitness).
- `lib/features/dashboard/screens/dashboard_screen.dart` — Profile reachable via tappable avatar in AppBar; added Fitness pillar to the daily-score formula (rebalanced weights: study 35% + habits 25% + prayer 20% + fitness 20% = 1.0, per CLAUDE.md invariant); added Workout stat tile in the Today grid; Workout plan item now reflects real fitness data.
- `lib/features/settings/screens/settings_screen.dart` — new "Fitness API" section at top with masked-key display + dialog to enter/change the RapidAPI key.

`flutter analyze`: 0 errors, 0 warnings, 8 info-level lints (same prior 4 + 4 new from fitness screens — all `Image.network(errorBuilder: (_, __, ___) => ...)` patterns; functionally identical to the existing `(_, __)` patterns elsewhere). Not auto-fixed per the policy.

User needs an ExerciseDB key on RapidAPI before fitness will populate — free tier ~50 requests/day. Cached responses persist across app restarts so the daily quota easily covers a personal user.

### Enabled Android core library desugaring (gradle fix)

`flutter run` failed on Android with `':flutter_local_notifications' requires core library desugaring to be enabled for :app`. v18+ of the plugin uses Java 8+ time/stream APIs that need to be desugared for older Android runtimes. User chose to enable desugaring (over downgrading the plugin).

- `android/app/build.gradle.kts` — `compileOptions { isCoreLibraryDesugaringEnabled = true }` and a new top-level `dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }` block.

Source/target already at Java 17 (Flutter default). `flutter analyze` still clean (4 unchanged info-level items). Next step: run `flutter clean && flutter run` to confirm the AAR check passes.

### Established the run-flutter-analyze-after-every-task rule

User asked Claude to run `flutter analyze` after every code-touching task. Calibrated: end of task (not per-file), auto-fix errors, surface warnings, ignore cosmetic info-hints. Saved as `feedback` memory `always-run-flutter-analyze`. Ran the first check immediately on Phase 1 and fixed 3 errors:

- `lib/features/notifications/service/notification_service.dart` — added the required `uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime` to both `zonedSchedule` calls (the installed `flutter_local_notifications` version still requires this legacy param).
- `lib/features/notifications/state/notification_controller.dart` — renamed the destructured `when` variable to `at` in `_scheduleAllPrayers` (Dart pattern matching treats `when` as a reserved guard keyword).

4 info-level findings remain (surfaced, not auto-fixed): one unnecessary string-interp brace; two `Radio.groupValue`/`onChanged` deprecations (post-Flutter-3.32 RadioGroup API); one unnecessary-underscores in `study_history_screen.dart`.

### Phase 1: Notifications

Built configurable local notifications matching PDF section 7 (silent / motivational / discipline tones). User picked: configurable 3-mode tone, all four reminder types on by default (prayer / study / water / streak), prayer notifications fire at -10 min + at exact time, settings live on a new screen reached from Profile. Decisions saved per `always-ask-clarifying` rule.

Implementation:

- `lib/features/notifications/service/notification_service.dart` — singleton wrapping `flutter_local_notifications`. Tz init via `flutter_timezone`. `showNow`, `scheduleAt`, `scheduleDaily`, `cancelAll`. Channels: prayer / study / water / streak / test. Tone maps to Android `Importance`/`Priority` + iOS `InterruptionLevel` + sound/vibration on-off.
- `lib/features/notifications/models/notification_settings.dart` — `NotificationSettings` (tone, per-type toggles, study time, water hours/step, streak time) with JSON round-trip, defaults.
- `lib/features/notifications/state/notification_controller.dart` — Hive-backed settings + `reschedule(prayerTimes:)` that cancels all and reschedules from current settings. ID-space partitioned by category (1000s prayer, 2000s study, 3000s water, 4000s streak, 9000s test). Prayer copy varies between at-time and 10-min-headsup. Test fire button supported.
- `lib/features/settings/screens/settings_screen.dart` — tone selector cards, per-reminder toggles, time pickers (study, water window, streak), test/reschedule buttons.
- `lib/features/profile/screens/profile_screen.dart` — added settings gear icon in AppBar.
- `lib/main.dart` — `NotificationService.instance.init()` at startup; added `ChangeNotifierProxyProvider<PrayerController, NotificationController>` that reschedules whenever prayer times change.
- `lib/core/storage/hive_setup.dart` — new `box_notifications` Hive box.
- `pubspec.yaml` — `flutter_local_notifications ^18.0.1`, `timezone ^0.10.0`, `flutter_timezone ^4.0.0`.
- `android/app/src/main/AndroidManifest.xml` — `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` permissions; registered the plugin's `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`, `ActionBroadcastReceiver`. iOS plugin handles its own permission request at runtime, no Info.plist change needed for local notifs.

Scheduling notes:

- All schedules use `AndroidScheduleMode.inexactAllowWhileIdle` — exact alarms need either user-granted `SCHEDULE_EXACT_ALARM` or app to be classified as alarm-clock-style. Inexact is fine for reminders within ~minute precision.
- Water reminders are scheduled as ~6 daily fixed-time pings between the configured start and end hours.
- Reschedule is triggered on app start (via `NotificationController` construction → first proxy update) and whenever `PrayerController` notifies (e.g. location set).

### Established the always-ask-clarifying rule

User asked Claude to always ask clarifying questions before acting. Calibrated to the strictest interpretation: ask at least one clarifying question before any actionable task, no matter how small. Informational questions are exempt. Saved as a `feedback` memory.

### Established the update-log convention

User asked Claude to maintain this file going forward. A `feedback` memory note (`project-elite-updates-log`) was added so future sessions append here automatically.

- `CLAUDE_UPDATES.md` — created

### Built the `project-elite` Claude skill

Project-local Claude Code skill that encodes the codebase patterns (feature-module layout, Hive-without-codegen, day-key time-series, daily-score invariant, PDF-as-source-of-truth, deliberate stack choices). Scoped per user input: feature-module + Hive persistence as the main body, scope/terminology rules kept as light reminders. Validation chosen: vibe-check, no eval loop.

- `.claude/skills/project-elite/SKILL.md` — created

### Initial CLAUDE.md

High-level architecture guide for future Claude sessions: product context (PDF spec, MVP vs phase 2), commands, feature-module layout rule, state-management convention, Hive-without-codegen pattern, day-key time-series pattern, daily-score weights invariant, prayer-times setup, PDF-fidelity rule.

- `CLAUDE.md` — created

### Built Project Elite MVP

Implemented the MVP scope chosen by the user (Profile, Dashboard, Study, Habits, Prayer) from `Project Elite App Overview.pdf`. Tech-stack choices confirmed with user: Hive local storage, Provider state management, rule-based "AI", `adhan` package for prayer times. Deferred to phase 2: Fitness, Notifications, Ayanokoji Mode, Gamification, Reports, AI Assistant, extended Islamic features.

Files created:

- `pubspec.yaml` — replaced stock deps with hive_flutter, provider, adhan, geolocator, permission_handler, intl, uuid, fl_chart
- `lib/main.dart` — replaced stock counter app; Hive init + provider tree + onboarding-vs-shell routing
- `lib/main_shell.dart` — bottom-nav IndexedStack across 5 tabs
- `lib/core/theme/app_theme.dart` — dark "elite" theme + `AppColors` palette
- `lib/core/storage/hive_setup.dart` — `HiveBoxes` constants and `init()`
- `lib/core/constants/ca_subjects.dart` — CA Certificate/Professional/Advance subject lists from PDF
- `lib/core/utils/date_utils.dart` — `DateX` helpers, `formatDuration`, `formatHms`
- `lib/shared/widgets/elite_card.dart` — `EliteCard`, `SectionHeader`, `StatTile`
- `lib/features/profile/` — `UserProfile` model, `ProfileController`, 4-step onboarding screen, profile view/edit screen
- `lib/features/dashboard/screens/dashboard_screen.dart` — daily score (40/35/25 study/habits/prayer), today's plan, next-prayer card
- `lib/features/study/` — `StudySession` model, `StudyController`, focus-mode timer, study home with 7-day bar chart and subject breakdown, history screen
- `lib/features/habits/` — `Habit` model, `HabitController` with 7 seeded defaults, habits screen with streaks and monthly heatmap
- `lib/features/prayer/screens/prayer_screen.dart`, `lib/features/prayer/state/prayer_controller.dart` — `adhan`-computed times keyed by `${dayKey}|${slot}`, completion checklist
- `test/widget_test.dart` — replaced stock counter test with a `DateX` sanity test

Platform changes:

- `android/app/src/main/AndroidManifest.xml` — added `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` permissions; renamed app label to "Project Elite"
- `ios/Runner/Info.plist` — added `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`
