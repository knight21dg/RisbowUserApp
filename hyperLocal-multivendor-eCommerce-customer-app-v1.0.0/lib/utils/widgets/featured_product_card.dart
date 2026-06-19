import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class FeaturedProductCard extends StatelessWidget {
  final int productId;
  final String productImage;
  final String productName;
  final String productSlug;
  final double productPrice;
  final double specialPrice;
  final String indicator;
  final String variantTitle;
  final int stock;
  final String estimatedDeliveryTime;

  const FeaturedProductCard({
    super.key,
    required this.productId,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.productPrice,
    required this.specialPrice,
    this.indicator = '',
    this.variantTitle = '',
    this.stock = 0,
    this.estimatedDeliveryTime = '',
  });

  double get discountPercentage {
    if (productPrice > 0 && specialPrice > 0 && productPrice > specialPrice) {
      return ((productPrice - specialPrice) / productPrice) * 100;
    }
    return 0;
  }

  bool get isVeg => indicator.toLowerCase() == 'veg';
  bool get outOfStock => stock <= 0;

  @override
  Widget build(BuildContext context) {
    final showDiscount = productPrice > specialPrice && specialPrice > 0;
    final displayPrice = specialPrice > 0 ? specialPrice : productPrice;

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=$productSlug'),
      child: Container(
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
                  productImage.trim().isNotEmpty
                      ? CustomImageContainer(imagePath: productImage, fit: BoxFit.cover, fallbackAsset: 'assets/images/placeholder.png')
                      : Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
                  if (outOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)),
                            child: Text('Out of Stock', style: TextStyle(color: Colors.black87, fontSize: 9.sp, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  if (indicator.isNotEmpty)
                    Positioned(
                      top: 6.w, left: 6.w,
                      child: Container(
                        width: 16.w, height: 16.w,
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(3.r),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3)],
                        ),
                        child: Center(
                          child: Container(
                            width: 9.w, height: 9.w,
                            decoration: BoxDecoration(
                              color: isVeg ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showDiscount)
                    Positioned(
                      bottom: 6.w, right: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text('${discountPercentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Text(productName, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (variantTitle.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(variantTitle, style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500)),
                  ],
                  SizedBox(height: 2.h),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${AppConstant.currency}${displayPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                    if (showDiscount) ...[
                      SizedBox(width: 4.w),
                      Text('${AppConstant.currency}${productPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                    ],
                  ]),
                  SizedBox(height: 2.h),
                  Row(children: [
                    if (estimatedDeliveryTime.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(3.r)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt, size: 10.sp, color: const Color(0xFFE65100)),
                          SizedBox(width: 2.w),
                          Text(estimatedDeliveryTime, style: TextStyle(fontSize: 9.sp, color: const Color(0xFFE65100), fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    const Spacer(),
                    Container(
                      width: 26.w, height: 26.w,
                      decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                      child: Icon(Icons.add, color: Colors.white, size: 16.w),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
