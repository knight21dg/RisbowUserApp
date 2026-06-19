import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/home_page/model/sub_category_model.dart';
import 'package:hyper_local/screens/home_page/repo/sub_category_repo.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_sorting_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/custom_variant_selector_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/constant.dart';
import '../../../config/api_routes.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../services/location/location_service.dart';

class CategoryStoreProductsPage extends StatefulWidget {
  final StoreData store;
  final String categorySlug;
  final String? parentCategorySlug;

  const CategoryStoreProductsPage({
    super.key,
    required this.store,
    required this.categorySlug,
    this.parentCategorySlug,
  });

  @override
  State<CategoryStoreProductsPage> createState() =>
      _CategoryStoreProductsPageState();
}

class _CategoryStoreProductsPageState extends State<CategoryStoreProductsPage> {
  final SubCategoryRepository _subRepo = SubCategoryRepository();

  List<SubCategoryData> _subCategories = [];
  SubCategoryData? _selectedSubcategory;
  List<ProductData> _products = [];
  bool _isLoadingSubs = true;
  bool _isLoadingProducts = false;
  String? _error;
  String _currentSort = 'relevance';
  double _maxPrice = 0;
  String _parentTitle = '';
  String _parentSlug = '';

  @override
  void initState() {
    super.initState();
    _fetchParentAndSubs();
  }

  Future<void> _fetchParentAndSubs() async {
    try {
      // Determine if we're in a subcategory context or parent category context
      final bool isSubcategoryContext =
          widget.parentCategorySlug != null &&
          widget.parentCategorySlug!.isNotEmpty;

      // When parentCategorySlug is provided, use it as the parent; otherwise categorySlug is the parent
      String parentSlug = isSubcategoryContext
          ? widget.parentCategorySlug!
          : widget.categorySlug;
      String parentTitle = isSubcategoryContext
          ? widget.parentCategorySlug!
          : widget.categorySlug;

      // Try to get parent category title from parent categories API
      if (isSubcategoryContext) {
        parentTitle = await _getParentCategoryTitle(parentSlug);
      } else {
        // For parent category context, try to use store categories to infer title
        if (widget.store.categories != null &&
            widget.store.categories!.isNotEmpty) {
          // Categories in store response have parent_id, we can check if any match our slug
          final match = widget.store.categories!
              .cast<StoreCategoryData?>()
              .firstWhere(
                (c) => c?.slug == widget.categorySlug,
                orElse: () => null,
              );
          if (match != null) {
            parentTitle = match.title ?? widget.categorySlug;
          }
        }
      }
      setState(() {
        _parentSlug = parentSlug;
        _parentTitle = parentTitle;
      });

      // Fetch subcategories of the parent
      final response = await _subRepo.fetchSubCategory(
        slug: parentSlug,
        isForAllCategory: false,
        perPage: 50,
        storeSlug: widget.store.slug,
      );
      final rawData = response['data'];

      // Try to get parent category title from API response (new field)
      if (rawData is Map && rawData['parent_category_title'] != null) {
        parentTitle = rawData['parent_category_title'] as String;
      }

      List<dynamic> data = [];
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map && rawData['data'] != null) {
        data = rawData['data'] as List<dynamic>;
      }

      setState(() {
        _subCategories = data
            .map((e) => SubCategoryData.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoadingSubs = false;
      });

      // If in subcategory context, auto-select the incoming category slug
      if (isSubcategoryContext) {
        final match = _subCategories.cast<SubCategoryData?>().firstWhere(
          (s) => s?.slug == widget.categorySlug,
          orElse: () => null,
        );
        if (match != null) {
          _selectSubcategory(match);
        } else if (_subCategories.isNotEmpty) {
          // No matching subcategory, auto-select first available
          _selectSubcategory(_subCategories.first);
        } else {
          // No subcategories - load products for the category itself
          _fetchProducts(widget.categorySlug);
        }
      } else {
        // Parent category context - auto-select first subcategory if available
        if (_subCategories.isNotEmpty) {
          _selectSubcategory(_subCategories.first);
        } else {
          _fetchProducts(parentSlug);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingSubs = false;
        _error = e.toString();
      });
      // On error, load products with parent slug (already set in state)
      _fetchProducts(_parentSlug);
    }
  }

  Future<String> _getParentCategoryTitle(String parentSlug) async {
    try {
      // Try to read parent_category_title from subcategories response (new API field)
      final response = await _subRepo.fetchSubCategory(
        slug: parentSlug,
        isForAllCategory: false,
        perPage: 1,
        storeSlug: widget.store.slug,
      );
      final rawData = response['data'];

      // Check for the new parent_category_title field
      if (rawData is Map && rawData['parent_category_title'] != null) {
        return rawData['parent_category_title'] as String;
      }

      // Fallback: check if response contains parent info in items
      if (rawData is Map &&
          rawData['data'] is List &&
          (rawData['data'] as List).isNotEmpty) {
        final firstItem =
            (rawData['data'] as List).first as Map<String, dynamic>;
        final parentId = firstItem['parent_id'];
        if (parentId != null) {
          final allCatsResponse = await _subRepo.fetchSubCategory(
            slug: '',
            isForAllCategory: true,
            perPage: 100,
          );
          final allData = allCatsResponse['data'];
          if (allData is Map && allData['data'] is List) {
            final categories = allData['data'] as List<dynamic>;
            for (final item in categories) {
              if (item is Map<String, dynamic> && item['id'] == parentId) {
                return item['title'] ?? parentSlug;
              }
            }
          }
        }
      }
      return parentSlug;
    } catch (_) {
      return parentSlug;
    }
  }

  void _selectSubcategory(SubCategoryData sub) {
    setState(() {
      _selectedSubcategory = sub;
      _products = [];
      _error = null;
    });
    _fetchProducts(sub.slug ?? '');
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
        'per_page': 50,
        'page': 1,
        'latitude': latitude,
        'longitude': longitude,
        'sort': _currentSort,
        if (zoneId != null && zoneId.isNotEmpty) 'zone_id': zoneId,
        'store_slug': widget.store.slug,
        if (slug.isNotEmpty) 'category': slug,
        if (_maxPrice > 0) 'price_max': _maxPrice,
      };

      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.storeProductsApi,
        query,
      );
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final rawList = data['data']['data'] as List<dynamic>? ?? [];
        setState(() {
          _products = rawList
              .map((p) => ProductData.fromJson(p as Map<String, dynamic>))
              .toList();
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _isLoadingProducts = false;
          _error = data['message'] ?? 'No products';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _error = e.toString();
      });
    }
  }

  void _showSortSheet() {
    CustomSortBottomSheet.show(
      context: context,
      currentSortType: SortOption.getSortOptionByType(
        SortType.values.firstWhere(
          (t) => t.name == _currentSort,
          orElse: () => SortType.relevance,
        ),
      ).type,
      onSortSelected: (SortOption option) {
        setState(() => _currentSort = option.type.name);
        if (_selectedSubcategory != null) {
          _fetchProducts(_selectedSubcategory!.slug ?? '');
        }
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price Filter',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                _maxPrice == 0
                    ? 'Showing all prices'
                    : 'Up to \u20B9${_maxPrice.round()}',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 8.h),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF1565C0),
                  inactiveTrackColor: const Color(
                    0xFF1565C0,
                  ).withValues(alpha: 0.2),
                  thumbColor: const Color(0xFF1565C0),
                  overlayColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                  valueIndicatorColor: const Color(0xFF1565C0),
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                child: Slider(
                  value: _maxPrice,
                  min: 0,
                  max: 2000,
                  divisions: 40,
                  label: _maxPrice == 0 ? 'All' : '\u20B9${_maxPrice.round()}',
                  onChanged: (v) {
                    setModalState(() {
                      _maxPrice = v;
                    });
                    setState(() {
                      _maxPrice = v;
                    });
                  },
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: () {
                          setModalState(() {
                            _maxPrice = 0;
                          });
                          setState(() {
                            _maxPrice = 0;
                          });
                          Navigator.pop(ctx);
                          _fetchProducts(_selectedSubcategory?.slug ?? '');
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 44.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _fetchProducts(_selectedSubcategory?.slug ?? '');
                        },
                        child: Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        title: Row(
          children: [
            if (widget.store.logo?.isNotEmpty == true)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: CustomImageContainer(
                    imagePath: widget.store.logo!,
                    width: 32.w,
                    height: 32.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.w,
                    runSpacing: 2.h,
                    children: [
                      Text(
                        widget.store.name ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                        child: Text(
                          _parentTitle,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: const Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoadingSubs
          ? _buildShimmer()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubcategoryPanel(),
                Container(width: 1, color: Colors.grey.shade200),
                Expanded(child: _buildProductPanel()),
              ],
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90.w,
            color: Colors.white,
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                child: Column(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
                    ),
                    SizedBox(height: 8.h),
                    Container(height: 10.h, width: 40.w, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.white),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Container(height: 20.h, width: 100.w, color: Colors.white),
                      const Spacer(),
                      Container(height: 30.h, width: 60.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r))),
                      SizedBox(width: 10.w),
                      Container(height: 30.h, width: 60.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r))),
                    ],
                  ),
                ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(10.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 0.52,
              ),
              itemCount: 4,
              itemBuilder: (context, i) => Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryPanel() {
    return SizedBox(
      width: 90.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_parentTitle.isNotEmpty)
              Container(
                padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 8.h),
                alignment: Alignment.center,
                child: Text(
                  _parentTitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _subCategories.length,
                itemBuilder: (context, i) {
                  final sub = _subCategories[i];
                  final isSelected = _selectedSubcategory?.slug == sub.slug;
                  return GestureDetector(
                    onTap: () => _selectSubcategory(sub),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        border: isSelected 
                            ? Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4))
                            : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                          color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          padding: EdgeInsets.all(isSelected ? 2.w : 4.w),
                          child: (sub.image ?? '').trim().isNotEmpty
                              ? CustomImageContainer(
                                  imagePath: sub.image ?? '',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.contain,
                                  fallbackAsset:
                                      'assets/images/placeholder.png',
                                )
                              : Center(
                                  child: Text(
                                    (sub.title ?? '').isNotEmpty
                                        ? sub.title![0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.blue.shade700
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        sub.title ?? '',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        _buildSortHeader(),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildSortHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedSubcategory?.title ?? 'All Products',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              InkWell(
                onTap: _showSortSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_vert,
                        size: 16.sp,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              InkWell(
                onTap: _showFilterSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16.sp,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return _isLoadingProducts
        ? const Center(child: CustomCircularProgressIndicator())
        : _products.isEmpty
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_logos/app-logo-light.png',
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _selectedSubcategory == null
                        ? 'Select a category'
                        : (_error ?? 'No products found'),
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : CustomRefreshIndicator(
            onRefresh: () => _fetchProducts(_selectedSubcategory?.slug ?? ''),
            child: GridView.builder(
              padding: EdgeInsets.all(10.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 0.52,
              ),
              itemCount: _products.length,
              itemBuilder: (context, i) => _buildProductCard(_products[i]),
            ),
          );
  }

  Widget _buildProductCard(ProductData product) {
    final variant = product.variants.isNotEmpty ? product.variants.first : null;
    final price = (variant?.price.toDouble() ?? product.price).toString();
    final specialPrice =
        (variant?.specialPrice.toDouble() ?? product.specialPrice).toString();

    return CustomProductCard(
      productId: product.id,
      productImage: product.mainImage.isNotEmpty
          ? product.mainImage
          : 'assets/images/placeholder.png',
      productName: product.title,
      productSlug: product.slug,
      storeSlug: widget.store.slug ?? '',
      productPrice: price,
      specialPrice: specialPrice,
      productTags: [],
      estimatedDeliveryTime: product.estimatedDeliveryTime,
      ratings: product.ratings?.toDouble() ?? 0.0,
      ratingCount: product.ratingCount,
      onTap: () => GoRouter.of(context).push(
        '/product-detail?slug=${product.slug}&store=${widget.store.slug ?? ''}',
      ),
      isStoreOpen: true,
      isWishListed: false,
      productVariantId: variant?.id ?? 0,
      storeId: widget.store.id ?? 0,
      wishlistItemId: 0,
      totalStocks: variant?.stock ?? product.stock,
      imageFit: product.imageFit.isNotEmpty ? product.imageFit : 'cover',
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
      variantCount: product.variants.length,
      onVariantSelectorRequested: product.variants.length > 1
          ? () => showVariantBottomSheet(
              variantsList: product.variants,
              productData: product,
              productImage: product.mainImage,
              quantityStepSize: product.quantityStepSize,
              context: context,
            )
          : null,
      onAddToCart: () => _handleAddToCart(product),
    );
  }

  void _handleAddToCart(ProductData product) {
    final storeId = widget.store.id ?? 0;
    if (product.variants.isEmpty) {
      final price = product.price > 0 ? product.price : 0.0;
      final specialPrice = product.specialPrice > 0
          ? product.specialPrice
          : price;
      final stock = product.stock > 0 ? product.stock : 100;
      final isAvailable = product.available && product.stock > 0;
      if (!isAvailable) return;
      final item = UserCart(
        productId: product.id.toString(),
        variantId: '0',
        variantName: 'Default',
        vendorId: storeId.toString(),
        name: product.title,
        image: product.mainImage,
        price: specialPrice > 0 ? specialPrice : price,
        originalPrice: price,
        quantity: 1,
        serverCartItemId: null,
        syncAction: CartSyncAction.add,
        updatedAt: DateTime.now(),
        minQty: 1,
        maxQty: stock,
        isOutOfStock: false,
        isSynced: false,
      );
      context.read<CartBloc>().add(AddToCart(item, context));
      return;
    }
    if (product.variants.length > 1) {
      showVariantBottomSheet(
        variantsList: product.variants,
        productData: product,
        productImage: product.mainImage,
        quantityStepSize: product.quantityStepSize,
        context: context,
      );
    } else {
      final defaultVariant = product.variants.first;
      final item = UserCart(
        productId: product.id.toString(),
        variantId: defaultVariant.id.toString(),
        variantName: defaultVariant.title.toString(),
        vendorId: storeId.toString(),
        name: product.title,
        image: product.mainImage,
        price: defaultVariant.specialPrice.toDouble(),
        originalPrice: defaultVariant.price.toDouble(),
        quantity: product.quantityStepSize,
        serverCartItemId: null,
        syncAction: CartSyncAction.add,
        updatedAt: DateTime.now(),
        minQty: product.minimumOrderQuantity,
        maxQty: product.totalAllowedQuantity,
        isOutOfStock: defaultVariant.stock <= 0,
        isSynced: false,
      );
      context.read<CartBloc>().add(AddToCart(item, context));
    }
  }
}
