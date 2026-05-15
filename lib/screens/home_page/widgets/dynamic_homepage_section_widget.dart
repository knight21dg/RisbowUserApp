import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/home_page/model/homepage_section_model.dart';

class DynamicHomepageSectionWidget extends StatelessWidget {
  final HomepageSectionModel section;

  const DynamicHomepageSectionWidget({
    super.key,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final products = section.products;
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final bgColor = section.backgroundColor != null
        ? Color(int.parse(section.backgroundColor!.replaceFirst('#', '0xFF')))
        : const Color(0xFFF7F7F7);
    final txtColor = section.textColor != null
        ? Color(int.parse(section.textColor!.replaceFirst('#', '0xFF')))
        : Colors.black;

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, txtColor),
          SizedBox(height: 16.h),
          SizedBox(
            height: _getSectionHeight(section.sectionType),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(right: _getSectionItemSpacing(section.sectionType)),
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
    if (type == 'deals' || type == 'deal_of_day' || type == 'special_products' || type == 'sale' || section.title.toLowerCase().contains('deal')) {
      return 300.h;
    }
    if (type == 'featured' || type == 'special' || section.title.toLowerCase().contains('featured')) {
      return 200.h;
    }
    return 260.h;
  }

  double _getSectionItemSpacing(String sectionType) {
    final type = sectionType.toLowerCase();
    if (type == 'deals' || type == 'deal_of_day' || type == 'special_products' || type == 'sale') {
      return 16.w;
    }
    if (type == 'featured' || type == 'special') {
      return 14.w;
    }
    return 12.w;
  }

  Widget _buildSectionHeader(BuildContext context, Color txtColor) {
    final sectionType = section.sectionType.toLowerCase();
    final isSpecialSection = sectionType == 'deals' ||
        sectionType == 'deal_of_day' ||
        sectionType == 'special_products' ||
        sectionType == 'sale' ||
        section.title.toLowerCase().contains('deal');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(width: 12.w),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          if (section.showViewAll) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _navigateToSection(context, section.viewAllRoute),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF1565C0)),
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
    final sectionType = section.sectionType.toLowerCase();
    final titleLower = section.title.toLowerCase();
    
    debugPrint('BUILD_CARD: Section Type: "$sectionType", Title: "${section.title}"');

    // Priority 1: Deal of the Day / Deals sections
    if (sectionType == 'deals' || sectionType == 'deal_of_day' || sectionType == 'special_products' || 
        sectionType == 'sale' || titleLower.contains('deal') || titleLower.contains('sale')) {
      debugPrint('  -> Using DealOfDayCard');
      return _buildDealOfDayCard(context, product, index);
    } 
    // Priority 2: Featured Products
    else if (sectionType == 'featured' || sectionType == 'specific_products' || titleLower.contains('featured')) {
      debugPrint('  -> Using FeaturedCard');
      return _buildFeaturedCard(context, product, index);
    } 
    // Priority 3: Trending / Best Sellers / New Arrivals
    else if (sectionType == 'best_sellers' || sectionType == 'trending' || sectionType == 'new_arrivals' || 
             sectionType == 'all' || sectionType == 'default' || titleLower.contains('trending') || 
             titleLower.contains('best seller')) {
      debugPrint('  -> Using TrendingCard');
      return _buildTrendingCard(context, product, index);
    } 
    // Priority 4: Category based
    else if (sectionType == 'category_based' || titleLower.contains('category') || titleLower.contains('shop by')) {
      debugPrint('  -> Using CategoryCard');
      return _buildCategoryCard(context, product, index);
    } 
    // Default: Normal card
    else {
      debugPrint('  -> Using NormalCard');
      return _buildNormalCard(context, product, index);
    }
  }

  Widget _buildDealOfDayCard(BuildContext context, HomepageProduct product, int index) {
    final discount = product.discountPercent ?? (product.mrp > product.price ? ((product.mrp - product.price) / product.mrp * 100).round() : 0);
    final showDiscount = discount > 0;
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 148.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 1, child: Stack(children: [
            Image.network(product.mainImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300))),
            if (showDiscount)
              Positioned(bottom: 6.w, right: 6.w, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                child: Text('-$discount%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          ])),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(product.title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                if (showDiscount) ...[SizedBox(width: 4.w), Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough))],
              ]),
              SizedBox(height: 2.h),
              Row(children: [
                if (showDiscount) Text('$discount% off', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(width: 26.w, height: 26.w, decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                  child: Icon(Icons.add, color: Colors.white, size: 16.w)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, HomepageProduct product, int index) {
    final discount = product.discountPercent ?? (product.mrp > product.price ? ((product.mrp - product.price) / product.mrp * 100).round() : 0);
    final showDiscount = discount > 0;
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 148.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 1, child: Stack(children: [
            Image.network(product.mainImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300))),
            if (showDiscount)
              Positioned(bottom: 6.w, right: 6.w, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                child: Text('-$discount%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          ])),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(product.title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                if (showDiscount) ...[SizedBox(width: 4.w), Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough))],
              ]),
              SizedBox(height: 2.h),
              Row(children: [
                if (showDiscount) Text('$discount% off', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(width: 26.w, height: 26.w, decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                  child: Icon(Icons.add, color: Colors.white, size: 16.w)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, HomepageProduct product, int index) {
    final discount = product.discountPercent ?? (product.mrp > product.price ? ((product.mrp - product.price) / product.mrp * 100).round() : 0);
    final showDiscount = discount > 0;

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 140.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Image.network(
                    product.mainImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300)),
                  ),
                  if (showDiscount)
                    Positioned(
                      bottom: 6.w, right: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                        child: Text('-$discount%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                      if (showDiscount) ...[
                        SizedBox(width: 4.w),
                        Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (showDiscount)
                        Text('$discount% off', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        width: 26.w, height: 26.w,
                        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                        child: Icon(Icons.add, color: Colors.white, size: 16.w),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, HomepageProduct product, int index) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 180.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 130.h,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16.r),
                ),
                child: Image.network(
                  product.mainImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[100],
                      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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

  Widget _buildNormalCard(BuildContext context, HomepageProduct product, int index) {
    final discount = product.discountPercent ?? (product.mrp > product.price ? ((product.mrp - product.price) / product.mrp * 100).round() : 0);
    final showDiscount = discount > 0;
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: 148.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 1, child: Stack(children: [
            Image.network(product.mainImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300))),
            if (showDiscount)
              Positioned(bottom: 6.w, right: 6.w, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                child: Text('-$discount%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          ])),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(product.title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${product.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                if (showDiscount) ...[SizedBox(width: 4.w), Text('₹${product.mrp.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough))],
              ]),
              SizedBox(height: 2.h),
              Row(children: [
                if (showDiscount) Text('$discount% off', style: TextStyle(fontSize: 9.sp, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(width: 26.w, height: 26.w, decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                  child: Icon(Icons.add, color: Colors.white, size: 16.w)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  IconData _getSectionIcon(String sectionType) {
    switch (sectionType) {
      case 'deal_of_day':
        return Icons.flash_on;
      case 'trending':
        return Icons.local_fire_department;
      case 'personalized':
        return Icons.auto_awesome;
      case 'recently_viewed':
        return Icons.access_time_filled;
      case 'continue_shopping':
        return Icons.shopping_bag_outlined;
      case 'frequently_bought':
        return Icons.repeat;
      case 'specific_products':
        return Icons.star_rounded;
      case 'category_based':
        return Icons.category_outlined;
      case 'similar_products':
        return Icons.compare_arrows;
      case 'best_sellers':
        return Icons.emoji_events;
      case 'new_arrivals':
        return Icons.new_releases;
      case 'featured':
        return Icons.star;
      case 'sale':
        return Icons.sell;
      case 'special_products':
        return Icons.card_giftcard;
      default:
        return Icons.flash_on;
    }
  }

  void _navigateToSection(BuildContext context, String? route) {
    switch (route) {
      case 'trending':
        context.push('/products?sort=best_seller');
        break;
      case 'personalized':
        context.push('/products?sort=best_seller');
        break;
      case 'recently_viewed':
        context.push('/products?sort=newest');
        break;
      case 'best_sellers':
        context.push('/products?sort=best_seller');
        break;
      case 'new_arrivals':
        context.push('/products?sort=newest');
        break;
      case 'featured':
        context.push('/products?sort=featured');
        break;
      default:
        context.push('/products');
    }
  }
}