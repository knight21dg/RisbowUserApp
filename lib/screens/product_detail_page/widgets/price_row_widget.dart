import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/constant.dart';
import '../../../utils/widgets/price_utils.dart';

class PriceRowWidget extends StatelessWidget {
  final double originalPrice;
  final double? salePrice;
  final double? fontSize;
  final double? originalFontSize;
  final double? discountFontSize;
  final FontWeight? fontWeight;
  final Color? priceColor;
  final Color? originalPriceColor;
  final Color? discountBackgroundColor;
  final Color? discountTextColor;

  const PriceRowWidget({
    super.key,
    required this.originalPrice,
    this.salePrice,
    this.fontSize,
    this.originalFontSize,
    this.discountFontSize,
    this.fontWeight,
    this.priceColor,
    this.originalPriceColor,
    this.discountBackgroundColor,
    this.discountTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrice = salePrice ?? originalPrice;
    final hasDiscount = PriceUtils.hasDiscount(originalPrice, effectivePrice);
    final discountPercentage = hasDiscount
        ? PriceUtils.calculateDiscountPercentage(originalPrice, effectivePrice)
        : 0;

    return Row(
      children: [
        // Current/Sale Price
        Text(
          PriceUtils.formatPrice(effectivePrice),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),

        if (hasDiscount) ...[
          const SizedBox(width: 8),
          // Original Price (crossed out)
          Text(
            PriceUtils.formatPrice(originalPrice),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: originalPriceColor ?? Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey.shade600,
              decorationThickness: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          // Discount Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: Text(
              '$discountPercentage% OFF',
              style: TextStyle(
                fontSize: isTablet(context) ? 14 : 10.sp,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
