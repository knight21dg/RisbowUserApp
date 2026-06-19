import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constant.dart';
import '../model/group_buy_models.dart';

class RoomDiscountInfo {
  final double currentDiscount;
  final int currentMembers;
  final int minMembers;
  final int maxMembers;
  final int membersNeededToUnlock;
  final double unlockProgress;
  final bool isUnlocked;
  final bool dynamicDiscountEnabled;
  final RoomDiscountSlabModel? activeSlab;
  final RoomDiscountSlabModel? nextSlab;
  final List<RoomDiscountSlabModel> slabs;

  RoomDiscountInfo({
    required this.currentDiscount,
    required this.currentMembers,
    required this.minMembers,
    required this.maxMembers,
    required this.membersNeededToUnlock,
    required this.unlockProgress,
    required this.isUnlocked,
    required this.dynamicDiscountEnabled,
    this.activeSlab,
    this.nextSlab,
    required this.slabs,
  });

  factory RoomDiscountInfo.fromJson(Map<String, dynamic> json) {
    return RoomDiscountInfo(
      currentDiscount: (json['current_discount'] ?? 0).toDouble(),
      currentMembers: json['current_members'] ?? 0,
      minMembers: json['min_members'] ?? 20,
      maxMembers: json['max_members'] ?? 100,
      membersNeededToUnlock: json['members_needed_to_unlock'] ?? 20,
      unlockProgress: (json['unlock_progress'] ?? 0).toDouble(),
      isUnlocked: json['is_unlocked'] ?? false,
      dynamicDiscountEnabled: json['dynamic_discount_enabled'] ?? false,
      activeSlab: json['active_slab'] != null 
          ? RoomDiscountSlabModel.fromJson(json['active_slab'])
          : null,
      nextSlab: json['next_slab'] != null 
          ? RoomDiscountSlabModel.fromJson(json['next_slab'])
          : null,
      slabs: (json['slabs'] as List<dynamic>?)
          ?.map((e) => RoomDiscountSlabModel.fromJson(e))
          .toList() ?? [],
    );
  }

  factory RoomDiscountInfo.empty() {
    return RoomDiscountInfo(
      currentDiscount: 0,
      currentMembers: 0,
      minMembers: 20,
      maxMembers: 100,
      membersNeededToUnlock: 20,
      unlockProgress: 0,
      isUnlocked: false,
      dynamicDiscountEnabled: false,
      slabs: [],
    );
  }
}

class RoomDiscountService {
  static RoomDiscountService? _instance;
  static RoomDiscountService get instance => _instance ??= RoomDiscountService._();
  RoomDiscountService._();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<RoomDiscountInfo> getDiscountInfo(String roomCode) async {
    try {
      final response = await http.get(
        Uri.parse('$AppConstant.baseUrl/rooms/$roomCode/discount-info'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return RoomDiscountInfo.fromJson(data['data']);
        }
      }
      throw Exception('Failed to fetch discount info');
    } catch (e) {
      throw Exception('Failed to fetch discount info: $e');
    }
  }

  double calculateDynamicPrice(double basePrice, double discountPercentage) {
    if (discountPercentage <= 0) return basePrice;
    return basePrice * (1 - discountPercentage / 100);
  }
}