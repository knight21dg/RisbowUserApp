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
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/constant.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_scaffold.dart';

class CategoryStoresPage extends StatefulWidget {
  final String categorySlug;
  final String? categoryTitle;

  const CategoryStoresPage({
    super.key,
    required this.categorySlug,
    this.categoryTitle,
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
      setState(() {
        _subcategories = categories;
        _isLoadingSubcategories = false;
      });
      if (categories.isNotEmpty && _selectedSubcategory == null) {
        _selectSubcategory(categories.first);
      } else if (categories.isEmpty && _selectedSubcategory == null) {
        // Leaf category with no subcategories - fetch stores for parent directly
        _fetchStoresForSlug(widget.categorySlug);
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
    final slug = _selectedSubcategory?.slug;
    if (slug == null && _stores.isEmpty) return;
    setState(() => _isLoadingStores = true);
    try {
      final response = await _storeRepo.getNearByStores(
        page: 1,
        perPage: 15,
        searchQuery: _searchQuery,
        category: slug ?? widget.categorySlug,
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
    final slug = _selectedSubcategory?.slug;
    if (_isLoadingMoreStores || !_hasMoreStores || (slug == null && _stores.isEmpty)) return;
    _isLoadingMoreStores = true;
    _storePage++;
    try {
      final response = await _storeRepo.getNearByStores(
        page: _storePage,
        perPage: 15,
        searchQuery: _searchQuery,
        category: slug ?? widget.categorySlug,
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
                onChanged: (v) => setModalState(() => _radiusKm = v),
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

  Widget _buildSubcategoryPanel() {
    return SizedBox(
      width: 100.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _subcategories.length,
          itemBuilder: (context, i) {
            final sub = _subcategories[i];
            final isSelected = _selectedSubcategory?.slug == sub.slug;
            return GestureDetector(
              onTap: () => _selectSubcategory(sub),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                color: isSelected ? Colors.white : null,
                child: Column(children: [
                  Container(
                    width: 44.w, height: 44.w,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.grey.shade200, width: 0.5)),
                    padding: EdgeInsets.all(6.w),
                    child: CustomImageContainer(imagePath: sub.image ?? '', fit: BoxFit.contain),
                  ),
                  SizedBox(height: 4.h),
                  Text(sub.title ?? '', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.sp, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? const Color(0xFF1565C0) : Colors.black87),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStorePanel() {
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
          : _stores.isEmpty
              ? Center(child: Text(_storeError ?? 'No stores found', style: TextStyle(fontSize: 13.sp, color: Colors.grey)))
              : CustomRefreshIndicator(
                  onRefresh: _fetchStores,
                  child: ListView.builder(
                    controller: _storeScrollController,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    itemCount: _stores.length + (_isLoadingMoreStores ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _stores.length) return const Center(child: Padding(padding: EdgeInsets.all(8), child: CustomCircularProgressIndicator()));
                      return _StoreCard(store: _stores[i], onTap: () {
                        GoRouter.of(context).push(
                          AppRoutes.categoryStoreProducts,
                          extra: {'store': _stores[i], 'categorySlug': _selectedSubcategory?.slug ?? widget.categorySlug},
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

  const _StoreCard({required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    final distance = store.distance ?? 0.0;
    final rating = double.tryParse(store.avgProductsRating ?? '0.0') ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Store image
          Container(
            width: 100.w, height: 120.h,
            color: Colors.grey.shade100,
            child: store.logo?.isNotEmpty == true
                ? CustomImageContainer(imagePath: store.logo!, fit: BoxFit.cover)
                : Icon(Icons.store_outlined, size: 30, color: Colors.grey.shade300),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(store.name ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 2.h),
                if (store.address?.isNotEmpty == true)
                  Text(store.address!, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4.h),
                Row(children: [
                  Icon(Icons.star, size: 14.sp, color: AppTheme.ratingStarColor),
                  SizedBox(width: 2.w),
                  Text('${rating.toStringAsFixed(1)}/5', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                  SizedBox(width: 10.w),
                  Icon(Icons.location_on, size: 14.sp, color: Colors.grey),
                  SizedBox(width: 2.w),
                  Text(distance > 0 ? '${distance.toStringAsFixed(1)} km' : '-', style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500)),
                ]),
                SizedBox(height: 4.h),
                Row(children: [
                  if (store.status?.isOpen == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4.r)),
                      child: Text('OPEN', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4.r)),
                      child: Text('CLOSED', style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  if (store.status?.isOpen == true)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4.r)),
                      child: Text('OPEN', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4.r)),
                      child: Text('CLOSED', style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
