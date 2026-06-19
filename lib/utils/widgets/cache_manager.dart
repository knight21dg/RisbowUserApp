import 'package:flutter_cache_manager/flutter_cache_manager.dart';

final customCacheManager = CacheManager(
  Config(
    'hyperLocalImageCache',
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 500,
  ),
);

typedef SessionCacheManager = PermanentCacheManager;

class PermanentCacheManager extends CacheManager {
  static final PermanentCacheManager _instance = PermanentCacheManager._();

  factory PermanentCacheManager() => _instance;

  PermanentCacheManager._() : super(Config('permanent_cache'));

  static Future<void> clearCache() async {
    await _instance.emptyCache();
  }
}