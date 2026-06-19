import 'dart:convert';
import 'dart:developer';

import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';

import 'package:dio/dio.dart' as dio;
import '../../../services/location/location_service.dart';
import '../model/store_detail_model.dart';

class NearByStoreRepo {
  Future<Map<String, dynamic>?> getNearByStores({
    int page = 1,
    int perPage = 15,
    required String searchQuery,
    String? category,
  }) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final Map<String, dynamic> query = {
        if(zoneId != null && zoneId.isNotEmpty)
          'zone_id': int.tryParse(zoneId) ?? zoneId,
        'latitude': latitude,
        'longitude': longitude,
        'page': page.toString(),
        'per_page': perPage.toString(),
        if(searchQuery.isNotEmpty)
          'search': searchQuery,
        if(category != null && category.isNotEmpty)
          'category': category,
      };

      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.nearByStores,
        query,
      );

      // Extract .data and ensure it's a Map
      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is Map<String, dynamic>) {
        log('API SUCCESS: Stores fetched');
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> updateStoreBanner({required int storeId, required String imagePath}) async {
    try {
      final dioInstance = AppConstant.apiBaseHelper.dio;
      final formData = dio.FormData.fromMap({
        'store_id': storeId,
        'banner': await dio.MultipartFile.fromFile(imagePath),
      });

      final response = await dioInstance.post(
        ApiRoutes.updateStoreBannerApi,
        data: formData,
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to update banner: ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      log('STORE REPO ERROR: $e');
      throw ApiException(e.toString());
    }
  }

  Future<List<StoreDetailModel>> fetchStoreDetail({required String storeSlug}) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];

      final url = '${ApiRoutes.storeDetailApi}$storeSlug?latitude=$latitude&longitude=$longitude';
      print('STORE API REQUEST: $url');

      final response = await AppConstant.apiBaseHelper.getAPICall(url, {});
      print('STORE API RESPONSE STATUS: ${response.statusCode}');
      print('STORE API RESPONSE DATA: ${response.data}');
      
      if(response.statusCode == 200) {
        final responseData = response.data;
        if(responseData is Map<String, dynamic>) {
          List<StoreDetailModel> storeData = [];
          storeData.add(StoreDetailModel.fromJson(responseData));
          print('STORE API SUCCESS: Parsed store data');
          return storeData;
        } else if(responseData is List && responseData.isNotEmpty) {
          List<StoreDetailModel> storeData = [];
          storeData.add(StoreDetailModel.fromJson(responseData.first));
          print('STORE API SUCCESS: Parsed list data');
          return storeData;
        }
      } 
      print('STORE API FAILED: Invalid status code or empty data');
      return [];
    }catch(e) {
      print('STORE API ERROR: $e');
      throw ApiException(e.toString());
    }
  }
}