import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/constant.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../../../utils/widgets/custom_variant_selector_bottom_sheet.dart';

class YouMightAlsoLikeProductWidget extends StatelessWidget {
  final List<ProductData> productData;
  const YouMightAlsoLikeProductWidget({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 12.0.w,
              right: 12.0.w,
              top: 12.h,
              bottom: 12.h
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.youMightAlsoLike,
                  style: TextStyle(
                    fontSize: isTablet(context) ? 24 : 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200.h,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(left: 12.0.w),
              scrollDirection: Axis.horizontal,
              itemCount: productData.length > 10 ? 10 : productData.length,
              itemBuilder: (context, index) {
                final product = productData[index];
                ProductVariants? defaultVariant;
                if (product.variants.isNotEmpty) {
                  defaultVariant = product.variants.firstWhere(
                    (variant) => variant.isDefault == true,
                    orElse: () => product.variants.first,
                  );
                }

                // Set price and specialPrice based on the default variant
                final price = defaultVariant != null
                    ? defaultVariant.price.toString()
                    : '0';
                final specialPrice = defaultVariant != null
                    ? defaultVariant.specialPrice.toString()
                    : '';
                return Padding(
                  padding: EdgeInsets.only(right: 12.0.w),
                  child: SizedBox(
                    width: isTablet(context) ? 80.w : 120.w,
                    child: CustomProductCard(
                      productId: product.id,
                      productImage: product.mainImage,
                      productSlug: product.slug,
                      productName: product.title,
                      productPrice: price,
                      specialPrice: specialPrice,
                      productTags: [],
                      estimatedDeliveryTime: product.estimatedDeliveryTime.toString(),
                      assetImage: '',
                      ratings: (double.tryParse(product.ratings.toString()) ?? 0.0),
                      ratingCount: product.ratingCount,
                      onAddToCart: (){
                        if (product.variants.length > 1) {
                          showVariantBottomSheet(
                            variantsList: product.variants,
                            productData: product,
                            productImage: product.mainImage,
                            quantityStepSize: product.quantityStepSize,
                            context: context,
                          );
                        }
                        else {
                          final dv = product.variants.firstWhere(
                            (variant) => variant.isDefault,
                            orElse: () => product.variants.first,
                          );
                          final item = UserCart(
                              productId: product.id.toString(),
                              variantId: dv.id.toString(),
                              variantName: dv.title.toString(),
                              vendorId: dv.storeId.toString(),
                              name: product.title,
                              image: product.mainImage,
                              price: dv.specialPrice.toDouble(),
                              originalPrice: dv.price.toDouble(),
                              quantity: product.quantityStepSize,
                              serverCartItemId: null,
                              syncAction: CartSyncAction.add,
                              updatedAt: DateTime.now(),
                              minQty: product.minimumOrderQuantity,
                              maxQty: product.totalAllowedQuantity,
                              isOutOfStock: dv.stock <= 0,
                              isSynced: false
                          );
                          context.read<CartBloc>().add(AddToCart(item, context));

                          /*context.read<AddToCartBloc>().add(
                            AddItemToCart(
                              productVariantId: product.variants.first.id,
                              storeId: product.variants.first.storeId,
                              quantity: product.quantityStepSize,
                            ),
                          );*/
                        }
                      },
                      variantCount: product.variants.length,
                      onVariantSelectorRequested: product.variants.length > 1
                        ? () => showVariantBottomSheet(
                          variantsList: product.variants,
                          productData: product,
                          productImage: product.mainImage,
                          quantityStepSize: product.quantityStepSize,
                          context: context,
                        ) : null,
                      isStoreOpen: product.storeStatus?.isOpen ?? true,
                      isWishListed: product.favorite != null,
                      productVariantId: product.variants.isNotEmpty
                          ? product.variants.firstWhere((variant) => variant.isDefault, orElse: () => product.variants.first).id
                          : 0,
                      storeId: product.variants.isNotEmpty
                          ? product.variants.firstWhere((variant) => variant.isDefault, orElse: () => product.variants.first).storeId
                          : 0,
                      wishlistItemId: (product.favorite?.isNotEmpty ?? false)
                          ? product.favorite!.first.id ?? 0
                          : 0,
                      totalStocks: product.variants.isNotEmpty
                          ? product.variants.firstWhere((variant) => variant.isDefault, orElse: () => product.variants.first).stock
                          : 0,
                      imageFit: product.imageFit,
                      quantityStepSize: product.quantityStepSize,
                      minQty: product.minimumOrderQuantity,
                      totalAllowedQuantity: product.totalAllowedQuantity,
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
