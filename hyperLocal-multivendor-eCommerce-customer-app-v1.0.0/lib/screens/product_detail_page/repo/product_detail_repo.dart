import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import '../../../services/location/location_service.dart';

class ProductDetailRepository {
  final ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  Future<Map<String, dynamic>> fetchProductDetail({required String productSlug, String? storeSlug}) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String url = '${ApiRoutes.productDetailApi}$productSlug?latitude=$latitude&longitude=$longitude';
      if (storeSlug != null && storeSlug.isNotEmpty) {
        url += '&store_slug=$storeSlug';
      }
      if (zoneId != null && zoneId.isNotEmpty) {
        url += '&zone_id=$zoneId';
      }
      url += '&_t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await apiBaseHelper.getAPICall(url, {});
      return response.data;
    }catch(e){
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchSimilarProduct({required List<String> excludeProductSlug}) async {
    try{
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      // First, get the product to find its ID from the slug
      // Use the recommendation-based similar products API instead
      
      // For now, use the exclude product approach but with category-based filtering
      String apiUrl = '';
      if(excludeProductSlug.isNotEmpty){
        String excludeParam = excludeProductSlug.join(",");
        apiUrl = '${ApiRoutes.getSimilarProductApi}?exclude_product=$excludeParam&latitude=$latitude&longitude=$longitude';
      } else {
        apiUrl = '${ApiRoutes.getSimilarProductApi}?latitude=$latitude&longitude=$longitude';
      }
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }
      final response = await apiBaseHelper.getAPICall(
          apiUrl,
          {}
      );
      return response.data;
    } catch(e){
      throw ApiException('Failed to fetch similar product');
    }
  }

  /// Fetch similar products using the recommendation engine
  Future<Map<String, dynamic>> fetchRecommendedSimilarProduct({required int productId, int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.getRecommendedSimilarProductApi}$productId?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch recommended similar products');
    }
  }
}