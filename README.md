# Project Elite

A self-improvement Flutter app for discipline, study, fitness, prayer, and habit mastery — built for Android and iOS, with all data stored locally on device.

## What it does

Project Elite is a single companion app that bundles the daily systems most people juggle across half a dozen tools:

- **Profile & Onboarding** — name, goals, study targets, prayer settings, location
- **Dashboard** — daily 0–100 score blended from study (40%), habits (35%), and prayer (25%)
- **Study Tracker** — session logging against CA Certificate / Professional / Advance subject lists
- **Habit Tracker** — daily checkmarks with streaks and weekly heatmaps
- **Prayer System** — offline prayer times (Karachi method, Hanafi madhab), qibla compass, duas
- **Fitness** — exercise library backed by ExerciseDB
- **Islamic Utilities** — Hijri date, duas, Ayanokoji discipline mode
- **Gamification** — XP, levels, achievement titles ("Mastermind", "Elite", …)
- **Reports** — weekly and monthly activity summaries, shareable via the system share sheet
- **Notifications** — local reminders scheduled by timezone

The full product spec is in `Project Elite App Overview.pdf` at the repo root.

## Tech stack

- **Flutter** (SDK ^3.11.5), Dart
- **Hive** for local persistence — no codegen, hand-rolled `toJson` / `fromJson`
- **Provider** for state (one `ChangeNotifier` per feature)
- **adhan** for offline prayer time calculation
- **geolocator** + **permission_handler** for location
- **fl_chart** for analytics
- **flutter_local_notifications** + **timezone** for scheduled reminders
- **share_plus** for report sharing

Storage is local-only by design — no Firebase, no cloud sync. AI features (Daily Planner, Assistant) are rule-based, not LLM-backed.

## Getting started

```bash
flutter pub get
flutter run                  # connected device
flutter run -d android
flutter run -d ios           # macOS only; cd ios && pod install first
```

### Useful commands

```bash
flutter analyze              # static analysis
flutter test                 # all tests
flutter build apk --release
flutter build ios --release
```

There is no `build_runner` step.

### API keys

The fitness feature uses ExerciseDB. The key lives in `lib/core/config/api_keys.dart`, which is gitignored. Create that file locally before running fitness flows.

## Project structure

Code is organized **by feature**, not by layer.

```
lib/
├── core/
│   ├── theme/            # AppTheme, AppColors
│   ├── storage/          # HiveBoxes + HiveSetup.init()
│   ├── constants/        # ca_subjects.dart (CA syllabus from PDF)
│   ├── config/           # api_keys.dart (gitignored)
│   └── utils/            # DateX (day-key, week-start, last-7-days)
├── shared/widgets/       # EliteCard, SectionHeader, StatTile
├── features/
│   ├── profile/          # onboarding, profile model
│   ├── dashboard/        # daily score
│   ├── study/            # subject sessions
│   ├── habits/           # daily check-ins
│   ├── prayer/           # adhan-based prayer times
│   ├── fitness/          # ExerciseDB-backed library
│   ├── islamic/          # Hijri, duas, qibla
│   ├── ayanokoji/        # discipline gamification
│   ├── gamification/     # XP, levels, titles
│   ├── notifications/    # local reminders
│   ├── reports/          # weekly/monthly summaries
│   └── settings/
├── main.dart             # MultiProvider wiring + Hive boxes
└── main_shell.dart       # bottom-nav IndexedStack
```

Each feature exposes models, a `ChangeNotifier` controller, and screens. Cross-feature imports of *controllers and models* are fine; importing another feature's *screens* is not.

## Architecture notes

- **Hive without codegen** — models are plain Dart classes; controllers store `model.toJson()` and read back with `Map<String, dynamic>.from(...)` (Hive returns `Map<dynamic, dynamic>`).
- **Time-series pattern** — daily booleans are keyed as composite strings, e.g. habit logs use `'$habitId|${DateX.dayKey(day)}'` and prayer logs use `'${DateX.dayKey(day)}|${slot.name}'`. Reuse this for any new daily-tracked metric.
- **Daily score weights** sum to 1.0 (study 0.40, habits 0.35, prayer 0.25). If new pillars are added, rebalance.
- **PrayerController** is wired through `ChangeNotifierProxyProvider` because it depends on profile lat/lng.

For deeper guidance see `CLAUDE.md`.

## Roadmap

The MVP shipped covers the core daily systems above. The remaining items from the PDF spec — AI Daily Planner with LLM backing, AI Assistant, deeper analytics — are deferred to phase 2 and will land once the rule-based versions hit their limits.

## License

Private project — no license granted.
