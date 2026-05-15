import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../router/app_routes.dart';
import '../../../services/location/location_service.dart';
import 'package:go_router/go_router.dart';

class CategoryStoreProductsPage extends StatefulWidget {
  final StoreData store;
  final String categorySlug;

  const CategoryStoreProductsPage({
    super.key,
    required this.store,
    required this.categorySlug,
  });

  @override
  State<CategoryStoreProductsPage> createState() => _CategoryStoreProductsPageState();
}

class _CategoryStoreProductsPageState extends State<CategoryStoreProductsPage> {
  List<ProductData> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final query = <String, dynamic>{
        'per_page': 50,
        'page': 1,
        'latitude': latitude,
        'longitude': longitude,
        'sort': 'relevance',
        if (zoneId != null && zoneId.isNotEmpty) 'zone_id': zoneId,
        'store_slug': widget.store.slug,
        'category': widget.categorySlug,
      };

      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.storeProductsApi,
        query,
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final rawList = data['data']['data'] as List<dynamic>? ?? [];
        setState(() {
          _products = rawList.map((p) => ProductData.fromJson(p as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _error = data['message'] ?? 'No products found'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.store.name ?? '', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          if (widget.store.distance != null && widget.store.distance! > 0)
            Text('${widget.store.distance!.toStringAsFixed(1)} km away', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        ]),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: widget.store.logo?.isNotEmpty == true
                    ? DecorationImage(image: NetworkImage(widget.store.logo!), fit: BoxFit.cover)
                    : null,
                color: Colors.grey.shade100,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomCircularProgressIndicator())
          : _products.isEmpty
              ? Center(child: Text(_error ?? 'No products found', style: TextStyle(fontSize: 13.sp, color: Colors.grey)))
              : CustomRefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: GridView.builder(
                    padding: EdgeInsets.all(12.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, i) => _buildProductCard(_products[i]),
                  ),
                ),
    );
  }

  Widget _buildProductCard(ProductData product) {
    final variant = product.variants.isNotEmpty ? product.variants.first : null;
    final price = variant?.price.toDouble() ?? product.price;
    final specialPrice = variant?.specialPrice.toDouble() ?? product.specialPrice;
    final mrp = variant?.mrp ?? product.mrp;
    final showDiscount = mrp > price && price > 0;

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 1, child: Stack(children: [
            CustomImageContainer(imagePath: product.mainImage, fit: BoxFit.cover, fallbackAsset: 'assets/images/placeholder.png'),
            if (showDiscount)
              Positioned(bottom: 6.w, right: 6.w, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                child: Text('${((mrp - price) / mrp * 100).round()}%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          ])),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(product.title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${AppConstant.currency}${price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                if (showDiscount) ...[
                  SizedBox(width: 4.w),
                  Text('${AppConstant.currency}${mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
