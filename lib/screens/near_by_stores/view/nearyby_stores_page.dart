import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config/constant.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import '../../../utils/widgets/custom_textfield.dart';

class NearbyStoresPage extends StatefulWidget {
  final String? categorySlug;
  final String? categoryTitle;

  const NearbyStoresPage({super.key, this.categorySlug, this.categoryTitle});

  @override
  State<NearbyStoresPage> createState() => _NearbyStoresPageState();
}

class _NearbyStoresPageState extends State<NearbyStoresPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late NearByStoreBloc _bloc;
  String? _lastLocationIdentifier;
  Timer? _debounceTimer;
  String _currentSearchQuery = '';
  double _radiusKm = 10.0;
  late VoidCallback _locationListener;

  @override
  void initState() {
    super.initState();
    _bloc = NearByStoreBloc()..add(FetchNearByStores(perPage: 15, searchQuery: '', category: widget.categorySlug));
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _locationListener = _onLocationBoxChanged;
    Hive.box<dynamic>('userLocationBox').listenable().addListener(_locationListener);
  }

  void _onLocationBoxChanged() {
    final box = Hive.box<dynamic>('userLocationBox');
    final storedLocation = box.get('user_location');
    final locationIdentifier = storedLocation == null
        ? null
        : '${storedLocation.latitude}_${storedLocation.longitude}_${storedLocation.fullAddress}_${storedLocation.area}_${storedLocation.city}_${storedLocation.pincode}';
    if (_lastLocationIdentifier != locationIdentifier) {
      _lastLocationIdentifier = locationIdentifier;
      _bloc.add(FetchNearByStores(
        perPage: 15,
        searchQuery: _currentSearchQuery,
      ));
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer - wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final searchQuery = _searchController.text.trim();

      // Only search if query has changed
      if (_currentSearchQuery != searchQuery) {
        _currentSearchQuery = searchQuery;
        _performSearch(searchQuery);
      }
    });
  }

  void _performSearch(String searchQuery) {
    // Reset scroll position when searching
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Trigger search
    _bloc.add(FetchNearByStores(perPage: 15, searchQuery: searchQuery, category: widget.categorySlug));
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _currentSearchQuery = '';
    });
    FocusScope.of(context).unfocus();
    _performSearch('');
  }

  void _showRadiusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Distance',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_radiusKm.toStringAsFixed(0)} km',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_radiusKm.toStringAsFixed(0)} km',
                    onChanged: (value) {
                      setModalState(() {
                        _radiusKm = value;
                      });
                      setState(() {
                        _radiusKm = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km', style: TextStyle(color: Colors.grey[600])),
                      Text('50 km', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        _bloc.state is NearByStoreLoaded) {
      final state = _bloc.state as NearByStoreLoaded;
      if (!state.hasReachedMax) {
        _bloc.add(LoadMoreNearByStores(
          perPage: 15,
          searchQuery: _currentSearchQuery,
          category: widget.categorySlug,
        ));
      }
    }
  }

  @override
  void dispose() {
    Hive.box<dynamic>('userLocationBox').listenable().removeListener(_locationListener);
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: true,
      // title: AppLocalizations.of(context)?.nearbyStores ?? 'Nearby Stores',
      // showAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.nearbyStores ?? widget.categoryTitle ?? 'Nearby Stores',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: isTablet(context) ? 24 : 16.sp
                ),
              ),
            ),
            GestureDetector(
              onTap: _showRadiusFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(51),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_radiusKm.toInt()} km',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _buildSearchBar()),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: CustomRefreshIndicator(
          onRefresh: () async {
            _bloc.add(FetchNearByStores(
              perPage: 15,
              searchQuery: _currentSearchQuery,
            ));
          },
          child: BlocBuilder<NearByStoreBloc, NearByStoreState>(
            builder: (context, state) {
                  if (state is NearByStoreInitial || state is NearByStoreLoading) {
                    return const CustomCircularProgressIndicator();
                  }
                  if (state is NearByStoreFailed) {
                    return NoStorePage(
                      onRetry: (){
                        _bloc.add(FetchNearByStores(
                          searchQuery: _currentSearchQuery,
                        ));
                      },
                    );
                  }
                  if (state is NearByStoreLoaded) {
                    var stores = List<StoreData>.from(state.stores.data ?? []);
                    
                    // Sort by distance (low to high), then by rating (high to low)
                    stores.sort((a, b) {
                      final distanceA = a.distance ?? 0.0;
                      final distanceB = b.distance ?? 0.0;
                      final distComp = distanceA.compareTo(distanceB);
                      
                      if (distComp != 0) return distComp;
                      
                      final ratingA = double.tryParse(a.avgProductsRating ?? '0.0') ?? 0.0;
                      final ratingB = double.tryParse(b.avgProductsRating ?? '0.0') ?? 0.0;
                      return ratingB.compareTo(ratingA);
                    });
                    
                    // Filter by radius
                    final filteredStores = stores.where((store) => (store.distance ?? 0) <= _radiusKm).toList();

                    if (filteredStores.isEmpty) {
                      return NoStorePage(
                        onRetry: (){_clearSearch();},
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 20),
                      controller: _scrollController,
                      itemCount: filteredStores.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= filteredStores.length) {
                          return const ShimmerStoreCard();
                        }

                        final store = filteredStores[index];
                        return StoreCardBanner(
                          key: Key(store.slug ?? store.id.toString()),
                          store: store,
                          onTap: () {
                            GoRouter.of(context).push(
                              AppRoutes.nearbyStoreDetails,
                              extra: {
                                'store-slug': store.slug,
                                'store-name': store.name,
                              },
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45,
      margin: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 12),
      child: ValueListenableBuilder(
        valueListenable: _searchController,
        builder: (context, TextEditingValue value, __){
          return CustomTextFormField(
            controller: _searchController,

            hintText: 'Search for store',
            prefixIcon: Icons.search,
            suffixIcon: value.text.isNotEmpty ? Icons.close : null,
            onSuffixIconTap: () {
              if (_searchController.text.isNotEmpty) {
                _clearSearch();
              }
            },
            onChanged: (value){
              _onSearchChanged();
            },
            onFieldSubmitted: (value) {
              // Immediate search on submit
              _debounceTimer?.cancel();
              _currentSearchQuery = value.trim();
              _performSearch(_currentSearchQuery);
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               STORE CARD WIDGET                              */
/* -------------------------------------------------------------------------- */
class StoreCardBanner extends StatelessWidget {
  final StoreData store;
  final VoidCallback? onTap;

  const StoreCardBanner({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double distance = store.distance ?? 0.0;
    final double rating = double.tryParse(store.avgProductsRating ?? '0.0') ?? 0.0;
    final bool isOpen = store.status?.isOpen == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Logo
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: store.logo?.isNotEmpty == true
                    ? CustomImageContainer(imagePath: store.logo!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(Icons.store, size: 26.sp, color: Colors.grey.shade400),
                      ),
              ),
              SizedBox(width: 12.w),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name ?? "Unknown Store",
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (store.address?.isNotEmpty == true)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 13.sp, color: Colors.grey[400]),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              store.address!,
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(AppTheme.ratingStarIconFilled, size: 13.sp, color: AppTheme.ratingStarColor),
                        SizedBox(width: 3.w),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '-',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.near_me, size: 13.sp, color: Colors.blue.shade300),
                        SizedBox(width: 3.w),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? Colors.green.shade700 : Colors.red.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               SHIMMER CARD                                  */
/* -------------------------------------------------------------------------- */
class ShimmerStoreCard extends StatelessWidget {
  const ShimmerStoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(width: 52.w, height: 52.w, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 180.w, height: 16.h, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4.r))),
                    SizedBox(height: 8.h),
                    Container(width: 140.w, height: 12.h, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4.r))),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Container(width: 40.w, height: 12.h, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4.r))),
                        SizedBox(width: 12.w),
                        Container(width: 50.w, height: 12.h, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4.r))),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(width: 50.w, height: 28.h, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8.r))),
            ],
          ),
        ),
      ),
    );
  }
}
