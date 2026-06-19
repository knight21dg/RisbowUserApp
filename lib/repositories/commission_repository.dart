import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/commission_model.dart';

class CommissionRepository {
  Future<List<CommissionRuleModel>> fetchRules({int page = 1, int perPage = 20, String? scope, bool? isActive}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (scope != null) queryParams['scope'] = scope;
      if (isActive != null) queryParams['is_active'] = isActive;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.commissionRulesApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<CommissionRuleModel> rules = [];
        if (response.data['data'] != null && response.data['data']['data'] != null) {
          for (var item in response.data['data']['data']) {
            rules.add(CommissionRuleModel.fromJson(item));
          }
        }
        return rules;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<CommissionStatsModel> fetchStats({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.commissionStatsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommissionStatsModel.fromJson(response.data['data']);
      }
      return CommissionStatsModel();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> createRule(Map<String, dynamic> ruleData) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.commissionCreateRuleApi,
        ruleData,
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateRule(int ruleId, Map<String, dynamic> ruleData) async {
    try {
      final response = await AppConstant.apiBaseHelper.putAPICall(
        '${ApiRoutes.commissionUpdateRuleApi}$ruleId',
        ruleData,
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}