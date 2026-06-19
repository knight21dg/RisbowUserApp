import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';

class BowPreferenceService {
  Future<void> trackView(String categoryId, int productId) async {
    // Already handled by existing product view tracking
  }

  Future<void> trackSearch(String query, String? category) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'search',
          'data': {
            'query': query,
            'category': category,
          },
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> trackAddToCart(String category, String? color) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'cart',
          'data': {
            'category': category,
            'color': color,
          },
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> trackPurchase(double amount, String category, String? color, String? brand) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'purchase',
          'data': {
            'amount': amount,
            'category': category,
            'color': color,
            'brand': brand,
          },
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> setBudget(int budget) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'set_budget',
          'data': {'budget': budget},
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> setPreferredColor(String color) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'set_color',
          'data': {'color': color},
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> setSize(String type, String size) async {
    try {
      await http.post(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
        body: jsonEncode({
          'type': 'set_size',
          'data': {'type': type, 'size': size},
        }),
      );
    } catch (e) {
      // Silent fail
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await http.get(
        Uri.parse(ApiRoutes.bowPreferencesApi),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      return data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }
}