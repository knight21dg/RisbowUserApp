import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/headers.dart';

class WeeklyRoomsRepo {
  Future<Map<String, String>> _getHeaders() async {
    return headers ?? {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<dynamic> getActiveWeeklyRooms() async {
    try {
      final h = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstant.baseUrl}weekly-rooms/active'),
        headers: h,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load active weekly rooms');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> getRoomDetails(int roomId) async {
    try {
      final h = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstant.baseUrl}weekly-rooms/$roomId'),
        headers: h,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load room details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> joinWeeklyRoom(int roomId) async {
    try {
      final h = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstant.baseUrl}weekly-rooms/$roomId/join'),
        headers: h,
      );
      
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> joinInstance(String code) async {
    try {
      final h = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstant.baseUrl}weekly-rooms/instances/$code/join'),
        headers: h,
      );
      
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> getInstanceDetails(int instanceId) async {
    try {
      final h = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstant.baseUrl}weekly-rooms/instances/$instanceId'),
        headers: h,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load instance details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
