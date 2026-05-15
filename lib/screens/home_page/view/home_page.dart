import 'dart:developer';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/model/settings_model/settings_model.dart';
import 'package:hyper_local/model/user_location/user_location_model.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_event.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_state.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_event.dart';
import 'package:hyper_local/screens/home_page/widgets/brands_widget.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:hyper_local/services/location/location_service.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import '../../../config/constant.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import '../../../utils/widgets/custom_scaffold.dart';
import '../bloc/banner/banner_bloc.dart';
import '../bloc/banner/banner_state.dart';
import '../bloc/brands/brands_bloc.dart';
import '../model/category_model.dart';
import '../widgets/animated_text_field.dart';
import '../widgets/banner_slider.dart';
import '../bloc/category/category_state.dart';
import '../widgets/location_bottom_sheet.dart';
import '../widgets/product_feature_section_widget.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sub_category_feature_section_widget.dart';
import '../../../utils/widgets/empty_states_page.dart';
import '../bloc/sub_category/sub_category_state.dart';
import '../bloc/homepage_section/homepage_section_bloc.dart';
import '../widgets/dynamic_homepage_section_widget.dart';
import '../bloc/custom_sale_page/custom_sale_page_bloc.dart';
import '../widgets/custom_sale_page_widget.dart';
import 'package:hyper_local/widgets/vendor_ad_banner_strip.dart';
import '../repo/homepage_enhanced_repo.dart';
import '../model/today_deal_model.dart';
import '../model/product_reel_model.dart';
import '../widgets/today_deals_section.dart';
import '../widgets/trending_reels_section.dart';
import '../widgets/weekly_rooms_preview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final ScrollController nestedScrollController = ScrollController();
  late String backgroundImagePath = '';
  String? backgroundColor;
  bool _isImageEmpty = false;
  Color? textColor;
  List<CategoryData> _categories = [];
  bool _isTabControllerInitialized = false;
  bool _isFlexibleSpaceHidden = false;
  bool _isRecreatingTabController = false;
  Color? _originalTextColor;
  Color? _collapsedTextColor;
  String? _lastLocationIdentifier;
  final Map<int, bool> _isLoadingMoreForTab = {};
  int localCategoryLength = 0;
  String _tabBarViewKey = 'initial';
  int _previousCategoryLength = 0;
  bool _isRedirecting = false;
  double _appBarOpacity = 1.0;
  bool _showScrollToTop = false;
  double _lastScrollPixels = 0.0;
  static const double _scrollThreshold = 100.0;
  double _latestScrollPixels = 0.0;
  bool isRetry = false;
  bool _isLoadingLocation = false;
  
  final HomepageEnhancedRepository _homepageRepo = HomepageEnhancedRepository();
  List<TodayDeal> _todayDeals = [];
  List<ProductReel> _trendingReels = [];
  List<RoomPreview> _weeklyRooms = [];
  bool _isLoadingTodayDeals = true;
  bool _isLoadingTrendingReels = true;
  bool _isLoadingWeeklyRooms = true;

  @override
  bool get wantKeepAlive => true;

  void updateAppBarBackground({
    String? image,
    String? bgColor,
    Color? fontColor,
  }) {
    setState(() {
      backgroundImagePath = image ?? '';
      backgroundColor = bgColor;
      _isImageEmpty = image == null || image.isEmpty;
      if (fontColor != null) {
        textColor = fontColor;
        _originalTextColor = fontColor;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      _categories = categoryState.categoryData;
      _previousCategoryLength = _categories.length;
      _tabController = TabController(length: _categories.length + 1, vsync: this);
    } else {
      _tabController = TabController(length: 1, vsync: this);
    }
    
    _isTabControllerInitialized = true;
    _tabController.addListener(_onTabChanged);
    nestedScrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationAndLoad();
      _loadTodayDeals();
      _loadTrendingReels();
      _loadWeeklyRooms();
    });
  }

  Future<void> _checkLocationAndLoad() async {
    if (!LocationService.hasStoredLocation()) {
      setState(() {
        _isLoadingLocation = true;
      });
      await LocationService.requestAndStoreLocationWithRetry();
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } else {
      final stored = LocationService.getStoredLocation();
      if (stored != null && (stored.zoneId == null || stored.zoneId!.isEmpty)) {
        final zoneInfo = await LocationService.getZoneFromApi(stored.latitude, stored.longitude);
        if (zoneInfo != null && zoneInfo['isDeliverable'] == true) {
          final updatedLocation = UserLocation(
            latitude: stored.latitude,
            longitude: stored.longitude,
            fullAddress: stored.fullAddress,
            area: stored.area,
            city: stored.city,
            state: stored.state,
            country: stored.country,
            pincode: stored.pincode,
            landmark: stored.landmark,
            zoneId: zoneInfo['zoneId'],
            zoneName: zoneInfo['zoneName'],
          );
          await LocationService.storeLocation(updatedLocation);
        }
      }
    }

    if (mounted) {
      _refreshDataForCurrentTab();
      _refreshApiOnLocationChange();
    }
  }

  Future<void> _loadTodayDeals() async {
    try {
      final result = await _homepageRepo.fetchTodayDeals();
      if (mounted && result.data?.deals != null) {
        setState(() {
          _todayDeals = result.data!.deals!;
          _isLoadingTodayDeals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTodayDeals = false;
        });
      }
    }
  }

  Future<void> _loadTrendingReels() async {
    try {
      final result = await _homepageRepo.fetchTrendingReels();
      if (mounted && result.data?.reels != null) {
        setState(() {
          _trendingReels = result.data!.reels!;
          _isLoadingTrendingReels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrendingReels = false;
        });
      }
    }
  }

  Future<void> _loadWeeklyRooms() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${AppConstant.baseUrl}rooms/weekly',
        {},
      );
      final data = response.data;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> roomsJson = data['data'];
        setState(() {
          _weeklyRooms = roomsJson.map((r) => RoomPreview(
            id: r['id'] ?? 0,
            code: r['code'] ?? '',
            name: r['name'] ?? '',
            bannerUrl: r['banner_url'] ?? '',
            maxMembers: r['max_members'] ?? 50,
            membersJoined: r['members_joined'] ?? 0,
            status: r['status'] ?? 'active',
            discount: r['discount'] ?? 0,
          )).toList();
          _isLoadingWeeklyRooms = false;
        });
      }
    } catch (e) {
      setState(() {
        _weeklyRooms = [];
        _isLoadingWeeklyRooms = false;
      });
    }
  }

  Color? _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    try {
      if (hexColor.startsWith('0x') || hexColor.startsWith('0X')) {
        return Color(int.parse(hexColor));
      }
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse('0x$cleanHex'));
    } catch (e) {
      return null;
    }
  }

  void _onTabChanged() {
    if (!_canUseTabController || _isRedirecting) return;

    final int index = _tabController.index;
    final int totalTabs = _categories.length + 1;

    if (index >= totalTabs) {
      _ensureValidTabIndex();
      return;
    }

    context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());

    if (index == 0) {
      apiCalls('');
      _applyHomeGeneralSettingsToAppBar();
    } else if (index > 0 && index - 1 < _categories.length) {
      final category = _categories[index - 1];
      apiCalls(category.slug ?? '');
      updateAppBarBackground(
        image: category.banner,
        bgColor: category.backgroundColor,
        fontColor: hexStringToColor(category.fontColor),
      );
    }

    scrollToTop(animated: true);
  }

  void _ensureValidTabIndex() {
    log('Ensure Valid Tab Index ${(!mounted || !_canUseTabController || _isRedirecting)}');
    if (!mounted || !_canUseTabController || _isRedirecting) return;

    final int totalTabs = _categories.length + 1;
    final int currentIndex = _tabController.index;
    if (currentIndex >= totalTabs || currentIndex < 0) {
      _isRedirecting = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_canUseTabController) {
          _isRedirecting = false;
          return;
        }

        _tabController.animateTo(0);
        _applyHomeGeneralSettingsToAppBar();
        context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());
        apiCalls('');

        setState(() {
          _tabBarViewKey = 'reset_${DateTime.now().millisecondsSinceEpoch}';
        });

        if (nestedScrollController.hasClients) {
          nestedScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isRedirecting = false;
          }
        });
      });
    }
  }

  bool get _canUseTabController =>
      _isTabControllerInitialized && !_isRecreatingTabController && mounted;

  void _initializeTabController(int categoriesLength) {
    if (_tabController.length != categoriesLength + 1 && !_isRecreatingTabController) {
      _isRecreatingTabController = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isRecreatingTabController = false;
          return;
        }

        try {
          if (_isTabControllerInitialized) {
            _tabController.removeListener(_onTabChanged);
            _tabController.dispose();
          }

          _tabController = TabController(
            length: categoriesLength + 1,
            vsync: this,
          );

          _isTabControllerInitialized = true;
          _tabController.addListener(_onTabChanged);
          _isRecreatingTabController = false;

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          _isRecreatingTabController = false;
          log('Error recreating TabController: $e');
          if (mounted) {
            setState(() {});
          }
        }
      });
    }
  }

  void apiCalls(String slug) {
    if (!_canUseTabController) return;

    if (_tabController.index < 0 || _tabController.index > _tabController.length) {
      return;
    }

    try {
      if (_tabController.index == 0) {
        context.read<FeatureSectionProductBloc>().add(FetchFeatureSectionProducts(slug: ''));
        context.read<SubCategoryBloc>().add(FetchSubCategory(slug: '', isForAllCategory: true, isHome: true));
        context.read<BrandsBloc>().add(const FetchBrands(categorySlug: ""));
        context.read<BannerBloc>().add(FetchBanner(categorySlug: ''));
        context.read<GetUserCartBloc>().add(FetchUserCart());
        context.read<GetAddressListBloc>().add(FetchUserAddressList());
      } else {
        context.read<SubCategoryBloc>().add(FetchSubCategory(slug: slug, isForAllCategory: false));
        context.read<BannerBloc>().add(FetchBanner(categorySlug: slug));
        context.read<BrandsBloc>().add(FetchBrands(categorySlug: slug));
        context.read<FeatureSectionProductBloc>().add(FetchFeatureSectionProducts(slug: slug));
        context.read<GetUserCartBloc>().add(FetchUserCart());
        context.read<GetAddressListBloc>().add(FetchUserAddressList());
      }
    } catch (e) {
      print('Error in apiCalls: $e');
    }
  }

  void _refreshDataForCurrentTab() {
    if (_categories.isEmpty) return;
    
    if (_tabController.index < 0 || _tabController.index > _tabController.length) {
      return;
    }
    
    if (_tabController.index == 0) {
      apiCalls('');
    } else if ((_tabController.index - 1) < _categories.length) {
      final idx = _tabController.index - 1;
      if (idx >= 0 && idx < _categories.length) {
        final selectedCategory = _categories[idx];
        if (selectedCategory != null) {
          apiCalls(selectedCategory.slug ?? '');
          return;
        }
      }
      apiCalls('');
    } else {
      apiCalls('');
    }
  }

  void _refreshApiOnLocationChange() {
    context.read<CategoryBloc>().add(FetchCategory(isHome: true));
    context.read<NearByStoreBloc>().add(FetchNearByStores(perPage: 15, searchQuery: ''));
  }

  void _scrollListener() {
    double expandedHeight = 100.0.h;
    const double toolbarHeight = kToolbarHeight;
    final double flexibleSpaceHeight = expandedHeight - toolbarHeight;
    final double currentOffset = nestedScrollController.offset;
    final bool isHidden = currentOffset >= (flexibleSpaceHeight - 10);
    _appBarOpacity = (1 - (currentOffset / expandedHeight)).clamp(0.0, 1.0);

    if (_isFlexibleSpaceHidden != isHidden) {
      setState(() {
        _isFlexibleSpaceHidden = isHidden;
        if (_isFlexibleSpaceHidden) {
          textColor = _collapsedTextColor ?? (Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor);
        } else {
          textColor = _originalTextColor ?? (Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor);
        }
      });
    }
  }

  @override
  void dispose() {
    nestedScrollController.removeListener(_scrollListener);
    nestedScrollController.dispose();
    if (_isTabControllerInitialized) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    super.dispose();
  }

  Widget _buildFlexibleSpaceBackground() {
    if (!_isImageEmpty && backgroundImagePath.isNotEmpty) {
      return CustomImageContainer(
        imagePath: backgroundImagePath,
        fit: BoxFit.cover,
      );
    } else {
      return _buildGradientBackground();
    }
  }

  Widget _buildGradientBackground() {
    Color primaryColor = AppTheme.primaryColor;
    if (backgroundColor != null) {
      Color? categoryColor = _getColorFromHex(backgroundColor);
      if (categoryColor != null) {
        primaryColor = categoryColor;
      }
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(dynamic category, bool isSelected) {
    String? imageUrl;
    if (category.icon != null && category.icon!.isNotEmpty) {
      imageUrl = isSelected && category.activeIcon != null ? category.activeIcon : category.icon;
    } else if (category.image != null && category.image!.isNotEmpty) {
      imageUrl = category.image;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: CustomImageContainer(
          imagePath: imageUrl,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Icon(
          isSelected ? Icons.category : Icons.category_outlined,
          size: 28,
          color: Colors.black,
        ),
      );
    }
  }

  bool _isValidHomeGeneralSettings(HomeGeneralSettings settings) {
    return settings.title.trim().isNotEmpty || settings.icon.trim().isNotEmpty || settings.activeIcon.trim().isNotEmpty;
  }

  void _applyHomeGeneralSettingsToAppBar() {
    final settings = SettingsData.instance.homeGeneralSettings;
    if (settings == null || !_isValidHomeGeneralSettings(settings)) {
      _collapsedTextColor = Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor;
      updateAppBarBackground(
        image: '',
        bgColor: null,
        fontColor: Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor,
      );
      return;
    }

    final String image = settings.backgroundImage.isNotEmpty ? settings.backgroundImage : '';
    final String? bgColor = settings.backgroundColor.isNotEmpty ? settings.backgroundColor : null;
    final Color? fontColor = settings.fontColor.isNotEmpty ? _getColorFromHex(settings.fontColor) : null;

    updateAppBarBackground(
      image: image,
      bgColor: bgColor,
      fontColor: fontColor,
    );
  }

  Widget _buildAllTabStatic() {
    return Tab(
      height: 75,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 56,
            child: Icon(HeroiconsOutline.squares2x2, size: 28),
          ),
          const SizedBox(height: 0),
          Text(
            AppLocalizations.of(context)!.all,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildAllTabDynamic(HomeGeneralSettings settings) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final bool isSelected = _tabController.index == 0;
        final String iconUrl = isSelected ? (settings.activeIcon.isNotEmpty ? settings.activeIcon : settings.icon) : settings.icon;
        final String trimmedIconUrl = iconUrl.trim();
        Widget iconWidget;
        if (trimmedIconUrl.isNotEmpty) {
          iconWidget = CustomImageContainer(
            imagePath: trimmedIconUrl,
            fit: BoxFit.contain,
            fallbackAsset: 'assets/images/placeholder.png',
          );
        } else {
          iconWidget = const Icon(HeroiconsOutline.squares2x2, size: 28);
        }

        return Tab(
          height: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 48, height: 56, child: iconWidget),
              const SizedBox(height: 0),
              Text(
                settings.title.isNotEmpty ? settings.title : AppLocalizations.of(context)!.all,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAddress() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<dynamic>('userLocationBox').listenable(),
      builder: (context, Box<dynamic> box, _) {
        final storedLocation = box.get('user_location');
        final locationIdentifier = storedLocation == null ? null : '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';

        if (_lastLocationIdentifier != locationIdentifier) {
          _lastLocationIdentifier = locationIdentifier;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshDataForCurrentTab();
            _refreshApiOnLocationChange();
          });
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    useRootNavigator: true,
                    builder: (context) => Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: LocationBottomSheet()),
                      ],
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180.w,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(TablerIcons.map_pin_filled, size: 22, color: textColor),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              storedLocation?.area.isNotEmpty == true ? storedLocation!.area : '',
                              style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(TablerIcons.chevron_down, size: 20, color: textColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 230.w,
                      child: Text(
                        storedLocation?.fullAddress.isNotEmpty == true ? storedLocation!.fullAddress : '',
                        style: TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w400, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget productFeaturedSectionEmptyState() {
    return SizedBox(
      height: isTablet(context) ? 240.h : 350.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: ShimmerWidget.rectangular(isBorder: true, height: 18, width: 200, borderRadius: 15),
          ),
          SizedBox(
            height: 210.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 20),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    children: [
                      ShimmerWidget.rectangular(isBorder: true, height: 105, width: 100, borderRadius: 15),
                      const SizedBox(height: 10.0),
                      ShimmerWidget.rectangular(isBorder: true, height: 15, width: 100, borderRadius: 15),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return CustomScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(TablerIcons.map_pin_filled, size: 22, color: Colors.grey.shade300),
                  const SizedBox(width: 8),
                  ShimmerWidget.rectangular(isBorder: true, height: 20, width: 200, borderRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    subCategoryLoading(),
                    const SizedBox(height: 20),
                    productFeaturedSectionEmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super.build() but ignore return value for AutomaticKeepAliveClientMixin
    if (_isLoadingLocation) {
      return _buildSkeleton();
    }
    return BlocListener<GetUserCartBloc, GetUserCartState>(
      listener: (BuildContext context, GetUserCartState state) {},
      child: CustomScaffold(
        showViewCart: true,
        onConnectivityRestored: (context) async {
          if (_tabController.index == 0) {
            apiCalls('');
          } else {
            final selectedCategory = _categories[_tabController.index - 1];
            apiCalls(selectedCategory.slug ?? '');
          }
        },
        body: Stack(
          children: [
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (BuildContext context, CategoryState state) {
                final homeGeneralSettings = SettingsData.instance.homeGeneralSettings;
                List<Widget> tabBarTabs = [
                  if (homeGeneralSettings != null && _isValidHomeGeneralSettings(homeGeneralSettings))
                    _buildAllTabDynamic(homeGeneralSettings)
                  else
                    _buildAllTabStatic(),
                ];
                List<Widget> tabBarViewChildren = [
                  CustomRefreshIndicator(
                    onRefresh: () async {
                      log('HomePage: Refreshing data...');
                      // Keep the current tab selection when refreshing - don't call apiCalls('') which resets to All tab
                      final currentTabIndex = _tabController.index;
                      _refreshDataForCurrentTab();
                      _applyHomeGeneralSettingsToAppBar();
                      
                      // Don't refresh categories on pull-to-refresh - this causes tab reset
                      // Categories are already loaded on first load
                      
                      // Refresh homepage sections and custom sale pages
                      context.read<HomepageSectionBloc>().add(FetchHomepageSections());
                      context.read<CustomSalePageBloc>().add(FetchCustomSalePages());
                      
                      // Wait for the states to update (optional but good for UI)
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: BlocBuilder<BannerBloc, BannerState>(
                      builder: (context, bannerState) {
                        return BlocBuilder<SubCategoryBloc, SubCategoryState>(
                          builder: (context, subCategoryState) {
                            return BlocBuilder<FeatureSectionProductBloc, FeatureSectionProductState>(
                              builder: (context, featureSectionState) {
                                return BlocBuilder<BrandsBloc, BrandsState>(
                                  builder: (context, brandsState) {
                                    final hasFailed = bannerState is BannerFailed && subCategoryState is SubCategoryFailed && featureSectionState is FeatureSectionProductFailed && brandsState is BrandsFailed;

                                    if (hasFailed) {
                                      return EmptyStatePage(
                                        title: 'Connection Error',
                                        description: 'Failed to load content. Please try again.',
                                        imageAsset: 'assets/images/icons/server_error.png',
                                        onRetry: () {
                                          setState(() { isRetry = true; });
                                          if (_tabController.index > 0) {
                                            final selectedCategory = _categories[_tabController.index - 1];
                                            apiCalls(selectedCategory.slug ?? '');
                                          } else {
                                            apiCalls('');
                                          }
                                          context.read<CategoryBloc>().add(FetchCategory());
                                        },
                                      );
                                    }

                                    return CustomScrollView(
                                      clipBehavior: Clip.antiAlias,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<BannerBloc, BannerState>(
                                            builder: (BuildContext context, BannerState state) {
                                              List<dynamic> banners = [];
                                              if (state is BannerLoaded) {
                                                banners = state.bannerData;
                                              }
                                              return SizedBox(
                                                height: (1.sw * 9 / 16) + 30.h,
                                                child: VendorAdBannerStrip(position: 'home_top', height: 1.sw * 9 / 16, existingBanners: banners),
                                              );
                                            },
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: TodayDealsSection(
                                            deals: _todayDeals,
                                            isLoading: _isLoadingTodayDeals,
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: TrendingReelsSection(
                                            reels: _trendingReels,
                                            isLoading: _isLoadingTrendingReels,
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: WeeklyRoomsPreview(
                                            rooms: _weeklyRooms,
                                            isLoading: _isLoadingWeeklyRooms,
                                          ),
                                        ),
                                        const SliverToBoxAdapter(child: SubCategoryFeatureSectionWidget()),
                                        SliverToBoxAdapter(
                                          child: BrandsSection(
                                            brandsSectionTitle: AppLocalizations.of(context)?.topBrands ?? 'Top Brands',
                                            categorySlug: '',
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<HomepageSectionBloc, HomepageSectionState>(
                                            builder: (context, state) {
                                              if (state is HomepageSectionLoaded && state.sections.isNotEmpty) {
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: 16.h),
                                                    ...state.sections.map((section) => DynamicHomepageSectionWidget(section: section)),
                                                  ],
                                                );
                                              }
                                              if (state is HomepageSectionLoading) {
                                                return Container(height: 200, color: Colors.grey, child: const Center(child: Text('Loading...')));
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<CustomSalePageBloc, CustomSalePageState>(
                                            builder: (context, state) {
                                              if (state is CustomSalePageListLoaded && state.pages.isNotEmpty) {
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text('SPECIAL SALES', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 1.5)),
                                                                Container(margin: EdgeInsets.only(top: 4.h), height: 2.h, width: 40.w, color: Colors.black),
                                                              ],
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () => context.push(AppRoutes.customSalePages),
                                                            child: Text('VIEW ALL', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 1.0)),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    ...state.pages.take(3).expand((page) => [
                                                      CustomSalePageListItemWidget(page: page, onTap: () => context.push('/custom-sale-page/${page.slug}')),
                                                      SizedBox(height: 16.h),
                                                    ]),
                                                  ],
                                                );
                                              }
                                              return SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<FeatureSectionProductBloc, FeatureSectionProductState>(
                                            builder: (context, state) {
                                              if (state is FeatureSectionProductLoaded) {
                                                return ListView.builder(
                                                  padding: EdgeInsets.only(top: 5.h),
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: state.hasReachedMax ? state.featureSectionProductData.length : state.featureSectionProductData.length + 1,
                                                  itemBuilder: (context, index) {
                                                    final bool hasAnyProducts = state.featureSectionProductData.any((section) => (section.products ?? []).isNotEmpty);
                                                    if (!hasAnyProducts) return const SizedBox.shrink();
                                                    if (index >= state.featureSectionProductData.length) {
                                                      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CustomCircularProgressIndicator()));
                                                    }

                                                    return hasAnyProducts ? ProductFeatureSectionWidget(
                                                      featureSectionData: state.featureSectionProductData[index],
                                                      featureSectionSlug: state.featureSectionProductData[index].slug ?? '',
                                                    ) : const SizedBox.shrink();
                                                  },
                                                );
                                              } else if (state is FeatureSectionProductLoading) {
                                                return productFeaturedSectionEmptyState();
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        const SliverToBoxAdapter(child: SizedBox(height: 70)),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ];

                if (state is CategoryLoaded) {
                  if (isRetry) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() { isRetry = false; });
                        }
                      });
                    });
                  }
                  final List<CategoryData> newCategories = state.categoryData;
                  if (newCategories.isNotEmpty) {
                    _categories = newCategories;
                  }
                  final int totalTabs = _categories.length + 1;
                  final bool categoriesChanged = _previousCategoryLength != _categories.length;
                  final int oldLength = _previousCategoryLength;
                  _previousCategoryLength = _categories.length;

                  if (_tabController.length != totalTabs) {
                    _initializeTabController(_categories.length);
                  }

                  if (_tabController.index >= totalTabs) {
                    _ensureValidTabIndex();
                  } else if (categoriesChanged && _tabController.index > 0 && !_isRedirecting) {
                    final currentIndex = _tabController.index - 1;
                    // Only reset to All tab if current category no longer exists
                    if (currentIndex >= newCategories.length) {
                      _ensureValidTabIndex();
                    }
                    // Don't call apiCalls('') here - it resets to All tab and breaks the selected category
                  }
                }

                // Always build tabs from _categories to prevent them from disappearing during loading
                tabBarTabs.addAll(_categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  return AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      bool isSelected = _tabController.index == index + 1;
                      return Tab(
                        height: 75,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 48, height: 56, child: _buildTabIcon(category, isSelected)),
                            const SizedBox(height: 0),
                            Text(category.title ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: Colors.black)),
                            const SizedBox(height: 3),
                          ],
                        ),
                      );
                    },
                  );
                }).toList());

                tabBarViewChildren.addAll(_categories.asMap().entries.map((entry) {
                  final category = entry.value;
                  return CustomRefreshIndicator(
                    onRefresh: () async {
                      // Don't fetch categories - just refresh the current category's data
                      apiCalls(category.slug ?? '');
                      updateAppBarBackground(image: category.banner, bgColor: category.backgroundColor, fontColor: hexStringToColor(category.fontColor));
                      // Don't refresh categories on pull-to-refresh to preserve tab state
                    },
                    child: BlocBuilder<BannerBloc, BannerState>(
                      builder: (context, bannerState) {
                        return BlocBuilder<SubCategoryBloc, SubCategoryState>(
                          builder: (context, subCategoryState) {
                            return BlocBuilder<FeatureSectionProductBloc, FeatureSectionProductState>(
                              builder: (context, featureSectionState) {
                                return BlocBuilder<BrandsBloc, BrandsState>(
                                  builder: (context, brandsState) {
                                    final hasFailed = bannerState is BannerFailed && subCategoryState is SubCategoryFailed && featureSectionState is FeatureSectionProductFailed && brandsState is BrandsFailed;
                                    if (hasFailed) {
                                      return EmptyStatePage(
                                        title: 'Connection Error',
                                        description: 'Failed to load content. Please try again.',
                                        imageAsset: 'assets/images/icons/server_error.png',
                                        onRetry: () {
                                          if (_categories.isNotEmpty && (_tabController.index - 1) < _categories.length) {
                                            final selectedCategory = _categories[_tabController.index - 1];
                                            apiCalls(selectedCategory.slug ?? '');
                                          } else {
                                            apiCalls('');
                                          }
                                        },
                                      );
                                    }

                                    return CustomScrollView(
                                      physics: AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<BannerBloc, BannerState>(
                                            builder: (BuildContext context, BannerState state) {
                                              List<dynamic> banners = [];
                                              if (state is BannerLoaded) {
                                                banners = state.bannerData;
                                              }
                                              final bannerHeight = (1.sw * 9 / 16);
                                              return SizedBox(
                                                height: bannerHeight + 30.h,
                                                child: VendorAdBannerStrip(position: 'category_page', height: bannerHeight, existingBanners: banners),
                                              );
                                            },
                                          ),
                                        ),
                                        const SliverToBoxAdapter(child: SubCategoryFeatureSectionWidget()),
                                        SliverToBoxAdapter(
                                          child: BrandsSection(
                                            brandsSectionTitle: AppLocalizations.of(context)?.topBrands ?? 'Top Brands',
                                            categorySlug: category.slug ?? '',
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: BlocBuilder<FeatureSectionProductBloc, FeatureSectionProductState>(
                                            builder: (context, state) {
                                              if (state is FeatureSectionProductLoaded) {
                                                return ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  physics: NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  itemCount: state.hasReachedMax ? state.featureSectionProductData.length : state.featureSectionProductData.length + 1,
                                                  itemBuilder: (context, index) {
                                                    if (index >= state.featureSectionProductData.length) {
                                                      return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CustomCircularProgressIndicator()));
                                                    }
                                                    return ProductFeatureSectionWidget(
                                                      featureSectionData: state.featureSectionProductData[index],
                                                      featureSectionSlug: state.featureSectionProductData[index].slug ?? '',
                                                    );
                                                  },
                                                );
                                              } else if (state is FeatureSectionProductLoading) {
                                                return productFeaturedSectionEmptyState();
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        const SliverToBoxAdapter(child: SizedBox(height: 70)),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList());

                if (state is CategoryFailed && isRetry) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() { isRetry = false; });
                      }
                    });
                  });
                }

                if ((state is CategoryLoading || state is CategoryInitial) && _categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomCircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)?.loading ?? 'Loading...', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ],
                    ),
                  );
                }

                if (state is CategoryFailed) {
                  return EmptyStatePage(
                    title: 'Connection Error',
                    description: 'Failed to load categories. Please try again.',
                    imageAsset: 'assets/images/icons/server_error.png',
                    onRetry: () {
                      setState(() { isRetry = true; });
                      context.read<CategoryBloc>().add(FetchCategory(isHome: true));
                    },
                  );
                }

                return NestedScrollView(
                  controller: nestedScrollController,
                  physics: _canUseTabController ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: _canUseTabController ? 195.0 : 120,
                        floating: false,
                        pinned: true,
                        elevation: 3,
                        shadowColor: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.2),
                        backgroundColor: Color.lerp(Colors.transparent, const Color(0xFFBDDCFB), 1 - _appBarOpacity),
                        automaticallyImplyLeading: false,
                        title: _buildTopAddress(),
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: isDarkMode(context) ? null : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF89C4F4), Color(0xFF89C4F4), Color(0xFF89C4F4), Color(0xFFb5d9f7), Colors.white],
                            ),
                            color: isDarkMode(context) ? AppTheme.darkProductCardColor : null,
                          ),
                          child: FlexibleSpaceBar(background: _buildFlexibleSpaceBackground()),
                        ),
                        bottom: _canUseTabController
                            ? PreferredSize(
                                preferredSize: const Size.fromHeight(70),
                                child: Column(
                                  children: [
                                    CustomAnimatedTextField(),
                                    const SizedBox(height: 5),
                                    _canUseTabController
                                        ? TabBar(
                                            controller: _tabController,
                                            isScrollable: true,
                                            tabAlignment: TabAlignment.start,
                                            enableFeedback: true,
                                            labelColor: Colors.black,
                                            automaticIndicatorColorAdjustment: true,
                                            unselectedLabelColor: textColor?.withValues(alpha: 0.6) ?? Theme.of(context).colorScheme.onSurfaceVariant,
                                            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                            indicatorColor: Colors.black,
                                            indicatorWeight: 3,
                                            indicatorSize: TabBarIndicatorSize.label,
                                            padding: const EdgeInsets.symmetric(horizontal: 0),
                                            tabs: tabBarTabs,
                                          )
                                        : const SizedBox(height: 50),
                                  ],
                                ),
                              )
                            : PreferredSize(
                                preferredSize: const Size.fromHeight(30),
                                child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: CustomAnimatedTextField()),
                              ),
                      ),
                    ];
                  },
                  body: _canUseTabController
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            _handleScrollNotification(notification);
                            if (notification is ScrollUpdateNotification) {
                              final metrics = notification.metrics;
                              if (metrics.pixels >= metrics.maxScrollExtent * 0.85) {
                                _loadMoreForCurrentTab(_tabController.index);
                              }
                            }
                            return false;
                          },
                          child: TabBarView(key: ValueKey(_tabBarViewKey), physics: NeverScrollableScrollPhysics(), controller: _tabController, children: tabBarViewChildren),
                        )
                      : const Center(child: CustomCircularProgressIndicator()),
                );
              },
            ),
            if (isRetry)
              Positioned.fill(
                top: 120,
                child: const Center(child: CustomCircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _loadMoreForCurrentTab(int tabIndex) {
    if (_isLoadingMoreForTab[tabIndex] == true) return;

    final featureSectionState = context.read<FeatureSectionProductBloc>().state;
    if (featureSectionState is FeatureSectionProductLoaded && !featureSectionState.hasReachedMax) {
      final slug = tabIndex == 0 ? '' : (tabIndex - 1 < _categories.length) ? _categories[tabIndex - 1].slug ?? '' : '';

      _isLoadingMoreForTab[tabIndex] = true;
      context.read<FeatureSectionProductBloc>().add(FetchMoreFeatureSectionProducts(slug: slug));

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _isLoadingMoreForTab[tabIndex] = false;
        }
      });
    }
  }

  EdgeInsets _getPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.04;
    return EdgeInsets.symmetric(horizontal: horizontalPadding);
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 6;
    if (screenWidth >= 800) return 5;
    if (screenWidth >= 600) return 4;
    if (screenWidth >= 400) return 4;
    return 3;
  }

  double _getSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * 0.04;
  }

  Widget subCategoryLoading() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: _getPadding(context).copyWith(top: 12.0, bottom: 12.0),
            child: ShimmerWidget.rectangular(isBorder: true, height: 18, width: 200, borderRadius: 15),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: _getPadding(context),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: _getSpacing(context),
              mainAxisSpacing: _getSpacing(context),
              childAspectRatio: 0.65,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return ShimmerWidget.rectangular(isBorder: true, width: double.infinity, height: 200);
            },
          ),
        ],
      ),
    );
  }

  void scrollToTop({bool animated = true}) {
    if (!nestedScrollController.hasClients) return;

    if (animated) {
      nestedScrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      nestedScrollController.jumpTo(0.0);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    _latestScrollPixels = notification.metrics.pixels;

    final bool isScrollingUp = _latestScrollPixels < _lastScrollPixels;
    final bool shouldShowButton = isScrollingUp && _latestScrollPixels > _scrollThreshold;
    if (shouldShowButton != _showScrollToTop) {
      setState(() { _showScrollToTop = shouldShowButton; });
    }

    _lastScrollPixels = _latestScrollPixels;
    return false;
  }
}