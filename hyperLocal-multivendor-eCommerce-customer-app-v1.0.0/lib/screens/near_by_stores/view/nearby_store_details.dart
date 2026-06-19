import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/sorting_model/sorting_model.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/near_by_stores/repo/near_by_store_repo.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/product_listing/product_listing_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';
import 'package:hyper_local/screens/product_listing_page/widgets/custom_filter_sort_btn_widget.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_sorting_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/widgets/vendor_ad_banner_strip.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_variant_selector_bottom_sheet.dart';


class NearbyStoreDetails extends StatelessWidget {
  final String storeSlug;
  final String storeName;
  final String? initialCategorySlug;

  const NearbyStoreDetails({
    super.key,
    required this.storeSlug,
    required this.storeName,
    this.initialCategorySlug,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => StoreDetailBloc()
            ..add(FetchStoreDetail(storeSlug: storeSlug)),
        ),
        BlocProvider(
          create: (_) => ProductListingBloc(),
        ),
      ],
      child: _NearbyStoreDetailsView(
        storeSlug: storeSlug,
        storeName: storeName,
        initialCategorySlug: initialCategorySlug,
      ),
    );
  }
}

class _NearbyStoreDetailsView extends StatefulWidget {
  final String storeSlug;
  final String storeName;
  final String? initialCategorySlug;

  const _NearbyStoreDetailsView({
    required this.storeSlug,
    required this.storeName,
    this.initialCategorySlug,
  });

  @override
  State<_NearbyStoreDetailsView> createState() => _NearbyStoreDetailsState();
}

class _NearbyStoreDetailsState extends State<_NearbyStoreDetailsView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool isSearchInStore = false;
  bool isSubmitted = false;
  int _selectedCategoryIndex = 0;
  String _currentCategorySlug = '';
  SortType _currentSortType = SortType.relevance;
  List<StoreCategoryData> _categories = [];
  bool _isLoadingCategories = false;
  bool _hasCategories = false;
  // Guard so we only trigger the initial product load once
  bool _initialProductsLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Trigger initial category + product load once the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerInitialLoad();
    });
  }

  void _triggerInitialLoad() {
    // Only load if StoreDetail is already loaded (fast path)
    final storeState = context.read<StoreDetailBloc>().state;
    if (storeState is StoreDetailLoaded && !_initialProductsLoaded) {
      _initialProductsLoaded = true;
      _handleStoreLoaded(storeState.storeData);
    }
    // Otherwise the BlocListener in _buildBody will call _handleStoreLoaded
  }

  void _handleStoreLoaded(StoreData store) {
    if (store.categories != null && store.categories!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _categories = [
            StoreCategoryData(
              id: -1,
              title: 'All',
              slug: '',
              image: '',
            ),
            ...store.categories!
          ];
          _hasCategories = true;
          _isLoadingCategories = false;
        });
      }
      // If there's an initial category slug, select it; otherwise load all products
      if (widget.initialCategorySlug != null && widget.initialCategorySlug!.isNotEmpty) {
        final matchIndex = _categories.indexWhere((c) => c.slug == widget.initialCategorySlug);
        if (matchIndex >= 0) {
          _onCategorySelected(matchIndex, _categories[matchIndex].slug ?? '', _categories[matchIndex].title ?? '');
        } else {
          _loadProducts();
        }
      } else {
        _loadProducts();
      }
    } else if (store.id != null) {
      _fetchCategories(store.id!).then((_) {
        if (!mounted) return;
        // After categories load, load products (either all or for initial category)
        if (widget.initialCategorySlug != null && widget.initialCategorySlug!.isNotEmpty) {
          final matchIndex = _categories.indexWhere((c) => c.slug == widget.initialCategorySlug);
          if (matchIndex >= 0) {
            _onCategorySelected(matchIndex, _categories[matchIndex].slug ?? '', _categories[matchIndex].title ?? '');
            return;
          }
        }
        _loadProducts(categorySlug: _currentCategorySlug);
      });
    } else {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ProductListingBloc>().state;
      if (state is ProductListingLoaded && !state.hasReachedMax) {
        _loadMoreProducts();
      }
    }
  }

  void _loadMoreProducts() {
    final sortOption = SortOption.getSortOptionByType(_currentSortType);
    context.read<ProductListingBloc>().add(
      FetchMoreListingProducts(
        type: ProductListingType.store,
        storeSlug: widget.storeSlug,
        identifier: _currentCategorySlug,
        sortType: sortOption.apiValue,
        isSearchInStore: isSearchInStore,
      ),
    );
  }

  void _loadProducts({String categorySlug = '', SortType? sortType}) {
    final sortOption = SortOption.getSortOptionByType(sortType ?? _currentSortType);
    context.read<ProductListingBloc>().add(
      FetchListingProducts(
        type: ProductListingType.store,
        storeSlug: widget.storeSlug,
        identifier: categorySlug,
        sortType: sortOption.apiValue,
        isSearchInStore: false,
      ),
    );
  }

  void _applySorting(SortOption sortOption) {
    setState(() {
      _currentSortType = sortOption.type;
    });
    _loadProducts(
      categorySlug: _currentCategorySlug,
      sortType: sortOption.type,
    );
  }

  void _onCategorySelected(int index, String categorySlug, String categoryName) {
    setState(() {
      _selectedCategoryIndex = index;
      _currentCategorySlug = index == 0 ? '' : categorySlug;
    });
    _loadProducts(categorySlug: _currentCategorySlug);
  }

  Future<void> _pickAndUploadBanner(int storeId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        // Show loading toast or indicator
        ToastManager.show(context: context, message: 'Uploading banner...', type: ToastType.info);
        
        await NearByStoreRepo().updateStoreBanner(
          storeId: storeId,
          imagePath: image.path,
        );
        
        ToastManager.show(context: context, message: 'Banner updated successfully', type: ToastType.success);
        
        // Refresh store detail
        if (mounted) {
          context.read<StoreDetailBloc>().add(
            FetchStoreDetail(storeSlug: widget.storeSlug),
          );
        }
      } catch (e) {
        if (mounted) {
          ToastManager.show(context: context, message: 'Failed to update banner: $e', type: ToastType.error);
        }
      }
    }
  }

  void showSortBottomSheet() {
    CustomSortBottomSheet.show(
      context: context,
      currentSortType: _currentSortType,
      onSortSelected: (SortOption selectedSort) {
        _applySorting(selectedSort);
      },
    );
  }

  void doSearch() {
    final query = _searchController.text.trim();
    final sortOption = SortOption.getSortOptionByType(_currentSortType);
    setState(() {
      isSearchInStore = query.isNotEmpty;
      isSubmitted = query.isNotEmpty;
    });
    context.read<ProductListingBloc>().add(
      FetchListingProducts(
        type: ProductListingType.store,
        storeSlug: widget.storeSlug,
        identifier: query,
        sortType: sortOption.apiValue,
        isSearchInStore: isSearchInStore,
      ),
    );
  }

  Future<void> _fetchCategories(int storeId) async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = true;
      });
    });
    debugPrint('STORE PAGE: _fetchCategories called for storeId=$storeId');
    try {
      final response = await ApiBaseHelper().getAPICall(
        '${ApiRoutes.categoryApi}?per_page=50&store_id=$storeId',
        {},
      );
      final data = response.data as Map<String, dynamic>?;
      debugPrint('STORE PAGE: _fetchCategories response data=$data');
      if (data != null && data['data'] != null) {
        final rawData = data['data'];
        List<dynamic> rawList = [];
        if (rawData is List) {
          rawList = rawData;
        } else if (rawData is Map<String, dynamic> && rawData['data'] != null) {
          rawList = rawData['data'] as List<dynamic>;
        }
        setState(() {
          _categories = [
            StoreCategoryData(
              id: -1,
              title: 'All',
              slug: '',
              image: '',
            ),
            ...rawList.map((c) => StoreCategoryData.fromJson(c as Map<String, dynamic>))
          ];
          _hasCategories = _categories.isNotEmpty;
          _isLoadingCategories = false;
        });
        // Auto-select initial category if provided
        if (widget.initialCategorySlug != null && widget.initialCategorySlug!.isNotEmpty && _categories.isNotEmpty) {
          final matchIndex = _categories.indexWhere((c) => c.slug == widget.initialCategorySlug);
          if (matchIndex >= 0) {
            _onCategorySelected(matchIndex, _categories[matchIndex].slug ?? '', _categories[matchIndex].title ?? '');
          }
        }
        debugPrint('STORE PAGE: _fetchCategories got ${_categories.length} categories');
      } else {
        setState(() {
          _isLoadingCategories = false;
          _hasCategories = false;
        });
      }
    } catch (e) {
      debugPrint('STORE PAGE: _fetchCategories error=$e');
      setState(() {
        _isLoadingCategories = false;
        _hasCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        elevation: 0,
        title: _buildSearchBar(),
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDarkMode(context) ? Colors.grey.shade800 : Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      margin: const EdgeInsetsGeometry.directional(end: 12),
      child: CustomTextFormField(
        controller: _searchController,
        hintText: 'Search in ${widget.storeName}',
        suffixIcon: _searchController.text.isNotEmpty ? Icons.close : Icons.search,
        onSuffixIconTap: () {
          setState(() {
            if (isSubmitted) {
              isSubmitted = false;
              isSearchInStore = false;
              _searchController.clear();
              _loadProducts();
            } else if (_searchController.text.isNotEmpty) {
              isSearchInStore = true;
              isSubmitted = true;
              doSearch();
            }
          });
          FocusScope.of(context).unfocus();
        },
        onFieldSubmitted: (_) {
          doSearch();
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<StoreDetailBloc, StoreDetailState>(
      listener: (context, storeState) {
        // React to store loading exactly once
        if (storeState is StoreDetailLoaded && !_initialProductsLoaded) {
          _initialProductsLoaded = true;
          _handleStoreLoaded(storeState.storeData);
        }
      },
      builder: (context, storeState) {
        if (storeState is StoreDetailLoading) {
          return const Center(child: CustomCircularProgressIndicator());
        }
        if (storeState is StoreDetailFailed) {
          return NoProductPage(
            onRetry: () {
              _initialProductsLoaded = false; // allow retry
              context.read<StoreDetailBloc>().add(
                FetchStoreDetail(storeSlug: widget.storeSlug),
              );
            },
          );
        }
        if (storeState is StoreDetailLoaded) {
          return _buildScrollableContent(storeState.storeData);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScrollableContent(StoreData store) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        _loadProducts(categorySlug: _currentCategorySlug);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreHeader(store, store.distance ?? 0.0, store.avgProductsRating ?? '0.0'),
            const SizedBox(height: 68),
            _buildStoreInfo(store, store.distance ?? 0.0),
            const SizedBox(height: 12),
            VendorAdBannerStrip(
              position: 'store_page',
              storeSlug: widget.storeSlug,
              existingBanners: store.banners,
              height: 180.h,
              borderRadius: BorderRadius.zero,
              boxShadow: const [],
            ),
            const SizedBox(height: 16),
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader(StoreData store, double distance, String rating) {
    double bannerHeight = isTablet(context) ? 220.h : 180.h;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: bannerHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: store.banner?.isNotEmpty == true
              ? CustomImageContainer(imagePath: store.banner!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(color: AppTheme.primaryColor),
                    padding: EdgeInsets.all(16.w),
                    child: const Icon(Icons.store, size: 50, color: Colors.white70),
                  ),
        ),
        // Risbow logo watermark
        PositionedDirectional(
          top: 8,
          start: 8,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/app_logos/app-logo-light.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        if (store.isOwner == true)
          PositionedDirectional(
            top: 16,
            end: 16,
            child: GestureDetector(
              onTap: () => _pickAndUploadBanner(store.id ?? 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Change Banner',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        PositionedDirectional(
          start: 16,
          bottom: -60,
          child: Container(
            width: isTablet(context) ? 120 : 90,
            height: isTablet(context) ? 120 : 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: store.logo?.isNotEmpty == true
                  ? CustomImageContainer(imagePath: store.logo!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.blue.shade50,
                      child: const Icon(Icons.store, size: 28, color: AppTheme.primaryColor),
                    ),
            ),
          ),
        ),
        PositionedDirectional(
          end: 12,
          bottom: -40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppTheme.ratingStarIconFilled, size: 16, color: AppTheme.ratingStarColor),
                const SizedBox(width: 4),
                Text('$rating/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfo(StoreData store, double distance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.name ?? "Unknown Store",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.address ?? "No address",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: store.status?.isOpen == true ? 'Open Now' : 'Closed',
                        style: TextStyle(
                          fontSize: 13,
                          color: store.status?.isOpen == true ? Colors.green : Colors.red,
                        ),
                      ),
                      if (store.timing != null && store.timing!.isNotEmpty)
                        TextSpan(
                          text: ' · ${store.timing}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 200,
        child: Center(child: CustomCircularProgressIndicator()),
      );
    }

    if (_categories.isNotEmpty) {
      return _buildCategoryAndProductsSection();
    }

    return _buildProductsWithoutCategories();
  }

  Widget _buildCategoryAndProductsSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80.w,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryItem(
                      index: index,
                      title: category.title ?? '',
                      image: category.image ?? '',
                      isSelected: _selectedCategoryIndex == index,
                      onTap: () => _onCategorySelected(
                        index,
                        category.slug ?? '',
                        category.title ?? '',
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CustomFilterSortBtnWidget(
                          onTap: showSortBottomSheet,
                          buttonName: 'Sort',
                          iconData: HeroiconsOutline.arrowsUpDown,
                        ),
                      ],
                    ),
                  ),
                  _buildProductList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildCategoryItem({
    required int index,
    required String title,
    required String image,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              left: BorderSide(
                width: 3,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.isNotEmpty
                        ? CustomImageContainer(
                            imagePath: image,
                            fit: BoxFit.cover,
                            fallbackAsset: 'assets/images/placeholder.png',
                          )
                        : Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Image.asset(
                              'assets/images/app_logos/app-logo-light.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.category, size: 22,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsWithoutCategories() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Row(
              children: [
                CustomFilterSortBtnWidget(
                  onTap: showSortBottomSheet,
                  buttonName: 'Sort',
                  iconData: HeroiconsOutline.arrowsUpDown,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return BlocBuilder<ProductListingBloc, ProductListingState>(
      builder: (context, state) {
        if (state is ProductListingLoading) {
          return SizedBox(
            height: isTablet(context) ? 800 : 400,
            child: const Center(child: CustomCircularProgressIndicator()),
          );
        }
        if (state is ProductListingFailed) {
          return SizedBox(
            height: isTablet(context) ? 800 : 400,
            child: Center(child: NoProductPage()),
          );
        }
        if (state is ProductListingLoaded) {
          return _buildProductGrid(state.productList, state.hasReachedMax);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductGrid(List<ProductData> productData, bool hasReachedMax) {
    if (productData.isEmpty) {
      return const Center(child: NoProductPage());
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet(context) ? 3 : 2,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 6.h,
          childAspectRatio: 0.75,
          mainAxisExtent: 330.h,
        ),
        itemCount: hasReachedMax ? productData.length : productData.length + 3,
        itemBuilder: (context, index) => _buildGridItem(productData, index, hasReachedMax),
      ),
    );
  }

  Widget _buildGridItem(List<ProductData> productData, int index, bool hasReachedMax) {
    if (index >= productData.length) {
      return productShimmer();
    }

    final product = productData[index];

    String priceStr = '0';
    String specialStr = '0';

    if (product.variants.isNotEmpty) {
      priceStr = product.variants.first.price.toString();
      specialStr = product.variants.first.specialPrice.toString();
    } else {
      priceStr = product.price > 0 ? product.price.round().toString() : '0';
      specialStr = product.specialPrice > 0 ? product.specialPrice.round().toString() : '0';
    }

    return CustomProductCard(
      productId: product.id,
      productImage: product.mainImage.isNotEmpty ? product.mainImage : 'assets/images/placeholder.png',
      productName: product.title,
      productSlug: product.slug,
      storeSlug: widget.storeSlug,
      productPrice: priceStr,
      specialPrice: specialStr,
      productTags: [],
      estimatedDeliveryTime: product.estimatedDeliveryTime,
      ratings: product.ratings?.toDouble() ?? 0.0,
      ratingCount: product.ratingCount,
      onTap: () {
        debugPrint('TAP: Navigating to product-detail with slug: ${product.slug}');
        GoRouter.of(context).push('/product-detail?slug=${product.slug}&store=${widget.storeSlug}');
      },
      onAddToCart: () => _handleAddToCart(product),
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
      isStoreOpen: product.storeStatus?.isOpen ?? true,
      isWishListed: product.favorite != null,
      productVariantId: product.variants.isNotEmpty ? product.variants.first.id : 0,
      storeId: product.variants.isNotEmpty ? product.variants.first.storeId : 0,
      wishlistItemId: (product.favorite?.isNotEmpty ?? false)
          ? product.favorite!.first.id ?? 0
          : 0,
      totalStocks: product.variants.isNotEmpty
          ? product.variants.first.stock
          : product.stock,
      imageFit: product.imageFit,
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
    );
  }

  void _handleAddToCart(ProductData product) {
    final storeState = context.read<StoreDetailBloc>().state;
    final storeId = (storeState is StoreDetailLoaded) ? (storeState.storeData.id ?? 0) : 0;
    if (product.variants.isEmpty) {
      final price = product.price > 0 ? product.price : 0.0;
      final specialPrice = product.specialPrice > 0 ? product.specialPrice : price;
      final stock = product.stock > 0 ? product.stock : 100;
      final isAvailable = product.available && product.stock > 0;

      if (!isAvailable) {
        return;
      }

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

  Widget productShimmer() {
    return Column(
      children: [
        ShimmerWidget.rectangular(
          height: 130,
          width: 130,
          borderRadius: 15,
          isBorder: true,
        ),
        SizedBox(height: 10),
        ShimmerWidget.rectangular(
          isBorder: false,
          height: 15,
          width: 130,
          borderRadius: 15,
        ),
      ],
    );
  }
}
