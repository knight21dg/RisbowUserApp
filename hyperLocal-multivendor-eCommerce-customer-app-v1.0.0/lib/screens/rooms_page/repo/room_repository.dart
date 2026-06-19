import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/services/group_buy/group_buy_hive_service.dart';
import 'package:hyper_local/model/group_buy/group_buy_cache_model.dart';

class RoomRepository {
  final http.Client _client;

  static final Map<String, GroupBuyRoom> _roomCache = <String, GroupBuyRoom>{};

  RoomRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<List<GroupBuyRoom>> getMyRooms({String? query}) async {
    try {
      final uri = Uri.parse(ApiRoutes.roomsApi).replace(
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      final response = await _client.get(uri, headers: headers);
      final payload = _decodeMap(response.body);
      final rooms = _extractRoomList(payload);
      if (rooms.isNotEmpty) {
        _cacheRooms(rooms);
        await GroupBuyHiveService.cacheRooms(rooms.map((r) => r.toJson()).toList());
        return _filterRooms(rooms, query: query);
      }
    } catch (error) {
      debugPrint('group-buy getMyRooms failed: $error');
    }
    return _loadFromHiveCache(query: query, publicOnly: false);
  }

  Future<List<GroupBuyRoom>> discoverRooms({String? query}) async {
    try {
      final uri = Uri.parse(ApiRoutes.publicRoomsApi).replace(
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      final response = await _client.get(uri, headers: headers);
      final payload = _decodeMap(response.body);
      final rooms = _extractRoomList(payload);
      if (rooms.isNotEmpty) {
        _cacheRooms(rooms);
        await GroupBuyHiveService.cacheRooms(rooms.map((r) => r.toJson()).toList());
        final publicRooms = rooms.where((room) => room.isPublic).toList();
        return _filterRooms(publicRooms, query: query);
      }
    } catch (error) {
      debugPrint('group-buy discoverRooms failed: $error');
    }
    return _loadFromHiveCache(query: query, publicOnly: true);
  }

  Future<GroupBuyRoom?> getRoomDetails(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final cached = _roomCache[normalizedCode];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(ApiRoutes.roomApi(normalizedCode));
      final response = await _client.get(uri, headers: headers);
      final payload = _decodeMap(response.body);
      final room = _extractSingleRoom(payload);
      if (room != null) {
        _upsertRoom(room);
        await GroupBuyHiveService.cacheRoom(room.toJson());
        return room;
      }
    } catch (error) {
      debugPrint('group-buy getRoomDetails failed: $error');
    }
    return _loadRoomFromHive(normalizedCode);
  }

  Future<GroupBuyRoom?> createRoom({
    required String name,
    required int maxMembers,
    required bool isPublic,
    DateTime? expiresAt,
  }) async {
    try {
      final now = DateTime.now();
      final durationHours = expiresAt != null
          ? expiresAt.difference(now).inHours.clamp(1, 168)
          : 24;
      final response = await _client.post(
        Uri.parse(ApiRoutes.roomsApi),
        headers: headers,
        body: jsonEncode({
          'name': name.trim(),
          'max_members': maxMembers,
          'is_private': !isPublic,
          'duration_hours': durationHours,
        }),
      );

      debugPrint('group-buy createRoom response status: ${response.statusCode}');
      debugPrint('group-buy createRoom response body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('group-buy createRoom HTTP error: ${response.statusCode}');
        final decoded = _decodeMap(response.body);
        final message = decoded['message'] ?? decoded['error'] ?? 'Unknown error';
        debugPrint('group-buy createRoom error message: $message');
        return null;
      }

      final payload = _decodeMap(response.body);
      final created = _extractSingleRoom(payload);
      if (created != null) {
        _upsertRoom(created);
        await GroupBuyHiveService.cacheRoom(created.toJson());
        return created;
      }
      final errorMsg = payload['message'] ?? payload['error'] ?? 'Failed to create room';
      debugPrint('group-buy createRoom: $errorMsg');
    } catch (error) {
      debugPrint('group-buy createRoom failed: $error');
    }
    return null;
  }

  Future<GroupBuyRoom?> updateRoom(String code, Map<String, dynamic> data) async {
    final normalizedCode = code.trim().toUpperCase();
    try {
      final response = await _client.put(
        Uri.parse(ApiRoutes.roomApi(normalizedCode)),
        headers: headers,
        body: jsonEncode(data),
      );
      final payload = _decodeMap(response.body);
      final updated = _extractSingleRoom(payload);
      if (updated != null) {
        _upsertRoom(updated);
        await GroupBuyHiveService.cacheRoom(updated.toJson());
        return updated;
      }
      final errorMsg = payload['message'] ?? payload['error'] ?? 'Failed to update room';
      debugPrint('group-buy updateRoom: $errorMsg');
    } catch (error) {
      debugPrint('group-buy updateRoom failed: $error');
    }
    return null;
  }

  Future<GroupBuyRoom?> joinRoom(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.joinRoomApi(normalizedCode)),
        headers: headers,
        body: jsonEncode({'invite_code': normalizedCode}),
      );
      final payload = _decodeMap(response.body);
      final joined = _extractSingleRoom(payload);
      if (joined != null) {
        _upsertRoom(joined);
        await GroupBuyHiveService.cacheRoom(joined.toJson());
        return joined;
      }
    } catch (error) {
      debugPrint('group-buy joinRoom failed: $error');
    }
    
    final cachedRoom = await _loadRoomFromHive(normalizedCode);
    if (cachedRoom != null && !cachedRoom.isExpired && !cachedRoom.isFull) {
      return cachedRoom;
    }
    
    return null;
  }

  Future<List<GroupBuyProduct>> getGroupProducts({
    String? search,
    String? category,
    String? sort,
  }) async {
    try {
      final uri = Uri.parse(ApiRoutes.categoryProductApi).replace(
        queryParameters: {
          'latitude': AppConstant.defaultLat,
          'longitude': AppConstant.defaultLng,
          if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
          if (category != null &&
              category.trim().isNotEmpty &&
              category != 'All')
            'category': category.trim(),
          if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
        },
      );
      final response = await _client.get(uri, headers: headers);
      final payload = _decodeMap(response.body);
      final rawList = _extractDataList(payload);
      if (rawList.isNotEmpty) {
        return rawList.map(GroupBuyProduct.fromJson).toList();
      }
    } catch (error) {
      debugPrint('group-buy getGroupProducts failed: $error');
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client.get(Uri.parse(ApiRoutes.categoryApi), headers: headers);
      final payload = _decodeMap(response.body);
      final data = payload['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('group-buy getCategories failed: $e');
    }
    return [];
  }

  Future<GroupBuyRoom?> addItemToRoom({
    required GroupBuyRoom room,
    required GroupBuyProduct product,
    required int quantity,
  }) async {
    if (quantity <= 0) return room;

    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.roomItemsApi(room.code)),
        headers: headers,
        body: jsonEncode({'product_id': product.id, 'quantity': quantity}),
      );
      final payload = _decodeMap(response.body);
      final updated = _extractSingleRoom(payload);
      if (updated != null) {
        _upsertRoom(updated);
        return updated;
      }
      if (_toSuccess(payload)) {
        _roomCache.remove(room.code.toUpperCase());
        final refreshed = await getRoomDetails(room.code);
        if (refreshed != null) return refreshed;
      }
    } catch (error) {
      debugPrint('group-buy addItemToRoom failed: $error');
    }

    final updatedItems = List<GroupBuyCartItem>.from(room.cartItems);
    final existingIndex = updatedItems.indexWhere(
      (item) => item.productId == product.id,
    );
    if (existingIndex >= 0) {
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updatedItems.add(
        GroupBuyCartItem(
          id: DateTime.now().microsecondsSinceEpoch,
          productId: product.id,
          name: product.name,
          imageUrl: product.imageUrl,
          quantity: quantity,
          unitPrice: product.groupPrice > 0
              ? product.groupPrice
              : product.price,
          addedByName: 'You',
          inStock: product.inStock,
        ),
      );
    }

    final updatedRoom = room.copyWith(
      cartItems: updatedItems,
      activities: [
        GroupBuyActivity(
          id: DateTime.now().millisecondsSinceEpoch,
          type: 'info',
          message: 'You added ${product.name} x$quantity',
          createdAt: DateTime.now(),
        ),
        ...room.activities,
      ],
    );
    _upsertRoom(updatedRoom);
    return updatedRoom;
  }

  Future<GroupBuyRoom?> updateItemQuantity({
    required GroupBuyRoom room,
    required GroupBuyCartItem item,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return removeFromRoomCart(room: room, itemId: item.id);
    }
    try {
      final response = await _client.put(
        Uri.parse(ApiRoutes.roomItemApi(room.code, item.id)),
        headers: headers,
        body: jsonEncode({'quantity': quantity}),
      );
      final payload = _decodeMap(response.body);
      final updated = _extractSingleRoom(payload);
      if (updated != null) {
        _upsertRoom(updated);
        return updated;
      }
      if (_toSuccess(payload)) {
        _roomCache.remove(room.code.toUpperCase());
        final refreshed = await getRoomDetails(room.code);
        if (refreshed != null) return refreshed;
      }
    } catch (error) {
      debugPrint('group-buy updateItemQuantity failed: $error');
    }
    final local = room.copyWith(
      cartItems: room.cartItems.map((entry) {
        if (entry.id == item.id) {
          return entry.copyWith(quantity: quantity);
        }
        return entry;
      }).toList(),
    );
    _upsertRoom(local);
    return local;
  }

  Future<GroupBuyRoom?> removeFromRoomCart({
    required GroupBuyRoom room,
    required int itemId,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse(ApiRoutes.roomItemApi(room.code, itemId)),
        headers: headers,
      );
      final payload = _decodeMap(response.body);
      final updated = _extractSingleRoom(payload);
      if (updated != null) {
        _upsertRoom(updated);
        return updated;
      }
      if (_toSuccess(payload)) {
        _roomCache.remove(room.code.toUpperCase());
        final refreshed = await getRoomDetails(room.code);
        if (refreshed != null) return refreshed;
      }
    } catch (error) {
      debugPrint('group-buy removeFromRoomCart failed: $error');
    }
    final local = room.copyWith(
      cartItems: room.cartItems.where((item) => item.id != itemId).toList(),
    );
    _upsertRoom(local);
    return local;
  }

  Future<Map<String, dynamic>?> confirmGroupBuyPurchase(
    GroupBuyCheckoutPayload payload,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.roomCheckoutApi(payload.roomCode)),
        headers: headers,
        body: jsonEncode({
          'address': payload.address,
          'payment_method': payload.paymentToken,
          'items': payload.items.map((item) => {
            'product_id': item.productId,
            'qty': item.qty,
          }).toList(),
        }),
      );
      final result = _decodeMap(response.body);
      if (result.isNotEmpty && result['success'] == true) {
        return result['data'];
      }
      return {
        'success': false,
        'message': result['message'] ?? 'Checkout failed',
      };
    } catch (error) {
      debugPrint('group-buy confirm purchase failed: $error');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>?> initiateGroupCheckout({
    required String code,
    required String splitType,
    required Map<String, dynamic> address,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.roomCheckoutInitiateApi(code)),
        headers: headers,
        body: jsonEncode({
          'split_type': splitType,
          'address': address,
        }),
      );
      final result = _decodeMap(response.body);
      return result;
    } catch (error) {
      debugPrint('group-buy initiateCheckout failed: $error');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>?> getGroupPaymentStatus(String code) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiRoutes.roomCheckoutPaymentStatusApi(code)),
        headers: headers,
      );
      final result = _decodeMap(response.body);
      return result;
    } catch (error) {
      debugPrint('group-buy getPaymentStatus failed: $error');
      return null;
    }
  }

  Future<Map<String, dynamic>?> payGroupShare({
    required String code,
    required String paymentMethod,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.roomCheckoutPayApi(code)),
        headers: headers,
        body: jsonEncode({
          'payment_method': paymentMethod,
        }),
      );
      final result = _decodeMap(response.body);
      return result;
    } catch (error) {
      debugPrint('group-buy payGroupShare failed: $error');
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>?> getRoomSummary(String code) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiRoutes.roomSummaryApi(code)),
        headers: headers,
      );
      final result = _decodeMap(response.body);
      if (result.isNotEmpty && result['success'] == true) {
        return result['data'];
      }
    } catch (error) {
      debugPrint('group-buy getRoomSummary failed: $error');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRoomStats(String code) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiRoutes.roomStatsApi(code)),
        headers: headers,
      );
      final result = _decodeMap(response.body);
      if (result.isNotEmpty && result['success'] == true) {
        return result['data'];
      }
    } catch (error) {
      debugPrint('group-buy getRoomStats failed: $error');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getRoomSavings(String code) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiRoutes.roomSavingsApi(code)),
        headers: headers,
      );
      final result = _decodeMap(response.body);
      if (result.isNotEmpty && result['success'] == true) {
        return result['data'];
      }
    } catch (error) {
      debugPrint('group-buy getRoomSavings failed: $error');
    }
    return null;
  }

  Future<GroupBuyRoom?> leaveRoom(GroupBuyRoom room) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.leaveRoomApi(room.code)),
        headers: headers,
      );
      final payload = _decodeMap(response.body);
      if (_toSuccess(payload)) {
        await GroupBuyHiveService.removeCachedRoom(room.code);
      }
    } catch (error) {
      debugPrint('group-buy leaveRoom failed: $error');
    }
    final updated = room.copyWith(status: 'closed');
    _upsertRoom(updated);
    return updated;
  }

  Future<GroupBuyRoom?> endRoom(GroupBuyRoom room) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiRoutes.completeRoomApi(room.code)),
        headers: headers,
      );
      final payload = _decodeMap(response.body);
      final updated = _extractSingleRoom(payload);
      if (updated != null) {
        _upsertRoom(updated);
        return updated;
      }
      if (_toSuccess(payload)) {
        final refreshed = await getRoomDetails(room.code);
        if (refreshed != null) return refreshed;
      }
    } catch (error) {
      debugPrint('group-buy endRoom failed: $error');
    }
    final updated = room.copyWith(status: 'closed');
    _upsertRoom(updated);
    return updated;
  }

  List<GroupBuyRoom> _extractRoomList(Map<String, dynamic> payload) {
    final list = _extractDataList(payload);
    return list.map(GroupBuyRoom.fromJson).toList();
  }

  GroupBuyRoom? _extractSingleRoom(Map<String, dynamic> payload) {
    // Handle { "success": true, "data": { "room": {...} } }
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (data['room'] is Map<String, dynamic>) {
        return GroupBuyRoom.fromJson(data['room'] as Map<String, dynamic>);
      }
      if (data.containsKey('code') || data.containsKey('invite_code')) {
        return GroupBuyRoom.fromJson(data);
      }
      if (data.containsKey('id') && data.containsKey('name')) {
        return GroupBuyRoom.fromJson(data);
      }
    }
    // Handle { "room": {...} }
    if (payload['room'] is Map<String, dynamic>) {
      return GroupBuyRoom.fromJson(payload['room'] as Map<String, dynamic>);
    }
    // Handle { "success": true, "room": {...} }
    if (payload['success'] == true && payload['room'] is Map<String, dynamic>) {
      return GroupBuyRoom.fromJson(payload['room'] as Map<String, dynamic>);
    }
    // Handle direct room object { "id": ..., "code": ..., ... }
    if (payload.containsKey('id') && payload.containsKey('code') && payload.containsKey('name')) {
      return GroupBuyRoom.fromJson(payload);
    }
    debugPrint('_extractSingleRoom: no room found in payload keys: ${payload.keys}');
    return null;
  }

  List<Map<String, dynamic>> _extractDataList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['rooms'] ?? data['products'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }
    if (payload['rooms'] is List) {
      return (payload['rooms'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    if (payload['products'] is List) {
      return (payload['products'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return const <String, dynamic>{};
    }
    return const <String, dynamic>{};
  }

  bool _toSuccess(Map<String, dynamic> payload) {
    final success = payload['success'];
    return success == true || success == 1 || success == 'true';
  }

  List<GroupBuyRoom> _filterRooms(List<GroupBuyRoom> rooms, {String? query}) {
    final normalized = query?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return rooms;
    return rooms.where((room) {
      return room.name.toLowerCase().contains(normalized) ||
          room.code.toLowerCase().contains(normalized);
    }).toList();
  }

  void _cacheRooms(List<GroupBuyRoom> rooms) {
    for (final room in rooms) {
      _upsertRoom(room);
    }
  }

  void _upsertRoom(GroupBuyRoom room) {
    _roomCache[room.code.toUpperCase()] = room;
  }

  Future<List<GroupBuyRoom>> _loadFromHiveCache({String? query, required bool publicOnly}) async {
    try {
      List<GroupBuyCacheModel> cached;
      if (publicOnly) {
        cached = GroupBuyHiveService.getPublicCachedRooms();
      } else {
        cached = GroupBuyHiveService.getMyCachedRooms();
      }
      if (cached.isEmpty) {
        return [];
      }
      final rooms = cached.map((model) => GroupBuyRoom(
        id: model.id,
        code: model.code,
        name: model.name,
        isPublic: model.isPublic,
        maxMembers: model.maxMembers,
        status: model.status,
        expiresAt: model.expiresAt != null ? DateTime.tryParse(model.expiresAt!) : null,
        createdAt: DateTime.tryParse(model.createdAt) ?? DateTime.now(),
        owner: GroupBuyMember(id: model.ownerId, name: model.ownerName, isOwner: true),
        members: _buildMembersFromCache(model),
        cartItems: _buildCartItemsFromCache(model),
        activities: _buildActivitiesFromCache(model),
      )).toList();
      _cacheRooms(rooms);
      return _filterRooms(rooms, query: query);
    } catch (e) {
      debugPrint('group-buy Hive cache load failed: $e');
      return [];
    }
  }

  Future<GroupBuyRoom?> _loadRoomFromHive(String code) async {
    try {
      final cached = GroupBuyHiveService.getCachedRoom(code);
      if (cached != null) {
        final room = GroupBuyRoom(
          id: cached.id,
          code: cached.code,
          name: cached.name,
          isPublic: cached.isPublic,
          maxMembers: cached.maxMembers,
          status: cached.status,
          expiresAt: cached.expiresAt != null ? DateTime.tryParse(cached.expiresAt!) : null,
          createdAt: DateTime.tryParse(cached.createdAt) ?? DateTime.now(),
          owner: GroupBuyMember(id: cached.ownerId, name: cached.ownerName, isOwner: true),
          members: _buildMembersFromCache(cached),
          cartItems: _buildCartItemsFromCache(cached),
          activities: _buildActivitiesFromCache(cached),
        );
        _upsertRoom(room);
        return room;
      }
    } catch (e) {
      debugPrint('group-buy Hive room load failed: $e');
    }
    return null;
  }

  List<GroupBuyMember> _buildMembersFromCache(GroupBuyCacheModel model) {
    final members = <GroupBuyMember>[];
    for (var i = 0; i < model.memberIds.length && i < model.memberNames.length; i++) {
      members.add(GroupBuyMember(
        id: int.tryParse(model.memberIds[i]) ?? 0,
        name: model.memberNames[i],
        isOwner: i == 0 && model.ownerId == int.tryParse(model.memberIds[i]),
      ));
    }
    if (members.isEmpty) {
      members.add(GroupBuyMember(id: model.ownerId, name: model.ownerName, isOwner: true));
    }
    return members;
  }

  List<GroupBuyCartItem> _buildCartItemsFromCache(GroupBuyCacheModel model) {
    final items = <GroupBuyCartItem>[];
    for (var i = 0; i < model.cartItemNames.length && i < model.cartItemQuantities.length && i < model.cartItemPrices.length; i++) {
      items.add(GroupBuyCartItem(
        id: i + 1,
        productId: i + 1,
        name: model.cartItemNames[i],
        quantity: model.cartItemQuantities[i],
        unitPrice: model.cartItemPrices[i],
        addedByName: model.userName,
      ));
    }
    return items;
  }

  List<GroupBuyActivity> _buildActivitiesFromCache(GroupBuyCacheModel model) {
    final activities = <GroupBuyActivity>[];
    for (var i = 0; i < model.activityMessages.length && i < model.activityTimestamps.length && i < model.activityIcons.length; i++) {
      activities.add(GroupBuyActivity(
        id: i,
        type: 'info',
        message: model.activityMessages[i],
        createdAt: DateTime.tryParse(model.activityTimestamps[i]) ?? DateTime.now(),
        timestamp: DateTime.tryParse(model.activityTimestamps[i]),
        iconKey: model.activityIcons[i],
      ));
    }
    return activities;
  }
}
