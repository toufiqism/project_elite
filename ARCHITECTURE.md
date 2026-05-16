# Project Elite — Architecture Reference

A complete reference for how the Project Elite Flutter app is wired together.
This describes the code as it actually exists; for product intent and deferred
features, see `Project Elite App Overview.pdf`. For day-to-day development
conventions, see `CLAUDE.md`.

> **Note on drift.** `CLAUDE.md` predates several features (auth, Firestore
> sync, fitness, ayanokoji, gamification, notifications, news, islamic,
> reports). This document supersedes it for architectural facts; it does not
> change the development conventions in `CLAUDE.md`.

---

## 1. Stack

| Concern               | Choice                                              |
| --------------------- | --------------------------------------------------- |
| UI                    | Flutter (Material 3, dark theme only)               |
| State                 | `provider` (`ChangeNotifier` + `ChangeNotifierProxyProvider`) |
| Local persistence     | `hive` / `hive_flutter`, no codegen                 |
| Cloud sync (optional) | Cloud Firestore (one document per Hive box)         |
| Auth                  | `firebase_auth` (email/password + Google)           |
| Prayer times          | AlAdhan REST API (`http`), cached per day in Hive   |
| Location              | `geolocator` + `geocoding`                          |
| Notifications         | `flutter_local_notifications` + `timezone`          |
| Charts                | `fl_chart`                                          |
| Fitness exercise DB   | ExerciseDB (RapidAPI) via `http`, cached in Hive    |
| Compass (qibla)       | `flutter_compass`                                   |
| WebView (news)        | `webview_flutter`                                   |

Hand-rolled `toJson` / `fromJson` everywhere — there is **no** `build_runner`
step. Don't add one.

---

## 2. Folder layout

```
lib/
├── main.dart                ← Firebase + Hive + Notifications init, MultiProvider, _Root
├── main_shell.dart          ← bottom-nav IndexedStack
├── firebase_options.dart    ← FlutterFire-generated
├── core/
│   ├── config/              ← api_keys.dart (gitignored), api_keys.example.dart
│   ├── constants/           ← ca_subjects.dart (verbatim from PDF)
│   ├── storage/             ← hive_setup.dart (HiveBoxes + init)
│   ├── theme/               ← app_theme.dart (AppColors, AppTheme.dark())
│   └── utils/               ← date_utils.dart (DateX, formatDuration/Hms)
├── shared/
│   └── widgets/             ← elite_card.dart (EliteCard, SectionHeader, StatTile)
└── features/
    ├── auth/                ← Firebase email + Google sign-in
    ├── profile/             ← UserProfile + onboarding
    ├── dashboard/           ← Home — composes everything
    ├── study/               ← Pomodoro timer + session history
    ├── habits/              ← Daily check-off + streaks
    ├── prayer/              ← AlAdhan-based times, completion, overrides
    ├── fitness/             ← ExerciseDB-backed workouts + weight log
    ├── gamification/        ← XP, levels, achievements, celebration overlay
    ├── ayanokoji/           ← Discipline mode, focus timer, mini-games, char-stats
    ├── notifications/       ← Local scheduling (prayer/study/water/streak)
    ├── islamic/             ← Tasbih counter, qibla, duas
    ├── news/                ← Local + international news via NewsService
    ├── reports/             ← Period reports (share-as-text)
    ├── settings/            ← Settings screen
    └── sync/                ← Firestore upload/restore of synced Hive boxes
```

Rules:

- Cross-feature imports are **allowed** only into another feature's `state/`,
  `models/`, or `data/` — never its `screens/`. The Dashboard is the
  composition root for state; navigation is owned by `MainShell`.
- New shared widgets go in `lib/shared/widgets/`. New cross-cutting helpers in
  `lib/core/`.

---

## 3. App startup (`lib/main.dart`)

`main()` runs, in order:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Edge-to-edge system UI + transparent system bars.
3. `Firebase.initializeApp(...)` with `DefaultFirebaseOptions.currentPlatform`.
4. Firestore offline persistence enabled with `CACHE_SIZE_UNLIMITED`.
5. `HiveSetup.init()` — opens 14 boxes (§5).
6. `NotificationService.instance.init()` — creates Android channels, requests perms.
7. `DuaService.instance.load()` — preloads `assets/duas.json`.
8. `runApp(const ProjectEliteApp())`.

`ProjectEliteApp` builds a single `MultiProvider` tree, then a `MaterialApp`
with `AppTheme.dark()` whose home is `_Root`.

### 3.1 Provider tree (`main.dart:55`)

Direct providers (no upstream deps):

- `AuthController`
- `ProfileController`
- `NewsController`
- `StudyController`
- `HabitController`
- `FitnessController`
- `TasbihController`

Proxy providers (depend on others):

- `ChangeNotifierProxyProvider<ProfileController, PrayerController>` — pushes
  `profile.profile?.prayerAddress` into `PrayerController.setAddress(...)`.
- `ChangeNotifierProxyProvider4<Study, Habits, Prayer, Fitness, Ayanokoji>` —
  calls `AyanokojiController.recompute(...)` whenever any source notifies.
- `ChangeNotifierProxyProvider2<Prayer, Ayanokoji, NotificationController>` —
  calls `applyContext(prayerTimes:, disciplineMode:)` so the notification
  layer reschedules when prayer times or discipline mode change.
- `ChangeNotifierProxyProvider4<Study, Habits, Prayer, Fitness, Gamification>`
  — same pattern for `GamificationController.recompute(...)`.

The proxies are why most controllers expose a `void recompute(...)` taking
their source controllers as positional/named args — see §6.4.

### 3.2 `_Root` and per-user data partitioning (`main.dart:125`)

`_Root` is the gatekeeper:

- If `!auth.isAuthenticated` → `AuthScreen`.
- Else while a per-uid `_handleLogin` is running → `CircularProgressIndicator`.
- Else if `!profile.hasProfile` → `OnboardingScreen`.
- Else → `MainShell`.

`_handleLogin(uid)` is the key cross-account safety mechanism. It runs every
time the Firebase auth user changes:

1. Reads `last_uid` from `HiveBoxes.settings`.
2. If the uid differs from the last one, **clears all user-data Hive boxes**
   (profile, study, habits, habitLogs, prayer, workoutSessions, weightLog,
   focusSessions, socialRatings, gameResults, tasbih).
3. Calls `SyncService.cloudTimestamp(uid)`; if there's a backup, awaits
   `SyncService.restore(uid)`.
4. Writes `last_uid = uid`.
5. Reloads every data controller (`profile`, `study`, `habits`, `fitness`,
   `tasbih`) so they re-read Hive after the wipe/restore.

This prevents account A from seeing account B's data on a shared device.

---

## 4. Navigation (`lib/main_shell.dart`)

A 6-tab `BottomNavigationBar` over an `IndexedStack` (preserves state of
inactive tabs). Tab order is hard-coded:

| Index | Tab     | Screen                |
| ----- | ------- | --------------------- |
| 0     | Home    | `DashboardScreen`     |
| 1     | Study   | `StudyHomeScreen`     |
| 2     | Habits  | `HabitsScreen`        |
| 3     | Prayer  | `PrayerScreen`        |
| 4     | Fitness | `FitnessHomeScreen`   |
| 5     | News    | `NewsScreen`          |

`DashboardScreen` receives `onJumpTab: (i) => setState(...)` so dashboard
cards can navigate to other tabs without a separate router.

Per-feature screens that aren't in the bottom nav (Settings, Profile, study
history, achievements, reports, ayanokoji home, qibla, tasbih, duas, mini-
games, workout session, etc.) are pushed via standard `Navigator` routes
from inside their tab.

---

## 5. Hive storage

### 5.1 Boxes (`lib/core/storage/hive_setup.dart`)

| Box constant       | Box name                  | Holds                                  |
| ------------------ | ------------------------- | -------------------------------------- |
| `profile`          | `box_profile`             | single `UserProfile` under key `profile` |
| `study`            | `box_study_sessions`      | `StudySession` records keyed by id     |
| `habits`           | `box_habits`              | `Habit` records keyed by id            |
| `habitLogs`        | `box_habit_logs`          | bool `'${habitId}|${dayKey}'`          |
| `prayer`           | `box_prayer`              | cache + overrides + completion (§7.3)  |
| `settings`         | `box_settings`            | misc kv (last_uid, gamification seen, ayanokoji mode) |
| `notifications`    | `box_notifications`       | `NotificationSettings` under `settings_v1` |
| `exerciseCache`    | `box_exercise_cache`      | ExerciseDB response cache              |
| `workoutSessions`  | `box_workout_sessions`    | `WorkoutSession` records               |
| `weightLog`        | `box_weight_log`          | `WeightEntry` records                  |
| `focusSessions`    | `box_focus_sessions`      | Ayanokoji `FocusSession` records       |
| `socialRatings`    | `box_social_ratings`      | one rating per day, keyed by `dayKey`  |
| `gameResults`      | `box_game_results`        | `MiniGameResult` records               |
| `tasbih`           | `box_tasbih`              | tasbih counts                          |

All boxes are untyped (`Hive.openBox(name)` — no adapter). Models are written
as `Map<String, dynamic>` via `toJson()` and read back with
`Map<String, dynamic>.from(rawMap)`. The cast is **required** because Hive
returns `Map<dynamic, dynamic>`.

### 5.2 Model pattern

Every persisted model has:

```dart
Map<String, dynamic> toJson() => { 'id': id, ... };
factory Model.fromJson(Map json) => Model(...);
```

`DateTime` fields are stored as ISO strings (`startedAt.toIso8601String()` →
`DateTime.parse(json['startedAt'] as String)`). Enums are stored as
`enumValue.name`. See `lib/features/study/models/study_session.dart` for the
canonical small example.

### 5.3 Time-series pattern

When something is tracked once per day per thing, do **not** create a record
type — store a bool keyed by a composite string instead.

- Habit completions — key: `'${habitId}|${DateX.dayKey(day)}'` in
  `HiveBoxes.habitLogs`.
- Prayer completions — key: `'${DateX.dayKey(day)}|${slot.name}'` in
  `HiveBoxes.prayer`.
- Daily social rating — key: `DateX.todayKey()` in `HiveBoxes.socialRatings`.

This makes streak/calendar queries cheap and avoids a per-day-per-thing
model. Reuse for new daily-tracked metrics.

`DateX.dayKey(d)` returns `yyyy-MM-dd` (see
`lib/core/utils/date_utils.dart:4`). Other helpers: `todayKey()`,
`startOfDay`, `startOfWeek` (Monday-first), `last7Days({from})`, `shortDay`,
`monthDay`, `prettyTime`. Top-level `formatDuration(d)` and `formatHms(d)`
are also there.

---

## 6. State management

### 6.1 Controller anatomy

Every feature has `state/<name>_controller.dart` exposing a `ChangeNotifier`
that:

- Holds `final Box _box = Hive.box(HiveBoxes.<name>);` directly (no
  repository layer for storage — `FitnessController` is the lone exception,
  it uses `FitnessRepository` for the *network*).
- Loads in the constructor by mapping `_box.values.whereType<Map>()` →
  models.
- Exposes `List<Model> get list => List.unmodifiable(_list);`.
- Mutations call `_box.put(id, model.toJson())` then update the in-memory
  list and `notifyListeners()`.
- Provides a public `void reload()` that re-reads from Hive and
  `notifyListeners()`. This is what `_RootState._handleLogin` calls after a
  cross-account wipe/restore.

### 6.2 Watching vs reading

UI reads with `context.watch<X>()` to rebuild on `notifyListeners()`, and
calls mutations via `context.read<X>()`. The dashboard
(`features/dashboard/screens/dashboard_screen.dart:44`) is the heaviest
watcher — it watches profile, study, habits, prayer, fitness, gamification,
and ayanokoji.

### 6.3 Reload after wipe/restore

After `SyncService.restore(uid)` overwrites Hive directly, in-memory
controller state is stale. `_RootState` explicitly calls `.reload()` on
profile, study, habits, fitness, and tasbih. **If you add a new feature
controller that holds cached lists, add it to the reload list in
`main.dart:195`.** Prayer reads through Hive on each call so it doesn't need
a reload; gamification/ayanokoji are recomputed by their proxies whenever
their sources notify.

### 6.4 The recompute() pattern

Controllers that are pure functions of other controllers expose
`recompute({required X, required Y, ...})` and are wired via
`ChangeNotifierProxyProvider*`. The proxy's `update` callback runs whenever
any source notifies, calls `recompute`, and the result is itself a
`ChangeNotifier`, so UI watchers re-render. See
`GamificationController.recompute` (`gamification_controller.dart:53`) and
`AyanokojiController.recompute` (`ayanokoji_controller.dart:155`).

`NotificationController.applyContext` is similar but it's
side-effect-heavy (schedules OS notifications), so it guards on
`overrideChanged || timesChanged` before doing work
(`notification_controller.dart:46`).

---

## 7. Feature reference

### 7.1 Auth (`features/auth/`)

`AuthController` wraps `FirebaseAuth.instance`:

- `signIn(email, password)`, `signUp(email, password)`,
  `signInWithGoogle()`, `signOut()`.
- Exposes `user`, `isAuthenticated`, `isLoading`, `error`.
- Subscribes to `_auth.authStateChanges()` in the constructor so any external
  state change triggers `notifyListeners()`.
- Error codes are mapped to friendly strings in `_message(code)`
  (`auth_controller.dart:100`).

`AuthScreen` (`features/auth/screens/auth_screen.dart`) is the sign-in UI.
Google sign-out is best-effort (wrapped in `try/catch`) because the active
session may have been email/password.

### 7.2 Profile (`features/profile/`)

`UserProfile` (`models/user_profile.dart`) is the big one — 22 fields
covering name/age/gender, height/weight/goalWeight, fitness level, study
mode (always `'ca'` today) + CA level + subjects (drawn from
`ca_subjects.dart`), occupation, daily free hours, sleep schedule,
study/workout/water goals, stress level, prayer-reminders bool, preferred
workout type, plus optional `latitude`/`longitude`/`prayerAddress`. `bmi`
is derived.

`ProfileController`:

- Stores the single profile under the string key `'profile'` (not under
  uid — uid partitioning happens via the wipe-on-uid-change in `_Root`).
- `save(profile)`, `update(Function(UserProfile) update)`, `clear()`,
  `reload()`.

`OnboardingScreen` is shown when `hasProfile` is false; `ProfileScreen` is
the post-onboarding editor.

### 7.3 Prayer (`features/prayer/`)

`PrayerController` is wired via `ChangeNotifierProxyProvider<Profile,
Prayer>`. The profile's `prayerAddress` is pushed in via `setAddress(...)`.

Storage layout in `HiveBoxes.prayer` (one box, three key namespaces):

| Key                                         | Value                              |
| ------------------------------------------- | ---------------------------------- |
| `cache|${dayKey}`                           | `Map<slotName, "HH:MM">` (API result) |
| `override|${dayKey}|${slotName}`            | `"HH:MM"` (user override)          |
| `${dayKey}|${slotName}`                     | `true` (slot was prayed)           |

`PrayerSlot` enum: `fajr, dhuhr, asr, maghrib, isha`. Method-1 (University
of Islamic Sciences, Karachi) is hard-coded in `AladhanService` — this is
intentional for South Asia.

Lifecycle:

1. Constructor with non-empty address → `_loadCached()` — shows cached times
   immediately so the UI doesn't flash.
2. `fetchByAddress(address)` → `AladhanService.fetchTimings(...)` → write
   `cache|...`, then `_withOverrides(...)` to apply any user overrides.
3. `setOverride(slot, time)` / `clearOverride(slot)` write/delete the
   `override|...` key and reapply.
4. `toggle(slot, [day])` flips the completion bool.

`AladhanService.fetchTimings` (`aladhan_service.dart`) hits
`https://api.aladhan.com/v1/timingsByAddress/dd-MM-yyyy?address=...&method=1`,
12-second timeout, defensively splits time strings on space (the API can
return `"04:39 (UTC+6)"`).

### 7.4 Study (`features/study/`)

`StudyController`:

- `addSession({subject, startedAt, duration, note})` — uuid id, prepend to
  in-memory list.
- `deleteSession(id)`, `reload()`.
- Aggregations: `totalToday()`, `totalOn(day)`, `last7DaysTotals()`,
  `subjectTotalsThisWeek()`, `totalThisWeek()`, `currentStreak()`.

Screens: `StudyHomeScreen` (overview), `StudyTimerScreen` (pomodoro),
`StudyHistoryScreen` (list/filter).

### 7.5 Habits (`features/habits/`)

`HabitController`:

- Holds two boxes — `habits` (definitions) and `habitLogs` (per-day bools).
- Seeds 7 defaults on first launch (Drink water, Read, Meditation,
  Journaling, Sleep on time, No social media, No NSFW content). `negative:
  true` flags last two — UI treats those inversely.
- `add(name, icon, negative)`, `remove(id)` (also deletes all matching log
  keys), `toggle(habitId, day)`, `isDone(habitId, day)`.
- `streak(habitId)`, `doneTodayCount()`, `monthSuccessRate(habitId)`.

### 7.6 Fitness (`features/fitness/`)

The most network-coupled feature.

- `FitnessRepository` (`data/fitness_repository.dart`) — wraps the ExerciseDB
  API, caches responses in `HiveBoxes.exerciseCache`. API key lives in
  `lib/core/config/api_keys.dart` (gitignored — there's an
  `api_keys.example.dart`).
- `WorkoutPlanner` (`services/workout_planner.dart`) — builds a `WorkoutPlan`
  for a given `UserProfile`.
- `FitnessController` — `buildTodayPlan(profile)`, `saveSession(...)`,
  `logWeight(kg)`, plus history queries (`didWorkoutToday()`,
  `currentWorkoutStreak()`, `totalWorkoutToday()`, `latestWeight`).
- Models: `Exercise`, `WorkoutPlan`, `WorkoutSession` (+
  `CompletedExercise`), `WeightEntry`.
- Screens: `FitnessHomeScreen`, `WorkoutSessionScreen`,
  `WorkoutHistoryScreen`, `WeightScreen`.

> **Security note.** ExerciseDB key is hard-coded into the gitignored
> `api_keys.dart`. Scrub it before any distribution action.

### 7.7 Dashboard (`features/dashboard/`)

Pure read-side composition over all data controllers. Calculates a 0–100
**daily score** as a weighted blend of pillar completion ratios.

Current weights (`dashboard_screen.dart:69`):

```
score = (study * 0.35 + habits * 0.25 + prayer * 0.20 + fitness * 0.20) * 100
```

(Totals 1.0. **`CLAUDE.md`'s stated 40/35/25 split is outdated** — the
fitness pillar was added later. Update CLAUDE.md if the weights change
again.)

Pillar normalizations:

- **study** — `study.totalToday().inSeconds / (goalHours * 3600)` clamped.
- **habits** — `habits.doneTodayCount() / habits.habits.length`.
- **prayer** — `prayer.completedToday() / 5`.
- **fitness** — `fitness.totalWorkoutToday().inMinutes /
  profile.workoutGoalMinutesPerDay` clamped.

The dashboard also kicks the gamification celebration overlay once per
mount (`_celebrationChecked` guard +
`CelebrationOverlay.showIfPending(context)` in a post-frame callback).

### 7.8 Gamification (`features/gamification/`)

Pure derived state — never the source of truth.

- `GamificationStats` is a frozen snapshot built by
  `GamificationStats.from({study, habits, prayer, fitness})`. The walk over
  the last 365 days × habits × prayer slots is **O(365·H + 365·5)**;
  acceptable today.
- `XpRules.totalFor(stats)` is the canonical XP formula (chosen 2026-05-15
  by the user):
  - 1 XP per study minute
  - 10 XP per habit completion
  - 8 XP per prayer
  - 1 XP per workout minute + 30 XP per workout session
- `LevelInfo.fromXp(totalXp)` — **quadratic curve**: total XP to *reach*
  level N is `N² × 100` (level 1 is free at 0 XP, level 2 at 400 XP, …).
- `Titles.forLevel(level)` — ladder Beginner / Disciplined / Elite /
  Mastermind / Ayanokoji at levels 1 / 5 / 10 / 20 / 50.
- `Achievements.all` — list of milestone definitions. The controller
  evaluates each on every recompute and stores the unlocked-id set in
  memory.
- Celebration overlay state lives in `HiveBoxes.settings` under
  `gamification_seen_ids` (set of ids already shown) and
  `gamification_last_seen_level` (so each level-up fires once).
  `markCelebrationSeen()` advances both.

### 7.9 Ayanokoji mode (`features/ayanokoji/`)

A discipline gamification layer on top of everything else. Persistent state:

- `ayanokoji_discipline_mode` (bool) in `HiveBoxes.settings` — toggling
  this propagates via the proxy provider into `NotificationController`,
  which switches all notification copy to the harsh "discipline" tone.
- `HiveBoxes.focusSessions` — completed focus-timer runs.
- `HiveBoxes.socialRatings` — one self-rating per day, keyed by `dayKey`.
- `HiveBoxes.gameResults` — every mini-game result (digit span, reaction
  time, stroop).

`recompute(...)` builds 6 character-stat XP totals (intelligence,
discipline, strength, focus, consistency, social) from study minutes,
habit/prayer completions, workout sessions, mini-game XP, focus minutes,
best streak, and social rating sum. The formulas are in `_recomputeStats()`
(`ayanokoji_controller.dart:220`).

Screens: `AyanokojiHomeScreen`, `CharacterStatsScreen`,
`FocusTimerScreen`, `MiniGamesScreen` plus three game screens under
`screens/games/`.

### 7.10 Notifications (`features/notifications/`)

Wired through a 2-source proxy so it reschedules whenever prayer times or
discipline mode change.

- `NotificationService` (`service/notification_service.dart`) — singleton
  wrapping `flutter_local_notifications`. Creates Android channels, handles
  timezone init, exposes `scheduleAt`, `scheduleDaily`, `cancelAll`,
  `showNow`, `requestPermissions`.
- `NotificationController`:
  - Loads `NotificationSettings` from `HiveBoxes.notifications` under key
    `settings_v1`.
  - `applyContext({prayerTimes, disciplineMode})` — guards on
    `overrideChanged || timesChanged` before calling `reschedule()`. This
    keeps the proxy provider's `update` cheap.
  - `reschedule({prayerTimes})` cancels everything, then re-schedules the
    enabled categories.
- ID ranges are partitioned by category so cancels don't stomp:
  - `1000-1099` prayer (heads-up + at-time per slot)
  - `2000-2009` study daily
  - `3000-3099` water (up to 100 slots in a day)
  - `4000-4009` streak end-of-day
  - `9000-9099` test
- Three tones (`silent`, `motivational`, `discipline`) drive copy in
  `_copy()` and `_prayerCopy()`. `_effectiveTone` returns
  `discipline` whenever the Ayanokoji override is on, regardless of the
  user's chosen tone.

### 7.11 Islamic (`features/islamic/`)

- `DuaService` — loads `assets/duas.json` once at startup
  (`main.dart:46`) and exposes the list.
- `TasbihController` — counter persisted in `HiveBoxes.tasbih`.
- Screens: `TasbihScreen`, `QibScreen` (compass-based), `DuasScreen`.

### 7.12 News (`features/news/`)

`NewsController`:

- `init()` — detects country via `Geolocator` + `geocoding`
  (`placemarkFromCoordinates → isoCountryCode`), falling back to `'us'`.
- Then `Future.wait([_fetchLocal(), _fetchIntl()])` via `NewsService`.
- `refreshLocal()` and `refreshIntl()` for pull-to-refresh.

`NewsScreen` opens articles in `ArticleWebViewScreen` (a `webview_flutter`
view).

### 7.13 Reports (`features/reports/`)

`ReportsService` builds a `PeriodReport` for a given range and shares it as
text via `share_plus`. No persistence — generated on demand.

### 7.14 Sync (`features/sync/`)

`SyncService` (no controller — static methods only):

- `cloudTimestamp(uid)` — reads
  `users/{uid}/sync/meta.uploadedAt` (a Firestore `Timestamp`). 15-second
  timeout.
- `upload(uid)` — batched write: `meta` + one document per box in
  `_syncedBoxes`. Each box becomes
  `users/{uid}/sync/{boxName}.data = serialized`. Splitting per box keeps
  each doc under Firestore's 1 MB limit.
- `restore(uid)` — fetches all box docs in parallel, **clears the local
  Hive box**, then `put`s each entry back.

`_syncedBoxes` deliberately **excludes** `exerciseCache` (rebuildable from
the API), `notifications` (device-specific), and `settings` (device-
specific). When adding a new user-data box, add it to both `HiveBoxes`,
the open list in `HiveSetup.init()`, the wipe list in
`_RootState._handleLogin`, and `_syncedBoxes`.

---

## 8. Theming & shared widgets

- `AppColors` — dark palette (background `#0B0F14`, surface `#141A22`,
  primary `#8AB4FF`, accent `#E7C77B`, plus semantic success/warning/
  danger/muted/text). Use these constants rather than literal `Color(...)`s.
- `AppTheme.dark()` — single source of theming, including `AppBarTheme`,
  `CardThemeData`, `InputDecorationTheme`, `BottomNavigationBarThemeData`.
  Material 3 is enabled.
- `EliteCard` — the standard card surface (rounded 16, surfaceAlt border,
  optional `onTap` → `InkWell`). Use it instead of raw `Card`.
- `SectionHeader` — title + optional right-aligned text action.
- `StatTile` — icon + big-number value + label, wrapped in `EliteCard`.

---

## 9. External services & secrets

| Service       | Where                                            | Auth                                  |
| ------------- | ------------------------------------------------ | ------------------------------------- |
| Firebase Auth | email/password + Google                          | `firebase_options.dart`               |
| Firestore     | `users/{uid}/sync/{box}` documents               | Firebase Auth uid                     |
| AlAdhan       | `https://api.aladhan.com/v1/timingsByAddress/...` | None (public)                        |
| ExerciseDB    | RapidAPI                                          | key in `lib/core/config/api_keys.dart` (gitignored) |
| News          | via `NewsService.fetchLocal/fetchInternational`  | (see service file)                    |

Platform configuration:

- Android — location perms (`ACCESS_COARSE_LOCATION`,
  `ACCESS_FINE_LOCATION`) in `android/app/src/main/AndroidManifest.xml`.
  Notification channels are created at runtime by `NotificationService`.
- iOS — location usage strings in `ios/Runner/Info.plist`. After any
  `pubspec.yaml` change, `cd ios; pod install`.

---

## 10. Conventions worth re-stating

- **No code generation.** All `toJson`/`fromJson` is by hand. Don't add
  `build_runner`.
- **Local-first by default.** Hive is the source of truth; Firestore sync
  is a backup, not a live store. Don't propose moving primary storage to
  Firestore.
- **Rule-based "AI".** PDF features called "AI Daily Planner" / "AI
  Assistant" are intentionally rule-based until the user opts in to an LLM
  flow. Don't wire an API key for one unprompted.
- **Preserve PDF terminology.** "CA Certificate/Professional/Advance",
  "Ayanokoji Mode", "Mastermind" — copy these verbatim. The CA subject
  lists in `lib/core/constants/ca_subjects.dart` are pulled directly from
  the PDF; don't trim or invent.
- **Always run `flutter analyze` after changes.** Errors auto-fixed,
  warnings surfaced to the user.
- **Append substantive changes to `CLAUDE_UPDATES.md`** so the running
  record stays current.
