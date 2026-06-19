import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';

class SlotBannerRepository {
  /// Fetch active vendor-purchased banner ads for a given [position].
  /// e.g. position = 'store_page', 'home_top', 'category_page'
  Future<Map<String, dynamic>> fetchSlotBanners({
    required String position,
    String? storeSlug,
    int limit = 5,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'position': position,
        'limit': limit.toString(),
        if (storeSlug != null && storeSlug.isNotEmpty) 'store_slug': storeSlug,
      };

      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.slotBannersApi,
        params,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to fetch slot banners: $e');
    }
  }

  /// Track banner impression or click.
  Future<void> trackImpression(int bannerId, {bool isClick = false}) async {
    try {
      await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.slotBannerImpressionApi,
        {
          'banner_id': bannerId.toString(),
          'type': isClick ? 'click' : 'impression',
        },
      );
    } catch (e) {
      print('Failed to track banner: $e');
    }
  }
}
