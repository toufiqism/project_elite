# CLAUDE_UPDATES

Running log of changes made by Claude across sessions. Newest entries at top.

---

## 2026-05-16

### Notifications: fire reliably when app is closed

User reported scheduled notifications not firing at all when the app is force-closed. Root causes for "alarm never fires" on modern Android are (1) `inexactAllowWhileIdle` schedule mode (Doze batches/drops these indefinitely) and (2) aggressive battery optimization on OEMs like Xiaomi/OPPO/Samsung/Huawei. Fixed both.

**Changes:**

- `lib/features/notifications/service/notification_service.dart`:
  - `scheduleAt` and `scheduleDaily` switched from `AndroidScheduleMode.inexactAllowWhileIdle` → `exactAllowWhileIdle`. This is the actual mechanism that survives Doze.
  - `requestPermissions()` now also calls `android.requestExactAlarmsPermission()` — without this, Android 12+ silently falls back to inexact even when we ask for exact.
  - New `isIgnoringBatteryOptimizations()` and `requestIgnoreBatteryOptimizations()` helpers using `permission_handler`'s `Permission.ignoreBatteryOptimizations`.
- `android/app/src/main/AndroidManifest.xml`: added `USE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `WAKE_LOCK`, `FOREGROUND_SERVICE` permissions.
- `lib/features/settings/screens/settings_screen.dart`: new **Reliability** section with `_BatteryOptimizationCard` — shows current status (battery optimization on/off), and exposes a "Allow background activity" `FilledButton` that opens the system whitelist dialog. Uses `WidgetsBindingObserver` to re-check on `AppLifecycleState.resumed` (after the user returns from system settings).

**iOS:** unchanged — `UNUserNotificationCenter` scheduled notifications already fire when the app is killed, no analogous battery-optimization concept.

**Files changed:**

- `lib/features/notifications/service/notification_service.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `android/app/src/main/AndroidManifest.xml`

`flutter analyze lib/features/notifications lib/features/settings`: 2 pre-existing `Radio` deprecation lints, no new issues.

---

### News: Local tab hidden behind a feature flag

Hid the "Local" section in the News tab. International articles now fill the screen with no TabBar. The Local code path is gated by `const _showLocal = false;` at the top of `news_screen.dart` so flipping it back to `true` restores the original two-tab UI.

**Behavior with `_showLocal == false`:**

- No `DefaultTabController`/`TabBarView` — just `Scaffold(body: intlView)`.
- AppBar's `bottom: TabBar` becomes `null`.
- Refresh button skips `news.refreshLocal()`.
- `NewsController` is unchanged; it still detects country and pre-fetches local on `init()` (intentional — keeps the flag a one-line flip). If we want to permanently drop Local, we should also strip the local fetch + geolocation from `NewsController.init()`.

**Files changed:**

- `lib/features/news/screens/news_screen.dart`.

`flutter analyze lib/features/news`: clean.

---

### Doc: ARCHITECTURE.md (full reference)

Added a top-level `ARCHITECTURE.md` covering the entire current codebase — stack, folder layout, `main.dart` startup sequence, the full `MultiProvider` tree (including all proxy providers), per-uid wipe/restore in `_RootState._handleLogin`, all 14 Hive boxes, the time-series key pattern, the controller `recompute()` pattern, and per-feature reference for auth, profile, dashboard, study, habits, prayer, fitness, gamification, ayanokoji, notifications, islamic, news, reports, and sync.

**Drift documented:** `CLAUDE.md` says the dashboard daily-score weights are 40/35/25 (study/habits/prayer), but the live code at `lib/features/dashboard/screens/dashboard_screen.dart:69` is 0.35 study + 0.25 habits + 0.20 prayer + 0.20 fitness — fitness was added as a fourth pillar later. `ARCHITECTURE.md` calls this out and recommends keeping `CLAUDE.md` in sync if the weights change again.

**Files changed:**

- `ARCHITECTURE.md` — new.

`flutter analyze`: 8 pre-existing info-level lints only — no new issues.

---

### Feature: Prayer city auto-detected from device location

Prayer times city is now set automatically from the device's GPS on the first Prayer tab visit (when no address is stored). Location permission is requested via `geolocator`; lat/lng is reverse-geocoded to `"City, Country"` via `geocoding` (e.g. "Dhaka, Bangladesh") and saved to `UserProfile.prayerAddress`, which triggers the AlAdhan fetch. Falls back silently to the manual-entry UI if permission is denied or location fails.

**UX additions:**

- **Auto-detect on first visit**: `_maybeAutoFetch` now calls `_tryAutoDetect()` when no address is stored; a spinner shows while detecting.
- **Empty-state card**: "Use my location" `OutlinedButton` + "Enter city manually" `FilledButton` side-by-side.
- **`_AddressSheet`**: "Use my location" `OutlinedButton` added between the TextField and "Load prayer times" button; shows an inline spinner and fills the TextField with the detected city so the user can confirm or edit before fetching.
- **`_detectCity()`**: top-level private function shared by both the screen state and the sheet; permission check → `Geolocator.getCurrentPosition` → `placemarkFromCoordinates` → formats `"$locality, $country"`.

**Files changed:**

- `lib/features/prayer/screens/prayer_screen.dart` — added `geocoding`/`geolocator` imports; `_autoDetecting` state; `_tryAutoDetect()`, `_locateMe()`, `_detectCity()`; updated empty-state card; updated `_AddressSheet`.

`flutter analyze`: 8 pre-existing info-level lints only — no errors or warnings.

---

### Feature: News tab (NewsAPI — local + international)

Added a 6th bottom-navigation tab — **News** — with two sections: Local (country auto-detected from device GPS) and International (BBC, Reuters, CNN, Al Jazeera). Articles open in an in-app WebView with share and "open in browser" actions.

**Architecture:**

- `NewsController.init()` is called lazily on first tab visit: requests location permission via `geolocator`, reverse-geocodes lat/lng to ISO country code via `geocoding`, then fires both feed fetches in parallel (`Future.wait`). Location falls back to `"us"` on any error.
- `NewsService.fetchLocal(countryCode)` calls `/v2/top-headlines?country=...`; `fetchInternational()` calls `/v2/top-headlines?sources=bbc-news,reuters,cnn,al-jazeera-english`. Both filter out removed/empty articles.
- `ArticleWebViewScreen` wraps `webview_flutter`'s `WebViewController` with a `LinearProgressIndicator` loading bar; shares via `share_plus`; opens externally via `url_launcher`.
- `android:usesCleartextTraffic="true"` added to `AndroidManifest.xml` so the WebView can load HTTP article URLs on Android API 28+.
- NewsAPI key added to the gitignored `lib/core/config/api_keys.dart` (same FIXME pattern as ExerciseDB key — scrub before any distribution action).

**Files changed:**

- `lib/features/news/models/news_article.dart` (NEW)
- `lib/features/news/data/news_service.dart` (NEW)
- `lib/features/news/state/news_controller.dart` (NEW)
- `lib/features/news/screens/news_screen.dart` (NEW)
- `lib/features/news/screens/article_webview_screen.dart` (NEW)
- `lib/core/config/api_keys.dart` — added `kNewsApiKey`
- `pubspec.yaml` — added `webview_flutter: ^4.8.0`, `geocoding: ^3.0.0`
- `lib/main.dart` — registered `NewsController` in `MultiProvider`
- `lib/main_shell.dart` — added `NewsScreen` as 6th page + `BottomNavigationBarItem`
- `android/app/src/main/AndroidManifest.xml` — `android:usesCleartextTraffic="true"`

`flutter analyze`: 8 pre-existing info-level lints only — no errors or warnings introduced.

---

### Feature: Prayer times via AlAdhan REST API + address-based lookup + manual slot editing

Replaced the `adhan` package (local lat/lng computation) with the AlAdhan REST API (`https://api.aladhan.com/v1/timingsByAddress`) for prayer times. Users now set a city/address instead of sharing GPS coordinates. Each slot can also be manually overridden and the edit is persisted per-day in Hive.

**Architecture changes:**

- `PrayerController` core type changed from `PrayerTimes` (adhan model) to `Map<PrayerSlot, DateTime>` throughout.
- `UserProfile` gains a nullable `prayerAddress` field (backwards-compatible `fromJson`). Saved to Hive profile box and synced to `PrayerController` via the existing `ChangeNotifierProxyProvider`.
- Daily API responses cached in Hive under key `"cache|YYYY-MM-DD"`. Per-slot user overrides stored as `"override|YYYY-MM-DD|slotname"` (HH:MM string). `_withOverrides()` merges them on every read.
- AlAdhan returns times like `"04:39 (UTC+6)"` — only the first space-token is used to strip timezone info.

**Files changed:**

- `lib/features/prayer/service/aladhan_service.dart` (NEW) — `AladhanService.fetchTimings(address, date)` HTTP client. Method 1 = University of Islamic Sciences, Karachi (same default as previous adhan package).
- `lib/features/prayer/state/prayer_controller.dart` (REWRITE) — removed adhan/geolocator; added `fetchByAddress`, `setAddress`, `setOverride`, `clearOverride`, `hasOverride`, `_loadCached`, `_reapplyOverrides`, `_withOverrides`, `_toStorable`, `_fromStorable`.
- `lib/features/profile/models/user_profile.dart` — added `prayerAddress` nullable field.
- `lib/features/prayer/screens/prayer_screen.dart` (REWRITE) — address card with "Change" button; per-slot edit `IconButton` with "edited" badge; `showTimePicker` → `setOverride` flow with confirmation sheet + "Reset to automatic" option; `_AddressSheet` bottom sheet that saves to `ProfileController` and calls `fetchByAddress`.
- `lib/features/notifications/state/notification_controller.dart` — removed `adhan` import; `PrayerTimes?` → `Map<PrayerSlot, DateTime>?`; `_samePrayerTimes` rewritten to compare slots by key.
- `lib/main.dart` — `ChangeNotifierProxyProvider` for `PrayerController` now calls `ctrl.setAddress(profile.profile?.prayerAddress)` instead of `setLocation(lat, lng)`.

`flutter analyze`: 8 pre-existing info-level lints only — no errors or warnings.

### Fix: Scroll clipping behind Android gesture navigation bar (13 screens)

All scrollable screens used `EdgeInsets.all(20)` as list padding. On Android with edge-to-edge gesture navigation, the last card clips under the nav bar. Fixed all 13 ListViews to use `EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom)`.

**Screens fixed:**

- `lib/features/study/screens/study_home_screen.dart`
- `lib/features/study/screens/study_history_screen.dart`
- `lib/features/fitness/screens/weight_screen.dart`
- `lib/features/fitness/screens/workout_history_screen.dart`
- `lib/features/ayanokoji/screens/character_stats_screen.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/prayer/screens/prayer_screen.dart`
- `lib/features/gamification/screens/achievements_screen.dart`
- `lib/features/reports/screens/reports_screen.dart`
- `lib/features/habits/screens/habits_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/features/fitness/screens/fitness_home_screen.dart`
- `lib/features/islamic/screens/duas_screen.dart`

`flutter analyze`: no new findings.

### Feature: YouTube search button on exercise cards

Added a YouTube search `IconButton` to each exercise card in the Fitness screens. Tapping opens a YouTube search for the exercise name in the YouTube app (or browser fallback). Uses `LaunchMode.externalApplication` so the YouTube app opens directly if installed.

**Implementation:**

- `pubspec.yaml` — added `url_launcher: ^6.3.0`.
- `lib/features/fitness/screens/fitness_home_screen.dart` — added `import 'package:url_launcher/url_launcher.dart'`; YouTube `IconButton` on each exercise card. URL pattern: `https://www.youtube.com/results?search_query=${Uri.encodeComponent(name)}`.
- `lib/features/fitness/screens/workout_session_screen.dart` — same import and button; exercise title + target wrapped in `Row(Expanded(Column(...)), IconButton(...))` to accommodate the icon alongside existing content.

`flutter analyze`: no new findings.

---

### Feature: User data isolation across accounts

Different Firebase users now see fully isolated data. Previously, local Hive data persisted across logins regardless of which user signed in.

**How it works:**

`_Root` in `lib/main.dart` was converted from a `StatelessWidget` to a `StatefulWidget`. On every auth state change it compares the incoming Firebase UID against the `last_uid` stored in the `settings` Hive box:

- **Same UID** (returning user, same session): data is left untouched, controllers are not reloaded — instant transition.
- **Different UID** (new user or user switch): all 11 user-data boxes are cleared (`profile`, `study`, `habits`, `habitLogs`, `prayer`, `workoutSessions`, `weightLog`, `focusSessions`, `socialRatings`, `gameResults`, `tasbih`). `SyncService.cloudTimestamp()` is then called — if a cloud backup exists it is silently restored before controllers reload; if not, the app presents a fresh empty state (onboarding).
- **Sign-out** (uid == null): spinner state and handled-UID are reset so the next sign-in is treated as a new session.

While the async check/restore is in progress a centered `CircularProgressIndicator` is shown so the UI never flashes stale data.

**Files changed:**

- `lib/main.dart` — imports `hive` + `sync_service`; `_Root` → `StatefulWidget` with `_handledUid` + `_sessionReady` state, `_onAuthChanged()` listener, `_handleLogin(uid)` async method
- `lib/features/habits/state/habit_controller.dart` — `reload()` now calls `_seedDefaults()` when the list is empty after reload (mirrors constructor behaviour; needed so a freshly-cleared habits box gets default habits seeded for new users)
- `lib/features/islamic/state/tasbih_controller.dart` — added `reload()` which resets the in-memory `currentCount` from the (now-cleared) box

`flutter analyze`: 9 pre-existing infos only — no errors.

### Fix: Sign out not working

Two bugs working together:

1. **Silent exception blocking Firebase sign-out** — `GoogleSignIn().signOut()` throws when the current session used email/password (no active Google session). Because it was `await`-ed without a try-catch, the exception propagated and `_auth.signOut()` was never reached.

2. **Navigator stack not cleared** — even after `_auth.signOut()` fires and `_Root` rebuilds to show `AuthScreen`, `SettingsScreen` was still sitting on top of the Navigator stack, so the user remained on the Settings screen and never saw the auth screen.

- `lib/features/auth/state/auth_controller.dart` — wrapped `GoogleSignIn().signOut()` in a `try/catch` that silently ignores errors (best-effort Google session clear). `_auth.signOut()` now always executes regardless of provider.
- `lib/features/settings/screens/settings_screen.dart` — added `Navigator.of(context).popUntil((route) => route.isFirst)` after `signOut()` completes. This pops SettingsScreen (and any other pushed routes) back to the root, where `_Root` now renders `AuthScreen`.

`flutter analyze`: 2 pre-existing Radio deprecation infos only — no errors.

### Fix: App hard-crashes on Google Sign-In (iOS)

**Root cause:** `CFBundleURLTypes` with the `REVERSED_CLIENT_ID` URL scheme was missing from `ios/Runner/Info.plist`. Google Sign-In on iOS completes the OAuth flow by redirecting back to the app via a custom URL scheme. Without it registered, the OS has no handler for the redirect and the app crashes instantly when the Google picker returns.

- `ios/Runner/Info.plist` — added `CFBundleURLTypes` array with `CFBundleURLSchemes` containing `com.googleusercontent.apps.345837181763-2jod7i44h2esabvuqrbcutj397ni0c5o` (sourced from `GoogleService-Info.plist` `REVERSED_CLIENT_ID`). Added at the top of the plist dict.

No Dart code changed. Requires a full rebuild (`flutter run`) — hot reload/restart does not pick up `Info.plist` changes.

### Fix: Upload button spins indefinitely

**Root cause:** `batch.commit()`, `_meta().get()`, and `Future.wait(boxSnaps)` in `SyncService` had no timeout. Firestore's `batch.commit()` waits for server acknowledgment — if the Firestore database hasn't been created in the Firebase console yet (or security rules block the write), the SDK retries silently forever rather than throwing, so the spinner never stopped and no error appeared.

- `lib/features/sync/service/sync_service.dart` — added `.timeout(const Duration(seconds: 15), onTimeout: ...)` to all three Firestore awaits (`cloudTimestamp`, `upload`, `restore`). The `onTimeout` callback throws a descriptive `Exception` that is caught by the calling `_upload()` / `_restore()` methods in the Settings screen and shown as an inline error banner.

**If the error "Upload timed out" appears after this fix:** Go to Firebase console → Firestore Database → Create database, then set security rules to allow authenticated users to read/write their own path (`users/{userId}/**`).

`flutter analyze lib/features/sync/`: no issues found.

### Fix: iOS notifications not firing (foreground display)

**Root cause:** `DarwinInitializationSettings` was missing `defaultPresentAlert / defaultPresentBadge / defaultPresentSound / defaultPresentBanner / defaultPresentList`. Without these, iOS silently drops notification banners whenever the app is in the foreground — which is the normal state when testing. The per-notification `DarwinNotificationDetails(presentAlert: true)` controls banner content but the init-level defaults gate whether iOS delivers it to the foreground app at all.

**Secondary note (simulator):** iOS Simulator is generally unreliable for `zonedSchedule` (scheduled) notifications on older Xcode versions. `showNow` (the test button) should always work. For reliable scheduled notification testing, use a physical device.

- `lib/features/notifications/service/notification_service.dart` — added `defaultPresentAlert: true`, `defaultPresentBadge: true`, `defaultPresentSound: true`, `defaultPresentBanner: true`, `defaultPresentList: true` to `DarwinInitializationSettings`.

`flutter analyze`: no issues found.

### Firestore offline persistence

Enabled Firestore offline persistence at app startup so the cloud sync feature works without a network connection and queues writes for later delivery.

- `lib/main.dart` — added `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` synchronously after `Firebase.initializeApp()` and before Hive init. Must be set before any Firestore calls. Unlimited cache size chosen by user — Firestore manages eviction automatically.
- `pubspec.yaml` already had `cloud_firestore ^5.6.0`; no new deps needed.

`flutter analyze lib/main.dart`: no issues found.

---

## 2026-05-15

### Firebase Cloud Sync (Firestore)

Added manual Upload / Restore sync via Firestore. User chose: all data boxes, manual trigger only (button in Settings), most-recent-timestamp-wins conflict strategy (shown to user via UI so they can make an informed choice of direction).

Implementation:

- `pubspec.yaml` — added `cloud_firestore: ^5.6.0`.
- `lib/features/sync/service/sync_service.dart` — new `SyncService` with three static methods: `cloudTimestamp(uid)` (reads `users/{uid}/sync/meta` for last upload time, single fast read), `upload(uid)` (serializes all 11 data boxes via Firestore batch write; each box is its own document under `users/{uid}/sync/{boxName}` to stay within the 1 MB per-document limit; `meta` doc holds `uploadedAt` server timestamp), `restore(uid)` (reads all box documents in parallel, clears each Hive box, rewrites data). Excluded boxes: `exerciseCache` (API cache), `notifications`, `settings` (device-specific prefs). Synced boxes: `profile`, `study`, `habits`, `habitLogs`, `prayer`, `workoutSessions`, `weightLog`, `focusSessions`, `socialRatings`, `gameResults`, `tasbih`.
- `lib/features/profile/state/profile_controller.dart` — added `reload()` (calls private `_load()` + `notifyListeners()`).
- `lib/features/study/state/study_controller.dart` — added `reload()`.
- `lib/features/habits/state/habit_controller.dart` — added `reload()`.
- `lib/features/fitness/state/fitness_controller.dart` — added `reload()` (calls `_loadHistory()` + `notifyListeners()`).
- `lib/features/settings/screens/settings_screen.dart` — added `_SyncSection` StatefulWidget (separate from the StatelessWidget `SettingsScreen`). Shows cloud backup timestamp ("Never backed up" or "Last upload: d MMM y, HH:mm"), Upload and Restore buttons. Upload/Restore show inline spinners while in progress, inline green success or red error banner on completion. Restore shows a confirmation dialog before overwriting. After restore, calls `reload()` on the four above controllers immediately; Ayanokoji/game stats note they refresh on next launch. Sync section placed between Notifications and Account.

Firestore security rules needed (user to configure in console):
```
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

`flutter analyze` (changed files): 0 errors, 0 warnings — 2 pre-existing Radio deprecation infos only.

### Password reset / forgot password

Added a forgot-password flow. User choices: link below the Sign in button, bottom sheet UI, inline confirmation on the same sheet.

- `lib/features/auth/screens/auth_screen.dart` — added `_ForgotPasswordSheet` (StatefulWidget), `_FormView`, and `_ConfirmationView` private widgets. Sheet manages its own loading/error/sent state independently of `AuthController` (no state bleed). Form validates email, calls `FirebaseAuth.instance.sendPasswordResetEmail()` directly. On success, transitions in-place to `_ConfirmationView` (envelope icon, "Check your inbox", the submitted email, "Back to sign in" button). Error banner shows mapped Firebase error codes. Sheet is keyboard-aware (`viewInsets.bottom` padding). "Forgot password?" link appears only on the sign-in form (not register), styled as underlined muted text below the Sign in button; taps `showModalBottomSheet`.
- Added `import 'package:firebase_auth/firebase_auth.dart'` to auth_screen.dart.

`flutter analyze lib/features/auth/`: no issues found.

### Google Sign-In

Added Google as a second authentication method. User choices: Google button above email/password with an "or" divider, works for both sign-in and registration, onboarding pre-filled from Google display name.

- `pubspec.yaml` — added `google_sign_in: ^6.2.1`.
- `lib/features/auth/state/auth_controller.dart` — added `signInWithGoogle()`: launches `GoogleSignIn().signIn()`, exchanges credential with `FirebaseAuth.signInWithCredential()`. Returns `false` silently if user cancels the picker. `signOut()` now also calls `GoogleSignIn().signOut()` to clear the Google session token.
- `lib/features/auth/screens/auth_screen.dart` — Google button placed at top of form via `_GoogleButton` widget (styled with `AppColors.surfaceAlt` background, custom `_GoogleGPainter` CustomPainter for the Google "G" logo). "or" divider row separates it from the email/password fields below. `_submitGoogle()` method wired to the button.
- `lib/features/profile/screens/onboarding_screen.dart` — added `initState()` override with `addPostFrameCallback` that reads `AuthController.user?.displayName` and pre-fills the `_name` TextEditingController if non-empty.

Manual steps required by user: add debug SHA-1 fingerprint to Firebase console (Android), add `REVERSED_CLIENT_ID` URL scheme to `ios/Runner/Info.plist` (iOS).

`flutter analyze` (auth + profile features): no issues found.

### Firebase Authentication

Added email/password authentication with contextual navigation. User choices asked and applied before implementation.

- `pubspec.yaml` — added `firebase_core: ^3.6.0`, `firebase_auth: ^5.3.0`.
- `lib/firebase_options.dart` — already generated by FlutterFire CLI; no changes needed.
- `lib/main.dart` — added `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before Hive init; added `AuthController` as the first provider in `MultiProvider`; updated `_Root` to three-state contextual navigation: not authenticated → `AuthScreen`, authenticated + no profile → `OnboardingScreen`, authenticated + has profile → `MainShell`.
- `lib/features/auth/state/auth_controller.dart` — new `ChangeNotifier` wrapping `FirebaseAuth`. Exposes `isAuthenticated`, `isLoading`, `error`, `user`. Methods: `signIn`, `signUp`, `signOut`, `clearError`. Listens to `authStateChanges()` stream so any external sign-out (token expiry, etc.) propagates immediately to `_Root`.
- `lib/features/auth/screens/auth_screen.dart` — single screen toggling between Login and Register modes. Styled with `AppColors` dark theme. Validates email format and password length. Shows inline error banner on failure, spinner during requests. Toggle link at bottom switches modes and clears errors.
- `lib/features/settings/screens/settings_screen.dart` — added "Account" section at bottom with a "Sign out" button (danger-red outline style) behind a confirmation dialog.

`flutter analyze` (all changed files): 9 info-level lints, all pre-existing — no errors or warnings introduced.

---

## 2026-05-15

### README rewrite

Replaced the one-line `README.md` placeholder with a full project README: product overview, MVP feature list, tech stack, setup/run commands, project structure tree, architecture notes (Hive-without-codegen, time-series key pattern, daily score weights), and a roadmap pointer for the deferred phase-2 systems. Mirrors the deliberate choices recorded in `CLAUDE.md` (local-only Hive, rule-based AI). `flutter analyze` clean (only pre-existing info-level lints).

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
