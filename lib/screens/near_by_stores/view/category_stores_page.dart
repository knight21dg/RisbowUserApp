import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/model/sub_category_model.dart';
import 'package:hyper_local/screens/home_page/repo/sub_category_repo.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/near_by_stores/repo/near_by_store_repo.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/constant.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_scaffold.dart';

class CategoryStoresPage extends StatefulWidget {
  final String categorySlug;
  final String? categoryTitle;
  final String? selectedSubcategorySlug;

  const CategoryStoresPage({
    super.key,
    required this.categorySlug,
    this.categoryTitle,
    this.selectedSubcategorySlug,
  });

  @override
  State<CategoryStoresPage> createState() => _CategoryStoresPageState();
}

class _CategoryStoresPageState extends State<CategoryStoresPage> {
  final SubCategoryRepository _subRepo = SubCategoryRepository();
  final NearByStoreRepo _storeRepo = NearByStoreRepo();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _storeScrollController = ScrollController();
  Timer? _debounceTimer;

  List<SubCategoryData> _subcategories = [];
  SubCategoryData? _selectedSubcategory;
  List<StoreData> _stores = [];
  bool _isLoadingSubcategories = true;
  bool _isLoadingStores = false;
  String? _subError;
  String? _storeError;
  String _searchQuery = '';
  bool _isLoadingMoreStores = false;
  bool _hasMoreStores = true;
  int _storePage = 1;
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _storeScrollController.addListener(_onStoreScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _storeScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubcategories() async {
    try {
      final response = await _subRepo.fetchSubCategory(
        slug: widget.categorySlug,
        isForAllCategory: false,
        isHome: false,
        perPage: 100,
      );
      final rawData = response['data'];
      final List<dynamic> data;
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map) {
        data = (rawData['data'] as List<dynamic>?) ?? [];
      } else {
        data = [];
      }
      final categories = data.map((d) => SubCategoryData.fromJson(d as Map<String, dynamic>)).toList();
      
      // Create "All" tab at the beginning
      final allTab = SubCategoryData(
        id: -1,
        title: 'All',
        slug: '',
        image: null,
      );
      final allCategories = [allTab, ...categories];
      
      setState(() {
        _subcategories = allCategories;
        _isLoadingSubcategories = false;
      });
      // Auto-select based on selectedSubcategorySlug or first/all
      if (allCategories.isNotEmpty && _selectedSubcategory == null) {
        if (widget.selectedSubcategorySlug != null) {
          final match = allCategories.cast<SubCategoryData?>().firstWhere(
            (s) => s?.slug == widget.selectedSubcategorySlug,
            orElse: () => null,
          );
          if (match != null) {
            _selectSubcategory(match);
          } else {
            // No match - select All to show all stores
            _selectSubcategory(allCategories.first);
          }
        } else {
          // No specific sub - select All to show all stores
          _selectSubcategory(allCategories.first);
        }
      }
    } catch (e) {
      setState(() {
        _subError = e.toString();
        _isLoadingSubcategories = false;
      });
    }
  }

  void _selectSubcategory(SubCategoryData sub) {
    setState(() {
      _selectedSubcategory = sub;
      _stores = [];
      _storePage = 1;
      _hasMoreStores = true;
      _storeError = null;
    });
    _fetchStores();
  }

  void _fetchStoresForSlug(String slug) {
    setState(() {
      _stores = [];
      _storePage = 1;
      _hasMoreStores = true;
      _storeError = null;
    });
    _fetchStoresWithSlug(slug);
  }

  Future<void> _fetchStoresWithSlug(String slug) async {
    setState(() => _isLoadingStores = true);
    try {
      final response = await _storeRepo.getNearByStores(
        page: 1, perPage: 15, searchQuery: _searchQuery, category: slug,
      );
      if (response != null) {
        final model = NearByStoreModel.fromJson(response);
        if (model.success == true && model.data != null) {
          setState(() {
            _stores = model.data!.data ?? [];
            _hasMoreStores = (_stores.length >= 15);
            _isLoadingStores = false;
          });
        } else {
          setState(() { _stores = []; _isLoadingStores = false; _storeError = model.message; });
        }
      } else {
        setState(() { _stores = []; _isLoadingStores = false; _storeError = 'Failed to load stores'; });
      }
    } catch (e) {
      setState(() { _isLoadingStores = false; _storeError = e.toString(); });
    }
  }

  Future<void> _fetchStores() async {
    final String? slug = _selectedSubcategory?.slug;
    // For "All" tab (slug is empty string), use parent category slug
    final categoryToUse = (slug == null || slug.isEmpty) ? widget.categorySlug : slug;
    setState(() => _isLoadingStores = true);
    try {
      final response = await _storeRepo.getNearByStores(
        page: 1,
        perPage: 15,
        searchQuery: _searchQuery,
        category: categoryToUse,
      );
      if (response != null) {
        final model = NearByStoreModel.fromJson(response);
        if (model.success == true && model.data != null) {
          setState(() {
            _stores = model.data!.data ?? [];
            _hasMoreStores = (_stores.length >= 15);
            _isLoadingStores = false;
          });
        } else {
          setState(() { _stores = []; _isLoadingStores = false; _storeError = model.message; });
        }
      } else {
        setState(() { _stores = []; _isLoadingStores = false; _storeError = 'Failed to load stores'; });
      }
    } catch (e) {
      setState(() { _isLoadingStores = false; _storeError = e.toString(); });
    }
  }

  Future<void> _loadMoreStores() async {
    final String? slug = _selectedSubcategory?.slug;
    // For "All" tab (slug is empty string), use parent category slug
    final categoryToUse = (slug == null || slug.isEmpty) ? widget.categorySlug : slug;
    if (_isLoadingMoreStores || !_hasMoreStores || _stores.isEmpty) return;
    _isLoadingMoreStores = true;
    _storePage++;
    try {
      final response = await _storeRepo.getNearByStores(
        page: _storePage,
        perPage: 15,
        searchQuery: _searchQuery,
        category: categoryToUse,
      );
      if (response != null) {
        final model = NearByStoreModel.fromJson(response);
        if (model.success == true && model.data?.data != null) {
          setState(() {
            for (final s in model.data!.data!) {
              if (!_stores.any((e) => e.id == s.id)) _stores.add(s);
            }
            _hasMoreStores = (model.data!.data!.length >= 15);
          });
        } else {
          _hasMoreStores = false;
        }
      }
    } catch (_) {
      _storePage--;
    }
    _isLoadingMoreStores = false;
  }

  void _onStoreScroll() {
    if (_storeScrollController.position.pixels >= _storeScrollController.position.maxScrollExtent - 200) {
      _loadMoreStores();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
      _fetchStores();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Filter by Distance', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ]),
            SizedBox(height: 8.h),
            Text('${_radiusKm.round()} km radius', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
            SizedBox(height: 8.h),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF1565C0),
                inactiveTrackColor: const Color(0xFF1565C0).withValues(alpha: 0.2),
                thumbColor: const Color(0xFF1565C0),
                overlayColor: const Color(0xFF1565C0).withValues(alpha: 0.12),
                valueIndicatorColor: const Color(0xFF1565C0),
                valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              child: Slider(
                value: _radiusKm,
                min: 1, max: 50,
                divisions: 49,
                label: '${_radiusKm.round()} km',
                onChanged: (v) {
                  setModalState(() {
                    _radiusKm = v;
                  });
                  setState(() {
                    _radiusKm = v;
                  });
                },
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 0,
                ),
                onPressed: () { Navigator.pop(ctx); _fetchStores(); },
                child: Text('Apply Filter', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(widget.categoryTitle ?? AppLocalizations.of(context)?.nearbyStores ?? 'Nearby Stores', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
          actions: [
            IconButton(icon: const Icon(Icons.tune), onPressed: _showFilterSheet),
          ],
        ),
        body: _isLoadingSubcategories
            ? _buildShimmer()
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_subcategories.isNotEmpty) ...[
                  _buildSubcategoryPanel(),
                  Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ],
                Expanded(child: _buildStorePanel()),
              ]),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
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
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              itemCount: 4,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
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
        child: ListView.builder(
          itemCount: _subcategories.length,
          itemBuilder: (context, i) {
            final sub = _subcategories[i];
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
                    // Category image with scale animation
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: isTablet(context) ? 75.w : 60.w,
                        height: isTablet(context) ? 75.w : 60.w,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        padding: EdgeInsets.all(isSelected ? 2.w : 4.w),
                        child: sub.id == -1
                            ? Image.asset(
                                'assets/images/app_logos/app-logo-light.png',
                                fit: BoxFit.contain,
                              )
                            : (sub.image ?? '').trim().isNotEmpty
                                ? CustomImageContainer(
                                    imagePath: sub.image ?? '',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    fallbackAsset: 'assets/images/placeholder.png',
                                  )
                                : Center(
                                    child: Text(
                                      (sub.title ?? '').isNotEmpty ? sub.title![0].toUpperCase() : '',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Category title - single line with ellipsis
                    Text(
                      sub.title ?? '',
                      style: TextStyle(
                        fontSize: isTablet(context) ? 11 : 9.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.black87,
                        fontFamily: AppTheme.fontFamily,
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
    );
  }

  Widget _buildStorePanel() {
    final filteredStores = _stores.where((store) => (store.distance ?? 0) <= _radiusKm).toList();

    return Column(children: [
      // Search bar
      Padding(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
        child: SizedBox(
          height: 40.h,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)?.search ?? 'Search stores...',
              hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
              prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: Icon(Icons.clear, size: 18.sp), onPressed: () { _searchController.clear(); _onSearchChanged(''); })
                  : null,
              filled: true, fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
      // Stores list
      Expanded(child: _isLoadingStores
          ? const Center(child: CustomCircularProgressIndicator())
          : filteredStores.isEmpty
              ? Center(child: Text(_stores.isEmpty ? (_storeError ?? 'No stores found') : 'No stores found within ${_radiusKm.round()} km', style: TextStyle(fontSize: 13.sp, color: Colors.grey)))
              : CustomRefreshIndicator(
                  onRefresh: _fetchStores,
                  child: ListView.builder(
                    controller: _storeScrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    itemCount: filteredStores.length + (_isLoadingMoreStores ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == filteredStores.length) return const Center(child: Padding(padding: EdgeInsets.all(8), child: CustomCircularProgressIndicator()));
                      return _StoreCard(store: filteredStores[i], onTap: () {
                        GoRouter.of(context).push(
                          AppRoutes.categoryStoreProducts,
                          extra: {
                            'store': filteredStores[i],
                            'categorySlug': _selectedSubcategory?.slug ?? widget.categorySlug,
                            'parentCategorySlug': _selectedSubcategory != null ? widget.categorySlug : null,
                          },
                        );
                      }, onStoreDetailTap: () {
                        GoRouter.of(context).push(
                          AppRoutes.nearbyStoreDetails,
                          extra: {
                            'store-slug': filteredStores[i].slug,
                            'store-name': filteredStores[i].name,
                          },
                        );
                      });
                    },
                  ),
                ),
      ),
    ]);
  }
}

class _StoreCard extends StatelessWidget {
  final StoreData store;
  final VoidCallback? onTap;
  final VoidCallback? onStoreDetailTap;

  const _StoreCard({required this.store, this.onTap, this.onStoreDetailTap});

  @override
  Widget build(BuildContext context) {
    final distance = store.distance ?? 0.0;
    final rating = double.tryParse(store.avgProductsRating ?? '0.0') ?? 0.0;
    final isOpen = store.status?.isOpen == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 48.w, height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: store.logo?.isNotEmpty == true
                    ? CustomImageContainer(imagePath: store.logo!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          (store.name ?? '').isNotEmpty ? store.name![0].toUpperCase() : 'S',
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                        ),
                      ),
              ),
              SizedBox(width: 12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(store.name ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: isOpen ? Colors.green.shade700 : Colors.red.shade500),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    if (store.address?.isNotEmpty == true)
                      Text(store.address!, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.star, size: 13.sp, color: AppTheme.ratingStarColor),
                        SizedBox(width: 2.w),
                        Text('${rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                        SizedBox(width: 12.w),
                        Icon(Icons.location_on, size: 13.sp, color: Colors.blue.shade300),
                        SizedBox(width: 2.w),
                        Text(distance > 0 ? '${distance.toStringAsFixed(1)} km' : '-', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
                        const Spacer(),
                        if (onStoreDetailTap != null)
                          IconButton(
                            icon: Icon(Icons.store, size: 18.sp, color: Theme.of(context).colorScheme.primary),
                            onPressed: onStoreDetailTap,
                            tooltip: 'View Store Details',
                            constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.w),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
