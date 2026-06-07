# Play Console — Data Safety form answers

Fill these into Play Console -> App content -> Data safety. Answers reflect the code shipped in v1.0.0.

---

## Section 1 — Data collection and security

**Does your app collect or share any of the required user data types?**
→ **Yes**

**Is all user data encrypted in transit?**
→ **Yes** (all network calls use HTTPS; cleartext disabled in manifest)

**Do you provide a way for users to request that their data be deleted?**
→ **Yes** (Settings → Delete account, plus email request to toufiqakbar@gmail.com)

**Has your app been independently validated against a global security standard?**
→ **No**

**Have you committed to follow the Play Families Policy?**
→ **No** (not directed at children)

---

## Section 2 — Data types collected

For each data type below, select **Collected** with the listed answers. Anything not listed = NOT collected.

### Personal info → Name
- Collected: **Yes**
- Shared with third parties: **No** (stored in your Firebase only)
- Processed ephemerally: **No**
- Required or optional: **Optional** (only collected if user creates a profile)
- Purposes: **App functionality**, **Account management**

### Personal info → Email address
- Collected: **Yes**
- Shared: **No**
- Required or optional: **Required** (for Google sign-in)
- Purposes: **App functionality**, **Account management**

### Personal info → User IDs
- Collected: **Yes** (Firebase UID)
- Shared: **No**
- Required or optional: **Required**
- Purposes: **App functionality**, **Account management**

### Photos and videos → Photos
- Collected: **Yes** (Google profile photo URL, only if user signs in with Google)
- Shared: **No**
- Required or optional: **Optional**
- Purposes: **App functionality**

### Location → Approximate location
- Collected: **Yes**
- Shared: **Yes** — with AlAdhan API for prayer-time calculation
- Required or optional: **Optional** (prayer features degrade without it)
- Purposes: **App functionality** (prayer times + Qibla direction)

### Location → Precise location
- Collected: **Yes** (only if the user grants fine-location permission)
- Shared: **Yes** — with AlAdhan API
- Required or optional: **Optional**
- Purposes: **App functionality**

### App activity → App interactions
- Collected: **Yes** (study sessions, habit completions, prayer logs, workouts — stored locally and optionally synced to user's own Firestore document)
- Shared: **No**
- Required or optional: **Required**
- Purposes: **App functionality**

### App activity → Other user-generated content
- Collected: **Yes** (profile goals, habit definitions, notes)
- Shared: **No**
- Required or optional: **Optional**
- Purposes: **App functionality**

### App info and performance → Crash logs
- Collected: **Yes** (Firebase Crashlytics, release builds only)
- Shared: **No**
- Required or optional: **Required**
- Purposes: **Analytics**, **App functionality**

### App info and performance → Diagnostics
- Collected: **Yes** (Crashlytics performance / non-fatal records)
- Shared: **No**
- Required or optional: **Required**
- Purposes: **Analytics**

### Device or other IDs → Device or other IDs
- Collected: **Yes** (Firebase Installations ID, used internally by Firebase Auth / Crashlytics)
- Shared: **No**
- Required or optional: **Required**
- Purposes: **App functionality**, **Analytics**

---

## Section 3 — Data types NOT collected

Explicitly answer "No" for these categories (Play will ask):
- Financial info
- Health and fitness data sent off-device (your fitness data stays local + user's own Firestore — fine to mark NOT collected for the purposes of "shared" categories, but you may flag *Health info* if Play flags weight log)
- Messages (SMS, email content)
- Audio files / voice / music
- Files and docs
- Calendar
- Contacts
- Web browsing
- Search history (search queries are sent to NewsAPI / ExerciseDB but not retained by your app — answer per Play definitions: NOT collected)
- Installed apps
- In-app actions outside of those listed above
- Other info

⚠️ **Health & fitness gotcha:** If Play flags the weight log as "Health info," mark it Collected (App functionality, not shared, optional, required = optional).

---

## Section 4 — Sharing summary (for your reference)

| Data | Where it goes | Why |
| --- | --- | --- |
| Email, name, photo URL, UID | Firebase Auth + Firestore (your own project) | Sign-in + cloud backup |
| Location (lat/lng) | AlAdhan API (https://api.aladhan.com) | Prayer times + Qibla |
| Exercise search terms | RapidAPI ExerciseDB | Exercise lookup |
| News search terms | NewsAPI | Islamic news feed |
| YouTube search query | YouTube (system browser) | "How to perform" exercise videos |
| Crash stack traces | Firebase Crashlytics | Crash diagnostics (release only) |

Firebase = data processor under Google. Play does not count first-party Firebase as "shared with third parties." AlAdhan / NewsAPI / RapidAPI DO count as shared.

---

## Section 5 — Permissions declaration (Play Console)

Play will ask you to justify each declared permission. Use these blurbs:

- **ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION** → "Used to compute accurate prayer times and Qibla direction. Coordinates are sent only to the AlAdhan prayer-times API."
- **POST_NOTIFICATIONS** → "Local prayer-time, habit, and study reminders. No push notifications from a server."
- **SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM** → "Required to fire the prayer adhan at the precise calculated minute. App is functionally a prayer/alarm app per Play's exempt categories."
- **RECEIVE_BOOT_COMPLETED** → "Reschedule prayer alarms after the device restarts."
- **REQUEST_IGNORE_BATTERY_OPTIMIZATIONS** → "Optional. Allows user to opt the app out of OEM battery savers that otherwise suppress prayer-time alarms."

---

## Final checklist before submit

- [ ] Privacy policy URL is live (GitHub Pages or similar)
- [ ] Account deletion path documented (Settings → Delete account + email)
- [ ] Data safety form filled per above
- [ ] AAB signed with upload keystore (not debug)
- [ ] targetSdk = 35
- [ ] Crashlytics receives a test crash in release build
- [ ] Screenshots taken (2-8, 9:16)
- [ ] Short + full descriptions pasted
