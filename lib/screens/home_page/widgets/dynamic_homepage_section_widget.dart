import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/home_page/model/homepage_section_model.dart';
import 'package:hyper_local/screens/home_page/model/banner_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DynamicHomepageSectionWidget extends StatefulWidget {
  final HomepageSectionModel section;

  const DynamicHomepageSectionWidget({
    super.key,
    required this.section,
  });

  @override
  State<DynamicHomepageSectionWidget> createState() => _DynamicHomepageSectionWidgetState();
}

class _DynamicHomepageSectionWidgetState extends State<DynamicHomepageSectionWidget> {
  int _currentBannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final products = widget.section.products;
    final banners = widget.section.banners;
    final isBanner = widget.section.sectionType == 'banner';
    final isBannerSlider = widget.section.sectionType == 'banner_slider';
    final isImageStrip = widget.section.sectionType == 'image_strip';

    if (products.isEmpty && (banners == null || banners.isEmpty)) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color txtColor;
    try {
      bgColor = widget.section.backgroundColor != null && widget.section.backgroundColor!.length == 7
          ? Color(int.parse(widget.section.backgroundColor!.replaceFirst('#', '0xFF')))
          : const Color(0xFFF7F7F7);
    } catch (_) {
      bgColor = const Color(0xFFF7F7F7);
    }
    try {
      txtColor = widget.section.textColor != null && widget.section.textColor!.length == 7
          ? Color(int.parse(widget.section.textColor!.replaceFirst('#', '0xFF')))
          : Colors.black;
    } catch (_) {
      txtColor = Colors.black;
    }

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, txtColor),
          SizedBox(height: 16.h),
          if (isBanner && banners != null && banners.isNotEmpty)
            _buildSingleBanner(context, banners.first)
          else if (isBannerSlider && banners != null && banners.isNotEmpty)
            _buildBannerSlider(context, banners)
          else if (isImageStrip && banners != null && banners.isNotEmpty)
            _buildImageStrip(context, banners)
          else
            SizedBox(
              height: _getSectionHeight(widget.section.sectionType),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(right: _getSectionItemSpacing(widget.section.sectionType)),
                    child: _buildProductCard(context, product, index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  double _getSectionHeight(String sectionType) {
    final type = sectionType.toLowerCase();
    if (type == 'deals' || type == 'deal_of_day' || type == 'special_products' || type == 'sale') {
      return 260.h;
    }
    return 230.h;
  }

  double _getSectionItemSpacing(String sectionType) {
    return 16.w;
  }

  Widget _buildSectionHeader(BuildContext context, Color txtColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getSectionIcon(widget.section.sectionType),
              size: 18.sp,
              color: const Color(0xFF1565C0),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              widget.section.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.section.showViewAll) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: () => _navigateToSection(context, widget.section.viewAllRoute),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 10.sp, color: const Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, HomepageProduct product, int index) {
    final discount = product.discountPercent ?? (product.mrp > product.price ? ((product.mrp - product.price) / product.mrp * 100).round() : 0);
    final showDiscount = discount > 0;

    return GestureDetector(
      onTap: () => context.push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.mainImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                    ),
                  ),
                ),
                if (showDiscount)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$discount% OFF',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${product.price.toInt()}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      if (showDiscount) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '₹${product.mrp.toInt()}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.05),
              ),
              child: Center(
                child: Text(
                  'ADD TO CART',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1565C0),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleBanner(BuildContext context, Top banner) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: () => _handleBannerTap(context, banner),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: CachedNetworkImage(
              imageUrl: banner.bannerImage ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSlider(BuildContext context, List<Top> banners) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = banners[index];
            return GestureDetector(
              onTap: () => _handleBannerTap(context, banner),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: CachedNetworkImage(
                    imageUrl: banner.bannerImage ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 180.h,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            autoPlayCurve: Curves.fastOutSlowIn,
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentBannerIndex == entry.key ? 20.w : 6.w,
              height: 6.w,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.r),
                color: _currentBannerIndex == entry.key
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF1565C0).withOpacity(0.2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Horizontal scrolling strip of image cards — used by image_strip section type
  Widget _buildImageStrip(BuildContext context, List<Top> banners) {
    return SizedBox(
      height: 130.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final banner = banners[index];
          return GestureDetector(
            onTap: () => _handleBannerTap(context, banner),
            child: Container(
              width: 110.w,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: CachedNetworkImage(
                      imageUrl: banner.bannerImage ?? '',
                      width: 110.w,
                      height: 130.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 110.w,
                          height: 130.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 110.w,
                        height: 130.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 28.sp,
                        ),
                      ),
                    ),
                  ),
                  // Title overlay at the bottom (optional — shown if banner has a title)
                  if (banner.title != null && banner.title!.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14.r),
                          bottomRight: Radius.circular(14.r),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            banner.title!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleBannerTap(BuildContext context, Top banner) {
    final bannerType = banner.type ?? banner.scopeType;
    switch (bannerType) {
      case 'product':
        if (banner.productSlug != null) {
          context.push('/product-detail?slug=${banner.productSlug}');
        }
        break;
      case 'category':
        if (banner.categorySlug != null) {
          context.push('/category-detail?slug=${banner.categorySlug}');
        }
        break;
      case 'brand':
        if (banner.brandSlug != null) {
          context.push('/brand-detail?slug=${banner.brandSlug}');
        }
        break;
      case 'custom_sale_page':
        if (banner.customSalePageSlug != null) {
          context.push('/custom-sale-page?slug=${banner.customSalePageSlug}');
        }
        break;
      case 'rooms':
      case 'room_detail':
        if (banner.roomCode != null) {
          context.push('/rooms/${banner.roomCode}');
        }
        break;
      case 'external':
        if (banner.customUrl != null && banner.customUrl!.isNotEmpty) {
          // launchUrl(Uri.parse(banner.customUrl!));
        }
        break;
      default:
        if (banner.productSlug != null) {
          context.push('/product-detail?slug=${banner.productSlug}');
        } else if (banner.customSalePageSlug != null) {
          context.push('/custom-sale-page?slug=${banner.customSalePageSlug}');
        }
        break;
    }
  }

  IconData _getSectionIcon(String sectionType) {
    switch (sectionType) {
      case 'deal_of_day': return Icons.flash_on_rounded;
      case 'trending': return Icons.local_fire_department_rounded;
      case 'personalized': return Icons.auto_awesome_rounded;
      case 'recently_viewed': return Icons.history_rounded;
      case 'category_based': return Icons.grid_view_rounded;
      case 'specific_products': return Icons.star_rounded;
      case 'banner': return Icons.campaign_rounded;
      case 'banner_slider': return Icons.collections_rounded;
      case 'image_strip': return Icons.photo_library_rounded;
      default: return Icons.rocket_launch_rounded;
    }
  }

  void _navigateToSection(BuildContext context, String? route) {
    switch (route) {
      case 'trending': context.push('/products?sort=best_seller'); break;
      case 'personalized': context.push('/products?sort=best_seller'); break;
      case 'recently_viewed': context.push('/products?sort=newest'); break;
      default: context.push('/products');
    }
  }
}