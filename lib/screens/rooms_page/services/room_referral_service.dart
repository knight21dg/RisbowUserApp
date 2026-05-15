import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constant.dart';
import '../model/room_referral_model.dart';

class RoomReferralService {
  static RoomReferralService? _instance;
  static RoomReferralService get instance => _instance ??= RoomReferralService._();
  RoomReferralService._();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<ReferralLink?> generateReferralLink(String roomCode) async {
    try {
      final response = await http.post(
        Uri.parse('$AppConstant.baseUrl/seller/rooms/$roomCode/referral-link'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return ReferralLink.fromJson(data['data']);
        }
      }
      throw Exception('Failed to generate referral link');
    } catch (e) {
      throw Exception('Failed to generate referral link: $e');
    }
  }

  Future<RoomReferral?> trackReferral(String referralCode, String roomCode, String? refereeId) async {
    try {
      final response = await http.post(
        Uri.parse('$AppConstant.baseUrl/referrals/track'),
        headers: _headers,
        body: json.encode({
          'referral_code': referralCode,
          'room_code': roomCode,
          'referee_id': refereeId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return RoomReferral.fromJson(data['data']);
        }
      }
      throw Exception('Failed to track referral');
    } catch (e) {
      throw Exception('Failed to track referral: $e');
    }
  }

  Future<List<RoomReferral>> getReferralHistory(String roomCode) async {
    try {
      final response = await http.get(
        Uri.parse('$AppConstant.baseUrl/seller/rooms/$roomCode/referrals'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> referrals = data['data'];
          return referrals.map((r) => RoomReferral.fromJson(r)).toList();
        }
      }
      throw Exception('Failed to fetch referral history');
    } catch (e) {
      throw Exception('Failed to fetch referral history: $e');
    }
  }

  String formatShareMessage(String roomName, String referralCode) {
    return '🔥 Join my group buy "$roomName" on RisBow!\n\n'
        'Use my referral code: $referralCode\n\n'
        'Tap to join: risbow://room/join?ref=$referralCode';
  }
}