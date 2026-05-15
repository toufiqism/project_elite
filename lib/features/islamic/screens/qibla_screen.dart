import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/elite_card.dart';
import '../../profile/state/profile_controller.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  // Kaaba coordinates.
  static const _meccaLat = 21.4225;
  static const _meccaLng = 39.8262;

  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  double? _qiblaBearing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _sub = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        setState(() => _heading = event.heading);
      },
      onError: (e) => setState(() => _error = e.toString()),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final profile = context.read<ProfileController>().profile;
    var lat = profile?.latitude;
    var lng = profile?.longitude;
    if (lat == null || lng == null) {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        setState(() => _error = 'Location unavailable: $e');
        return;
      }
    }
    setState(() => _qiblaBearing = _bearingTo(lat!, lng!, _meccaLat, _meccaLng));
  }

  /// Initial-bearing great-circle formula. Degrees clockwise from north.
  double _bearingTo(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final l1 = lat1 * math.pi / 180;
    final l2 = lat2 * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(l2);
    final x = math.cos(l1) * math.sin(l2) -
        math.sin(l1) * math.cos(l2) * math.cos(dLon);
    final bearingRad = math.atan2(y, x);
    return (bearingRad * 180 / math.pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (_error != null)
                EliteCard(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.muted)),
                      ),
                    ],
                  ),
                )
              else if (_heading == null)
                const EliteCard(
                  child: Text(
                    'Compass not available on this device.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              else if (_qiblaBearing == null)
                const EliteCard(
                  child: Text(
                    'Computing Qibla direction…',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              const Spacer(),
              if (_heading != null && _qiblaBearing != null)
                _compass(_heading!, _qiblaBearing!),
              const Spacer(),
              if (_qiblaBearing != null) ...[
                Text(
                  'Bearing to Mecca: ${_qiblaBearing!.toStringAsFixed(1)}°',
                  style:
                      const TextStyle(color: AppColors.text, fontSize: 16),
                ),
                const SizedBox(height: 4),
                if (_heading != null)
                  Text(
                    'Heading: ${_heading!.toStringAsFixed(1)}°',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Hold the phone flat. If the arrow wobbles, move it in a figure-8 to calibrate the magnetometer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compass(double heading, double qibla) {
    final aligned = ((qibla - heading) % 360).abs() < 5 ||
        ((qibla - heading) % 360).abs() > 355;
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceAlt, width: 2),
              color: AppColors.surface,
            ),
          ),
          // Cardinal markers — rotate with negative heading so N stays at top
          // relative to the world, not the device.
          Transform.rotate(
            angle: -heading * math.pi / 180,
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    top: 10,
                    child: Text('N',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  const Positioned(
                    bottom: 10,
                    child: Text('S',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                  const Positioned(
                    left: 10,
                    child: Text('W',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                  const Positioned(
                    right: 10,
                    child: Text('E',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                  // Qibla arrow
                  Transform.rotate(
                    angle: qibla * math.pi / 180,
                    child: Container(
                      width: 6,
                      height: 220,
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: aligned
                                ? AppColors.success
                                : AppColors.accent,
                            size: 32,
                          ),
                          Container(
                            width: 4,
                            height: 80,
                            color: aligned
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.text,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
