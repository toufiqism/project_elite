---
name: android-prod-ready
description: >
  End-to-end checklist for taking a Flutter app from "runs on my device" to a
  signed AAB ready for Google Play Internal Testing. Covers signing, manifest
  hardening, icons, splash, Crashlytics, Play-required policies (privacy,
  account deletion, data safety), backup rules, and known cross-drive build
  bugs on Windows. Trigger when user asks to "make production ready",
  "prepare for Play Store", "ship to Android", "release build", or invokes
  /android-prod-ready.
---

Goal: ship a Flutter Android app to Play Store Internal Testing without rejections. Work through every branch below. Each branch is a separate decision — surface the trade-off, then act.

## Pre-flight (read once)

- This is an **interview-style** skill. Walk the user through decisions one at a time, with a recommended answer. Some branches have hard requirements (signing, privacy policy, account deletion if auth) — flag those as **Play blockers** so the user can't ship without them.
- Read CLAUDE.md first if it exists. Match its conventions (storage, state, naming).
- Use the Bash tool's `keytool` via the JDK that ships with Android Studio if `keytool` isn't on PATH. Common Windows path: `C:\Program Files\Java\jdk-17\bin\keytool.exe`.
- Cross-drive gotcha (Windows): if pub cache (`C:`) and project (`D:` etc.) are on different drives, Kotlin incremental compilation crashes with `RelocatableFileToPathConverter` `different roots` errors. Fix: add `kotlin.incremental=false` to `android/gradle.properties`. Document the why in a comment.

## The 13 branches

Order matters — earlier decisions feed later ones.

### 1. Signing keystore
**Play blocker.** Release defaults to debug keys; Play rejects.
- Generate fresh `android/upload-keystore.jks` via `keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
- 32-char random password via `python -c "import secrets,string; print(''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(32)))"`.
- Run non-interactively with `-storepass`, `-keypass`, `-dname "CN=..., OU=..., O=..., L=..., ST=..., C=PK"` so no stdin needed.
- Write `android/key.properties` (gitignored): `storePassword`, `keyPassword`, `keyAlias`, `storeFile=upload-keystore.jks`.
- Create `android/key.properties.example` (committed) as the template.
- Add to `.gitignore`: `android/key.properties`, `android/upload-keystore.jks`, `android/*.jks`, `android/*.keystore`.
- Wire `android/app/build.gradle.kts`: load props if file exists, define `signingConfigs.release`, set `buildTypes.release.signingConfig` with a debug-fallback so `flutter run --release` still works locally.
- **Critical:** `storeFile = rootProject.file(...)` — the default `file(...)` resolves relative to `android/app/`, not `android/`. Wrong path = signing failure at AAB time.
- **Tell user explicitly to back up both files.** Lost keystore = lost ability to publish updates.

### 2. App ID
Once on Play, `applicationId` is **immutable forever**. Confirm the reverse-DNS is intentional (typo, company rename, abbreviation preference) before locking.

### 3. Version
Set `version: 1.0.0+1` in `pubspec.yaml`. `1.0.0` = `versionName` (semver, user-facing). `+1` = `versionCode` (monotonic int, never reuse). Bump `+N` per Play upload, bump x.y.z on real user-facing releases.

### 4. SDK levels
- `targetSdk = 35` (Android 15) — Play policy 2025+ requires it for new apps.
- `minSdk = 23` is the pragmatic floor (drops <1% global, gains compat with `flutter_local_notifications`, `geolocator`, Firebase). Pin explicitly in `build.gradle.kts`.
- `compileSdk = 35`.

### 5. R8 / shrinking
Optional v1. Enabling adds risk (strips reflection-using code → crashes). If user wants smaller APK, enable `isMinifyEnabled=true` + `isShrinkResources=true` on release and add ProGuard keep rules for Hive, Firebase, geolocator, flutter_local_notifications. **Always test the release build on a real device before publishing.**

### 6. Permissions + manifest cleanup
- Audit `AndroidManifest.xml`. Justify every `uses-permission` in the Data Safety form. Drop ones with no code path.
- Default `android:usesCleartextTraffic="true"` is a Play flag + MITM risk. Set `"false"` unless WebView needs http content; add `network_security_config.xml` if you need per-domain whitelist.
- `FOREGROUND_SERVICE` declared without an actual service → drop.
- `USE_EXACT_ALARM` (Android 14+) only allowed for alarm/clock/calendar/prayer apps. Justify in Play Console permission declaration.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` is sensitive. Play wants core-functionality justification. Prayer alarms qualify.

### 7. API key strategy
Three options, pick one **with the user**:
- **A. Ship baked** (in gitignored `lib/core/config/api_keys.dart`): easy, will leak via APK decompile, rotate when abused.
- **B. Blank + user enters own** in Settings: privacy-good, UX-bad for casual users.
- **C. Cloud Function proxy**: server holds keys; only right answer long-term.
Record the choice and the risk in plain language so the user owns the trade-off.

### 8. Firebase project (if Firebase is in use)
Recommend separate `<app>-prod` Firebase project to isolate dev/test data from prod users. Costs $0 on Spark. If user declines, document it — noisy data will bite later. Either way, deploy Firestore rules restricting reads/writes to the owning UID.

### 9. App icon + adaptive + monochrome
- One source PNG `assets/icon/icon.png` (1024×1024 opaque). One foreground `assets/icon/icon_foreground.png` (1024×1024 transparent, ~33% padding for adaptive-icon safe zone). One monochrome `assets/icon/icon_monochrome.png` (white-on-transparent for Android 13 themed icons).
- Generate via Pillow if no art exists; metaphor should match the app's identity, not be random clip-art.
- Add `flutter_launcher_icons` to dev_deps with `adaptive_icon_background`, `adaptive_icon_foreground`, `adaptive_icon_monochrome`. Run `dart run flutter_launcher_icons`.

### 10. Splash
`flutter_native_splash` in dev_deps. Config: `color: "#<your bg>"`, `image: assets/icon/icon_foreground.png`, plus an `android_12:` block with the same. Run `dart run flutter_native_splash:create`. Skipping leaves the default white splash, which looks unbranded on launch.

### 11. Notification icon
Status-bar icons MUST be white-on-transparent silhouettes — colored mipmaps render as solid white squares.
- Generate per-density PNGs (24, 36, 48, 72, 96 px) under `android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_stat_notification.png`. Easiest: downscale the monochrome icon with Pillow.
- In NotificationService: change `AndroidInitializationSettings` to `@drawable/ic_stat_notification`. Add `icon: 'ic_stat_notification'` + a brand `color:` to every `AndroidNotificationDetails` so the silhouette tints correctly.

### 12. Crashlytics
Without it, prod crashes are invisible. Add `firebase_crashlytics` to deps. In `android/settings.gradle.kts` add `id("com.google.firebase.crashlytics") version("3.0.2") apply false` (this version needs google-services **4.4.1+** — bump that too if older). Apply both plugins in `android/app/build.gradle.kts`.

In `main()`:
- Wrap in `runZonedGuarded` so async errors that escape `FlutterError`/`PlatformDispatcher` still report.
- `await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode)` — debug builds report to console, not the prod dashboard.
- Hook `FlutterError.onError` → `recordFlutterFatalError` and `PlatformDispatcher.instance.onError` → `recordError(..., fatal: true)`.

### 13. Account deletion
**Play blocker** if the app has any sign-in. Required in-app path AND a web/email path for users without app access.
- `SyncService.deleteRemoteData(uid)` — batch-delete the user's Firestore doc tree.
- `AuthController.deleteAccount()` — call `User.delete()`, handle `requires-recent-login` with a "sign out + sign back in" message.
- Settings UI: red "Delete account" button → first confirm (lists what gets deleted) → second confirm requiring user to type `DELETE` → progress dialog → wipe Firestore first, then clear all user-scoped Hive boxes, then `delete('last_uid')` in settings box, then `auth.deleteAccount()`. Auth state listener routes back to AuthScreen automatically.
- Web/email path: mention `mailto:` in privacy policy + add explicit "Account deletion" section.

### 14. Backup rules
Default `allowBackup=true` cloud-backs-up everything including auth tokens. Risky.
- Set `android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:dataExtractionRules="@xml/data_extraction_rules"` on `<application>`.
- Create `android/app/src/main/res/xml/data_extraction_rules.xml` with `<cloud-backup>` and `<device-transfer>` blocks excluding `root`, `file`, `database`, `sharedpref`, `external`. User data already syncs via Firebase — Android Backup would resurrect deleted state.

### 15. Privacy policy
**Play blocker.** Markdown file under `docs/privacy_policy.md`. Cover: data collected (be honest — Firebase Auth email/UID, location for prayer, profile data, device IDs, crash logs), data NOT collected (no ads, no analytics, no contacts/SMS/camera), third parties (every API the code calls), retention + deletion, security, children (≥13), international transfer, contact email, last-updated date. Tell user to enable GitHub Pages (Settings → Pages → source main, `/docs`) to host it.

### 16. Play Store listing assets
Generate now so user has a complete handoff package:
- `feature_graphic_1024x500.png` — bg + wordmark + tagline + small icon. Pillow + Segoe UI works on Windows.
- `play_icon_512.png` — downscale of legacy icon to 512×512, RGB (no alpha).
- `listing_copy.md` — short description (<80 chars), full description (<4000 chars), what's-new, category, tags, content rating, contact, privacy URL placeholder. Include a screenshot-order suggestion.

User takes 2–8 portrait screenshots themselves — can't generate from agent. Suggest Pixel-sized AVD (1080×2400) for cleanest render.

### 17. Data Safety form draft
**Play blocker** at submit time. Wrong answers = rejection or post-publish suspension. Draft `docs/store_listing/data_safety.md` mapping each Play question to the actual code reality, per-data-type (Name, Email, UID, Photos, Location, App activity, Crash logs, Diagnostics, Device IDs). Note Firebase ≠ third party for Play's "shared" classification; AlAdhan/NewsAPI/RapidAPI etc. ARE third parties. End with a final pre-submit checklist.

### 18. Ship strategy
Recommend **Internal Testing track first**, never straight to Production. Upload AAB → Internal Testing → add testers via email → 7 days clean smoke on real devices (catches OEM battery kills, signing wrongness, Crashlytics-not-reporting) → promote same AAB to Production.

## Build verification

Final step — actually build the AAB end-to-end so the user knows it works:

```
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

If build fails, common causes:
- **Crashlytics v3 + google-services <4.4.1** → bump `google-services` to `4.4.2` in `settings.gradle.kts`.
- **Cross-drive Kotlin cache crash** → set `kotlin.incremental=false` in `android/gradle.properties`.
- **`Keystore file ... not found`** → `storeFile` resolved against `android/app/` not `android/`. Switch to `rootProject.file(...)`.

After success, verify signing fingerprint matches the keystore — Play Console will ask for SHA-1 and SHA-256:

```
keytool -list -v -keystore android/upload-keystore.jks
```

## Handoff summary

Always end with a punch list separating:
- **Done** (committed in working tree)
- **You still need to do** (cannot automate: keytool prompts in some environments, hosting privacy policy, Play Console clicks, taking screenshots, enrolling in Play App Signing, promoting tracks)

Make the cannot-automate list explicit and ordered. The user shouldn't have to ask "what next."

## Caveman compatibility

If caveman mode is active, the user interview stays terse but the technical substance above does not shrink — Play rejections don't care about your token budget. Still drop articles and filler in responses, but keep all decision points + tradeoffs intact.
