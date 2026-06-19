import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_event.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/gst_utils.dart';
import 'package:hyper_local/services/auth_guard.dart';
import '../model/product_detail_model.dart';
import '../widgets/price_row_widget.dart';

class BottomAppBarWidget extends StatelessWidget {
  final ProductData productData;
  const BottomAppBarWidget({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    // Determine prices from variant or product level
    final activeVariant = productData.variants.isNotEmpty
        ? productData.variants.firstWhere(
            (v) => v.isDefault,
            orElse: () => productData.variants.first,
          )
        : null;

    final double inclusivePrice = activeVariant != null && activeVariant.price > 0
        ? activeVariant.price.toDouble()
        : productData.price;
    final double inclusiveSpecialPrice = activeVariant != null && activeVariant.specialPrice > 0
        ? activeVariant.specialPrice.toDouble()
        : productData.specialPrice;
    final double displayPrice = productData.priceExcludeTax ?? GstUtils.getBasePrice(inclusivePrice);
    final double displaySpecialPrice = productData.specialPriceExcludeTax ?? GstUtils.getBasePrice(inclusiveSpecialPrice);
    final bool inStock = activeVariant != null
        ? activeVariant.stock > 0
        : productData.stock > 0;

    return BottomAppBar(
      elevation: 8,
      child: Container(
        height: 80,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PriceRowWidget(
                    originalPrice: displayPrice,
                    salePrice: displaySpecialPrice > 0 ? displaySpecialPrice : null,
                    fontSize: 12.sp,
                    originalFontSize: 10.sp,
                    discountFontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    originalPriceColor: Colors.grey.shade600,
                  ),

                ],
              ),
            ),
            if (inStock)
              CustomButton(
                onPressed: () async {
                  if (await AuthGuard.ensureLoggedIn(context)) {
                    if (context.mounted && activeVariant != null) {
                      context.read<AddToCartBloc>().add(AddItemToCart(
                          productVariantId: activeVariant.id,
                          storeId: activeVariant.storeId,
                          quantity: 1));
                    }
                  }
                },
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  'Out of stock',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
