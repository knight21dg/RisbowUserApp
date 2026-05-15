import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/services/user_cart/cart_validation.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../model/user_cart_model/user_cart.dart';

class CompactHorizontalProductCard extends StatelessWidget {
  final int productId;
  final String productImage;
  final String productName;
  final String productSlug;
  final String productPrice;
  final String specialPrice;
  final List<String> productTags;
  final String estimatedDeliveryTime;
  final double ratings;
  final int ratingCount;
  final VoidCallback onAddToCart;
  final bool isStoreOpen;
  final bool isWishListed;
  final int productVariantId;
  final int storeId;
  final int wishlistItemId;
  final int totalStocks;
  final String imageFit;
  final int? variantCount;
  final VoidCallback? onVariantSelectorRequested;
  final int quantityStepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final Color? backgroundColor;
  final bool showShadow;

  const CompactHorizontalProductCard({
    super.key,
    required this.productId,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.productPrice,
    required this.specialPrice,
    this.productTags = const [],
    required this.estimatedDeliveryTime,
    required this.ratings,
    required this.ratingCount,
    required this.onAddToCart,
    required this.isStoreOpen,
    required this.isWishListed,
    required this.productVariantId,
    required this.storeId,
    required this.wishlistItemId,
    required this.totalStocks,
    required this.imageFit,
    this.variantCount,
    this.onVariantSelectorRequested,
    required this.quantityStepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    this.backgroundColor,
    this.showShadow = true,
  });

  BoxFit get boxFit {
    switch (imageFit.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
      default:
        return BoxFit.contain;
    }
  }

  double get discountPercentage {
    final price = double.tryParse(productPrice) ?? 0;
    final special = double.tryParse(specialPrice) ?? 0;
    if (price > 0 && special > 0 && price > special) {
      return ((price - special) / price) * 100;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSpecialPrice = double.tryParse(specialPrice) ?? 0;
    final effectiveProductPrice = double.tryParse(productPrice) ?? 0;
    final showDiscount = effectiveProductPrice > effectiveSpecialPrice && effectiveSpecialPrice > 0;
    final displayPrice = effectiveSpecialPrice > 0 ? effectiveSpecialPrice : effectiveProductPrice;

    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push('/product-detail?slug=$productSlug');
      },
      child: Opacity(
        opacity: totalStocks <= 0 ? 0.5 : 1,
        child: Container(
          width: 160.w,
          height: 220.h,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: showShadow ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: double.infinity,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: backgroundColor == Colors.transparent ? Colors.transparent : Colors.grey[100],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r),
                      ),
                      child: productImage.trim().isNotEmpty
                          ? CustomImageContainer(
                              imagePath: productImage,
                              fit: BoxFit.contain,
                              fallbackAsset: 'assets/images/placeholder.png',
                            )
                          : Image.asset(
                              'assets/images/placeholder.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title - fixed height for alignment
                        SizedBox(
                          height: 38.h,
                          child: Text(
                            productName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppTheme.fontFamily,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        // Price
                        Row(
                          children: [
                            Text(
                              '${AppConstant.currency}${displayPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTheme.fontFamily,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (showDiscount) ...[
                              SizedBox(width: 4.w),
                              Text(
                                '${AppConstant.currency}${effectiveProductPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Discount badge
              if (discountPercentage > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppTheme.discountCardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12.r),
                        bottomRight: Radius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '${discountPercentage.toStringAsFixed(0)}% OFF',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final cartItem = _getCartItem(state);
        final isInCart = cartItem != null;

        return GestureDetector(
          onTap: totalStocks > 0
              ? () {
                  if (variantCount != null && variantCount! > 1 && onVariantSelectorRequested != null) {
                    onVariantSelectorRequested!();
                  } else {
                    onAddToCart();
                  }
                }
              : null,
          child: Container(
            width: double.infinity,
            height: 28.h,
            decoration: BoxDecoration(
              color: isInCart ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 1.2.w,
              ),
            ),
            alignment: Alignment.center,
            child: isInCart
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (cartItem.quantity > 1) {
                            context.read<CartBloc>().add(
                                  UpdateCartQty(
                                    cartItem.cartKey,
                                    cartItem.quantity - 1,
                                    cartItem.serverCartItemId,
                                    context,
                                  ),
                                );
                          } else {
                            context.read<CartBloc>().add(
                                  RemoveFromCart(cartItem.cartKey, context),
                                );
                          }
                        },
                        child: Icon(
                          TablerIcons.minus,
                          size: 14.r,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        cartItem.quantity.toString(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {
                          final error = CartValidation.validateProductAddToCart(
                            context: context,
                            requestedQuantity: cartItem.quantity + quantityStepSize,
                            minQty: minQty,
                            maxQty: totalAllowedQuantity,
                            stock: totalStocks,
                            isStoreOpen: isStoreOpen,
                          );
                          if (error != null) {
                            ToastManager.show(context: context, message: error, type: ToastType.error);
                            return;
                          }
                          context.read<CartBloc>().add(
                                UpdateCartQty(
                                  cartItem.cartKey,
                                  cartItem.quantity + 1,
                                  cartItem.serverCartItemId,
                                  context,
                                ),
                              );
                        },
                        child: Icon(
                          TablerIcons.plus,
                          size: 14.r,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        );
      },
    );
  }

  UserCart? _getCartItem(CartState state) {
    if (state is CartLoaded) {
      try {
        final item = state.items.firstWhere(
          (item) =>
              int.parse(item.productId) == productId &&
              int.parse(item.variantId) == productVariantId &&
              int.parse(item.vendorId) == storeId,
          orElse: () => throw Exception('Not found'),
        );
        return item;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}