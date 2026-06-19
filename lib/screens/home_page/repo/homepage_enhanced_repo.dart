import 'package:hyper_local/config/constant.dart';
import '../../../services/location/location_service.dart';
import '../model/today_deal_model.dart';
import '../model/product_reel_model.dart';

class HomepageEnhancedRepository {

  Future<TodayDealsModel> fetchTodayDeals() async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '${AppConstant.baseUrl}today-deals?latitude=$latitude&longitude=$longitude';
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      
      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      return TodayDealsModel.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to fetch today deals: $e');
    }
  }

  Future<ProductReelsModel> fetchTrendingReels({int page = 1, int limit = 10}) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '${AppConstant.baseUrl}reels/trending?page=$page&limit=$limit&latitude=$latitude&longitude=$longitude';
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      
      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      return ProductReelsModel.fromJson(response.data);
    } catch (e) {
      throw ApiException('Failed to fetch trending reels: $e');
    }
  }

  Future<Map<String, dynamic>> fetchHomepageData() async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '${AppConstant.baseUrl}homepage?latitude=$latitude&longitude=$longitude';
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      
      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch homepage data');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}