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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  Future<void> _initLocation() async {
    final prayer = context.read<PrayerController>();
    if (prayer.times != null) return;
    final p = context.read<ProfileController>().profile;
    if (p?.latitude != null && p?.longitude != null) {
      prayer.setLocation(p!.latitude!, p.longitude!);
    } else {
      await prayer.fetchLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerController>();
    final times = prayer.times;

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
            tooltip: 'Refresh location',
            icon: const Icon(Icons.my_location),
            onPressed: () => prayer.fetchLocation(),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        children: [
          EliteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today',
                    style: TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 20),
          if (prayer.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (times == null)
            EliteCard(
              child: Column(
                children: [
                  const Icon(Icons.location_off,
                      color: AppColors.muted, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    prayer.locationError ??
                        'We need your location to compute prayer times.',
                    style: const TextStyle(color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use my location'),
                    onPressed: () => prayer.fetchLocation(),
                  ),
                ],
              ),
            )
          else ...[
            const SectionHeader(title: 'Today\'s prayer times'),
            ...PrayerSlot.values.map((slot) => _slotTile(prayer, slot)),
          ],
          const SizedBox(height: 24),
          _duaOfDayCard(context),
        ],
      ),
    );
  }

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

  Widget _slotTile(PrayerController ctrl, PrayerSlot slot) {
    final t = ctrl.timeOf(slot);
    final done = ctrl.isCompleted(slot);
    final isNext = ctrl.nextSlot() == slot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: EliteCard(
        onTap: () => ctrl.toggle(slot),
        color: isNext ? AppColors.primary.withValues(alpha: 0.08) : null,
        child: Row(
          children: [
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
            Text(t == null ? '--:--' : DateX.prettyTime(t),
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
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
}
