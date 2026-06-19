import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../services/location/location_service.dart';

class SearchRepository {
  Future<Map<String, dynamic>> fetchSearchData({
    SortType? sortType,
    String? type,
    required String query,
    required int perPage,
    required int currentPage
  }) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final queryParams = <String, String>{
        'search': query,
        'per_page': perPage.toString(),
        'page': currentPage.toString(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'sort': (sortType ?? SortType.relevance).name,
      };
      
      if (zoneId != null && zoneId.isNotEmpty) {
        queryParams['zone_id'] = zoneId;
      }

      final uri = Uri.parse(ApiRoutes.searchApi).replace(queryParameters: queryParams);
      final apiUrl = uri.toString();

      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> advancedSearch({
    required String query,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? color,
    String sort = 'best_seller',
    int perPage = 15,
    int currentPage = 1,
  }) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude']!;
      final longitude = coords['longitude']!;
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final queryParams = <String, String>{
        'q': query,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'per_page': perPage.toString(),
        'page': currentPage.toString(),
        'sort': sort,
      };
      
      if (zoneId != null && zoneId.isNotEmpty) {
        queryParams['zone_id'] = zoneId;
      }

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (brand != null && brand.isNotEmpty) {
        queryParams['brand'] = brand;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (minRating != null) {
        queryParams['min_rating'] = minRating.toString();
      }
      if (color != null && color.isNotEmpty) {
        queryParams['color'] = color;
      }

      final uri = Uri.parse(ApiRoutes.advancedSearchApi).replace(queryParameters: queryParams);
      final response = await AppConstant.apiBaseHelper.getAPICall(
        uri.toString(),
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<String>> getSuggestions(String query, {int limit = 5}) async {
    try {
      final uri = Uri.parse(ApiRoutes.suggestionsApi).replace(
        queryParameters: {'q': query, 'limit': limit.toString()},
      );
      final response = await AppConstant.apiBaseHelper.getAPICall(uri.toString(), {});
      if (response.data['success'] == true) {
        return List<String>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.filterOptionsApi,
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}