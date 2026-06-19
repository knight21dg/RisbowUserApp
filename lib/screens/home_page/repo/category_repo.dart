import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';

import '../../../config/constant.dart';
import '../../../services/location/location_service.dart';

class CategoryRepository {
  Future<Map<String, dynamic>> fetchCategory({
    required int perPage, required int currentPage, bool isHome = false
  }) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '';
      if (isHome) {
        apiUrl = '${ApiRoutes.homeMainCategoriesApi}?per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl = '${ApiRoutes.categoryApi}?per_page=$perPage&page=$currentPage&latitude=$latitude&longitude=$longitude';
      }
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {}
      );
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch categories');
    }
  }

  Future<Map<String, dynamic>> fetchHomeCategories() async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.homeCategoriesApi,
        {}
      );
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch home categories');
    }
  }

  Future<Map<String, dynamic>> fetchMainCategories() async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.homeMainCategoriesApi,
        {}
      );
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch main categories');
    }
  }

  Future<Map<String, dynamic>> fetchHomeSections() async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.homeSectionsApi,
        {}
      );
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch home sections');
    }
  }
}