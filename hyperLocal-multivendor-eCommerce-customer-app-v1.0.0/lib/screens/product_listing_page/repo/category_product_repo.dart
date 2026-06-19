import 'dart:developer' as developer;

import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/sorting_model/sorting_model.dart';
import '../../../services/location/location_service.dart';
import '../model/product_listing_type.dart';

class CategoryProductRepository {

  Future<Map<String, dynamic>> fetchProductsByType({
    required ProductListingType type,
    required String identifier,
    String? storeSlug,
    String? sortType,
    required int perPage,
    required int currentPage,
    bool? isSearchInStore,
    String? includeChildCategories,
    dynamic cancelToken,
  }) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;
      
      String apiUrl = '';
      Map<String, dynamic> queryParams = {
        'per_page': perPage,
        'page': currentPage,
        'latitude': latitude,
        'longitude': longitude,
        'sort': sortType ?? SortType.relevance,
        '_t': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (zoneId != null && zoneId.isNotEmpty) {
        queryParams['zone_id'] = zoneId;
      }

      if (isSearchInStore == true) {
        apiUrl = ApiRoutes.searchApi;
        queryParams['search'] = identifier;
        queryParams['store'] = storeSlug;
      } else {
        switch (type) {
          case ProductListingType.category:
            apiUrl = ApiRoutes.categoryProductApi;
            queryParams['categories'] = identifier;
            queryParams['include_child_categories'] = includeChildCategories ?? '1';
            break;
          case ProductListingType.brand:
            apiUrl = ApiRoutes.categoryProductApi;
            queryParams['brands'] = identifier;
            break;
          case ProductListingType.store:
            // Custom handling for store API as it uses a slightly different format
            apiUrl = ApiRoutes.storeProductsApi;
            if (storeSlug != null && storeSlug.isNotEmpty) {
              queryParams['store_slug'] = storeSlug;
            }
            if (identifier.isNotEmpty && identifier != storeSlug) {
              queryParams['category'] = identifier;
            }
            break;
          case ProductListingType.search:
            apiUrl = ApiRoutes.searchApi;
            queryParams['search'] = identifier;
            break;
          case ProductListingType.featuredSection:
            apiUrl = '${ApiRoutes.specificFeatureSectionProductApi}$identifier/products';
            break;
          case ProductListingType.all:
            apiUrl = ApiRoutes.categoryProductApi;
            break;
        }
      }

      developer.log('REPOSITORY: Fetching products for type: $type, identifier: $identifier, storeSlug: $storeSlug');
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl, 
        queryParams,
        cancelToken: cancelToken,
      );
      developer.log('REPOSITORY API RESPONSE STATUS: ${response.statusCode}');
      return response.data;

    } catch (e) {
      if (e.toString().contains('cancel')) {
        developer.log('REPOSITORY: Request cancelled');
        rethrow;
      }
      developer.log('REPOSITORY API ERROR: $e');
      throw ApiException(e.toString());
    }
  }

  String _buildStoreApiUrl(String? storeSlug, String? categorySlug, int perPage, int currentPage, {String? sortType}) {
    final baseUrl = ApiRoutes.storeProductsApi;  // Uses /api/products/store-products
    final params = <String>[];
    
    if (storeSlug != null && storeSlug.isNotEmpty) {
      params.add('store_slug=$storeSlug');
    }
    // Use category param (single category)
    if (categorySlug != null && categorySlug.isNotEmpty && categorySlug != storeSlug) {
      params.add('category=$categorySlug');
    }
    params.add('per_page=$perPage');
    params.add('page=$currentPage');
    
    // Add sort parameter
    if (sortType != null && sortType.isNotEmpty) {
      params.add('sort=$sortType');
    }
    
    if (params.isEmpty) {
      return baseUrl;
    }
    return '$baseUrl?${params.join('&')}';
  }
}
