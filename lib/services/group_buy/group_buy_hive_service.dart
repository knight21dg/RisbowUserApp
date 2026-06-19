import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/model/group_buy/group_buy_cache_model.dart';

class GroupBuyHiveService {
  static const String boxName = 'group_buy_cache';
  static const String boxKey = 'cached_rooms';
  static Box<GroupBuyCacheModel>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(GroupBuyCacheModelAdapter());
    }
    await Hive.initFlutter();
    _box = await Hive.openBox<GroupBuyCacheModel>(boxName);
  }

  static Box<GroupBuyCacheModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('GroupBuyHiveService not initialized. Call init() first.');
    }
    return _box!;
  }

  static int get _currentUserId {
    final raw = Global.userData?.userId;
    return int.tryParse(raw ?? '') ?? 1;
  }

  static String get _currentUserName {
    final name = Global.userData?.name;
    if (name == null || name.trim().isEmpty) return 'You';
    return name.trim();
  }

  static Future<void> cacheRoom(Map<String, dynamic> roomJson) async {
    try {
      final model = GroupBuyCacheModel.fromRoomJson(
        roomJson,
        _currentUserId,
        _currentUserName,
      );
      await box.put(model.cacheKey, model);
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to cache room: $e');
    }
  }

  static Future<void> cacheRooms(List<Map<String, dynamic>> roomsJson) async {
    for (final room in roomsJson) {
      await cacheRoom(room);
    }
  }

  static GroupBuyCacheModel? getCachedRoom(String code) {
    try {
      return box.get(code.toUpperCase());
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to get cached room: $e');
      return null;
    }
  }

  static List<GroupBuyCacheModel> getAllCachedRooms() {
    try {
      return box.values.toList();
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to get all cached rooms: $e');
      return [];
    }
  }

  static List<GroupBuyCacheModel> getMyCachedRooms() {
    try {
      final userId = _currentUserId;
      return box.values.where((room) => room.ownerId == userId || room.memberIds.contains(userId.toString())).toList();
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to get my cached rooms: $e');
      return [];
    }
  }

  static List<GroupBuyCacheModel> getPublicCachedRooms() {
    try {
      return box.values.where((room) => room.isPublic).toList();
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to get public cached rooms: $e');
      return [];
    }
  }

  static Future<void> removeCachedRoom(String code) async {
    try {
      await box.delete(code.toUpperCase());
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to remove cached room: $e');
    }
  }

  static Future<void> clearAllCache() async {
    try {
      await box.clear();
    } catch (e) {
      debugPrint('GroupBuyHiveService: Failed to clear cache: $e');
    }
  }

  static Future<void> clearAllAndReseed() async {
    await clearAllCache();
  }
}