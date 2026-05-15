import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_sorting_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/api_base_helper.dart';
import '../../../config/api_routes.dart';
import '../../../config/constant.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../services/location/location_service.dart';

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
  List<StoreCategoryData> _categories = [];
  StoreCategoryData? _selectedCategory;
  List<ProductData> _products = [];
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = false;
  String? _error;
  String _currentSort = 'relevance';
  double _maxPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final query = <String, dynamic>{
        'per_page': 50,
        'latitude': latitude,
        'longitude': longitude,
        if (zoneId != null && zoneId.isNotEmpty) 'zone_id': zoneId,
      };

      final response = await ApiBaseHelper().getAPICall(
        '${ApiRoutes.categoryApi}?store_id=${widget.store.id}',
        query,
      );

      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final rawData = data['data'];
        List<dynamic> rawList = [];
        if (rawData is List) {
          rawList = rawData;
        } else if (rawData is Map && rawData['data'] != null) {
          rawList = rawData['data'] as List<dynamic>;
        }
        final allCats = rawList.map((c) => StoreCategoryData.fromJson(c as Map<String, dynamic>)).toList();
        // Filter to only categories that match or are children of the selected category slug
        final filtered = allCats.where((c) => c.slug == widget.categorySlug || allCats.any((p) => p.id == c.parentId && p.slug == widget.categorySlug)).toList();
        filtered.sort((a, b) => (b.productCount ?? 0).compareTo(a.productCount ?? 0));
        setState(() {
          _categories = filtered;
          _isLoadingCategories = false;
        });
        if (filtered.isNotEmpty) {
          _selectCategory(filtered.first);
        }
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      setState(() { _isLoadingCategories = false; _error = e.toString(); });
    }
  }

  void _selectCategory(StoreCategoryData cat) {
    setState(() {
      _selectedCategory = cat;
      _products = [];
      _error = null;
    });
    _fetchProducts(cat.slug ?? '');
  }

  Future<void> _fetchProducts(String slug) async {
    setState(() => _isLoadingProducts = true);
    try {
      final coords = LocationService.getCoordinates();
      final latitude = coords['latitude'];
      final longitude = coords['longitude'];
      final storedLocation = LocationService.getStoredLocation();
      final zoneId = storedLocation?.zoneId;

      final query = <String, dynamic>{
        'per_page': 50, 'page': 1,
        'latitude': latitude, 'longitude': longitude,
        'sort': _currentSort,
        if (zoneId != null && zoneId.isNotEmpty) 'zone_id': zoneId,
        'store_slug': widget.store.slug,
        'category': slug,
        if (_maxPrice > 0) 'price_max': _maxPrice,
      };

     final response = await AppConstant.apiBaseHelper.getAPICall(ApiRoutes.storeProductsApi, query);
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final rawList = data['data']['data'] as List<dynamic>? ?? [];
        setState(() {
          _products = rawList.map((p) => ProductData.fromJson(p as Map<String, dynamic>)).toList();
          _isLoadingProducts = false;
        });
      } else {
        setState(() { _isLoadingProducts = false; _error = data['message'] ?? 'No products'; });
      }
    } catch (e) {
      setState(() { _isLoadingProducts = false; _error = e.toString(); });
    }
  }

  void _showSortSheet() {
    CustomSortBottomSheet.show(
      context: context,
      currentSortType: SortOption.getSortOptionByType(
        SortType.values.firstWhere((t) => t.name == _currentSort, orElse: () => SortType.relevance),
      ).type,
      onSortSelected: (SortOption option) {
        setState(() => _currentSort = option.type.name);
        if (_selectedCategory != null) _fetchProducts(_selectedCategory!.slug ?? '');
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Price Filter', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            Slider(
              value: _maxPrice,
              min: 0, max: 2000,
              divisions: 40,
              label: _maxPrice == 0 ? 'All prices' : '₹${_maxPrice.round()}',
              onChanged: (v) => setModalState(() => _maxPrice = v),
            ),
            Text(_maxPrice == 0 ? 'Showing all prices' : 'Up to ₹${_maxPrice.round()}', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            SizedBox(height: 24.h),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { setModalState(() => _maxPrice = 0); },
                  child: const Text('Clear'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 14.h)),
                  onPressed: () { Navigator.pop(ctx); if (_selectedCategory != null) _fetchProducts(_selectedCategory!.slug ?? ''); },
                  child: const Text('Apply'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        titleSpacing: 0,
        title: Row(children: [
          if (widget.store.logo?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: CustomImageContainer(imagePath: widget.store.logo!, width: 32.w, height: 32.w, fit: BoxFit.cover),
              ),
            ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.store.name ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (widget.store.distance != null && widget.store.distance! > 0)
                Text('${widget.store.distance!.toStringAsFixed(1)} km', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500)),
            ]),
          ),
        ]),
      ),
      body: _isLoadingCategories
          ? _buildShimmer()
          : _categories.isEmpty
              ? Center(child: Text(_error ?? 'No categories available', style: TextStyle(color: Colors.grey)))
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildCategoryPanel(),
                  Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                  Expanded(child: _buildProductPanel()),
                ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(children: List.generate(6, (i) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(height: 40.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r))),
        ))),
      ),
    );
  }

  Widget _buildCategoryPanel() {
    return SizedBox(
      width: 100.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView.builder(
          padding: EdgeInsets.only(top: 8.h),
          itemCount: _categories.length,
          itemBuilder: (context, i) {
            final cat = _categories[i];
            final isSelected = _selectedCategory?.slug == cat.slug;
            return GestureDetector(
              onTap: () => _selectCategory(cat),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                color: isSelected ? Colors.white : null,
                child: Column(children: [
                  Container(
                    width: 44.w, height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200, width: isSelected ? 1.5 : 0.5),
                    ),
                    padding: EdgeInsets.all(6.w),
                    child: CustomImageContainer(imagePath: cat.image ?? '', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 4.h),
                  Text(cat.title ?? '', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9.sp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFF1565C0) : Colors.black87),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  if (cat.productCount != null && cat.productCount! > 0)
                    Text('${cat.productCount}', style: TextStyle(fontSize: 8.sp, color: Colors.grey.shade400)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductPanel() {
    return Column(children: [
      // Header with sort & filter
      Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
        color: Colors.white,
        child: Row(children: [
          Text(_selectedCategory?.title ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
          SizedBox(width: 8.w),
          Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
          SizedBox(width: 8.w),
          InkWell(onTap: _showSortSheet,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6.r)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.swap_vert, size: 14.sp, color: const Color(0xFF1565C0)),
                SizedBox(width: 4.w),
                Text('Sort', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          SizedBox(width: 6.w),
          InkWell(onTap: _showFilterSheet,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6.r)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune, size: 14.sp, color: const Color(0xFF1565C0)),
                SizedBox(width: 4.w),
                Text('Filter', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
      // Products grid
      Expanded(
        child: _isLoadingProducts
            ? const Center(child: CustomCircularProgressIndicator())
            : _products.isEmpty
                ? Center(child: Text(_error ?? 'No products', style: TextStyle(fontSize: 13.sp, color: Colors.grey)))
                : CustomRefreshIndicator(
                    onRefresh: () => _fetchProducts(_selectedCategory?.slug ?? ''),
                    child: GridView.builder(
                      padding: EdgeInsets.all(10.w),
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
      ),
    ]);
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
