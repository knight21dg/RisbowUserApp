import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/screens/category_list_page/bloc/all_category_bloc/all_category_bloc.dart';
import 'package:hyper_local/screens/home_page/model/sub_category_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';
import 'package:hyper_local/utils/widgets/custom_variant_selector_bottom_sheet.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/constant.dart';
import '../../../config/theme.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import '../../../utils/widgets/custom_shimmer.dart';
import '../../home_page/repo/sub_category_repo.dart';
import '../../product_detail_page/model/product_detail_model.dart';
import '../../product_listing_page/model/product_listing_type.dart';
import '../../product_listing_page/repo/category_product_repo.dart';
import '../../product_listing_page/widgets/custom_filter_sort_btn_widget.dart';
import '../../../model/sorting_model/sorting_model.dart';
import '../../../utils/widgets/custom_sorting_bottom_sheet.dart';
import '../bloc/all_category_bloc/all_category_event.dart';
import '../bloc/all_category_bloc/all_category_state.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class CategoryListPage extends StatelessWidget {
  final bool isEmbed;
  
  const CategoryListPage({super.key, this.isEmbed = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AllCategoriesBloc()..add(
        FetchAllCategories(),
      ),
      child: _CategoryListView(isEmbed: isEmbed),
    );
  }
}

class _CategoryListView extends StatefulWidget {
  final bool isEmbed;
  
  const _CategoryListView({this.isEmbed = false});

  @override
  State<_CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<_CategoryListView> {
  final ScrollController _scrollController = ScrollController();
  int _selectedCategoryIndex = 0;

  // Search state
  String _searchQuery = '';
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  // Subcategory state
  List<SubCategoryData> _subcategories = [];
  bool _isLoadingSubcategories = false;
  String? _subcategoryError;
  final SubCategoryRepository _subCategoryRepo = SubCategoryRepository();

  // ─── Level 2: Product view state ───
  bool _isShowingProducts = false;
  SubCategoryData? _selectedSubcategory;
  int _selectedSubcategoryIndex = 0;
  List<ProductData> _products = [];
  bool _isLoadingProducts = false;
  String? _productError;
  bool _hasMoreProducts = false;
  int _productPage = 1;
  bool _isLoadingMoreProducts = false;
  final CategoryProductRepository _productRepo = CategoryProductRepository();
  final ScrollController _productScrollController = ScrollController();
  SortType _currentSortType = SortType.relevance;
  int _totalProductsCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _productScrollController.addListener(_onProductScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _productScrollController.removeListener(_onProductScroll);
    _productScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;

    if (current >= (maxScroll - 200)) {
      context.read<AllCategoriesBloc>().add(FetchMoreAllCategories());
    }
  }

  void _onProductScroll() {
    if (!_productScrollController.hasClients) return;
    final maxScroll = _productScrollController.position.maxScrollExtent;
    final current = _productScrollController.offset;

    if (current >= (maxScroll - 200) && _hasMoreProducts && !_isLoadingMoreProducts) {
      _fetchMoreProducts();
    }
  }

  Future<void> _onRefresh() async {
    if (_isShowingProducts) {
      // Refresh products for selected subcategory
      if (_selectedSubcategory != null) {
        _fetchProducts(_selectedSubcategory!);
      }
    } else {
      context.read<AllCategoriesBloc>().add(
        FetchAllCategories(),
      );
    }
  }

  /// Fetch subcategories for the selected parent category
  Future<void> _fetchSubcategories(SubCategoryData parentCategory) async {
    setState(() {
      _isLoadingSubcategories = true;
      _subcategoryError = null;
      _subcategories = [];
    });

    try {
      final response = await _subCategoryRepo.fetchSubCategory(
        slug: parentCategory.slug ?? '',
        isForAllCategory: false,
        perPage: 80,
        page: 1,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final subCategoriesData = data?['data'] as List<dynamic>?;

        if (subCategoriesData != null && subCategoriesData.isNotEmpty) {
          setState(() {
            _subcategories = List<SubCategoryData>.from(
              subCategoriesData.map((d) => SubCategoryData.fromJson(d)),
            );
            _isLoadingSubcategories = false;
          });
        } else {
          // No subcategories - show stores for this category
          GoRouter.of(context).push(
            AppRoutes.nearbyStores,
            extra: {'categorySlug': parentCategory.slug, 'categoryTitle': parentCategory.title},
          );
          setState(() {
            _subcategories = [];
            _isLoadingSubcategories = false;
          });
        }
      } else {
        setState(() {
          _subcategoryError = response['message'] ?? 'Failed to load';
          _isLoadingSubcategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _subcategoryError = e.toString();
        _isLoadingSubcategories = false;
      });
    }
  }

  /// Fetch products for the selected subcategory
  Future<void> _fetchProducts(SubCategoryData subcategory, {String? sortType}) async {
    final effectiveSort = sortType ?? SortOption.getSortOptionByType(_currentSortType).apiValue;
    
    setState(() {
      _isLoadingProducts = true;
      _productError = null;
      _products = [];
      _productPage = 1;
      _hasMoreProducts = false;
    });

    try {
      final response = await _productRepo.fetchProductsByType(
        type: ProductListingType.category,
        identifier: subcategory.slug ?? subcategory.id.toString(),
        sortType: effectiveSort,
        currentPage: 1,
        perPage: 15,
        includeChildCategories: '1',
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final productsData = data?['data'] as List<dynamic>?;

        if (productsData != null && productsData.isNotEmpty) {
          final products = List<ProductData>.from(
            productsData.map((item) => ProductData.fromJson(item)),
          );
          final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
          final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
          final totalCount = int.tryParse(data?['total']?.toString() ?? '0') ?? 0;

          setState(() {
            _products = products;
            _hasMoreProducts = currentTotal < lastPageNum;
            // Derive count from products list if API returns 0
            _totalProductsCount = totalCount > 0 ? totalCount : products.length;
            _isLoadingProducts = false;
          });
        } else {
          setState(() {
            _products = [];
            _totalProductsCount = 0;
            _isLoadingProducts = false;
          });
        }
      } else {
        setState(() {
          _productError = response['message'] ?? 'Failed to load products';
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _productError = e.toString();
        _isLoadingProducts = false;
      });
    }
  }

  /// Fetch more products (pagination)
  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMoreProducts || !_hasMoreProducts || _selectedSubcategory == null) return;

    setState(() {
      _isLoadingMoreProducts = true;
    });

    try {
      _productPage += 1;
      final response = await _productRepo.fetchProductsByType(
        type: ProductListingType.category,
        identifier: _selectedSubcategory!.slug ?? _selectedSubcategory!.id.toString(),
        sortType: SortOption.getSortOptionByType(_currentSortType).apiValue,
        currentPage: _productPage,
        perPage: 15,
        includeChildCategories: '1',
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final productsData = data?['data'] as List<dynamic>?;

        if (productsData != null && productsData.isNotEmpty) {
          final newProducts = List<ProductData>.from(
            productsData.map((item) => ProductData.fromJson(item)),
          );
          final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
          final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;

          setState(() {
            // Add only unique products
            for (final p in newProducts) {
              if (!_products.any((existing) => existing.id == p.id)) {
                _products.add(p);
              }
            }
            _hasMoreProducts = currentTotal < lastPageNum;
            _isLoadingMoreProducts = false;
          });
        } else {
          setState(() {
            _hasMoreProducts = false;
            _isLoadingMoreProducts = false;
          });
        }
      } else {
        setState(() {
          _productPage -= 1;
          _isLoadingMoreProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _productPage -= 1;
        _isLoadingMoreProducts = false;
      });
    }
  }

  void _onParentCategoryTap(int index, SubCategoryData category) {
    if (_selectedCategoryIndex == index && (_subcategories.isNotEmpty || _isLoadingSubcategories)) {
      return;
    }
    setState(() {
      _selectedCategoryIndex = index;
      _subcategories = [];
      _subcategoryError = null;
      // Reset product view when switching parent categories
      _isShowingProducts = false;
      _selectedSubcategory = null;
      _products = [];
    });
    _fetchSubcategories(category);
  }

  /// When a subcategory is tapped: switch to product view
  void _onSubcategoryTap(SubCategoryData subcategory, int index) {
    GoRouter.of(context).push(
      AppRoutes.nearbyStores,
      extra: {'categorySlug': subcategory.slug, 'categoryTitle': subcategory.title},
    );
  }

  void _showSortBottomSheet() {
    CustomSortBottomSheet.show(
      context: context,
      currentSortType: _currentSortType,
      onSortSelected: (SortOption selectedSort) {
        setState(() {
          _currentSortType = selectedSort.type;
        });
        if (_selectedSubcategory != null) {
          _fetchProducts(_selectedSubcategory!, sortType: selectedSort.apiValue);
        }
      },
    );
  }

  /// Go back from product view to subcategory view
  void _onBackToSubcategories() {
    setState(() {
      _isShowingProducts = false;
      _selectedSubcategory = null;
      _selectedSubcategoryIndex = 0;
      _products = [];
      _productError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
      return widget.isEmbed ? _buildBodyContent() : CustomScaffold(
      showViewCart: true,
      onConnectivityRestored: (_) async {
        _onRefresh();
      },
      appBar: _isShowingProducts
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                onPressed: _onBackToSubcategories,
                icon: const Icon(Icons.arrow_back),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  if (_selectedSubcategory?.image != null)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: CustomImageContainer(
                        imagePath: _selectedSubcategory!.image!,
                        height: 32.h,
                        width: 32.h,
                        fit: BoxFit.contain,
                      ),
                    ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedSubcategory?.title ?? '',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      _isLoadingProducts
                          ? SizedBox(
                              width: 60,
                              height: 12,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.grey.shade200,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Text(
                              '$_totalProductsCount items',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    GoRouter.of(context).push(AppRoutes.search);
                  },
                  icon: const Icon(TablerIcons.search, color: Colors.black),
                ),
              ],
            )
          : null,
      title: _isShowingProducts ? null : AppLocalizations.of(context)!.categories,
      appBarActions: _isShowingProducts
          ? null
          : [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                icon: Icon(_showSearchBar ? TablerIcons.x : TablerIcons.search),
              ),
            ],
      showAppBar: true,
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    return Column(
      children: [
        if (widget.isEmbed && _isShowingProducts)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _onBackToSubcategories,
                  icon: const Icon(Icons.arrow_back),
                ),
                SizedBox(width: 12.w),
                if (_selectedSubcategory?.image != null)
                  Container(
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CustomImageContainer(
                      imagePath: _selectedSubcategory!.image!,
                      height: 24.h,
                      width: 24.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSubcategory?.title ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '$_totalProductsCount items',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: PopScope(
        canPop: !_isShowingProducts,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isShowingProducts) {
            _onBackToSubcategories();
          }
        },
        child: BlocConsumer<AllCategoriesBloc, AllCategoriesState>(
        listener: (context, state) {
          // Auto-select first category when data loads
          if (state is AllCategoriesLoaded && state.subCategoryData.isNotEmpty && !state.isLoadingMore) {
            final parents = state.subCategoryData.where((c) => c.parentId == null || c.parentId == 0).toList();
            // Trigger first load even if no parent categories found - show all as parents
            if (_subcategories.isEmpty && !_isShowingProducts && !_isLoadingSubcategories) {
              if (parents.isNotEmpty) {
                _onParentCategoryTap(0, parents[0]);
              } else if (state.subCategoryData.isNotEmpty) {
                // Fallback: use first category as parent if no parentId filtering
                _onParentCategoryTap(0, state.subCategoryData[0]);
              }
            }
          }
        },
        builder: (context, state) {
          if (state is AllCategoriesLoading || state is AllCategoriesInitial) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParentCategoryListSkeleton(),
                Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                Expanded(child: _buildSubcategoryGridSkeleton()),
              ],
            );
          }

          if (state is AllCategoriesFailed) {
            return Center(
              child: NoCategoryPage(onRetry: _onRefresh),
            );
          }

          if (state is AllCategoriesLoaded) {
            final hasData = state.subCategoryData.isNotEmpty;

            if (!hasData) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(child: NoCategoryPage(onRetry: _onRefresh)),
                ],
              );
            }

            // Filter for parent categories - use all categories as fallback if no root categories
            final rootCategories = state.subCategoryData.where((c) => c.parentId == null || c.parentId == 0).toList();
            final parentCategories = rootCategories.isNotEmpty ? rootCategories : state.subCategoryData;

            return CustomRefreshIndicator(
              onRefresh: _onRefresh,
              child: _isShowingProducts
                  ? _buildProductViewLayout()
                  : _buildCategoryViewLayout(parentCategories),
            );
          }

          return const Center(child: CustomCircularProgressIndicator());
        },
      ),
        ),
      ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // LEVEL 1: Parent Categories + Subcategories Grid
  // ═══════════════════════════════════════════════════

  Widget _buildCategoryViewLayout(List<SubCategoryData> categories) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Left side: Parent categories ───
        _buildParentCategoryList(categories),

        // Divider
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        // ─── Right side: Subcategories grid ───
        Expanded(
          child: _buildSubcategoryPanel(),
        ),
      ],
    );
  }



  /// Left panel: list of parent categories
  Widget _buildParentCategoryList(List<SubCategoryData> categories) {
    // Filter categories based on search query
    final filteredCategories = _searchQuery.isEmpty 
        ? categories 
        : categories.where((c) => 
            (c.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();

    return SizedBox(
      width: isTablet(context) ? 110.w : 95.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: filteredCategories.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    'No categories found',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final isSelected = _selectedCategoryIndex == index;

            return GestureDetector(
              onTap: () => _onParentCategoryTap(index, category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
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
                              ? Colors.white 
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        padding: EdgeInsets.all(isSelected ? 2.w : 4.w),
                        child: (category.image ?? '').trim().isNotEmpty
                            ? CustomImageContainer(
                                imagePath: category.image ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                fallbackAsset: 'assets/images/placeholder.png',
                              )
                            : Icon(
                                TablerIcons.category,
                                size: 28,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Category title - single line with ellipsis
                    Text(
                      category.title ?? '',
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

  /// Skeleton loader for left sidebar (parent categories)
  Widget _buildParentCategoryListSkeleton() {
    return SizedBox(
      width: 80.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView.builder(
          itemCount: 8,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
              child: Column(
                children: [
                  ShimmerWidget.circular(
                    width: 48.w,
                    height: 48.w,
                    isBorder: false,
                    borderRadius: 12,
                  ),
                  SizedBox(height: 6.h),
                  ShimmerWidget.rectangular(
                    width: 40.w,
                    height: 10,
                    isBorder: false,
                    borderRadius: 4,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Skeleton loader for right side (subcategories grid)
  Widget _buildSubcategoryGridSkeleton() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet(context) ? 3 : 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.9,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return ShimmerWidget.rectangular(
          width: double.infinity,
          height: double.infinity,
          isBorder: false,
          borderRadius: 20,
        );
      },
    );
  }

  /// Right panel: subcategories grid
  Widget _buildSubcategoryPanel() {
    if (_isLoadingSubcategories) {
      return _buildSubcategoryGridSkeleton();
    }

    if (_subcategoryError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.alert_circle,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              'Failed to load subcategories',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {
                final state = context.read<AllCategoriesBloc>().state;
                if (state is AllCategoriesLoaded && state.subCategoryData.isNotEmpty) {
                  _fetchSubcategories(state.subCategoryData[_selectedCategoryIndex]);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.layout_grid,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              _selectedCategoryIndex == 0
                  ? 'Select a category to browse'
                  : 'No subcategories found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    // Filter subcategories based on search query
    final filteredSubcategories = _searchQuery.isEmpty 
        ? _subcategories 
        : _subcategories.where((s) => 
            (s.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();

    if (filteredSubcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.search,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No subcategories found'
                  : 'No subcategories found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet(context) ? 3 : 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: filteredSubcategories.length,
      itemBuilder: (context, index) {
        final subcat = filteredSubcategories[index];
        return _buildSubcategoryGridItem(subcat, index);
      },
    );
  }

  /// Individual subcategory item tile in the grid
  Widget _buildSubcategoryGridItem(SubCategoryData subcat, int index) {
    final isSelected = _selectedSubcategoryIndex == index;
    return GestureDetector(
      onTap: () => _onSubcategoryTap(subcat, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Subcategory image with decorative background
            Expanded(
              child: AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: (subcat.image ?? '').trim().isNotEmpty
                      ? CustomImageContainer(
                          imagePath: subcat.image ?? '',
                          fit: BoxFit.contain,
                          fallbackAsset: 'assets/images/placeholder.png',
                        )
                      : Icon(
                          TablerIcons.package,
                          size: 32.r,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Subcategory name
            Text(
              subcat.title ?? '',
              style: TextStyle(
                fontSize: isTablet(context) ? 11 : 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.blue.shade700
                    : Colors.black87,
                fontFamily: AppTheme.fontFamily,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton for subcategory sidebar in product view
  Widget _buildSubcategorySidebarSkeleton() {
    return SizedBox(
      width: 90.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
              child: Column(
                children: [
                  ShimmerWidget.circular(
                    width: 48.w,
                    height: 48.w,
                    isBorder: false,
                    borderRadius: 12,
                  ),
                  SizedBox(height: 6.h),
                  ShimmerWidget.rectangular(
                    width: 40.w,
                    height: 10,
                    isBorder: false,
                    borderRadius: 4,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // LEVEL 2: Subcategories List + Products Grid
  // ═══════════════════════════════════════════════════

  Widget _buildProductViewLayout() {
    if (_isLoadingSubcategories) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubcategorySidebarSkeleton(),
          Container(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(child: _buildProductGridSkeleton()),
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Left side: Subcategories list ───
        if (_subcategories.isNotEmpty) ...[
          _buildSubcategorySidebar(),

          // Divider
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ],

        // ─── Right side: Products grid ───
        Expanded(
          child: _buildProductsPanel(),
        ),
      ],
    );
  }

  /// Left sidebar in product view: list of subcategories
  Widget _buildSubcategorySidebar() {
    return SizedBox(
      width: isTablet(context) ? 115.w : 100.w,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _subcategories.length,
          itemBuilder: (context, index) {
            final subcat = _subcategories[index];
            final isSelected = _selectedSubcategoryIndex == index;

            return GestureDetector(
              onTap: () => _onSubcategoryTap(subcat, index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.transparent,
                  border: isSelected
                      ? Border(
                          right: BorderSide(
                            width: 3.w,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subcategory image - supports all PNG formats
                    SizedBox(
                      width: isTablet(context) ? 90.w : 82.w,
                      height: isTablet(context) ? 90.w : 82.w,
                      child: (subcat.image ?? '').trim().isNotEmpty
                          ? CustomImageContainer(
                              imagePath: subcat.image ?? '',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              fallbackAsset: 'assets/images/placeholder.png',
                            )
                          : Icon(
                              TablerIcons.category,
                              size: 26,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                    ),
                    SizedBox(height: 6.h),
                    // Subcategory title
                    Text(
                      subcat.title ?? '',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.black87,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  /// Skeleton for product grid
  Widget _buildProductGridSkeleton() {
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ShimmerWidget.rectangular(
          width: double.infinity,
          height: double.infinity,
          isBorder: true,
          borderRadius: 12,
        );
      },
    );
  }

  /// Right panel in product view: products grid
  Widget _buildProductsPanel() {
    if (_isLoadingProducts) {
      return _buildProductGridSkeleton();
    }

    if (_productError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.alert_circle,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 12.h),
            Text(
              'Failed to load products',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () {
                if (_selectedSubcategory != null) {
                  _fetchProducts(_selectedSubcategory!);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.package,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.h),
            Text(
              'No products found',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = isTablet(context) ? 3 : 2;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Sort Bar matching Screenshot
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CustomFilterSortBtnWidget(
                  onTap: _showSortBottomSheet,
                  buttonName: 'Sort',
                  iconData: TablerIcons.arrows_up_down,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsetsGeometry.directional(
                start: 14.w,
                end: 8.w,
                top: 8.h,
                bottom: 8.h,
              ),
              child: GridView.builder(
                controller: _productScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 70.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 6.h,
                  mainAxisExtent: 245.h,
                ),
                itemCount: _hasMoreProducts ? _products.length + crossAxisCount : _products.length,
                itemBuilder: (context, index) {
                  if (index >= _products.length) {
                    return _buildProductShimmer();
                  }
                  return _buildProductItem(_products[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single product card
  Widget _buildProductItem(ProductData product) {
    if (product.variants.isEmpty) return const SizedBox.shrink();

    final defaultVariant = product.variants.firstWhere(
      (variant) => variant.isDefault,
      orElse: () => product.variants.first,
    );

    return CustomProductCard(
      productId: product.id,
      productImage: product.mainImage,
      productName: product.title,
      productSlug: product.slug,
      productPrice: defaultVariant.price.toString(),
      specialPrice: defaultVariant.specialPrice.toString(),
      estimatedDeliveryTime: product.estimatedDeliveryTime.toString(),
      assetImage: '',
      productTags: product.tags,
      ratings: double.parse(product.ratings.toString()),
      ratingCount: product.ratingCount,
      onAddToCart: () {
        if (product.variants.length > 1) {
          showVariantBottomSheet(
            variantsList: product.variants,
            productData: product,
            productImage: product.mainImage,
            quantityStepSize: product.quantityStepSize,
            context: context,
          );
        } else {
          final item = UserCart(
            productId: product.id.toString(),
            variantId: defaultVariant.id.toString(),
            variantName: defaultVariant.title.toString(),
            vendorId: defaultVariant.storeId.toString(),
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
      },
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
      productVariantId: defaultVariant.id,
      storeId: defaultVariant.storeId,
      wishlistItemId: product.favorite?.isNotEmpty == true
          ? product.favorite!.first.id ?? 0
          : 0,
      totalStocks: defaultVariant.stock,
      imageFit: product.imageFit,
      quantityStepSize: product.quantityStepSize,
      minQty: product.minimumOrderQuantity,
      totalAllowedQuantity: product.totalAllowedQuantity,
    );
  }

  Widget _buildProductShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 130,
          width: double.infinity,
          borderRadius: 15,
        ),
        const SizedBox(height: 10.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 100,
          borderRadius: 15,
        ),
        const SizedBox(height: 2.0),
        ShimmerWidget.rectangular(
          isBorder: true,
          height: 15,
          width: 80,
          borderRadius: 15,
        ),
      ],
    );
  }
}
