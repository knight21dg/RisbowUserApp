import 'package:flutter/foundation.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

class FeatureSettingsService {
  static FeatureSettingsService? _instance;
  static FeatureSettingsService get instance => _instance ??= FeatureSettingsService._();
  FeatureSettingsService._();

  final ApiBaseHelper _api = ApiBaseHelper();

  Map<String, dynamic> _cachedFeatures = {};
  DateTime? _lastFetchTime;
  static const int _cacheValidMinutes = 5;

  bool get roomsEnabled => _cachedFeatures['roomsEnabled'] ?? true;
  bool get flashSalesEnabled => _cachedFeatures['flashSalesEnabled'] ?? true;
  bool get couponsEnabled => _cachedFeatures['couponsEnabled'] ?? true;
  bool get wishlistEnabled => _cachedFeatures['wishlistEnabled'] ?? true;
  bool get compareEnabled => _cachedFeatures['compareEnabled'] ?? true;
  bool get storiesEnabled => _cachedFeatures['storiesEnabled'] ?? true;
  bool get liveChatEnabled => _cachedFeatures['liveChatEnabled'] ?? false;
  bool get refundEnabled => _cachedFeatures['refundEnabled'] ?? true;
  bool get returnEnabled => _cachedFeatures['returnEnabled'] ?? true;
  int get maxReturnDays => (_cachedFeatures['maxReturnDays'] ?? 7).toInt();

  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes < _cacheValidMinutes;
  }

  Future<void> fetchFeatureSettings() async {
    try {
      final response = await _api.getAPICall(
        ApiRoutes.featureSettingsApi,
        {},
      );

      if (response != null && response.data != null && response.data['success'] == true) {
        Map<String, dynamic> featureData;
        
        final data = response.data['data'];
        if (data is Map && data.containsKey('value')) {
          featureData = Map<String, dynamic>.from(data['value'] ?? {});
        } else {
          featureData = Map<String, dynamic>.from(data);
        }
        
        _cachedFeatures = featureData;
        _lastFetchTime = DateTime.now();
        debugPrint('Feature settings loaded: $_cachedFeatures');
      }
    } catch (e) {
      // Gracefully handle errors - use default values
      debugPrint('Feature settings fetch failed, using defaults: $e');
      _setDefaults();
    }
  }

  void _setDefaults() {
    _cachedFeatures = {
      'roomsEnabled': true,
      'flashSalesEnabled': true,
      'couponsEnabled': true,
      'wishlistEnabled': true,
      'compareEnabled': true,
      'storiesEnabled': true,
      'liveChatEnabled': false,
      'refundEnabled': true,
      'returnEnabled': true,
      'maxReturnDays': 7,
    };
    _lastFetchTime = DateTime.now();
  }

  Future<void> refresh() async {
    _lastFetchTime = null;
    await fetchFeatureSettings();
  }

  bool isFeatureEnabled(String featureName) {
    return _cachedFeatures[featureName] ?? true;
  }
}