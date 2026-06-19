import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/model/banner_model.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';
import 'package:hyper_local/widgets/banner_media_widget.dart';

import '../../../config/constant.dart';

class AutoPlayCarouselSlider extends StatefulWidget {
  final List<Top> banners;
  final double height;
  final Duration autoPlayInterval;

  const AutoPlayCarouselSlider({
    super.key,
    required this.banners,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<AutoPlayCarouselSlider> createState() => _AutoPlayCarouselSliderState();
}

class _AutoPlayCarouselSliderState extends State<AutoPlayCarouselSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isTabletMode = isTablet(context);
    final height = isTabletMode ? 280.h : 240.h;

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: widget.banners.length,
            options: CarouselOptions(
              height: height,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayInterval: widget.autoPlayInterval,
              autoPlayAnimationDuration: const Duration(milliseconds: 500),
              autoPlayCurve: Curves.easeInOut,
              pauseAutoPlayOnTouch: false,
              pauseAutoPlayOnManualNavigate: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final banner = widget.banners[index];
              final String? imageUrl = banner.bannerImage;
              
              return GestureDetector(
                onTap: () => _navigateToProductListing(banner, context),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          BannerMediaWidget(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            autoPlay: true,
                            muteVideos: true,
                          )
                        else
                          Container(color: Colors.grey[200]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        _buildCustomIndicator(),
      ],
    );
  }

  Widget _buildCustomIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.banners.length,
        (index) {
          final isActive = _currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: isActive ? 20.w : 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _navigateToProductListing(Top banner, BuildContext context) {
    switch (banner.type) {
      case 'brand':
        GoRouter.of(context).push(
          AppRoutes.productListing,
          extra: {
            'isTheirMoreCategory': false,
            'title': banner.title,
            'logo': banner.bannerImage,
            'totalProduct': '',
            'type': ProductListingType.brand,
            'identifier': banner.brandSlug,
          }
        );
        break;

      case 'category':
        GoRouter.of(context).push(
            AppRoutes.productListing,
            extra: {
              'isTheirMoreCategory': false,
              'title': banner.title,
              'logo': banner.bannerImage,
              'totalProduct': '',
              'type': ProductListingType.category,
              'identifier': banner.categorySlug,
            }
        );
        break;

      case 'product':
        final slug = banner.productSlug?.toString() ?? '';
        if (slug.isEmpty) {
          return;
        }
        GoRouter.of(context).push(
          AppRoutes.productDetailPage,
          extra: {'productSlug': slug},
        );
        break;

      case 'custom_sale_page':
        final salePageSlug = banner.customSalePageSlug?.toString() ?? '';
        final salePageId = banner.customSalePageId;
        
        if (salePageId != null) {
          GoRouter.of(context).push('/custom-sale-page/$salePageId');
        } else if (salePageSlug.isNotEmpty) {
          GoRouter.of(context).push('/custom-sale-page/$salePageSlug');
        } else {
          log('Banner has no customSalePage identifier');
        }
        break;

      case 'rooms':
        GoRouter.of(context).push(AppRoutes.rooms);
        break;

      case 'room_detail':
        final code = banner.roomCode ?? banner.slug ?? '';
        if (code.isNotEmpty) {
           GoRouter.of(context).push('/room/$code');
        } else {
          log('Banner has no roomCode');
        }
        break;

      case 'custom':
        final url = banner.customUrl?.toString() ?? '';
        if (url.isNotEmpty) {
          if (url.startsWith('http://') || url.startsWith('https://')) {
            GoRouter.of(context).push('/webview?url=${Uri.encodeComponent(url)}');
          } else {
            GoRouter.of(context).push(url);
          }
        }
        break;
      
      case 'external':
        final externalUrl = banner.customUrl?.toString() ?? '';
        if (externalUrl.isNotEmpty) {
          GoRouter.of(context).push('/webview?url=${Uri.encodeComponent(externalUrl)}');
        }
        break;

      default:
        log('Unknown banner type: ${banner.type}');
        return;
    }
  }
}