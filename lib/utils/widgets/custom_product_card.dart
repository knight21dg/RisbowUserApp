import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/product_detail_page/view/product_detail_page.dart';
import 'package:hyper_local/services/auth_guard.dart';
import 'package:hyper_local/utils/widgets/animated_button.dart';
import 'package:hyper_local/utils/widgets/custom_delivery_time_widget.dart';
import 'package:hyper_local/utils/widgets/price_utils.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../config/global.dart';
import '../../model/user_cart_model/user_cart.dart';
import '../../screens/wishlist_page/widgets/wishlist_bottom_sheet.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import '../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_state.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_cart/cart_validation.dart';
import 'custom_toast.dart';

class CustomProductCard extends StatelessWidget {
  final int productId;
  final String productImage;
  final String productName;
  final String productSlug;
  final String productPrice;
  final List<String> productTags;
  final String specialPrice;
  final String estimatedDeliveryTime;
  final String? assetImage;
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
  final bool showWishlist;
  final int? variantCount;
  final VoidCallback? onVariantSelectorRequested;
  final int quantityStepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final String storeSlug;
  final VoidCallback? onTap;

  const CustomProductCard({
    super.key,
    required this.productId,
    required this.productImage,
    required this.productName,
    required this.productSlug,
    required this.productPrice,
    required this.productTags,
    this.assetImage,
    required this.specialPrice,
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
    this.showWishlist = true,
    this.variantCount,
    this.onVariantSelectorRequested,
    this.onTap,
    required this.quantityStepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    this.storeSlug = '',
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

@override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        context.push('/product-detail?slug=$productSlug');
      },
      child: Opacity(
        opacity: totalStocks <= 0 ? 0.5 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image - flexible but constrained
                      productImageWidget(
                          productImage: productImage,
                          discountPercentage: PriceUtils.calculateDiscountPercentage(double.parse(productPrice), double.parse(specialPrice)).toString(),
                        context: context
                      ),
                      // Content area with fixed spacing
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [

                            productNameWidget(productName: productName, context: context),
                            SizedBox(height: 1.h),
                            // Product Price
                            productPriceWidget(
                                price: productPrice,
                                specialPrice: specialPrice,
                                locale: 'en_IN',
                              context: context
                            ),
                            SizedBox(height: 2.h),
                            ratingWidget(context),
                            SizedBox(height: 4.h),
                            // Delivery Time
                            DeliveryTimeWidget(time: estimatedDeliveryTime),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget productImageWidget({
    required String productImage,
    required String discountPercentage,
    required BuildContext context,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Main image container
          Container(
            width: double.infinity,
            height: 120.h,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            padding: EdgeInsets.zero,
            child: productImage.trim().isNotEmpty
                ? Hero(
                    tag: 'product-image-$productId',
                    child: CustomImageContainer(
                      imagePath: productImage,
                      fit: boxFit,
                      fallbackAsset: 'assets/images/placeholder.png',
                    ),
                  )
                : _buildAssetImageOrPlaceholder(),
          ),

          // Discount badge - top leading corner
          if (discountPercentage.isNotEmpty && discountPercentage != '0')
            PositionedDirectional(
              top: 0,
              start: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.discountCardColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(8.r),
                    bottomEnd: Radius.circular(4.r),
                  ),
                ),
                child: Text(
                  '$discountPercentage% OFF',
                  style: TextStyle(
                    fontSize: isTablet(context) ? 12 : 8.sp,
                    color: Colors.white,
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          if (!productName.toLowerCase().contains('fresh apples'))
            PositionedDirectional(
              bottom: 8.h,
              end: 3.w,
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                final cartItem = _getCartItem(state);
                final isInCart = cartItem != null;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  width: isInCart ? 80 : 26.h,
                  height: 26.h,
                  decoration: BoxDecoration(
                    color: isInCart ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 1.5.w,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isInCart
                        ? _QuantityStepperInner(
                            key: const ValueKey('stepper_inner'),
                            quantity: cartItem.quantity,
                            currentLocalQty: cartItem.quantity,
                            stepSize: quantityStepSize,
                            isStoreOpen: isStoreOpen,
                            stock: totalStocks,
                            minQty: minQty,
                            totalAllowedQuantity: totalAllowedQuantity,
                            onIncrement: () async {
                              await HapticFeedback.lightImpact();
                              if (variantCount != null && variantCount! > 1 && onVariantSelectorRequested != null) {
                                onVariantSelectorRequested!();
                              } else {
                                if (context.mounted) {
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
                                  } else {
                                    context.read<CartBloc>().add(
                                          UpdateCartQty(
                                            cartItem.cartKey,
                                            cartItem.quantity + 1,
                                            cartItem.serverCartItemId,
                                            context,
                                          ),
                                        );
                                  }
                                }
                              }
                            },
                            onDecrement: () async {
                              await HapticFeedback.lightImpact();
                              if (variantCount != null && variantCount! > 1 && onVariantSelectorRequested != null) {
                                onVariantSelectorRequested!();
                              } else {
                                // Normal decrement for single variant
                                if (cartItem.quantity > 1) {
                                  if (context.mounted) {
                                    context.read<CartBloc>().add(
                                          UpdateCartQty(
                                            cartItem.cartKey,
                                            cartItem.quantity - 1,
                                            cartItem.serverCartItemId,
                                            context,
                                          ),
                                        );
                                  }
                                } else {
                                  if (context.mounted) {
                                    context.read<CartBloc>().add(
                                          RemoveFromCart(cartItem.cartKey, context),
                                        );
                                  }
                                }
                              }
                            },
                          )
                        : _AddButtonInner(
                            key: const ValueKey('add_button_inner'),
                            currentLocalQty: cartItem?.quantity ?? 0,
                            stepSize: quantityStepSize,
                            isStoreOpen: isStoreOpen,
                            stock: totalStocks,
                            minQty: minQty,
                            totalAllowedQuantity: totalAllowedQuantity,
                            onTap: totalStocks > 0
                                ? () async {
                                    await HapticFeedback.lightImpact();
                                    onAddToCart();
                                  }
                                : null,
                            opacity: totalStocks > 0 ? 1.0 : 0.5,
                          ),
                  ),
                );
              },
            ),
          ),

          // Wishlist button - top trailing
          if (showWishlist)
            PositionedDirectional(
              top: 3.h,
              end: 12.w,
              child: Builder(
                builder: (btnContext) {
                  return BlocBuilder<UserWishlistBloc, UserWishlistState>(
                    builder: (context, wishlistState) {
                      final bloc = context.read<UserWishlistBloc>();
                      final isWishListedFromBloc = bloc.isProductWishlisted(productId, productVariantId, storeId);
                      final hasBlocData = bloc.hasProductData(productId, productVariantId, storeId);
                      final finalIsWishListed = hasBlocData ? isWishListedFromBloc : isWishListed;

                      return GestureDetector(
                        onTap: () {
                          if (Global.userData != null) {
                            final wishlistItemId = bloc.getWishlistItemId(productId, productVariantId, storeId);
                            if (finalIsWishListed && wishlistItemId != null) {
                              context.read<UserWishlistBloc>().add(RemoveItemFromWishlist(itemId: wishlistItemId));
                            } else {
                              context.read<UserWishlistBloc>().add(AddItemInWishlist(
                                wishlistTitle: 'My Wishlist',
                                productId: productId,
                                productVariantId: productVariantId,
                                storeId: storeId,
                              ));
                              // Refresh wishlist data to update UI
                              context.read<UserWishlistBloc>().add(GetUserWishlistRequest());
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 28.r,
                          width: 28.r,
                          decoration: BoxDecoration(
                            color: isDarkMode(context) ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: finalIsWishListed ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              finalIsWishListed ? AppConstant.wishListedIcon : AppConstant.notWishListedIcon,
                              key: ValueKey(finalIsWishListed),
                              color: finalIsWishListed 
                                  ? AppTheme.primaryColor 
                                  : (isDarkMode(context) ? Colors.white54 : Colors.black26),
                              size: 15.r,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
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
          orElse: () => null as dynamic,
        );
        return item as UserCart?;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAssetImageOrPlaceholder() {
    if (assetImage != null && assetImage!.isNotEmpty) {
      return CustomImageContainer(
        imagePath: assetImage!,
        fit: BoxFit.cover,
        fallbackAsset: 'assets/images/placeholder.png',
      );
    }
    return Image.asset(
      'assets/images/placeholder.png',
      fit: BoxFit.cover,
    );
  }

  Widget productTagsWidget({required List<String> tags}) {
    final List<String> validTags = tags.where((tag) => tag.isNotEmpty).toList();
    if (validTags.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double tagSpacing = 4.w;

        return Wrap(
          spacing: tagSpacing,
          runSpacing: 2.h,
          children: validTags.take(2).map((tag) {
            return Container(
              constraints: BoxConstraints(
                maxWidth: (availableWidth - tagSpacing) / 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 8.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget productNameWidget({required String productName, required BuildContext context}) {
    return Text(
      productName,
      style: TextStyle(
        fontSize: isTablet(context) ? 20 : 11.5.sp,
        height: isTablet(context) ? 1.2 : 1.2,
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  Widget productPriceWidget({
    required String price,
    required String specialPrice,
    required String locale,
    required BuildContext context,
  }) {
    final effectiveSpecialPrice = double.tryParse(specialPrice) ?? 0;
    final effectiveOriginalPrice = double.tryParse(price) ?? 0;
    final showDiscount = effectiveOriginalPrice > effectiveSpecialPrice && effectiveSpecialPrice > 0 && effectiveOriginalPrice > 0;
    
    final displayPrice = showDiscount ? effectiveSpecialPrice : (effectiveOriginalPrice > 0 ? effectiveOriginalPrice : 0);
    final displayText = displayPrice > 0 ? '${AppConstant.currency}${displayPrice.toStringAsFixed(0)}' : 'N/A';

    return Row(
      children: [
        Text(
          displayText,
          style: TextStyle(
            fontSize: isTablet(context) ? 20 : 14.sp,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontFamily,
            color: displayPrice <= 0 ? Colors.red : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (showDiscount) ...[
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppConstant.currency}${effectiveOriginalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: isTablet(context) ? 16 : 11.sp,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.grey,
                  decorationThickness: 2,
                  color: Colors.grey,
                  fontFamily: AppTheme.fontFamily
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget ratingWidget (BuildContext context) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: ratings,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 11.h,
          itemBuilder: (context, _) => Icon(
            AppTheme.ratingStarIconFilled,
            color: AppTheme.ratingStarColor,
          ),
          unratedColor: Colors.grey[350],
          onRatingUpdate: (rating) {},
          ignoreGestures: true,
        ),
        SizedBox(width: 5.w,),
        Expanded(
          child: Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: isTablet(context) ? 18 : 8.sp,
              fontFamily: AppTheme.fontFamily,
              color: Colors.grey,
            ),
          ),
        )
      ],
    );
  }
}


class _AddButtonInner extends StatelessWidget {
  final VoidCallback? onTap;
  final double opacity;
  final int currentLocalQty;
  final int stepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final int stock;
  final bool isStoreOpen;

  const _AddButtonInner({
    required Key key,
    required this.onTap,
    required this.opacity,
    required this.currentLocalQty,
    required this.stepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    required this.stock,
    required this.isStoreOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: (){
          final error = CartValidation.validateProductAddToCart(
            context: context,
            requestedQuantity: currentLocalQty + stepSize,
            minQty: minQty,
            maxQty: totalAllowedQuantity,
            stock: stock,
            isStoreOpen: isStoreOpen,
          );
          if (error != null) {
            ToastManager.show(context: context, message: error, type: ToastType.error);
            return;
          } else {
            onTap!();
          }
        },
        child: Icon(
          TablerIcons.plus,
          size: 18.r,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class _QuantityStepperInner extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int currentLocalQty;
  final int stepSize;
  final int minQty;
  final int totalAllowedQuantity;
  final int stock;
  final bool isStoreOpen;

  const _QuantityStepperInner({
    required Key key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.currentLocalQty,
    required this.stepSize,
    required this.minQty,
    required this.totalAllowedQuantity,
    required this.stock,
    required this.isStoreOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              TablerIcons.minus,
              size: 16.r,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          quantity.toString(),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              TablerIcons.plus,
              size: 16.r,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
