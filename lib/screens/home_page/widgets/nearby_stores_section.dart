import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:shimmer/shimmer.dart';

class NearbyStoresSection extends StatelessWidget {
  const NearbyStoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureSettingsService.instance.nearbyStoresEnabled) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<NearByStoreBloc, NearByStoreState>(
      builder: (context, state) {
        if (state is NearByStoreInitial) {
          return _buildShimmer(context);
        }
        if (state is NearByStoreLoading) {
          return _buildShimmer(context);
        }
        if (state is NearByStoreFailed) {
          return _buildError(context);
        }
        if (state is NearByStoreLoaded) {
          final rawStores = state.stores.data;
          if (rawStores == null || rawStores.isEmpty) {
            return _buildEmpty(context);
          }

          final stores = List<StoreData>.from(rawStores);
          _sortStores(stores);
          final displayStores = stores.take(10).toList();

          return _buildSection(context, stores.length, displayStores);
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _sortStores(List<StoreData> stores) {
    stores.sort((a, b) {
      final aPromoted = a.isPromoted == true ? 0 : 1;
      final bPromoted = b.isPromoted == true ? 0 : 1;
      if (aPromoted != bPromoted) return aPromoted.compareTo(bPromoted);
      
      final distanceA = a.distance ?? 0.0;
      final distanceB = b.distance ?? 0.0;
      final distComp = distanceA.compareTo(distanceB);
      
      if (distComp != 0) return distComp;
      
      final ratingA = double.tryParse(a.avgProductsRating ?? '0.0') ?? 0.0;
      final ratingB = double.tryParse(b.avgProductsRating ?? '0.0') ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
  }

  void _onStoreTap(BuildContext context, StoreData store) {
    if (store.slug == null || store.slug!.isEmpty) return;
    context.push(
      AppRoutes.nearbyStoreDetails,
      extra: {'store-slug': store.slug, 'store-name': store.name},
    );
  }

  // -------------------------------------------------------
  //  SECTION (stores available)
  // -------------------------------------------------------
  Widget _buildSection(
    BuildContext context,
    int totalStores,
    List<StoreData> displayStores,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, totalStores),
        SizedBox(height: 12.h),
        SizedBox(
          height: 195.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: displayStores.length,
            itemBuilder: (context, index) {
              final store = displayStores[index];
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: _CompactStoreCard(
                  store: store,
                  onTap: () => _onStoreTap(context, store),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int totalStores) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)?.nearbyStores ?? 'Nearby Stores',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (totalStores > 5)
            GestureDetector(
              onTap: () => context.push(AppRoutes.nearbyStores),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  //  ERROR STATE
  // -------------------------------------------------------
  Widget _buildError(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.nearbyStores ?? 'Nearby Stores',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<NearByStoreBloc>().add(
                FetchNearByStores(perPage: 15, searchQuery: ''),
              );
            },
            icon: Icon(Icons.refresh, size: 16.sp),
            label: Text('Retry', style: TextStyle(fontSize: 12.sp)),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  //  EMPTY STATE
  // -------------------------------------------------------
  Widget _buildEmpty(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)?.nearbyStores ?? 'Nearby Stores',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.store_mall_directory_outlined,
                  size: 40.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.h),
                Text(
                  'No stores nearby',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Try searching in a different area',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  //  SHIMMER / LOADING STATE
  // -------------------------------------------------------
  Widget _buildShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final shimmerHighlight = isDark ? Colors.grey[600]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Container(
              width: 160.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 195.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Container(
                    width: 180.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16.r),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 16.h,
                                  width: 140.w,
                                  color: Colors.grey.shade100,
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  height: 14.h,
                                  width: 90.w,
                                  color: Colors.grey.shade100,
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}

// -------------------------------------------------------
//  COMPACT STORE CARD
// -------------------------------------------------------
class _CompactStoreCard extends StatelessWidget {
  final StoreData store;
  final VoidCallback? onTap;

  const _CompactStoreCard({required this.store, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double distance = store.distance ?? 0.0;
    final double rating = double.tryParse(store.avgProductsRating ?? '0.0') ?? 0.0;
    final bool isPromoted = store.isPromoted == true;
    final bool isOpen = store.status?.isOpen == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170.w,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: isDark ? null : Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner section (shorter)
            SizedBox(
              height: 60.h,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                    child: store.banner?.isNotEmpty == true
                        ? CustomImageContainer(imagePath: store.banner!, fit: BoxFit.cover)
                        : Container(
                            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.6 : 1.0),
                            child: Center(
                              child: Icon(Icons.storefront_rounded, size: 32.sp, color: Colors.white70),
                            ),
                          ),
                  ),
                  // Rating badge
                  if (rating > 0)
                    Positioned(
                      top: 6.h,
                      right: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 11.sp, color: Colors.amber),
                            SizedBox(width: 2.w),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Circular logo (bottom-left overlapping - smaller)
                  Positioned(
                    left: 10.w,
                    bottom: -14.h,
                    child: Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(2.w),
                      child: ClipOval(
                        child: store.logo?.isNotEmpty == true
                            ? CustomImageContainer(imagePath: store.logo!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.blue.shade50,
                                child: Icon(Icons.store, size: 18.sp, color: AppTheme.primaryColor),
                              ),
                      ),
                    ),
                  ),
                  // Promoted badge
                  if (isPromoted)
                    Positioned(
                      left: 48.w,
                      bottom: -6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)]),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          'Promoted',
                          style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Store info section (more compact)
            SizedBox(
              height: 52.h,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 18.h, 10.w, 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      store.name ?? "Unknown Store",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 11.sp, color: Colors.blue.shade300),
                        SizedBox(width: 2.w),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 10.sp, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          width: 4.w,
                          height: 4.w,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? Colors.green : Colors.red.shade300),
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: isOpen ? Colors.green.shade700 : Colors.red.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
