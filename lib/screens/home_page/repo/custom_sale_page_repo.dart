import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/screens/home_page/model/custom_sale_page_model.dart';
import 'package:hyper_local/services/location/location_service.dart';

class CustomSalePageRepo {
  Future<List<CustomSalePageListItem>> getCustomSalePages({bool footer = false}) async {
    try {
      final String apiUrl = footer 
          ? ApiRoutes.customPagesFooterApi 
          : ApiRoutes.customPagesApi;

      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> pagesData = response.data['data'];
        return pagesData
            .map((json) => CustomSalePageListItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch custom sale pages');
    }
  }

  Future<CustomSalePageModel> getCustomSalePageBySlug(String slug) async {
    try {
      final String apiUrl = ApiRoutes.customPageBySlug(slug);
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        apiUrl,
        {},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return CustomSalePageModel.fromJson(response.data['data']);
      }
      throw ApiException('Custom sale page not found');
    } catch (e) {
      throw ApiException('Failed to fetch custom sale page');
    }
  }

  Future<List<CustomSalePageProduct>> getProductsForSection({
    String? categorySlug,
    int? categoryId,
    int perPage = 10,
    int page = 1,
  }) async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final categoryValue = (categorySlug != null && categorySlug.isNotEmpty)
          ? categorySlug
          : (categoryId?.toString() ?? '');

      if (categoryValue.isEmpty) return [];

      String apiUrl =
          '${ApiRoutes.categoryProductApi}?categories=$categoryValue&per_page=$perPage&page=$page&latitude=$latitude&longitude=$longitude&sort=relevance&include_child_categories=1';
      
      if (zoneId != null && zoneId.isNotEmpty) {
        apiUrl += '&zone_id=$zoneId';
      }

      final response = await AppConstant.apiBaseHelper.getAPICall(apiUrl, {});
      final data = response.data['data'];

      List<dynamic> productsJson = const [];
      if (data is Map<String, dynamic> && data['data'] is List) {
        productsJson = data['data'] as List<dynamic>;
      } else if (data is List) {
        productsJson = data;
      }

      return productsJson
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(CustomSalePageProduct.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Advanced Custom Page APIs
  Future<Map<String, dynamic>?> getCustomPageFull(String slug) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.customPageFull(slug),
        {},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      throw ApiException('Failed to fetch custom page full data');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomPageBanners(String slug) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.customPageBanners(slug),
        {},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch custom page banners');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomPageSections(String slug, {int page = 1, int perPage = 20}) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.customPageSections(slug),
        {'page': page.toString(), 'per_page': perPage.toString()},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch custom page sections');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomPageGrids(String slug) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.customPageGrids(slug),
        {},
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      throw ApiException('Failed to fetch custom page grids');
    }
  }
}
