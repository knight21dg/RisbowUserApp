import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/coins_model.dart';

class CoinsRepository {
  Future<CoinsBalanceModel> fetchCoinsBalance() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.coinsBalanceApi,
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CoinsBalanceModel.fromJson(response.data['data']);
      }
      return CoinsBalanceModel();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<CoinsStatsModel> fetchCoinsStats() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.coinsStatsApi,
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CoinsStatsModel.fromJson(response.data['data']);
      }
      return CoinsStatsModel();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchCoinsSettings() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.coinsSettingsApi,
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchCoinsTransactions({required int perPage, int page = 1}) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.coinsTransactionsApi}?page=$page&per_page=$perPage',
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> validateReferralCode(String referralCode) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.validateReferralApi,
        {'referral_code': referralCode},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> applyReferralCode(
    String referralCode, {
    String? deviceId,
    String? referralSource,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    String? utmTerm,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.applyReferralApi,
        {
          'referral_code': referralCode,
          if (deviceId != null) 'device_id': deviceId,
          if (referralSource != null) 'referral_source': referralSource,
          if (utmSource != null) 'utm_source': utmSource,
          if (utmMedium != null) 'utm_medium': utmMedium,
          if (utmCampaign != null) 'utm_campaign': utmCampaign,
          if (utmContent != null) 'utm_content': utmContent,
          if (utmTerm != null) 'utm_term': utmTerm,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> calculateRedemption(int coins) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.calculateRedemptionApi,
        {'coins': coins},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> redeemCoinsForOrder(int coins, int orderId) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.redeemForOrderApi,
        {'coins': coins, 'order_id': orderId},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> trackInstallAttribution({
    String? referralCode,
    String? googlePlayReferrer,
    String? utmSource,
    String? utmMedium,
    String? utmCampaign,
    String? utmContent,
    String? utmTerm,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.trackAttributionApi,
        {
          if (referralCode != null) 'referral_code': referralCode,
          if (googlePlayReferrer != null) 'google_play_referrer': googlePlayReferrer,
          if (utmSource != null) 'utm_source': utmSource,
          if (utmMedium != null) 'utm_medium': utmMedium,
          if (utmCampaign != null) 'utm_campaign': utmCampaign,
          if (utmContent != null) 'utm_content': utmContent,
          if (utmTerm != null) 'utm_term': utmTerm,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
