import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';

class RecommendationsRepository {
  final ApiBaseHelper apiBaseHelper = AppConstant.apiBaseHelper;

  /// Record a product view
  /// [productId] - ID of the product being viewed
  /// [timeSpent] - Time spent on product in seconds (optional)
  /// [completed] - Whether user completed the view (optional)
  /// [source] - Source of view like 'home', 'search', 'category' (optional)
  Future<Map<String, dynamic>> recordProductView({
    required int productId,
    int? timeSpent,
    bool? completed,
    String? source,
  }) async {
    try {
      final response = await apiBaseHelper.postAPICall(
        ApiRoutes.recordProductViewApi,
        {
          'product_id': productId,
          if (timeSpent != null) 'time_spent': timeSpent,
          if (completed != null) 'completed': completed,
          if (source != null) 'source': source,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to record product view: ${e.toString()}');
    }
  }

  /// Record a search query
  /// [query] - Search query string
  /// [resultsCount] - Number of results found (optional)
  /// [foundResults] - Whether results were found (optional)
  /// [source] - Source of search (optional)
  Future<Map<String, dynamic>> recordSearch({
    required String query,
    int? resultsCount,
    bool? foundResults,
    String? source,
  }) async {
    try {
      final response = await apiBaseHelper.postAPICall(
        ApiRoutes.recordSearchApi,
        {
          'query': query,
          if (resultsCount != null) 'results_count': resultsCount,
          if (foundResults != null) 'found_results': foundResults,
          if (source != null) 'source': source,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to record search: ${e.toString()}');
    }
  }

  /// Get personalized recommendations for user
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getPersonalizedRecommendations({int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.personalizedRecommendationsApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch personalized recommendations: ${e.toString()}');
    }
  }

  /// Get trending products
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getTrendingRecommendations({int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.trendingRecommendationsApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch trending recommendations: ${e.toString()}');
    }
  }

  /// Get recently viewed products
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getRecentlyViewed({int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.recentlyViewedApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch recently viewed: ${e.toString()}');
    }
  }

  /// Get continue shopping recommendations
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getContinueShopping({int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.continueShoppingApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch continue shopping: ${e.toString()}');
    }
  }

  /// Get cart recommendations
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getCartRecommendations({int limit = 20}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.cartRecommendationsApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch cart recommendations: ${e.toString()}');
    }
  }

  /// Get frequently bought together products
  /// [productId] - Product ID
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getFrequentlyBoughtTogether({
    required int productId,
    int limit = 20,
  }) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.frequentlyBoughtTogetherApi}$productId?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch frequently bought together: ${e.toString()}');
    }
  }

  /// Get similar products
  /// [productId] - Product ID
  /// [limit] - Number of recommendations (default: 20)
  Future<Map<String, dynamic>> getSimilarProducts({
    required int productId,
    int limit = 20,
  }) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.similarProductsApi}$productId?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch similar products: ${e.toString()}');
    }
  }

  /// Get popular searches
  /// [limit] - Number of searches (default: 50)
  Future<Map<String, dynamic>> getPopularSearches({int limit = 50}) async {
    try {
      final response = await apiBaseHelper.getAPICall(
        '${ApiRoutes.popularSearchesApi}?limit=$limit',
        {},
      );
      return response.data;
    } catch (e) {
      throw ApiException('Failed to fetch popular searches: ${e.toString()}');
    }
  }
}
