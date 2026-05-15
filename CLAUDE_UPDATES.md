# CLAUDE_UPDATES

Running log of changes made by Claude across sessions. Newest entries at top.

---

## 2026-05-15

### Phase 4: Weekly + Monthly Reports

Built PDF section 11. User picked: pushed from Achievements + Profile (no nav change), current-week + current-month scope only (no historical browse), share-as-text via system share sheet.

Implementation:

- `lib/features/reports/models/period_report.dart` — `PeriodReport` value class covering both weekly & monthly periods with derived consistency rates (study days at goal, workout days, prayer perfect days, habit success) and `HabitBreakdown` per-habit completion record.
- `lib/features/reports/data/reports_service.dart` — stateless aggregator. `buildWeek(...)` / `buildMonth(...)` walk the source controllers in date range and produce a `PeriodReport`. **Productivity score** = average daily score across the period (same 35/25/20/20 weights as the Dashboard's `_dailyScoreCard`). **Self-improvement score** = period XP normalised against `days × 50` XP/day target. XP-in-period computed inline (same rules as `XpRules` but date-scoped). Monthly only: weight change from earliest weight entry in range to latest. Plain-text formatter (`formatShareText`) packages everything for the share sheet.
- `lib/features/reports/screens/reports_screen.dart` — hero score card (productivity + self-improvement + XP); for each period: 4-bar consistency card (study/workout/prayer/habit), summary grid (totals + sub-counts), per-habit breakdown bars, and (monthly only) weight-change card with trend icon. Share buttons fire `Share.share(formatShareText(...), subject: r.label)`.
- `pubspec.yaml` — `share_plus ^10.1.2`.

Wiring:

- `lib/features/gamification/screens/achievements_screen.dart` — added a Reports `Icons.bar_chart` action in the AppBar.
- `lib/features/profile/screens/profile_screen.dart` — added a Reports `Icons.bar_chart` icon between Achievements and Settings.

Bug caught by `flutter analyze` and fixed in-turn: I wrote `SharePlus.instance.share(ShareParams(text: text))` initially (that's the v13+ API). The pinned `share_plus ^10.1.2` exposes `Share.share(text, subject: ...)` as a static. Switched and analyze went clean.

Final `flutter analyze`: 0 errors, 0 warnings — same 9 pre-existing info lints (no new findings).

### Extended Islamic features (PDF section 6 follow-up)

User picked all four sub-features (Daily duas, Tasbih, Hijri date, Qibla) and asked them to live inside the Prayer tab rather than as a separate bottom-nav tab. Bundled JSON for dua content (no API).

Implementation:

- `assets/duas.json` — curated 25-entry library (morning / evening / food / sleep / travel / protection / forgiveness / distress / knowledge / gratitude) with `{arabic, transliteration, meaning, reference}` per entry. Sourced from Hisnul Muslim canonical duas.
- `pubspec.yaml` — `hijri ^3.0.0`, `flutter_compass ^0.8.1`, `assets:` block declaring `assets/duas.json`.
- `lib/features/islamic/models/dua.dart` — Dua record + fromJson.
- `lib/features/islamic/data/dua_service.dart` — singleton loader, loaded once at startup via `DuaService.instance.load()` in `main()`. `duaOfTheDay()` picks deterministically by `year×1000 + month×50 + day` so the same dua holds all day and rotates the next.
- `lib/features/islamic/state/tasbih_controller.dart` — `TasbihPresets` (Subhan'Allah ×33, Alhamdulillah ×33, Allahu Akbar ×34 = 99); per-preset per-day counts persisted to `box_tasbih` keyed `preset|yyyy-MM-dd`; all-time and today-across-presets totals.
- `lib/features/islamic/screens/tasbih_screen.dart` — preset row, large circular progress with tabular-figures count, light haptic on tap + heavy haptic on hitting target, reset button.
- `lib/features/islamic/screens/duas_screen.dart` — horizontal category filter chips, scrollable list of `DuaCard`s with Arabic right-aligned, transliteration italic, meaning + reference.
- `lib/features/islamic/screens/qibla_screen.dart` — `flutter_compass` stream + great-circle initial-bearing formula from current location to Kaaba (21.4225°N, 39.8262°E). Compass dial counter-rotates with device heading; qibla arrow rotates by the absolute bearing inside that frame. Turns green when within 5° of target. Calibration tip in footer.

Wiring:

- `lib/core/storage/hive_setup.dart` — new `box_tasbih`.
- `lib/main.dart` — `DuaService.instance.load()` after Hive init; `TasbihController` registered in `MultiProvider`.
- `lib/features/prayer/screens/prayer_screen.dart` — AppBar title now stacks "Prayer" + today's Hijri date (e.g. `26 Dhū al-Qaʿdah 1447 AH`); new AppBar action icons for Tasbih and Qibla (alongside Refresh location). New "Dua of the day" card at the bottom of the Prayer body with an "All duas" action linking to `DuasScreen`. Tap-anywhere on the dua card also navigates to the full library.

`flutter analyze`: 0 errors, 0 warnings — same 9 pre-existing info lints (no new findings).

Notes:

- The Qibla compass relies on the device magnetometer. Some hardware (especially older iPads / phones with cases that interfere) won't have it; the screen surfaces a graceful "Compass not available" message in that case.
- `flutter_compass` is unmaintained but still works on recent Flutter; if it breaks in the future, drop in `sensors_plus` magnetometer events instead.
- Tasbih currently feeds its own Hive box only — it does **not** yet feed the Ayanokoji Discipline character stat (I mentioned that as a possibility in the question but skipped to keep this drop tight). Easy follow-up if you want it: add a `dailyTasbihCount` term to `AyanokojiController._recomputeStats`.

### Phase 5: Ayanokoji Mode

Built the PDF's section 8 "Ayanokoji Mode" in full (user explicitly opted into all 4 sub-systems and skipped Phase 4 Reports). The mode is a hub reached from the Dashboard mode-pill in the AppBar (top-right, shows AYANOKOJI when on, NORMAL otherwise) and from a shield icon in the Profile AppBar.

Sub-systems:

1. **Discipline Mode toggle** — single bool persisted in `box_settings`. When ON, the NotificationController's `_effectiveTone` is forced to `discipline` regardless of the user's Settings tone selection (their setting is restored when the toggle goes off). Mode shows as a glowing AYANOKOJI pill on the dashboard.
2. **Six Character Stats** — Intelligence, Discipline, Strength, Focus, Consistency, Social Confidence. Each has its own XP pool with a sqrt-curve level (lvl ≈ √(xp/50), so lvl 10 = 5000 XP). Mappings: study min → INT (+ digit span + stroop bonuses); habit + prayer completions → DSC; workout minutes/sessions → STR; focus-mode minutes + reaction-time bonus → FOC; best-running-streak → CON; daily 1–5 self-rating → SOC. Radar chart on the Stats screen (custom painter).
3. **Focus / Deep-Work timer** — 50-min default Pomodoro. `FocusTimerScreen` wraps `PopScope` to block back-nav; tapping back or End during a session opens a confirm dialog warning that partial minutes don't count. Completed-fully sessions award Focus XP, partial sessions log time but no XP (soft penalty per user choice).
4. **3 Mini-games**: Digit Span (memory → INT), Reaction Time (focus → FOC, 5 rounds with too-early detection), Stroop (executive control → INT, 30-second time-attack). Hub at `MiniGamesScreen` with recent-plays list. Each result writes to `box_game_results` and recomputes stats.

Implementation:

- `lib/features/ayanokoji/models/character_stats.dart` — `CharacterStat` enum + `StatValue` with sqrt-curve level/progress derivation.
- `lib/features/ayanokoji/models/focus_session.dart` — focus block log (started/duration/planned/completedFully).
- `lib/features/ayanokoji/models/social_rating.dart` — single rating per day, keyed by `DateX.todayKey()` so re-saves overwrite.
- `lib/features/ayanokoji/models/mini_game_result.dart` — kind/score/xpEarned per play.
- `lib/features/ayanokoji/state/ayanokoji_controller.dart` — central controller. `recompute()` pulls study/habit/prayer/fitness totals on every source notify; merges with focus/social/games totals to produce 6 stat XP values. Exposes `setDisciplineMode`, `recordFocusSession`, `setSocialRatingToday`, `recordGameResult`.
- `lib/features/ayanokoji/screens/ayanokoji_home_screen.dart` — hub. Discipline toggle card, mini stat list (tap → full stats screen), focus timer entry, mini-games entry.
- `lib/features/ayanokoji/screens/character_stats_screen.dart` — hexagonal radar chart (CustomPainter normalizing each level against lvl 20), detailed stat rows with XP + source hint, daily Social-Confidence slider.
- `lib/features/ayanokoji/screens/focus_timer_screen.dart` — fullscreen black, circular progress, focus-lock via `PopScope`, soft-penalty confirm dialog.
- `lib/features/ayanokoji/screens/mini_games_screen.dart` — three game cards + recent-plays list.
- `lib/features/ayanokoji/screens/games/digit_span_game.dart` — increasing-length sequence, type-to-recall.
- `lib/features/ayanokoji/screens/games/reaction_time_game.dart` — wait-for-green tap test, 5 rounds, ms-based scoring.
- `lib/features/ayanokoji/screens/games/stroop_game.dart` — colored word picker, 30-second time-attack.

Wiring:

- `lib/core/storage/hive_setup.dart` — three new boxes: `focusSessions`, `socialRatings`, `gameResults`.
- `lib/main.dart` — registered `AyanokojiController` in `MultiProvider` (proxy over the 4 source controllers). NotificationController's proxy provider promoted to `ChangeNotifierProxyProvider2<PrayerController, AyanokojiController, ...>` so it can react to discipline-mode flips. Order: AyanokojiController declared before NotificationController so the latter can depend on it.
- `lib/features/notifications/state/notification_controller.dart` — added `_disciplineOverride` field + `applyContext(prayerTimes:, disciplineMode:)` entry point with cheap dirty-checking (`PrayerTimes` equality across 5 slots + override-bit change). `reschedule()` now uses `_effectiveTone` which routes through the override.
- `lib/features/dashboard/screens/dashboard_screen.dart` — added the MODE pill in AppBar actions next to the profile avatar; tappable → AyanokojiHomeScreen.
- `lib/features/profile/screens/profile_screen.dart` — added a shield icon in the AppBar that opens the Ayanokoji hub.

`flutter analyze`: 0 errors, 0 warnings, 9 info-level lints (8 pre-existing + 1 new cosmetic `${...}` brace in reaction_time_game). Phase compiles clean.

### Phase 3: Gamification

Built XP/levels/titles/achievements per PDF section 10. User picked: all four XP sources (study minutes / habit completions / prayers / workouts) feeding one XP pool; quadratic level curve (N² × 100); Dashboard hero card + dedicated Achievements screen pushed from Profile; in-app celebration overlay on unlock or level-up (no notification).

XP rules (1 XP/min study, 10 XP/habit completion, 8 XP/prayer, 1 XP/min workout + 30 XP/session). Title bands match PDF exactly: Beginner (lv 1+) → Disciplined (5+) → Elite (10+) → Mastermind (20+) → Ayanokoji (50+).

Implementation:

- `lib/features/gamification/models/level_info.dart` — `LevelInfo.fromXp(total)` computes level via the inverted quadratic curve, exposes progress fraction + XP-to-next; `Titles` ladder + `forLevel`/`nextBandAfter` helpers.
- `lib/features/gamification/models/xp.dart` — `GamificationStats` snapshot pulled from the 4 source controllers (totals + streaks); `XpRules.totalFor(stats)` computes the XP scalar. Prayer streak is derived by walking the last 365 days for full 5-of-5 days.
- `lib/features/gamification/models/achievement.dart` — `Achievement` records carrying `(current, target)` progress closures; catalog seeds the PDF's 3 required (7-day study streak, 30 workouts, 100 prayers) plus natural extensions: first session, 100 study hours, 30-day study streak, habit streaks (7/30), 500 habit days, prayer streaks (7/30), first workout, 7-day workout streak, 50 hours trained, XP milestones (10k/50k), level milestones (5/10/20). Milestones use synthetic targets — the controller intercepts them in `progressFor` to evaluate against live XP/level rather than stats.
- `lib/features/gamification/state/gamification_controller.dart` — Hive-backed seen-set + last-seen-level. `recompute(...)` runs on every source-controller notify (via proxy provider). `hasPendingCelebration` = newly unlocked OR level-up since last seen. `markCelebrationSeen()` persists.
- `lib/features/gamification/widgets/celebration_overlay.dart` — animated modal dialog (scale + fade tween) showing the level number, title (if level-up), and newly-unlocked badges. `showIfPending(context)` is the single entry point.
- `lib/features/gamification/screens/achievements_screen.dart` — hero card with level/XP/progress + full title ladder showing locked/unlocked/NEXT bands + grouped badge list (unlocked count, in-progress with `(current/target)` and progress bar).

Wiring:

- `lib/main.dart` — added `ChangeNotifierProxyProvider4<Study, Habit, Prayer, Fitness, Gamification>`. `recompute` runs on every dependency notify.
- `lib/features/dashboard/screens/dashboard_screen.dart` — converted to StatefulWidget so `didChangeDependencies` can schedule a post-frame call to `CelebrationOverlay.showIfPending(context)` exactly once per app session. New `_xpHeroCard` placed at the top of the dashboard scroll, tappable → Achievements screen. The card surfaces a "N NEW" accent pill when there are newly-unlocked badges since last viewed. Rewrote `onJumpTab` references to `widget.onJumpTab` after the stateful conversion.
- `lib/features/profile/screens/profile_screen.dart` — added a 🏆 trophy icon in the AppBar that opens the Achievements screen.

`flutter analyze`: 0 errors, 0 warnings, same 8 info-level lints as before (no new findings from Phase 3).

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
