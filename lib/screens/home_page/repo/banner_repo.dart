import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';

import '../../../config/api_routes.dart';
import '../../../services/location/location_service.dart';

class BannerRepository {

  Future<Map<String, dynamic>> fetchBanners(
      {required String categorySlug}) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '';
      
      if (categorySlug.isNotEmpty) {
        apiUrl = '${ApiRoutes.bannerApi}?scope_category_slug=$categorySlug&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl = '${ApiRoutes.bannerApi}?latitude=$latitude&longitude=$longitude';
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
      throw ApiException('Failed to fetch Banners');
    }
  }
}
