import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';

class AnalyticsRepository {
  Future<Map<String, dynamic>> fetchOverview({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsOverviewApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchCohort({String? period, int? months}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (months != null) queryParams['months'] = months;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsCohortApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchClv({String? period, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (limit != null) queryParams['limit'] = limit;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsClvApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchRfm({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsRfmApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchVendorScorecards({String? period, int? vendorId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (vendorId != null) queryParams['vendor_id'] = vendorId;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsVendorScorecardsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchCategoryPerformance({String? period, int? categoryId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsCategoryPerformanceApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchOrderMetrics({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsOrderMetricsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchRevenueMetrics({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.analyticsRevenueMetricsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] ?? {};
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}