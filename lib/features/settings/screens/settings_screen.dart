import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../fitness/state/fitness_controller.dart';
import '../../notifications/models/notification_settings.dart';
import '../../notifications/service/notification_service.dart';
import '../../notifications/state/notification_controller.dart';
import '../../prayer/state/prayer_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationController>();
    final prayer = context.watch<PrayerController>();
    final fitness = context.watch<FitnessController>();
    final s = ctrl.settings;

    Future<void> apply(NotificationSettings next) async {
      await ctrl.update(next, prayerTimes: prayer.times);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Fitness API'),
          _apiKeyCard(context, fitness),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Notification tone'),
          _toneSelector(s.tone, (t) => apply(s.copyWith(tone: t))),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Which reminders'),
          EliteCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _toggle(
                  icon: Icons.mosque,
                  title: 'Prayer times',
                  subtitle:
                      'Heads-up 10 min before + at the exact time, all 5 prayers',
                  value: s.prayerOn,
                  onChanged: (v) => apply(s.copyWith(prayerOn: v)),
                ),
                _divider(),
                _toggle(
                  icon: Icons.menu_book,
                  title: 'Study block',
                  subtitle: 'Daily reminder at ${_fmtTime(s.studyHour, s.studyMinute)}',
                  value: s.studyOn,
                  onChanged: (v) => apply(s.copyWith(studyOn: v)),
                ),
                _divider(),
                _toggle(
                  icon: Icons.water_drop,
                  title: 'Water',
                  subtitle:
                      'Between ${_fmtHour(s.waterStartHour)} and ${_fmtHour(s.waterEndHour)}',
                  value: s.waterOn,
                  onChanged: (v) => apply(s.copyWith(waterOn: v)),
                ),
                _divider(),
                _toggle(
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
                  startHour: s.waterStartHour,
                  endHour: s.waterEndHour,
                  onPicked: (start, end) => apply(s.copyWith(
                    waterStartHour: start,
                    waterEndHour: end,
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
                  const SnackBar(
                    content: Text('Test notification fired.'),
                  ),
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
            onPressed: () => ctrl.reschedule(prayerTimes: prayer.times),
            icon: const Icon(Icons.refresh),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Reschedule all notifications'),
            ),
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
            color: fitness.hasApiKey ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ExerciseDB (RapidAPI)',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(masked,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
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
        backgroundColor: AppColors.surface,
        title: const Text('ExerciseDB API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign up at rapidapi.com/justin-WFnsXH_t6/api/exercisedb and paste your x-rapidapi-key below.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
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

  Widget _toneSelector(NotificationTone current, ValueChanged<NotificationTone> onPick) {
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
            color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  t.$4,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.$2,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 2),
                      Text(t.$3,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Radio<NotificationTone>(
                  value: tone,
                  groupValue: current,
                  onChanged: (v) {
                    if (v != null) onPick(v);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      title: Text(title,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          )),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      secondary: Icon(icon, color: value ? AppColors.primary : AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }

  Widget _divider() => const Divider(
        height: 0,
        color: AppColors.surfaceAlt,
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
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
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
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
        ),
      ],
    );
  }

  Widget _hourRangeRow(
    BuildContext context, {
    required int startHour,
    required int endHour,
    required void Function(int start, int end) onPicked,
  }) {
    return Row(
      children: [
        const Expanded(
          child: Text('Water reminder window',
              style: TextStyle(color: AppColors.muted)),
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
              style: const TextStyle(
                color: AppColors.text,
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
