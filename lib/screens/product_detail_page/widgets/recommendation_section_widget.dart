import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/constant.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_product_card.dart';
import '../../../utils/widgets/custom_variant_selector_bottom_sheet.dart';

class RecommendationSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<ProductData> products;
  final VoidCallback? onViewAll;
  
  const RecommendationSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.products,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet(context) ? 20 : 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: isTablet(context) ? 320.h : 280.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productData = products[index];
              if (productData.variants.isEmpty) return SizedBox.shrink();
              
              return _buildProductCard(context, productData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductData productData) {
    return Container(
      width: isTablet(context) ? 180.w : 160.w,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: CustomProductCard(
        productId: productData.id,
        productImage: productData.mainImage,
        productSlug: productData.slug,
        productName: productData.title,
        productPrice: productData.variants.isNotEmpty 
            ? productData.variants.first.price.toString() 
            : '0',
        specialPrice: productData.variants.isNotEmpty 
            ? productData.variants.first.specialPrice.toString() 
            : '0',
        productTags: [],
        estimatedDeliveryTime: productData.estimatedDeliveryTime.toString(),
        ratings: double.parse(productData.ratings.toString()),
        ratingCount: productData.ratingCount,
        onAddToCart: () {
          if (productData.variants.isEmpty) return;
          
          if (productData.variants.length > 1) {
            showVariantBottomSheet(
              variantsList: productData.variants,
              productData: productData,
              productImage: productData.mainImage,
              quantityStepSize: productData.quantityStepSize,
              context: context,
            );
          } else {
            final variant = productData.variants.firstWhere(
              (v) => v.isDefault, 
              orElse: () => productData.variants.first,
            );
            final item = UserCart(
              productId: productData.id.toString(),
              variantId: variant.id.toString(),
              variantName: variant.title.toString(),
              vendorId: variant.storeId.toString(),
              name: productData.title,
              image: productData.mainImage,
              price: variant.specialPrice.toDouble(),
              originalPrice: variant.price.toDouble(),
              quantity: productData.quantityStepSize,
              serverCartItemId: null,
              syncAction: CartSyncAction.add,
              updatedAt: DateTime.now(),
              minQty: productData.minimumOrderQuantity,
              maxQty: productData.totalAllowedQuantity,
              isOutOfStock: variant.stock <= 0,
              isSynced: false,
            );
            context.read<CartBloc>().add(AddToCart(item, context));
          }
        },
        variantCount: productData.variants.length,
        onVariantSelectorRequested: productData.variants.length > 1
            ? () => showVariantBottomSheet(
                variantsList: productData.variants,
                productData: productData,
                productImage: productData.mainImage,
                quantityStepSize: productData.quantityStepSize,
                context: context,
              )
            : null,
        isStoreOpen: productData.storeStatus?.isOpen ?? true,
        isWishListed: productData.favorite != null,
        productVariantId: productData.variants.isNotEmpty
            ? productData.variants.firstWhere((v) => v.isDefault, orElse: () => productData.variants.first).id
            : 0,
        storeId: productData.variants.isNotEmpty
            ? productData.variants.firstWhere((v) => v.isDefault, orElse: () => productData.variants.first).storeId
            : 0,
        wishlistItemId: (productData.favorite?.isNotEmpty ?? false)
            ? productData.favorite!.first.id ?? 0
            : 0,
        totalStocks: productData.variants.isNotEmpty
            ? productData.variants.firstWhere((v) => v.isDefault, orElse: () => productData.variants.first).stock
            : 0,
        imageFit: productData.imageFit,
        quantityStepSize: productData.quantityStepSize,
        minQty: productData.minimumOrderQuantity,
        totalAllowedQuantity: productData.totalAllowedQuantity,
      ),
    );
  }
}