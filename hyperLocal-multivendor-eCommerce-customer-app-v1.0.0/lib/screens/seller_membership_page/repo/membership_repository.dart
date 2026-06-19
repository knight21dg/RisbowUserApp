import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/headers.dart';
import 'package:hyper_local/screens/seller_membership_page/model/membership_model.dart';

class MembershipRepository {
  Future<List<MembershipTierModel>> getTiers() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.membershipTiersApi),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((tier) => MembershipTierModel.fromJson(tier))
            .toList();
      }
    }
    return [];
  }

  Future<CurrentSubscriptionModel?> getCurrentSubscription() async {
    final response = await http.get(
      Uri.parse(ApiRoutes.membershipCurrentApi),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return CurrentSubscriptionModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> subscribe({
    required int tierId,
    required String billingCycle,
  }) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.membershipSubscribeApi),
      headers: headers,
      body: jsonEncode({
        'tier_id': tierId,
        'billing_cycle': billingCycle,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> cancelSubscription({String? reason}) async {
    final response = await http.post(
      Uri.parse(ApiRoutes.membershipCancelApi),
      headers: headers,
      body: jsonEncode({
        'reason': reason,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<SubscriptionHistoryModel?> getSubscriptionHistory({int page = 1}) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.membershipHistoryApi}?page=$page'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return SubscriptionHistoryModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<FeatureAccessModel?> checkFeatureAccess(String feature) async {
    final response = await http.get(
      Uri.parse('${ApiRoutes.membershipCheckFeatureApi}$feature'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return FeatureAccessModel.fromJson(data['data']);
      }
    }
    return null;
  }
}
