---
name: project-elite
description: Practical guide for working on the Project Elite Flutter codebase at K:\project_elite — a self-improvement app for study, habits, prayer, and fitness. Use this skill whenever the user asks to add a new feature, create a screen or controller, persist data with Hive, modify the provider tree in main.dart, or touch anything under lib/features/. Also use it for less obvious tasks in this repo (theme tweaks, refactoring, bug fixes) so new code stays in the same shape as existing code. Trigger generously when working in this project — the patterns here are deliberate and easy to break by accident.
---

# Project Elite — codebase guide

Project Elite is a self-improvement Flutter app (Android + iOS) at `K:\project_elite`. The product spec lives in `Project Elite App Overview.pdf` at the repo root — twelve feature systems, of which five are implemented (Profile, Dashboard, Study, Habits, Prayer) and seven are deferred to phase 2 (Fitness, Notifications, Ayanokoji Mode, Gamification, Reports, AI Assistant, extended Islamic features).

`CLAUDE.md` summarizes the architecture; this skill is the hands-on "how do I add something" guide. Read both when starting work.

## Adding a feature module

Features are organized **by domain, not by layer**. Every feature lives under `lib/features/<name>/` with three subdirectories:

```
lib/features/<name>/
├── models/        # plain Dart classes with toJson/fromJson
├── state/         # ChangeNotifier controller(s)
└── screens/       # UI — imports the controller via Provider
```

A feature may import *another feature's controller and models*, but should not import another feature's screens — those are private to the feature. The dashboard is the canonical example: it watches Study, Habit, and Prayer controllers to compute the daily score.

### The 5-step recipe

When adding a new feature (e.g. "fitness"), do these steps in order:

**1. Add a Hive box constant.** Open `lib/core/storage/hive_setup.dart` and add a new entry to `HiveBoxes`, then open it in `init()`. Pick a name like `box_fitness_sessions` — the `box_` prefix is the convention.

**2. Write the model(s).** Plain Dart class under `lib/features/<name>/models/`. No `@HiveType` annotation, no codegen. Just a constructor, `toJson()` returning `Map<String, dynamic>`, and a `fromJson(Map)` factory. See the next section for the exact pattern.

**3. Write the controller.** A `ChangeNotifier` under `lib/features/<name>/state/<name>_controller.dart`. It opens the Hive box via `Hive.box(HiveBoxes.<name>)` in its constructor and exposes read methods plus mutating methods that call `notifyListeners()`.

**4. Write the screens.** Under `lib/features/<name>/screens/`. Use `context.watch<X>()` to read state, `context.read<X>()` to mutate. Reach for `lib/shared/widgets/elite_card.dart` (`EliteCard`, `SectionHeader`, `StatTile`) and the `AppColors` palette from `lib/core/theme/app_theme.dart` so the UI matches.

**5. Register the controller and (optionally) the tab.** In `lib/main.dart` add a `ChangeNotifierProvider` to the `MultiProvider` list. If the feature gets its own bottom-nav tab, add it to `lib/main_shell.dart`'s `_pages` and `BottomNavigationBar` items.

### Why this layout

The feature-module split lets each domain own its data, state, and UI in one place, which is what you scan for when extending one feature without breaking another. The "no cross-feature screen imports" rule keeps screens swappable — you can rewrite the Study UI without touching the Dashboard because the Dashboard only knows the Study *controller*, not the *screen*.

## Hive persistence: no codegen, JSON-shaped models

The codebase **deliberately avoids `build_runner`**. Hive stores `Map<String, dynamic>` directly. Every model follows this shape:

```dart
class StudySession {
  final String id;
  final String subject;
  final DateTime startedAt;
  final int durationSeconds;

  const StudySession({
    required this.id,
    required this.subject,
    required this.startedAt,
    required this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory StudySession.fromJson(Map json) => StudySession(
        id: json['id'] as String,
        subject: json['subject'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        durationSeconds: (json['durationSeconds'] as num).toInt(),
      );
}
```

Notes that matter:

- `DateTime` → ISO 8601 string, parsed back with `DateTime.parse`.
- Numeric fields come back as `num` from Hive, so cast with `(json['x'] as num).toInt()` or `.toDouble()`. Don't cast directly to `int` — if you ever write a value that round-trips as `double`, the cast throws.
- The `fromJson` parameter is `Map` (not `Map<String, dynamic>`) because Hive hands back `Map<dynamic, dynamic>`. The caller is responsible for the cast.

### Reading from a Hive box

The pattern for hydrating a list on controller init:

```dart
_sessions = _box.values
    .whereType<Map>()
    .map((m) => StudySession.fromJson(Map<String, dynamic>.from(m)))
    .toList();
```

The `Map<String, dynamic>.from(m)` cast is required because `_box.values` yields `Map<dynamic, dynamic>` even though we wrote a `Map<String, dynamic>`. Omitting it compiles but throws at the field-access sites in `fromJson`.

### Writing to a Hive box

```dart
await _box.put(session.id, session.toJson());
```

The key can be anything `String` (id, day-key, composite). Use a UUID via `package:uuid` for record-style data, or a deterministic key for time-series data (see next section).

## Day-key time-series pattern

For daily-tracked metrics (habit completions, prayer completions, water glasses, etc.), don't model each entry as a record. Instead, write a boolean (or count) keyed by a composite string. This makes streak/calendar queries trivial — no scanning, no per-day model.

```dart
String _key(String habitId, DateTime day) => '$habitId|${DateX.dayKey(day)}';

// write
await _logs.put(_key(habitId, day), true);

// read
final done = (_logs.get(_key(habitId, day)) as bool?) ?? false;
```

`DateX.dayKey` in `lib/core/utils/date_utils.dart` returns `yyyy-MM-dd`, which sorts lexicographically. `DateX` also has `last7Days()`, `startOfWeek(d)`, and `startOfDay(d)` — use them instead of writing date math inline.

When to use this pattern vs records:
- **Day-key**: per-day completions or counts, anything you'd visualize as a calendar heatmap, streak/consistency metrics.
- **Records (UUID key)**: events with rich metadata that recur multiple times per day (study sessions, workout sets, journal entries).

## Wiring into `main.dart`

`main.dart` does three things and they need to happen in this order:

1. `WidgetsFlutterBinding.ensureInitialized()` and `HiveSetup.init()` (opens all boxes — the controllers assume their boxes are open).
2. Build the `MultiProvider` tree.
3. `_Root` reads `ProfileController.hasProfile` and routes to `OnboardingScreen` or `MainShell`.

A controller that depends on another controller's state should use `ChangeNotifierProxyProvider`, not `ChangeNotifierProvider`. `PrayerController` is the live example — it picks up lat/lng from the profile if previously stored. The proxy's `update` callback must return the *existing* instance when the dependency changes, not construct a new one (that would lose internal state and re-fire listeners unnecessarily).

## Daily score (Dashboard) invariant

`DashboardScreen` computes a 0–100 daily score as `study 40% + habits 35% + prayer 25%`. The weights sum to 1.0. If you add a new pillar (fitness, meditation, water), re-balance the weights — keep them summing to 1.0 so the score stays bounded.

## Two product-side reminders

These aren't about code mechanics but they bite if forgotten:

- **The PDF is source of truth for terminology.** CA subject names, level names ("Certificate"/"Professional"/"Advance"), the title ranks ("Beginner → Disciplined → Elite → Mastermind → Ayanokoji"), and feature names ("Ayanokoji Mode") all come from `Project Elite App Overview.pdf`. Don't invent, trim, or rename them. The CA subject lists in `lib/core/constants/ca_subjects.dart` are pulled verbatim — keep them that way.
- **The deliberate stack choices.** Storage is local-only Hive (not Firebase/Supabase). The "AI" features are rule-based (not LLM-backed). Prayer times come from the `adhan` package offline (not the Aladhan API). These were the user's explicit choices, not defaults. Don't propose migrating any of them unprompted — surface the tradeoff if it becomes genuinely relevant, then let the user decide.

## Build / run

Commands run from the project root in PowerShell:

```
flutter pub get
flutter run
flutter run -d android
flutter analyze
flutter test
```

No `build_runner` step — Hive models are hand-rolled.
