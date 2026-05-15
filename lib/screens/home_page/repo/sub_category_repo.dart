import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../services/location/location_service.dart';

class SubCategoryRepository {

  Future<Map<String, dynamic>> fetchSubCategory({
      required String slug,
      required bool isForAllCategory,
      int? page,
      int? perPage,
      bool? isFiltered = false,
      bool isHome = false
  }) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '';
      final perPageParam = perPage;
      final pageParam = page != null ? '&page=$page' : '';
      
      String zoneIdParam = (zoneId != null && zoneId.isNotEmpty) ? '&zone_id=$zoneId' : '';

      // filter=top_category is only used for home page when isHome=true to get main category children
      // For specific category tabs and "All" tab, we don't need this filter
      String filterParam = '';
      if(isFiltered == true && isHome) {
        filterParam = '&filter=top_category';
      }

      if (isHome) {
        apiUrl = '${ApiRoutes.homeCategoriesApi}?latitude=$latitude&longitude=$longitude&per_page=$perPageParam$pageParam$filterParam$zoneIdParam&_t=${DateTime.now().millisecondsSinceEpoch}';
      } else if(isForAllCategory) {
        // Use filter=all to get ALL categories (both parents and children)
        // Don't add extra filter param when getting all categories
        apiUrl = '${ApiRoutes.allTabSubCategoryApi}?filter=all&latitude=$latitude&longitude=$longitude&per_page=$perPageParam$pageParam$zoneIdParam&_t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // For specific category, use the categories endpoint with slug to get children
        apiUrl = '${ApiRoutes.subCategoryApi}?slug=$slug&latitude=$latitude&longitude=$longitude&per_page=$perPage$pageParam$zoneIdParam&_t=${DateTime.now().millisecondsSinceEpoch}';
      }
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
          {});
      return response.data;
    }catch(e){
      throw ApiException('Failed to fetch Banners');
    }
  }
}