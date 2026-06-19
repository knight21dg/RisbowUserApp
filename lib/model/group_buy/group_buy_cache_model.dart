import 'package:hive_flutter/hive_flutter.dart';

part 'group_buy_cache_model.g.dart';

@HiveType(typeId: 20)
class GroupBuyCacheModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final bool isPublic;

  @HiveField(4)
  final int maxMembers;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String? expiresAt;

  @HiveField(7)
  final String createdAt;

  @HiveField(8)
  final int ownerId;

  @HiveField(9)
  final String ownerName;

  @HiveField(10)
  final List<String> memberIds;

  @HiveField(11)
  final List<String> memberNames;

  @HiveField(12)
  final List<String> cartItemNames;

  @HiveField(13)
  final List<int> cartItemQuantities;

  @HiveField(14)
  final List<double> cartItemPrices;

  @HiveField(15)
  final List<String> activityMessages;

  @HiveField(16)
  final List<String> activityTimestamps;

  @HiveField(17)
  final List<String> activityIcons;

  @HiveField(18)
  final int userId;

  @HiveField(19)
  final String userName;

  @HiveField(20)
  DateTime cachedAt;

  GroupBuyCacheModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isPublic,
    required this.maxMembers,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    required this.ownerId,
    required this.ownerName,
    required this.memberIds,
    required this.memberNames,
    required this.cartItemNames,
    required this.cartItemQuantities,
    required this.cartItemPrices,
    required this.activityMessages,
    required this.activityTimestamps,
    required this.activityIcons,
    required this.userId,
    required this.userName,
    required this.cachedAt,
  });

  factory GroupBuyCacheModel.fromRoomJson(
    Map<String, dynamic> json,
    int currentUserId,
    String currentUserName,
  ) {
    final members = json['members'] as List? ?? [];
    final cartItems = json['cart_items'] as List? ?? [];
    final activities = json['activities'] as List? ?? [];

    return GroupBuyCacheModel(
      id: _toInt(json['id']),
      code: (_toString(json['code']) ?? _toString(json['invite_code']) ?? 'ROOM00').toUpperCase(),
      name: _toString(json['name']) ?? 'Group Buy Room',
      isPublic: _toBool(json['is_public'] ?? json['isPublic'] ?? false),
      maxMembers: _toInt(json['max_members'] ?? 5, fallback: 5),
      status: _toString(json['status']) ?? 'open',
      expiresAt: _toString(json['expires_at']),
      createdAt: _toString(json['created_at']) ?? DateTime.now().toIso8601String(),
      ownerId: _toInt((json['owner'] is Map) ? json['owner']['id'] : json['owner_id'] ?? currentUserId),
      ownerName: _toString((json['owner'] is Map) ? json['owner']['name'] : json['owner_name']) ?? currentUserName,
      memberIds: members.map((m) => _toString(m['id']) ?? '').toList(),
      memberNames: members.map((m) => _toString(m['name']) ?? 'User').toList(),
      cartItemNames: cartItems.map((c) => _toString(c['name'] ?? c['product_name']) ?? 'Item').toList(),
      cartItemQuantities: cartItems.map((c) => _toInt(c['quantity'] ?? 1)).toList(),
      cartItemPrices: cartItems.map((c) => _toDouble(c['price'] ?? c['unit_price'] ?? 0)).toList(),
      activityMessages: activities.map((a) => _toString(a['message']) ?? 'Activity').toList(),
      activityTimestamps: activities.map((a) => _toString(a['timestamp'] ?? a['created_at']) ?? DateTime.now().toIso8601String()).toList(),
      activityIcons: activities.map((a) => _toString(a['icon']) ?? 'activity').toList(),
      userId: currentUserId,
      userName: currentUserName,
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toRoomJson() {
    final members = <Map<String, dynamic>>[];
    for (var i = 0; i < memberIds.length; i++) {
      members.add({
        'id': int.tryParse(memberIds[i]) ?? 0,
        'name': memberNames[i],
        'is_owner': i == 0 && ownerId == int.tryParse(memberIds[i]),
      });
    }

    final cartItems = <Map<String, dynamic>>[];
    for (var i = 0; i < cartItemNames.length; i++) {
      cartItems.add({
        'id': i + 1,
        'product_id': i + 1,
        'name': cartItemNames[i],
        'quantity': cartItemQuantities[i],
        'unit_price': cartItemPrices[i],
        'added_by': {'name': userName},
      });
    }

    final activities = <Map<String, dynamic>>[];
    for (var i = 0; i < activityMessages.length; i++) {
      activities.add({
        'id': 'act_$i',
        'message': activityMessages[i],
        'timestamp': activityTimestamps[i],
        'icon': activityIcons[i],
      });
    }

    return {
      'id': id,
      'code': code,
      'name': name,
      'is_public': isPublic,
      'max_members': maxMembers,
      'status': status,
      'expires_at': expiresAt,
      'created_at': createdAt,
      'owner': {'id': ownerId, 'name': ownerName},
      'members': members,
      'cart_items': cartItems,
      'activities': activities,
    };
  }

  String get cacheKey => code.toUpperCase();
}

String? _toString(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

bool _toBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final l = value.trim().toLowerCase();
    if (l == 'true' || l == '1' || l == 'yes') return true;
    if (l == 'false' || l == '0' || l == 'no') return false;
  }
  return fallback;
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _toDouble(Object? value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String && value.isNotEmpty) {
    final parsed = double.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback;
}