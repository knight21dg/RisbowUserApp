import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/model/featured_section_product_model.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';

import '../../../utils/widgets/featured_product_card.dart';
import '../../product_listing_page/model/product_listing_type.dart';

class ProductFeatureSectionWidget extends StatelessWidget {
  final FeatureSectionData featureSectionData;
  final String featureSectionSlug;

  const ProductFeatureSectionWidget({
    super.key,
    required this.featureSectionData,
    required this.featureSectionSlug,
  });

  ProductVariants _getDefaultVariant(ProductData data) {
    if (data.variants.isEmpty) return ProductVariants();
    try {
      return data.variants.firstWhere((v) => v.isDefault);
    } catch (_) {
      return data.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = featureSectionData.products ?? [];
    final validProducts = products.where((d) => d.variants.isNotEmpty).toList();
    if (validProducts.isEmpty) return const SizedBox.shrink();

    final rowCount = ((validProducts.length / 2).ceil()).clamp(0, 4);
    final gridHeight = rowCount * 190.h + (rowCount - 1) * 8.h;

    return Container(
      color: const Color(0xFFF7F7F7),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Text(
                  'Deals You Can\'t Miss',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
                ),
                SizedBox(width: 12.w),
                Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                SizedBox(width: 8.w),
                InkWell(
                  borderRadius: BorderRadius.circular(6.r),
                  onTap: () => GoRouter.of(context).push(
                    AppRoutes.productListing,
                    extra: {
                      'isTheirMoreCategory': false,
                      'title': featureSectionData.title,
                      'logo': '',
                      'totalProduct': 10,
                      'type': ProductListingType.featuredSection,
                      'identifier': featureSectionSlug,
                    },
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF1565C0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // 2-column product grid
          SizedBox(
            height: gridHeight,
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 0.72,
              ),
              itemCount: validProducts.length > 8 ? 8 : validProducts.length,
              itemBuilder: (context, index) {
                final data = validProducts[index];
                final variant = _getDefaultVariant(data);
                return FeaturedProductCard(
                  productId: data.id,
                  productImage: data.mainImage,
                  productName: data.title,
                  productSlug: data.slug,
                  productPrice: variant.mrp > 0 ? variant.mrp : variant.price.toDouble(),
                  specialPrice: variant.specialPrice.toDouble(),
                  indicator: data.indicator,
                  variantTitle: variant.title,
                  stock: variant.stock,
                  estimatedDeliveryTime: data.estimatedDeliveryTime,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
