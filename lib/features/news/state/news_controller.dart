import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../data/news_service.dart';
import '../models/news_article.dart';

class NewsController extends ChangeNotifier {
  List<NewsArticle> _local = [];
  List<NewsArticle> _international = [];
  bool _loadingLocal = false;
  bool _loadingIntl = false;
  String? _localError;
  String? _intlError;
  String _countryCode = 'us';
  bool _initialized = false;

  List<NewsArticle> get local => _local;
  List<NewsArticle> get international => _international;
  bool get loadingLocal => _loadingLocal;
  bool get loadingIntl => _loadingIntl;
  String? get localError => _localError;
  String? get intlError => _intlError;
  String get countryCode => _countryCode;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _detectCountry();
    await Future.wait([_fetchLocal(), _fetchIntl()]);
  }

  Future<void> refreshLocal() => _fetchLocal();
  Future<void> refreshIntl() => _fetchIntl();

  Future<void> _detectCountry() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));

      final marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final code =
          marks.isNotEmpty ? marks.first.isoCountryCode?.toLowerCase() : null;
      if (code != null && code.isNotEmpty) { _countryCode = code; }
    } catch (_) {
      // keep default 'us'
    }
  }

  Future<void> _fetchLocal() async {
    _loadingLocal = true;
    _localError = null;
    notifyListeners();
    try {
      _local = await NewsService.fetchLocal(_countryCode);
    } catch (e) {
      _localError = e.toString();
    } finally {
      _loadingLocal = false;
      notifyListeners();
    }
  }

  Future<void> _fetchIntl() async {
    _loadingIntl = true;
    _intlError = null;
    notifyListeners();
    try {
      _international = await NewsService.fetchInternational();
    } catch (e) {
      _intlError = e.toString();
    } finally {
      _loadingIntl = false;
      notifyListeners();
    }
  }
}
