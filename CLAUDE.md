# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product context

This is **Project Elite**, a self-improvement Flutter app for Android and iOS. The full product spec lives in `Project Elite App Overview.pdf` at the repo root — twelve feature systems covering profile setup, AI daily planner, fitness, study tracking (the PDF calls study "the main star"), habits, prayer/Islamic features, notifications, "Ayanokoji Mode" discipline gamification, dashboard, XP/levels gamification, reports, and an AI assistant.

The codebase currently implements the **MVP**: Profile onboarding, Dashboard, Study tracker, Habit tracker, Prayer system. The other seven systems are deferred to phase 2 — see `Project Elite App Overview.pdf` for what each entails. The deferred features were chosen deliberately, not by accident.

## Commands

All commands run from the project root (`K:\project_elite` on Windows, mounted `/mnt/k/project_elite` on WSL). The shell is PowerShell on this machine.

```powershell
flutter pub get                                  # install deps after pubspec changes
flutter run                                      # run on a connected device
flutter run -d android
flutter run -d ios                               # macOS only; needs `cd ios; pod install` first
flutter analyze                                  # static analysis (uses analysis_options.yaml)
flutter test                                     # run all tests
flutter test test/widget_test.dart -p chrome     # single test file
flutter build apk --release
flutter build ios --release
```

There is no code generation step — Hive models are hand-rolled (`toJson` / `fromJson`), so `build_runner` is not part of the workflow.

## Architecture

### Feature-module layout

Code is organized by **feature**, not by layer. Each feature under `lib/features/<name>/` is self-contained with `models/`, `state/`, and `screens/`. Cross-feature imports are allowed (the dashboard reads from study/habit/prayer controllers), but a feature should not import another feature's *screens* — only its `state/` controllers and `models/`.

Shared scaffolding lives in:
- `lib/core/theme/app_theme.dart` — dark theme, `AppColors` palette
- `lib/core/storage/hive_setup.dart` — `HiveBoxes` constants + `HiveSetup.init()`
- `lib/core/constants/ca_subjects.dart` — the CA subject lists from the PDF (referenced verbatim — do not rename or omit subjects)
- `lib/core/utils/date_utils.dart` — `DateX` with day-key, week-start, last-7-days helpers
- `lib/shared/widgets/elite_card.dart` — `EliteCard`, `SectionHeader`, `StatTile`

`lib/main.dart` wires the Hive boxes and the `MultiProvider` tree, then `lib/main_shell.dart` hosts the bottom-nav `IndexedStack`. `_Root` in `main.dart` decides between `OnboardingScreen` and `MainShell` based on whether a profile exists in the Hive `profile` box.

### State management

Every feature exposes a `ChangeNotifier` controller in `state/<name>_controller.dart`, registered in `main.dart`'s `MultiProvider`. UI watches controllers with `context.watch<X>()` and mutates with `context.read<X>()`. `PrayerController` is the one exception — it's wired through a `ChangeNotifierProxyProvider` because it needs the profile's lat/lng if previously stored.

### Storage: Hive without codegen

Hive is used in a deliberately codegen-free way. Models are plain Dart classes with `toJson()` returning `Map<String, dynamic>` and a `fromJson(Map)` factory. Controllers call `Box.put(id, model.toJson())` and read back via `_box.values.whereType<Map>().map((m) => Model.fromJson(Map<String, dynamic>.from(m)))`. The `Map<String,dynamic>.from(...)` cast is required because Hive returns `Map<dynamic,dynamic>`.

Six boxes are opened at startup (`HiveBoxes.profile`, `study`, `habits`, `habitLogs`, `prayer`, `settings`). When adding a new feature with persistence, add the box name to `HiveBoxes`, open it in `HiveSetup.init()`, and follow the same model pattern.

### Time-series storage pattern

Habit completions and prayer completions are stored as boolean entries keyed by a composite string, not as model records. Habit log key: `'$habitId|${DateX.dayKey(day)}'`. Prayer log key: `'${DateX.dayKey(day)}|${slot.name}'`. `DateX.dayKey` returns `yyyy-MM-dd`. This is intentional — it makes streak/calendar queries cheap and avoids needing a per-day-per-thing model. Reuse this pattern for new daily-tracked metrics.

### Daily score (dashboard)

`DashboardScreen` computes a 0–100 daily score as a weighted blend: `study 40% + habits 35% + prayer 25%`. Each pillar is normalized against the user's profile goals. If you add new pillars (fitness, meditation, etc. — they exist in the PDF), update the weights so they still sum to 1.0.

### Prayer times

`PrayerController` uses the `adhan` package with `CalculationMethod.karachi` and `Madhab.hanafi` defaults. These are appropriate for South Asia. `geolocator` requests location at runtime; iOS strings are in `ios/Runner/Info.plist`, Android permissions are in `android/app/src/main/AndroidManifest.xml` (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`).

## Working with the PDF spec

When implementing a new feature from `Project Elite App Overview.pdf`, copy field names and category labels exactly — the user has specific terminology (CA Certificate/Professional/Advance levels, "Ayanokoji Mode", title ranks like "Mastermind"/"Elite") that should be preserved. The CA subject lists in `ca_subjects.dart` are pulled directly from the PDF; do not invent or trim them.

The AI features in the PDF (Daily Planner, AI Assistant) are currently rule-based and should stay that way until the user explicitly opts in to an LLM API key flow. Same for storage: the user chose local-only Hive over cloud sync deliberately — do not propose Firebase/Supabase migrations unprompted.
