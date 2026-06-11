# Privacy Policy — Project Elite

**Last updated:** 2026-06-07
**App:** Project Elite (Android)
**Developer:** Toufiq Akbar
**Contact:** toufiqakbar@gmail.com

This policy describes what data Project Elite collects, why, where it goes, and the choices you have. Project Elite is a personal self-improvement app for tracking study, fitness, habits, and Islamic practice.

---

## 1. Data we collect

### 1.1 Stored locally on your device (default)
By design, the app is local-first. The following stay on your phone in an encrypted Hive database and are not transmitted unless you sign in (see §1.2):

- Profile (display name, age, gender, goals, title rank)
- Study sessions, subjects, focus timers
- Habit definitions and daily completion logs
- Fitness data: workouts, exercises, weight log
- Prayer logs and Qibla settings
- Tasbih counts, Ayanokoji discipline stats
- App settings and preferences

### 1.2 Stored in the cloud (only if you sign in)
If you sign in with Google, the data in §1.1 is synced to your private Firestore document, keyed by your Firebase user ID. Only you can read or write your own document. We do not access, sell, or share this data.

We also store from sign-in:
- Firebase user ID (UID)
- Email address
- Display name and Google profile photo URL

### 1.3 Device permissions
- **Location** (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`) — used only to compute prayer times and Qibla direction. Coordinates are stored locally; they are sent only to the AlAdhan prayer-times API (see §2). Never sold or shared.
- **Notifications** (`POST_NOTIFICATIONS`) — local prayer-time and habit reminders. No push notifications from our servers.
- **Exact alarms** (`SCHEDULE_EXACT_ALARM`) — required to fire prayer adhan at the precise calculated time. Runtime-granted.
- **Boot completed** (`RECEIVE_BOOT_COMPLETED`) — re-schedule prayer alarms after device restart.
- **Ignore battery optimizations** (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) — optional, lets you exclude the app so prayer alarms aren't suppressed by OEM battery savers.

---

## 2. Third-party services

The app calls these services. Each has its own privacy policy.

| Service | What is sent | Why |
| --- | --- | --- |
| Firebase Auth (Google) | Email, Google credential | Sign-in only |
| Cloud Firestore (Google) | Profile + app data from §1.1 | Cloud backup so you can restore on a new device |
| AlAdhan API (`api.aladhan.com`) | Latitude, longitude, date | Prayer-time calculation |
| ExerciseDB via RapidAPI | Exercise lookup keywords | Fitness exercise database |
| YouTube (via system browser) | Search query | "How to perform exercise" video lookup |

- Firebase / Firestore: https://firebase.google.com/support/privacy
- AlAdhan: https://aladhan.com/privacy
- RapidAPI: https://rapidapi.com/privacy
- YouTube: https://policies.google.com/privacy

---

## 3. Data we do NOT collect

- We do not collect analytics, crash reports, or telemetry.
- We do not use advertising IDs or run ads.
- We do not access contacts, SMS, call logs, microphone, camera, or media files.
- We do not track you across other apps or websites.

---

## 4. Sharing and disclosure

We do not sell, rent, or share personal data with third parties for marketing. The only disclosures are the API calls listed in §2, made automatically when you use the corresponding feature.

We may disclose data if required by law (subpoena, court order) or to protect against fraud or abuse.

---

## 5. Retention and deletion

- **Local data:** Stored until you uninstall the app or use the in-app "Reset data" option (Settings).
- **Cloud data:** Stored as long as your account exists.
- **Account deletion:** Settings → Account → Delete account. This permanently erases your Firestore document, Firebase Auth record, and local data. Action cannot be undone.
- You may also request deletion by emailing toufiqakbar@gmail.com. We will respond within 30 days.

---

## 6. Security

- Cloud data is protected by Firestore security rules restricting reads/writes to the owning UID.
- Network traffic uses HTTPS / TLS.
- We do not store passwords; authentication is delegated to Google sign-in.

No system is perfectly secure. Use a strong Google account password and enable 2-Step Verification.

---

## 7. Children

Project Elite is not directed to children under 13. We do not knowingly collect data from children under 13. If you believe we have, contact us and we will delete it.

---

## 8. International users

Data is processed by Google services and may be transferred to servers outside your country (including the United States). By using the app you consent to this transfer.

---

## 9. Changes to this policy

We may update this policy. The "Last updated" date at the top will change. Material changes will be announced in-app on next launch.

---

## 10. Contact

Questions, deletion requests, or data inquiries:
**toufiqakbar@gmail.com**
