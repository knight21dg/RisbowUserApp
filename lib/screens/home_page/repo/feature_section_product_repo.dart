import 'package:hyper_local/config/api_base_helper.dart';

import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../services/location/location_service.dart';

class FeatureSectionProductRepository {

  Future<Map<String, dynamic>> fetchFeatureSectionProduct({
    required String slug,
    required int perPage,
    required int page,
  }) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '';
      
      if(slug.isNotEmpty){
        apiUrl = '${ApiRoutes.featureSectionProductApi}?scope_category_slug=$slug&latitude=$latitude&longitude=$longitude&page=$page&per_page=$perPage';
      } else {
        apiUrl = '${ApiRoutes.featureSectionProductApi}?latitude=$latitude&longitude=$longitude&page=$page&per_page=$perPage';
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
      throw ApiException(e.toString());
    }
  }
}
