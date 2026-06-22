import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/atoms.dart';
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
  bool _autoDetecting = false;

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
    } else if (address == null || address.isEmpty) {
      _tryAutoDetect();
    }
  }

  Future<void> _tryAutoDetect() async {
    if (_autoDetecting || !mounted) return;
    setState(() => _autoDetecting = true);
    try {
      final city = await _detectCity();
      if (city == null || !mounted) return;
      final profileCtrl = context.read<ProfileController>();
      final prayerCtrl = context.read<PrayerController>();
      await profileCtrl.update((p) => p.copyWith(prayerAddress: city));
      await prayerCtrl.fetchByAddress(city);
    } catch (_) {
      // silent — falls back to manual entry
    } finally {
      if (mounted) setState(() => _autoDetecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prayer = context.watch<PrayerController>();
    final hijri = HijriCalendar.now();
    final hijriLabel = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    final hasTimes = prayer.times != null;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
            bottom: 32 + MediaQuery.of(context).padding.bottom),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.address?.isNotEmpty == true
                            ? '${prayer.address} · $hijriLabel'
                            : hijriLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                      const SizedBox(height: 2),
                      Text('Prayer',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.6,
                            color: c.text,
                          )),
                    ],
                  ),
                ),
                EliteIconButton(
                  icon: Icons.fingerprint,
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TasbihScreen())),
                ),
                const SizedBox(width: 8),
                EliteIconButton(
                  icon: Icons.explore_outlined,
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const QiblaScreen())),
                ),
                const SizedBox(width: 8),
                EliteIconButton(
                  icon: Icons.location_city_outlined,
                  onPressed: () => _showAddressSheet(context),
                ),
              ],
            ),
          ),

          if (prayer.loading || _autoDetecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (prayer.locationError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EliteCard(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: c.danger, size: 36),
                    const SizedBox(height: 12),
                    Text(prayer.locationError!,
                        style: TextStyle(color: c.muted),
                        textAlign: TextAlign.center),
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
              ),
            )
          else if (!hasTimes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EliteCard(
                child: Column(
                  children: [
                    Icon(Icons.location_on_outlined, color: c.muted, size: 36),
                    const SizedBox(height: 12),
                    Text('Set your city to load prayer times.',
                        style: TextStyle(color: c.muted),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Use my location'),
                        onPressed: _tryAutoDetect,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_location_outlined),
                        label: const Text('Enter city manually'),
                        onPressed: () => _showAddressSheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _upNextHero(context, prayer),
            ),
            EliteSection(
              title: "Today's prayers",
              child: EliteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < PrayerSlot.values.length; i++)
                      _prayerRow(context, prayer, PrayerSlot.values[i],
                          last: i == PrayerSlot.values.length - 1),
                  ],
                ),
              ),
            ),
            _duaSection(context),
            _consistencySection(context, prayer),
          ],
        ],
      ),
    );
  }

  Widget _upNextHero(BuildContext context, PrayerController prayer) {
    final c = context.colors;
    final now = DateTime.now();
    final next = prayer.nextSlot();
    PrayerSlot? prev;
    for (final s in PrayerSlot.values) {
      final t = prayer.timeOf(s);
      if (t != null && !t.isAfter(now)) prev = s;
    }
    final nextTime = next == null ? null : prayer.timeOf(next);
    final prevTime = prev == null ? null : prayer.timeOf(prev);

    double pct;
    String elapsedText;
    String remainingText;
    String nameText;
    String timeText;

    if (next != null && nextTime != null) {
      nameText = next.labelOn(now);
      timeText = DateX.prettyTime(nextTime);
      final remaining = nextTime.difference(now);
      remainingText = '${_hm(remaining)} to $nameText';
      if (prevTime != null) {
        final total = nextTime.difference(prevTime).inSeconds;
        final done = now.difference(prevTime).inSeconds;
        pct = total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
        elapsedText = 'Time elapsed since ${prev!.labelOn(now)}';
      } else {
        pct = 0.05;
        elapsedText = 'Before Fajr';
      }
    } else {
      // All of today's prayers are in the past.
      nameText = 'Fajr';
      timeText = 'tomorrow';
      pct = 1;
      elapsedText = 'Day complete';
      remainingText = '${prayer.completedToday()}/5 prayed today';
    }

    const heroDark = Color(0xFF0A0A0A);
    const heroText = Color(0xFFFAFAFA);
    const heroMuted = Color(0xFFA1A1AA);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: heroDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262626), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UP NEXT',
              style: TextStyle(
                fontSize: 11,
                color: heroMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
              )),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(nameText,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.9,
                    color: heroText,
                  )),
              const SizedBox(width: 10),
              Text(timeText,
                  style: monoStyle(fontSize: 18, color: heroMuted)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 2, color: Colors.white.withValues(alpha: 0.1)),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(height: 2, color: c.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsedText,
                  style: const TextStyle(fontSize: 11.5, color: heroMuted)),
              Text(remainingText,
                  style: monoStyle(fontSize: 11.5, color: heroText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prayerRow(BuildContext context, PrayerController ctrl, PrayerSlot slot,
      {required bool last}) {
    final c = context.colors;
    final now = DateTime.now();
    final t = ctrl.timeOf(slot);
    final done = ctrl.isCompleted(slot);
    final isNext = ctrl.nextSlot() == slot;
    final passed = t != null && t.isBefore(now);
    final overridden = ctrl.hasOverride(slot);

    final status = done
        ? 'Completed'
        : isNext
            ? 'Up next'
            : passed
                ? 'Missed'
                : 'Upcoming';

    final badgeBg = done
        ? c.success
        : isNext
            ? c.accent
            : c.surfaceAlt;
    final badgeFg = (done || isNext) ? Colors.white : c.muted;

    return Material(
      color: isNext ? c.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: () => ctrl.toggle(slot),
        onLongPress: () => _editSlotTime(context, ctrl, slot, t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: c.line, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: done
                    ? Icon(Icons.check, size: 16, color: badgeFg)
                    : Text(slot.label[0],
                        style: TextStyle(
                            color: badgeFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.labelOn(now),
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: c.text)),
                    const SizedBox(height: 1),
                    Text(status,
                        style: TextStyle(fontSize: 11.5, color: c.muted)),
                  ],
                ),
              ),
              if (overridden)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('edited',
                      style: TextStyle(
                          fontSize: 10,
                          color: c.accent,
                          fontWeight: FontWeight.w600)),
                ),
              Text(t == null ? '--:--' : DateX.prettyTime(t),
                  style: monoStyle(
                      fontSize: 14,
                      color: done ? c.success : c.text,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _consistencySection(BuildContext context, PrayerController prayer) {
    final c = context.colors;
    // Last 7 days completion total (out of 35).
    int weekDone = 0;
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      weekDone +=
          PrayerSlot.values.where((s) => prayer.isCompleted(s, d)).length;
    }
    // Longest run of perfect (5/5) days within the last 60 days.
    int longest = 0, run = 0;
    for (var i = 59; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final full =
          PrayerSlot.values.every((s) => prayer.isCompleted(s, d));
      if (full) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 0;
      }
    }
    final onTime = (weekDone / 35 * 100).round();

    return EliteSection(
      title: 'Consistency',
      child: Row(
        children: [
          Expanded(
            child: _statCard(context, 'THIS WEEK', '$weekDone / 35',
                '$onTime% complete', c.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(context, 'LONGEST STREAK', '$longest days',
                '5 prayers / day', c.muted),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      String sub, Color subColor) {
    final c = context.colors;
    return EliteCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: c.muted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.44,
              )),
          const SizedBox(height: 6),
          Text(value, style: monoStyle(fontSize: 26, color: c.text)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11.5, color: subColor)),
        ],
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
      helpText: 'Set ${slot.labelOn(DateTime.now())} time',
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
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.check_circle, color: context.colors.success),
                title: Text(
                    '${slot.labelOn(DateTime.now())} set to ${picked.format(context)}'),
                subtitle: Text('Tap "Reset" to revert to API time.',
                    style: TextStyle(color: context.colors.muted, fontSize: 12)),
              ),
              ListTile(
                leading: Icon(Icons.refresh, color: context.colors.muted),
                title: Text('Reset to automatic',
                    style: TextStyle(color: context.colors.text)),
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

  void _showAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressSheet(
        initial: context.read<PrayerController>().address ?? '',
        onSave: (address) async {
          if (address.trim().isEmpty) return;
          final profileCtrl = context.read<ProfileController>();
          final prayerCtrl = context.read<PrayerController>();
          await profileCtrl
              .update((p) => p.copyWith(prayerAddress: address.trim()));
          await prayerCtrl.fetchByAddress(address.trim());
        },
      ),
    );
  }

  Widget _duaSection(BuildContext context) {
    final c = context.colors;
    final dua = DuaService.instance.duaOfTheDay();
    if (dua == null) return const SizedBox.shrink();
    return EliteSection(
      title: 'Daily dua',
      action: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DuasScreen()),
        ),
        child: Text('All duas',
            style: TextStyle(
                fontSize: 12, color: c.accent, fontWeight: FontWeight.w500)),
      ),
      child: EliteCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DuasScreen()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dua.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                  letterSpacing: 0.66,
                )),
            const SizedBox(height: 12),
            Text(
              dua.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: c.text,
                fontSize: 22,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(dua.meaning,
                style: TextStyle(
                    color: c.muted, height: 1.5, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  static String _hm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
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
  bool _locating = false;

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

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final city = await _detectCity();
      if (city != null && mounted) _ctrl.text = city;
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
              Text('Prayer city',
                  style: TextStyle(
                    color: context.colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: context.colors.muted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter a city name or full address. Times are fetched from aladhan.com.',
            style: TextStyle(color: context.colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'e.g. Dhaka, Bangladesh',
              prefixIcon:
                  Icon(Icons.search, color: context.colors.muted, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(_locating ? 'Detecting...' : 'Use my location'),
              onPressed: (_saving || _locating) ? null : _locateMe,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: context.colors.background),
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

// ── Location helper (shared by screen + sheet) ────────────────────────────────

Future<String?> _detectCity() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  ).timeout(const Duration(seconds: 8));
  final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
  if (marks.isEmpty) return null;
  final p = marks.first;
  final city = p.locality?.isNotEmpty == true
      ? p.locality!
      : p.administrativeArea ?? '';
  final country = p.country ?? '';
  if (city.isEmpty && country.isEmpty) return null;
  return city.isNotEmpty ? '$city, $country' : country;
}
