import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/screens/home_page/model/homepage_section_model.dart';
import 'package:flutter/foundation.dart';
import '../../../services/location/location_service.dart';

class HomepageSectionRepo {
  Future<List<HomepageSectionModel>> getHomepageSections({String? categorySlug}) async {
    try {
      final coords = LocationService.getCoordinates();
      final lat = coords['latitude'];
      final lng = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '${ApiRoutes.homepageApi}?latitude=$lat&longitude=$lng';
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      
      if (categorySlug != null && categorySlug.isNotEmpty) {
        apiUrl += '&category_slug=$categorySlug';
      }
      
      debugPrint('=== HOMEPAGE API REQUEST ===');
      debugPrint('URL: $apiUrl');
      debugPrint('Coords: lat=$lat, lng=$lng');

      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      final dynamic resData = response.data;
      bool isSuccess = false;
      List<dynamic> sectionsData = [];

      if (resData is Map<String, dynamic>) {
        final successValue = resData['success'];
        isSuccess = successValue == true || successValue == 1 || successValue == '1' || successValue == 'true';

        if (resData['data'] != null) {
          if (resData['data'] is List) {
            sectionsData = resData['data'];
          } else if (resData['data'] is Map && resData['data']['data'] is List) {
            sectionsData = resData['data']['data'];
          } else if (resData['data'] is Map) {
            sectionsData = [resData['data']];
          }
        } else if (resData.containsKey('sections') && resData['sections'] is List) {
          sectionsData = resData['sections'];
        }
      } else if (resData is List) {
        sectionsData = resData;
        isSuccess = sectionsData.isNotEmpty;
      }

      debugPrint('Success: $isSuccess, Sections count: ${sectionsData.length}');
      
      if (isSuccess && sectionsData.isNotEmpty) {
        for (var i = 0; i < sectionsData.length; i++) {
          final section = sectionsData[i];
          final products = section['products'] ?? [];
          debugPrint('Section $i: ${section['title']} - ${(products as List).length} products');
        }
        
        final sections = sectionsData
            .map((json) => HomepageSectionModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        debugPrint('Returning ${sections.length} sections');
        return sections;
      }

      debugPrint('Returning empty list');
      return [];
    } catch (e) {
      debugPrint('ERROR in getHomepageSections: $e');
      throw ApiException('Failed to fetch homepage sections: $e');
    }
  }
}