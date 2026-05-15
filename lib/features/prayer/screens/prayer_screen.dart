import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../islamic/data/dua_service.dart';
import '../../islamic/screens/duas_screen.dart';
import '../../islamic/screens/qibla_screen.dart';
import '../../islamic/screens/tasbih_screen.dart';
import '../../profile/state/profile_controller.dart';
import '../state/prayer_controller.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoFetch());
  }

  void _maybeAutoFetch() {
    final prayer = context.read<PrayerController>();
    final address = prayer.address;
    if (address != null && address.isNotEmpty && prayer.times == null) {
      prayer.fetchByAddress(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerController>();

    final hijri = HijriCalendar.now();
    final hijriLabel =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prayer',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                )),
            Text(hijriLabel,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tasbih',
            icon: const Icon(Icons.fingerprint),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasbihScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Qibla',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QiblaScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Edit city',
            icon: const Icon(Icons.location_city_outlined),
            onPressed: () => _showAddressSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── Progress card ────────────────────────────────────────────────
          EliteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  '${prayer.completedToday()} / 5 prayers',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: prayer.completedToday() / 5,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceAlt,
                    color: prayer.completedToday() == 5
                        ? AppColors.success
                        : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── City / address card ──────────────────────────────────────────
          _addressCard(context, prayer),
          const SizedBox(height: 16),

          // ── Prayer times ─────────────────────────────────────────────────
          if (prayer.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (prayer.locationError != null)
            EliteCard(
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.danger, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    prayer.locationError!,
                    style: const TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      final addr = prayer.address;
                      if (addr != null) prayer.fetchByAddress(addr);
                    },
                  ),
                ],
              ),
            )
          else if (prayer.times == null)
            EliteCard(
              child: Column(
                children: [
                  const Icon(Icons.location_city_outlined,
                      color: AppColors.muted, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter your city to load prayer times.',
                    style: TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.edit_location_outlined),
                    label: const Text('Set city'),
                    onPressed: () => _showAddressSheet(context),
                  ),
                ],
              ),
            )
          else ...[
            const SectionHeader(title: 'Today\'s prayer times'),
            ...PrayerSlot.values
                .map((slot) => _slotTile(context, prayer, slot)),
          ],

          const SizedBox(height: 24),
          _duaOfDayCard(context),
        ],
      ),
    );
  }

  // ── Address card ──────────────────────────────────────────────────────────

  Widget _addressCard(BuildContext context, PrayerController prayer) {
    return EliteCard(
      child: Row(
        children: [
          const Icon(Icons.location_city, color: AppColors.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prayer.address?.isNotEmpty == true
                  ? prayer.address!
                  : 'No city set',
              style: TextStyle(
                color: prayer.address?.isNotEmpty == true
                    ? AppColors.text
                    : AppColors.muted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showAddressSheet(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // ── Slot tile with edit button ────────────────────────────────────────────

  Widget _slotTile(
    BuildContext context,
    PrayerController ctrl,
    PrayerSlot slot,
  ) {
    final t = ctrl.timeOf(slot);
    final done = ctrl.isCompleted(slot);
    final isNext = ctrl.nextSlot() == slot;
    final overridden = ctrl.hasOverride(slot);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        onTap: () => ctrl.toggle(slot),
        color: isNext ? AppColors.primary.withValues(alpha: 0.08) : null,
        child: Row(
          children: [
            // Check circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.mosque,
                color: done ? AppColors.success : AppColors.muted,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Name + next label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  if (isNext)
                    const Text('Next',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            // Time + optional "edited" badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(t == null ? '--:--' : DateX.prettyTime(t),
                    style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600)),
                if (overridden)
                  const Text('edited',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            // Edit time button
            IconButton(
              tooltip: overridden ? 'Reset time' : 'Edit time',
              icon: Icon(
                overridden ? Icons.edit : Icons.edit_outlined,
                size: 18,
                color: overridden ? AppColors.accent : AppColors.muted,
              ),
              onPressed: () => _editSlotTime(context, ctrl, slot, t),
            ),
            Checkbox(
              value: done,
              onChanged: (_) => ctrl.toggle(slot),
              activeColor: AppColors.success,
              shape: const CircleBorder(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSlotTime(
    BuildContext context,
    PrayerController ctrl,
    PrayerSlot slot,
    DateTime? current,
  ) async {
    final initial = current != null
        ? TimeOfDay(hour: current.hour, minute: current.minute)
        : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Set ${slot.label} time',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;

    final now = DateTime.now();
    final dt =
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    await ctrl.setOverride(slot, dt);

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: AppColors.success),
                title: Text('${slot.label} set to ${picked.format(context)}'),
                subtitle: const Text('Tap "Reset" to revert to API time.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.refresh, color: AppColors.muted),
                title: const Text('Reset to automatic',
                    style: TextStyle(color: AppColors.text)),
                onTap: () {
                  ctrl.clearOverride(slot);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }

  // ── Address bottom sheet ──────────────────────────────────────────────────

  void _showAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressSheet(
        initial: context.read<PrayerController>().address ?? '',
        onSave: (address) async {
          if (address.trim().isEmpty) return;
          final profileCtrl = context.read<ProfileController>();
          final prayerCtrl = context.read<PrayerController>();
          // Save to profile for persistence across sessions
          await profileCtrl.update(
            (p) => p.copyWith(prayerAddress: address.trim()),
          );
          // Fetch immediately
          await prayerCtrl.fetchByAddress(address.trim());
        },
      ),
    );
  }

  // ── Dua of the day ────────────────────────────────────────────────────────

  Widget _duaOfDayCard(BuildContext context) {
    final dua = DuaService.instance.duaOfTheDay();
    if (dua == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Dua of the day',
          action: 'All duas',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DuasScreen()),
          ),
        ),
        EliteCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DuasScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dua.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              const SizedBox(height: 12),
              Text(
                dua.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 20,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dua.transliteration,
                style: const TextStyle(
                  color: AppColors.text,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(dua.meaning,
                  style: const TextStyle(
                      color: AppColors.muted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Address input bottom sheet ────────────────────────────────────────────────

class _AddressSheet extends StatefulWidget {
  final String initial;
  final Future<void> Function(String) onSave;

  const _AddressSheet({required this.initial, required this.onSave});

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(v);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Prayer city',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.muted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter a city name or full address. Times are fetched from aladhan.com.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'e.g. Dhaka, Bangladesh',
              prefixIcon:
                  Icon(Icons.search, color: AppColors.muted, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background),
                      )
                    : const Text('Load prayer times',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
