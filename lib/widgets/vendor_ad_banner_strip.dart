import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/bloc/slot_banner/slot_banner_bloc.dart';
import 'package:hyper_local/screens/home_page/model/banner_model.dart';
import 'package:hyper_local/screens/home_page/model/slot_banner_model.dart';
import 'package:hyper_local/screens/near_by_stores/model/near_by_store_model.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';
import 'package:hyper_local/widgets/banner_media_widget.dart';

class VendorAdBannerStrip extends StatelessWidget {
  final String position;
  final String? storeSlug;
  final double height;
  final List<dynamic>? existingBanners;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const VendorAdBannerStrip({
    super.key,
    required this.position,
    this.storeSlug,
    this.existingBanners,
    this.height = 160,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SlotBannerBloc()
        ..add(FetchSlotBanners(position: position, storeSlug: storeSlug)),
      child: _SlotBannerStripContent(
        height: height,
        existingBanners: existingBanners,
        position: position,
        storeSlug: storeSlug,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
    );
  }
}

class _SlotBannerStripContent extends StatefulWidget {
  final double height;
  final String position;
  final String? storeSlug;
  final List<dynamic>? existingBanners;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const _SlotBannerStripContent({
    required this.height,
    required this.position,
    this.storeSlug,
    this.existingBanners,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  State<_SlotBannerStripContent> createState() => _SlotBannerStripContentState();
}

class _SlotBannerStripContentState extends State<_SlotBannerStripContent> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotBannerBloc, SlotBannerState>(
      builder: (context, state) {
        List<SlotBannerModel> ads = [];
        if (state is SlotBannerLoaded) {
          ads = state.banners;
        }

        final List<dynamic> localBanners = widget.existingBanners ?? [];
        final List<dynamic> combinedItems = [...localBanners, ...ads];

        // Filter out items with empty image URLs before checking if empty
        final validItems = combinedItems.where((item) => _hasValidImage(item)).toList();

        if (validItems.isEmpty) {
          if (state is SlotBannerLoading) {
            return _buildShimmer(context);
          }
          return const SizedBox.shrink();
        }

        return _buildCarousel(context, validItems);
      },
    );
  }

  bool _hasValidImage(dynamic item) {
    if (item is SlotBannerModel) {
      return (item.imageUrl ?? '').isNotEmpty;
    } else if (item is Top) {
      return (item.bannerImage ?? '').isNotEmpty;
    } else if (item is StoreBannerData) {
      return (item.image ?? '').isNotEmpty;
    } else if (item is Map) {
      final image = item['image'] ?? item['banner_image'] ?? '';
      return (image as String?)?.isNotEmpty ?? false;
    }
    return false;
  }

  Widget _buildShimmer(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(14.r),
      ),
    );
   }

  bool _isVideoUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.mp4') ||
           lowerUrl.contains('.mov') ||
           lowerUrl.contains('.m4v') ||
           lowerUrl.contains('.webm') ||
           lowerUrl.contains('.avi') ||
           lowerUrl.contains('.mkv');
  }

  Widget _buildCarousel(BuildContext context, List<dynamic> items) {
    return Column(
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
            boxShadow: widget.boxShadow ?? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height: widget.height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.easeInOut,
              pauseAutoPlayOnTouch: false,
              pauseAutoPlayOnManualNavigate: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
            items: items.asMap().entries.map((entry) {
              final item = entry.value;
              final bool isAd = item is SlotBannerModel;

              String imageUrl = '';

              if (isAd) {
                imageUrl = item.imageUrl ?? '';
              } else {
                if (item is Top) {
                  imageUrl = item.bannerImage ?? '';
                } else if (item is StoreBannerData) {
                  imageUrl = item.image ?? '';
                } else if (item is Map) {
                  imageUrl = item['image'] ?? item['banner_image'] ?? '';
                } else {
                  try {
                    final dynamicItem = item as dynamic;
                    imageUrl = (dynamicItem.image ?? dynamicItem.bannerImage ?? '')?.toString() ?? '';
                  } catch (_) {}
                }
              }

              // Skip items with empty image URLs
              if (imageUrl.isEmpty) {
                return const SizedBox.shrink();
              }

              final String title = isAd ? (item.title ?? '') : (item is Top ? (item.title ?? '') : '');

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
                  color: Colors.transparent,
                ),
                child: _buildBannerItem(context, item, isAd, imageUrl, title, entry.key),
              );
            }).toList(),
          ),
        ),
        if (items.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: items.asMap().entries.map((entry) {
                return Container(
                  width: _currentIndex == entry.key ? 16.w : 6.w,
                  height: 6.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    color: _currentIndex == entry.key
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBannerItem(BuildContext context, dynamic item, bool isAd, String imageUrl, String title, int index) {
    // Hide items without a valid image URL
    if (imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool isVideo = _isVideoUrl(imageUrl);

    return GestureDetector(
        onTap: () {
          if (isAd) {
            _handleBannerTap(context, targetUrl: item.targetUrl, adBanner: item);
          } else {
            String? targetUrl;
            Map<String, dynamic>? storeData;
            if (item is Map) {
              targetUrl = item['target_url']?.toString();
              storeData = item['store'] as Map<String, dynamic>?;
            } else {
              try {
                targetUrl = (item as dynamic).targetUrl?.toString();
                storeData = (item as dynamic).store as Map<String, dynamic>?;
              } catch (_) {}
            }
            if (targetUrl != null && targetUrl.isNotEmpty) {
              _handleBannerTap(context, targetUrl: targetUrl, storeData: storeData);
            } else {
              _handleNonAdNavigation(context, item);
            }
          }
        },
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
        child: BannerMediaWidget(
          url: imageUrl,
          fit: BoxFit.cover,
          autoPlay: true,
          muteVideos: true,
        ),
      ),
    );
  }

  void _handleBannerTap(BuildContext context, {String? targetUrl, SlotBannerModel? adBanner, Map<String, dynamic>? storeData}) {
    final url = targetUrl ?? '';
    if (url.isEmpty) {
      _navigateToStore(context, adBanner: adBanner, storeData: storeData);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _navigateToStore(context, adBanner: adBanner, storeData: storeData);
      return;
    }
    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      final prefix = segments[0];
      final slug = segments[1];
      if (prefix == 'p' && slug.isNotEmpty) {
        context.push('${AppRoutes.productDetailPage}?slug=$slug');
        return;
      }
      if (prefix == 's' && slug.isNotEmpty) {
        context.push('${AppRoutes.nearbyStoreDetails}?store-slug=$slug');
        return;
      }
      if (prefix == 'c' && slug.isNotEmpty) {
        context.push('${AppRoutes.productListing}?type=category&identifier=$slug');
        return;
      }
      if (prefix == 'r' && slug.isNotEmpty) {
        context.push('/room/$slug');
        return;
      }
      if (prefix == 'custom-sale-page' && slug.isNotEmpty) {
        context.push('/custom-sale-page/$slug');
        return;
      }
    }

    if (segments.isNotEmpty) {
      if (segments[0] == 'rooms') {
        context.push(AppRoutes.rooms);
        return;
      }
    }
    final query = uri.queryParameters;
    final productSlug = query['slug'] ?? query['product_slug'];
    final storeSlug = query['store-slug'] ?? query['store_slug'];
    if (productSlug != null && productSlug.isNotEmpty) {
      context.push('${AppRoutes.productDetailPage}?slug=$productSlug');
      return;
    }
    if (storeSlug != null && storeSlug.isNotEmpty) {
      context.push('${AppRoutes.nearbyStoreDetails}?store-slug=$storeSlug');
      return;
    }
    _navigateToStore(context, adBanner: adBanner, storeData: storeData);
  }

  void _navigateToStore(BuildContext context, {SlotBannerModel? adBanner, Map<String, dynamic>? storeData}) {
    String slug = '';
    String name = '';
    if (adBanner != null) {
      slug = adBanner.store?['slug']?.toString() ?? '';
      name = adBanner.store?['name']?.toString() ?? '';
    } else if (storeData != null) {
      slug = storeData['slug']?.toString() ?? '';
      name = storeData['name']?.toString() ?? '';
    }
    if (slug.isNotEmpty) {
      context.push(AppRoutes.nearbyStoreDetails, extra: {'store-slug': slug, 'store-name': name});
    }
  }

  /// Handles navigation for non-ad banners (e.g., home page banners, store page organic banners)
  void _handleNonAdNavigation(BuildContext context, dynamic item) {
    try {
      final type = (item as dynamic).type?.toString();
      switch (type) {
        case 'brand':
          final brandSlug = (item as dynamic).brandSlug?.toString();
          if (brandSlug != null && brandSlug.isNotEmpty) {
            context.push(AppRoutes.productListing, extra: {
              'isTheirMoreCategory': false,
              'title': (item as dynamic).title ?? '',
              'logo': (item as dynamic).bannerImage ?? '',
              'totalProduct': '',
              'type': ProductListingType.brand,
              'identifier': brandSlug,
            });
          }
          break;

        case 'category':
          final categorySlug = (item as dynamic).categorySlug?.toString();
          if (categorySlug != null && categorySlug.isNotEmpty) {
            context.push(AppRoutes.productListing, extra: {
              'isTheirMoreCategory': false,
              'title': (item as dynamic).title ?? '',
              'logo': (item as dynamic).bannerImage ?? '',
              'totalProduct': '',
              'type': ProductListingType.category,
              'identifier': categorySlug,
            });
          }
          break;

        case 'product':
          final productSlug = (item as dynamic).productSlug?.toString();
          if (productSlug != null && productSlug.isNotEmpty) {
            context.push('${AppRoutes.productDetailPage}?slug=$productSlug');
          }
          break;

        case 'custom_sale_page':
          final slug = (item as dynamic).customSalePageSlug?.toString() ??
                       (item as dynamic).slug?.toString();
          if (slug != null && slug.isNotEmpty) {
            context.push('/custom-sale-page/$slug');
          }
          break;

        case 'rooms':
          context.push(AppRoutes.rooms);
          break;

        case 'room_detail':
          final code = (item as dynamic).roomCode?.toString() ??
                       (item as dynamic).slug?.toString();
          if (code != null && code.isNotEmpty) {
            context.push('/room/$code');
          }
          break;

        case 'custom':
          final url = (item as dynamic).customUrl?.toString() ?? '';
          if (url.isNotEmpty) {
            if (url.startsWith('http://') || url.startsWith('https://')) {
              context.push('/webview?url=${Uri.encodeComponent(url)}');
            } else {
              context.push(url);
            }
          }
          break;

        case 'external':
          final externalUrl = (item as dynamic).customUrl?.toString() ?? '';
          if (externalUrl.isNotEmpty) {
            if (externalUrl.startsWith('http://') || externalUrl.startsWith('https://')) {
              context.push('/webview?url=${Uri.encodeComponent(externalUrl)}');
            } else {
              context.push(externalUrl);
            }
          }
          break;

        default:
          // If the item has a store field (e.g., StoreBannerData but already handled via targetUrl)
          // No action for unknown types
          break;
      }
    } catch (e) {
      debugPrint('Error handling non-ad banner navigation: $e');
    }
  }
}