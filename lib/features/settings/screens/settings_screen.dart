import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/hive_setup.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../auth/state/auth_controller.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../habits/state/habit_controller.dart';
import '../../notifications/models/notification_settings.dart';
import '../../notifications/service/notification_service.dart';
import '../../notifications/state/notification_controller.dart';
import '../../prayer/state/prayer_controller.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/state/profile_controller.dart';
import '../../steps/state/step_controller.dart';
import '../../study/state/study_controller.dart';
import '../../sync/service/sync_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();
    final s = ctrl.settings;

    Future<void> apply(NotificationSettings next) async {
      await ctrl.update(
        next,
        prayerTimesByDay: prayer.timesForUpcomingDays(days: 7),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          const SectionHeader(title: 'Appearance'),
          _appearanceCard(context),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Fitness API'),
          _apiKeyCard(context, fitness),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Steps'),
          _stepsCard(context),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Notification tone'),
          _toneSelector(context, s.tone, (t) => apply(s.copyWith(tone: t))),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Which reminders'),
          EliteCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _toggle(
                  context,
                  icon: Icons.mosque,
                  title: 'Prayer times',
                  subtitle:
                      'Heads-up 10 min before + at the exact time, all 5 prayers',
                  value: s.prayerOn,
                  onChanged: (v) => apply(s.copyWith(prayerOn: v)),
                ),
                _divider(context),
                _toggle(
                  context,
                  icon: Icons.menu_book,
                  title: 'Study block',
                  subtitle:
                      'Daily reminder at ${_fmtTime(s.studyHour, s.studyMinute)}',
                  value: s.studyOn,
                  onChanged: (v) => apply(s.copyWith(studyOn: v)),
                ),
                _divider(context),
                _toggle(
                  context,
                  icon: Icons.water_drop,
                  title: 'Water',
                  subtitle:
                      'Between ${_fmtHour(s.waterStartHour)} and ${_fmtHour(s.waterEndHour)}',
                  value: s.waterOn,
                  onChanged: (v) => apply(s.copyWith(waterOn: v)),
                ),
                _divider(context),
                _toggle(
                  context,
                  icon: Icons.directions_walk,
                  title: 'Walk / steps',
                  subtitle:
                      'Nudge to move between ${_fmtHour(s.walkStartHour)} and ${_fmtHour(s.walkEndHour)}',
                  value: s.walkOn,
                  onChanged: (v) => apply(s.copyWith(walkOn: v)),
                ),
                _divider(context),
                _toggle(
                  context,
                  icon: Icons.local_fire_department,
                  title: "Don't break the streak",
                  subtitle:
                      'End-of-day check at ${_fmtTime(s.streakHour, s.streakMinute)}',
                  value: s.streakOn,
                  onChanged: (v) => apply(s.copyWith(streakOn: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Timing'),
          EliteCard(
            child: Column(
              children: [
                _timeRow(
                  context,
                  label: 'Study reminder time',
                  hour: s.studyHour,
                  minute: s.studyMinute,
                  onPicked: (h, m) =>
                      apply(s.copyWith(studyHour: h, studyMinute: m)),
                ),
                const SizedBox(height: 12),
                _hourRangeRow(
                  context,
                  label: 'Water reminder window',
                  startHour: s.waterStartHour,
                  endHour: s.waterEndHour,
                  onPicked: (start, end) => apply(s.copyWith(
                    waterStartHour: start,
                    waterEndHour: end,
                  )),
                ),
                const SizedBox(height: 12),
                _hourRangeRow(
                  context,
                  label: 'Walk reminder window',
                  startHour: s.walkStartHour,
                  endHour: s.walkEndHour,
                  onPicked: (start, end) => apply(s.copyWith(
                    walkStartHour: start,
                    walkEndHour: end,
                  )),
                ),
                const SizedBox(height: 12),
                _timeRow(
                  context,
                  label: 'Streak check time',
                  hour: s.streakHour,
                  minute: s.streakMinute,
                  onPicked: (h, m) =>
                      apply(s.copyWith(streakHour: h, streakMinute: m)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await ctrl.fireTest();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification fired.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Send a test notification'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ctrl.reschedule(
                  prayerTimesByDay: prayer.timesForUpcomingDays(days: 7),
                );
                final n = await ctrl.pendingCount();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Rescheduled — $n now queued.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Reschedule failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Reschedule all notifications'),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Reliability'),
          const _BatteryOptimizationCard(),
          const SizedBox(height: 12),
          const _PendingNotifCard(),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Cloud Sync'),
          const SizedBox(height: 8),
          const _SyncSection(),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: Icon(Icons.logout, color: context.colors.danger),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sign out',
                  style: TextStyle(color: context.colors.danger)),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.danger),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmDeleteAccount(context),
            icon: Icon(Icons.delete_forever, color: context.colors.danger),
            label: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Delete account',
                  style: TextStyle(color: context.colors.danger)),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.danger),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently erases your cloud backup, account, and all on-device data. '
            'This cannot be undone.',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final auth = context.read<AuthController>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    // First confirm
    final first = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Delete your account?'),
        content: Text(
          'This will permanently delete:\n'
          '  • Your cloud backup\n'
          '  • Your sign-in credentials\n'
          '  • All data on this device\n\n'
          'You will not be able to recover any of it.',
          style: TextStyle(color: context.colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    // Second confirm — type DELETE to proceed
    final typed = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: typed,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'DELETE'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, typed.text.trim() == 'DELETE'),
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    // Show progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? err;
    try {
      // 1) Wipe Firestore data first — if this fails the account is preserved
      //    so the user can retry without orphaned cloud data.
      await SyncService.deleteRemoteData(uid);

      // 2) Clear all user-scoped local Hive boxes.
      const userBoxes = [
        HiveBoxes.profile,
        HiveBoxes.study,
        HiveBoxes.habits,
        HiveBoxes.habitLogs,
        HiveBoxes.prayer,
        HiveBoxes.workoutSessions,
        HiveBoxes.weightLog,
        HiveBoxes.focusSessions,
        HiveBoxes.socialRatings,
        HiveBoxes.gameResults,
        HiveBoxes.tasbih,
        HiveBoxes.stepLog,
      ];
      for (final name in userBoxes) {
        await Hive.box(name).clear();
      }
      // Forget last_uid so the next sign-in is treated as a fresh login.
      await Hive.box(HiveBoxes.settings).delete('last_uid');

      // 3) Delete the Firebase Auth user. Triggers authStateChanges ->
      //    _Root flips back to AuthScreen automatically.
      err = await auth.deleteAccount();
    } catch (e) {
      err = 'Could not delete: $e';
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress

    if (err != null) {
      await showDialog(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: context.colors.surface,
          title: const Text('Account deletion incomplete'),
          content: Text(err!, style: TextStyle(color: context.colors.muted)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Sign out?'),
        content: Text(
          'You will need to sign in again to access your data.',
          style: TextStyle(color: context.colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthController>().signOut();
      // Pop every pushed route so _Root (now showing AuthScreen) is visible.
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _appearanceCard(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Theme',
              style: TextStyle(
                  color: context.colors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
            ],
            selected: {themeCtrl.mode},
            onSelectionChanged: (sel) => themeCtrl.setMode(sel.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  Widget _stepsCard(BuildContext context) {
    final steps = context.watch<StepController>();
    final profile = context.watch<ProfileController>().profile;
    final goal = profile?.stepGoalPerDay ?? 10000;
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk,
                  color: steps.available
                      ? context.colors.success
                      : context.colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily step goal',
                        style: TextStyle(
                            color: context.colors.text,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      steps.available
                          ? '$goal steps · counting active'
                          : '$goal steps · sensor off',
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showStepGoalDialog(context, profile),
                child: const Text('Change'),
              ),
            ],
          ),
          if (!steps.available) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final ok = await steps.requestAndStart();
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Permission denied or no step sensor available.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text('Enable step counting'),
            ),
          ],
        ],
      ),
    );
  }

  void _showStepGoalDialog(BuildContext context, UserProfile? profile) {
    if (profile == null) return;
    final ctrl =
        TextEditingController(text: profile.stepGoalPerDay.toString());
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Daily step goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'steps'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(ctrl.text);
              if (v == null || v <= 0) return;
              await context
                  .read<ProfileController>()
                  .update((p) => p.copyWith(stepGoalPerDay: v));
              if (dctx.mounted) Navigator.pop(dctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _apiKeyCard(BuildContext context, FitnessController fitness) {
    final masked = fitness.hasApiKey
        ? '${fitness.repository.apiKey.substring(0, 4)}…'
            '${fitness.repository.apiKey.substring(fitness.repository.apiKey.length - 4)}'
        : 'Not set';
    return EliteCard(
      child: Row(
        children: [
          Icon(
            fitness.hasApiKey ? Icons.check_circle : Icons.vpn_key,
            color: fitness.hasApiKey ? context.colors.success : context.colors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ExerciseDB (RapidAPI)',
                    style: TextStyle(
                      color: context.colors.text,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(masked,
                    style: TextStyle(
                        color: context.colors.muted, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showApiKeyDialog(context, fitness),
            child: Text(fitness.hasApiKey ? 'Change' : 'Set key'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, FitnessController fitness) {
    final ctrl = TextEditingController(text: fitness.repository.apiKey);
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('ExerciseDB API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign up at rapidapi.com/justin-WFnsXH_t6/api/exercisedb and paste your x-rapidapi-key below.',
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'x-rapidapi-key'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await fitness.setApiKey(ctrl.text);
              if (dctx.mounted) Navigator.pop(dctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _toneSelector(BuildContext context, NotificationTone current,
      ValueChanged<NotificationTone> onPick) {
    final items = [
      (
        NotificationTone.silent,
        'Silent',
        'Quiet pings, no sound, soft copy.',
        Icons.volume_off,
      ),
      (
        NotificationTone.motivational,
        'Motivational',
        'Default sound, encouraging copy.',
        Icons.bolt,
      ),
      (
        NotificationTone.discipline,
        'Discipline',
        'Sharp, urgent. No soft touch.',
        Icons.shield,
      ),
    ];
    return Column(
      children: items.map((t) {
        final tone = t.$1;
        final selected = tone == current;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: EliteCard(
            onTap: () => onPick(tone),
            color: selected ? context.colors.primary.withValues(alpha: 0.08) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  t.$4,
                  color: selected ? context.colors.primary : context.colors.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2,
                          style: TextStyle(
                            color: selected
                                ? context.colors.primary
                                : context.colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 2),
                      Text(t.$3,
                          style: TextStyle(
                              color: context.colors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Radio<NotificationTone>(
                  value: tone,
                  groupValue: current,
                  onChanged: (v) {
                    if (v != null) onPick(v);
                  },
                  activeColor: context.colors.primary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _toggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.colors.primary,
      title: Text(title,
          style: TextStyle(
            color: context.colors.text,
            fontWeight: FontWeight.w600,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(color: context.colors.muted, fontSize: 12)),
      secondary:
          Icon(icon, color: value ? context.colors.primary : context.colors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 0,
        color: context.colors.surfaceAlt,
        indent: 14,
        endIndent: 14,
      );

  Widget _timeRow(
    BuildContext context, {
    required String label,
    required int hour,
    required int minute,
    required void Function(int hour, int minute) onPicked,
  }) {
    return Row(
      children: [
        Expanded(
          child:
              Text(label, style: TextStyle(color: context.colors.muted)),
        ),
        TextButton(
          onPressed: () async {
            final res = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: hour, minute: minute),
            );
            if (res != null) onPicked(res.hour, res.minute);
          },
          child: Text(_fmtTime(hour, minute),
              style: TextStyle(
                color: context.colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
        ),
      ],
    );
  }

  Widget _hourRangeRow(
    BuildContext context, {
    required String label,
    required int startHour,
    required int endHour,
    required void Function(int start, int end) onPicked,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(color: context.colors.muted)),
        ),
        TextButton(
          onPressed: () async {
            final s = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: startHour, minute: 0),
              helpText: 'Start',
            );
            if (s == null) return;
            if (!context.mounted) return;
            final e = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: endHour, minute: 0),
              helpText: 'End',
            );
            if (e == null) return;
            onPicked(s.hour, e.hour);
          },
          child: Text('${_fmtHour(startHour)} – ${_fmtHour(endHour)}',
              style: TextStyle(
                color: context.colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
        ),
      ],
    );
  }

  String _fmtTime(int h, int m) {
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _fmtHour(int h) => '${h.toString().padLeft(2, '0')}:00';
}

// ── Cloud Sync section ────────────────────────────────────────────────────────

class _SyncSection extends StatefulWidget {
  const _SyncSection();

  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  DateTime? _cloudTs;
  bool _loadingTs = true;
  bool _uploading = false;
  bool _restoring = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _fetchTimestamp();
  }

  Future<void> _fetchTimestamp() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) {
      setState(() => _loadingTs = false);
      return;
    }
    try {
      final ts = await SyncService.cloudTimestamp(uid);
      if (mounted) {
        setState(() {
          _cloudTs = ts;
          _loadingTs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTs = false);
    }
  }

  Future<void> _upload() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;
    setState(() {
      _uploading = true;
      _error = null;
      _success = null;
    });
    try {
      await SyncService.upload(uid);
      final ts = await SyncService.cloudTimestamp(uid);
      if (mounted) {
        setState(() {
          _cloudTs = ts;
          _success = 'Backup uploaded successfully.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _restore() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Restore from cloud?'),
        content: Text(
          'This will overwrite all local data with your cloud backup. '
          'This cannot be undone.',
          style: TextStyle(color: context.colors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: context.colors.warning),
            child: Text('Restore',
                style: TextStyle(color: context.colors.background)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _restoring = true;
      _error = null;
      _success = null;
    });
    try {
      await SyncService.restore(uid);
      if (!mounted) return;
      context.read<ProfileController>().reload();
      context.read<StudyController>().reload();
      context.read<HabitController>().reload();
      context.read<FitnessController>().reload();
      setState(() => _success =
          'Data restored. Ayanokoji stats will refresh on next launch.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Restore failed: $e');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _uploading || _restoring;

    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined,
                  color: context.colors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cloud backup',
                        style: TextStyle(
                            color: context.colors.text,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    _loadingTs
                        ? Text('Checking…',
                            style: TextStyle(
                                color: context.colors.muted, fontSize: 12))
                        : Text(
                            _cloudTs == null
                                ? 'Never backed up'
                                : 'Last upload: ${DateFormat('d MMM y, HH:mm').format(_cloudTs!.toLocal())}',
                            style: TextStyle(
                                color: context.colors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: TextStyle(
                      color: context.colors.danger, fontSize: 12)),
            ),
          ],
          if (_success != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_success!,
                  style: TextStyle(
                      color: context.colors.success, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _upload,
                  icon: _uploading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.primary))
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Upload'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : _restore,
                  icon: _restoring
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: context.colors.text))
                      : const Icon(Icons.cloud_download_outlined,
                          size: 18),
                  label: const Text('Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Battery optimization section ──────────────────────────────────────────────

class _BatteryOptimizationCard extends StatefulWidget {
  const _BatteryOptimizationCard();

  @override
  State<_BatteryOptimizationCard> createState() =>
      _BatteryOptimizationCardState();
}

class _BatteryOptimizationCardState extends State<_BatteryOptimizationCard>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _exempt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when the user returns from the system settings screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final exempt =
        await NotificationService.instance.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _exempt = exempt;
        _loading = false;
      });
    }
  }

  Future<void> _request() async {
    await NotificationService.instance.requestIgnoreBatteryOptimizations();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return EliteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _exempt ? Icons.check_circle : Icons.battery_alert,
                color: _exempt ? context.colors.success : context.colors.warning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Background reliability',
                        style: TextStyle(
                            color: context.colors.text,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      _loading
                          ? 'Checking…'
                          : _exempt
                              ? 'Battery optimization is off for this app. Notifications will fire even when the app is closed.'
                              : 'Android may kill scheduled notifications when the app is closed. Whitelist this app to ensure reminders fire on time.',
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_loading && !_exempt) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _request,
              icon: const Icon(Icons.bolt, size: 18),
              label: const Text('Allow background activity'),
            ),
          ],
          const SizedBox(height: 16),
          const _OemAutostartGuidance(),
        ],
      ),
    );
  }
}

// ── Pending notification diagnostic ──────────────────────────────────────────

class _PendingNotifCard extends StatefulWidget {
  const _PendingNotifCard();

  @override
  State<_PendingNotifCard> createState() => _PendingNotifCardState();
}

class _PendingNotifCardState extends State<_PendingNotifCard> {
  int? _count;
  bool _loading = false;

  Future<void> _check() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await context.read<NotificationController>().pendingCount();
      if (mounted) setState(() => _count = n);
    } catch (e) {
      // Surface the error instead of leaving the spinner stuck forever.
      messenger.showSnackBar(
        SnackBar(content: Text('Could not read scheduled notifications: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EliteCard(
      child: Row(
        children: [
          Icon(
            _count == null
                ? Icons.help_outline
                : _count! > 0
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
            size: 20,
            color: _count == null
                ? context.colors.muted
                : _count! > 0
                    ? context.colors.success
                    : context.colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled notifications',
                    style: TextStyle(
                        color: context.colors.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  _count == null
                      ? 'Tap "Check" to see how many are queued'
                      : _count! > 0
                          ? '$_count notification${_count! == 1 ? '' : 's'} are queued by the OS'
                          : 'None queued — tap "Reschedule" above, then check again',
                  style: TextStyle(color: context.colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _loading ? null : _check,
            child: _loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: context.colors.primary))
                : const Text('Check'),
          ),
        ],
      ),
    );
  }
}

// Many Android OEMs (Xiaomi/MIUI, OPPO/Realme, Vivo, Huawei) bypass the
// standard battery-optimization API and silently kill scheduled alarms after
// the user swipe-kills the app — even when the app is whitelisted above.
// There's no API to grant the OEM-specific "Autostart" permission; the user
// has to flip it manually. This widget surfaces the per-brand path.
class _OemAutostartGuidance extends StatelessWidget {
  const _OemAutostartGuidance();

  static const _brands = <(String, String)>[
    ('Xiaomi / Redmi / POCO (MIUI/HyperOS)',
        'Settings → Apps → Manage apps → Project Elite → Autostart (ON). Also Battery saver → No restrictions.'),
    ('OPPO / Realme (ColorOS/RealmeUI)',
        'Two steps required:\n'
            '1. Phone Manager → Startup Management (or Privacy/Permissions → Startup) → Project Elite → ON\n'
            '2. Settings → Battery → App battery management → Project Elite → Allow background activity + Auto launch'),
    ('Vivo / iQOO (FuntouchOS/OriginOS)',
        'Two steps required:\n'
            '1. i Manager → App Management → Manage Auto-Start → Project Elite → ON\n'
            '2. Settings → Battery → Background power consumption manager → Project Elite → Allow'),
    ('Huawei / Honor (EMUI/MagicOS)',
        'Settings → Apps → Project Elite → Battery → App launch → switch to Manage manually → enable all three toggles.'),
    ('Samsung (One UI)',
        'Settings → Apps → Project Elite → Battery → Unrestricted.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
        title: Text(
          'Reminders still get killed?',
          style: TextStyle(
            color: context.colors.text,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Some Android phones need an extra Autostart permission',
          style: TextStyle(color: context.colors.muted, fontSize: 12),
        ),
        children: [
          for (final b in _brands)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.$1,
                      style: TextStyle(
                          color: context.colors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(b.$2,
                      style: TextStyle(
                          color: context.colors.muted, fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open app settings'),
          ),
        ],
      ),
    );
  }
}
