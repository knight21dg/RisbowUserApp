import 'dart:async';
// ignore_for_file: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/env_config.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_event.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_dotted_divider.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/gst_utils.dart';
import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../utils/widgets/debounce_function.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../model/get_cart_model.dart';
import '../../../l10n/app_localizations.dart';

class StoreGroup {
  final String name;
  final String? slug;
  final String? logo;
  final bool? storeStatus;
  final List<CartItems> items;

  StoreGroup({
    required this.name,
    required this.slug,
    required this.logo,
    this.storeStatus = false,
    required this.items,
  });
}

List<StoreGroup> groupCartItemsByStore(List<CartItems> items) {
  Map<String, StoreGroup> groupedItems = {};

  for (var item in items) {
    String storeKey = item.store?.name ?? 'Unknown Store';
    if (!groupedItems.containsKey(storeKey)) {
      groupedItems[storeKey] = StoreGroup(
        name: storeKey,
        slug: item.store?.slug,
        logo: item.product?.image,
        storeStatus: item.store?.status?.isOpen ?? false,
        items: [],
      );
    }
    groupedItems[storeKey]!.items.add(item);
  }

  return groupedItems.values.toList();
}

class CartWidget extends StatelessWidget {
  final List<CartItems> items;
  final String deliveryTime;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final VoidCallback? onAddMoreItems;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? deliveryTextStyle;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final BorderRadius? borderRadius;
  final int? totalItem;

  const CartWidget({
    super.key,
    required this.items,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.onAddMoreItems,
    this.padding,
    this.backgroundColor,
    this.headerTextStyle,
    this.deliveryTextStyle,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.borderRadius,
    this.totalItem,
  });

  @override
  Widget build(BuildContext context) {
    // Group items by store
    final groupedStores = groupCartItemsByStore(items);
    return Column(
      children: groupedStores.map((storeGroup) {
        return Container(
          margin: EdgeInsets.only(bottom: 9.h),
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              StoreCartSection(
                storeName: storeGroup.name,
                items: storeGroup.items,
                storeStatus: storeGroup.storeStatus ?? false,
                deliveryTime: deliveryTime,
                onQuantityChanged: onQuantityChanged,
                onRemoveItem: onRemoveItem,
                onAddMoreItems: onAddMoreItems,
                padding: padding,
                backgroundColor: backgroundColor,
                headerTextStyle: headerTextStyle,
                deliveryTextStyle: deliveryTextStyle,
                quantityButtonColor: quantityButtonColor,
                priceColor: priceColor,
                originalPriceColor: originalPriceColor,
                borderRadius: borderRadius,
                totalItems: totalItem,
              ),
              buildDottedLine(context),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    GoRouter.of(context).push(
                      AppRoutes.nearbyStoreDetails,
                      extra: {
                        'store-slug': storeGroup.slug,
                        'store-name': storeGroup.name,
                      },
                    );
                  },
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r)
                  ),
                  child: Ink(
                    child: Opacity(
                      opacity: (storeGroup.storeStatus == false) ? 0.3 : 1,
                      child: SizedBox(
                        height: 55,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.circle_plus,
                              size: isTablet(context) ? 28 : 18.r,
                              color: (storeGroup.storeStatus == false) ? Theme.of(context).colorScheme.outlineVariant : AppTheme.primaryColor,
                            ),
                            SizedBox(width: 5.w,),
                            Text(
                              AppLocalizations.of(context)!.addMoreItemsTapped,
                              style: TextStyle(
                                  color: (storeGroup.storeStatus == false) ? Theme.of(context).colorScheme.outlineVariant : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTablet(context) ? 20 : 14.sp
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Store-specific cart section widget
class StoreCartSection extends StatefulWidget {
  final String storeName;
  final List<CartItems> items;
  final bool storeStatus;
  final String deliveryTime;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemoveItem;
  final VoidCallback? onAddMoreItems;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final TextStyle? headerTextStyle;
  final TextStyle? deliveryTextStyle;
  final Color? quantityButtonColor;
  final Color? priceColor;
  final Color? originalPriceColor;
  final BorderRadius? borderRadius;
  final int? totalItems;

  const StoreCartSection({
    super.key,
    required this.storeName,
    required this.items,
    required this.storeStatus,
    required this.deliveryTime,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    this.onAddMoreItems,
    this.padding,
    this.backgroundColor,
    this.headerTextStyle,
    this.deliveryTextStyle,
    this.quantityButtonColor,
    this.priceColor,
    this.originalPriceColor,
    this.borderRadius,
    this.totalItems,
  });

  @override
  State<StoreCartSection> createState() => _StoreCartSectionState();
}

class _StoreCartSectionState extends State<StoreCartSection> {
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));
  Timer? _apiThrottleTimer;

  @override
  void dispose() {
    _apiThrottleTimer?.cancel();
    _debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStoreHeader(context),
        ...widget.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: _buildCartItem(context, item),
        )),
      ],
    );
  }

  Widget _buildStoreHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode(context) ? Theme.of(context).colorScheme.secondary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.storeName,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: widget.headerTextStyle ??
                  TextStyle(
                    fontSize: isTablet(context) ? 24 : 15.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
            ),
          ),
          SizedBox(width: 10,),
          if(!widget.storeStatus)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TablerIcons.x, color: AppTheme.errorColor, size: 16,),
                SizedBox(width: 5,),
                Text(
                  'Currently closed',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ],
            )
          else
            Text(
            '${widget.items.length} Product${widget.items.length != 1 ? 's' : ''}',
            style: widget.deliveryTextStyle ??
                TextStyle(
                  fontSize: isTablet(context) ? 18 : 12.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppTheme.fontFamily,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItems item) {
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.horizontal,

      // Backgrounds (same as before)
      background: Container(
        color: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.bookmark_add, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)?.saveForLater ?? "Save for Later",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: AppTheme.errorColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)?.delete ?? "Delete",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.delete, color: Colors.white, size: 28),
          ],
        ),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {

          // Save for Later → trigger API, but don't dismiss yet
          context.read<SaveForLaterBloc>().add(SaveForLaterRequest(
            cartItemId: item.id!,
            productId: item.productId.toString(),
            variantId: item.productVariantId.toString(),
          ));
          return false; // Don't dismiss
        }

        if (direction == DismissDirection.endToStart) {
          // Show confirmation dialog
          final bool? shouldDelete = await showDialog<bool>(
            context: context,
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                title: Text(l10n?.removeItem ?? "Remove item"),
                content: Text(
                  l10n?.areYouSureYouWantToRemoveItemFromCart(item.product?.name ?? '') ??
                      "Are you sure you want to remove ${item.product?.name ?? ''} from cart?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n?.cancel ?? "Cancel"),
                  ),
                  CustomButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n?.delete ?? "Delete"),
                  ),
                ],
              );
            },
          );

          if (shouldDelete == true) {
            if(context.mounted) {
              context.read<CartBloc>().add(RemoveFromCart(
                  '${item.product?.id ?? 0}_${item.productVariantId}',context
              ));
            }
            // Trigger remove API
            widget.onRemoveItem(item.id.toString());
            return false; // Don't dismiss yet — wait for Bloc success
          }
        }

        return false;
      },

      // REMOVE onDismissed completely → we control dismissal manually
      // onDismissed: null, // ← Remove this entirely

      child: Opacity(
        opacity: (widget.storeStatus == false) ? 0.3 : 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isDarkMode(context) ? Colors.grey.shade800 : Colors.grey[200]!, width: 0.5)),
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProductImage(item.product?.image ?? ''),
              SizedBox(width: 10.w),
              Expanded(child: _buildProductInfo(item)),
              SizedBox(width: 10.w),
              _buildQuantityControl(item),
              SizedBox(width: 12.w),
              _buildPriceSection(item),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImageContainer(imagePath: imageUrl, fit: BoxFit.contain,),
      ),
    );
  }

  Widget _buildProductInfo(CartItems item) {
    final productName = item.variant?.title ?? item.product?.name ?? 'Unknown Product';
    final productSlug = item.product?.slug ?? '';
    return SizedBox(
      width: 125.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              productName,
              style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (productSlug.isNotEmpty)
            GestureDetector(
              onTap: () => _shareProduct(productName, productSlug),
              child: Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Icon(
                  Icons.share,
                  size: 14.r,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _shareProduct(String productName, String slug) {
    final webUrl = '${EnvConfig.domainBaseUrl}/p/$slug';
    final shareText = 'Check out this product: $productName\n$webUrl\n\nOpen in app: risbow://p/$slug';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Widget _buildQuantityControl(CartItems item) {
    final String cartKey = '${item.product?.id ?? 0}_${item.productVariantId}';

    return BlocSelector<CartBloc, CartState, int?>(
      selector: (state) {
        if (state is CartLoaded) {
          final localItem = state.items.firstWhereOrNull(
                (i) => i.cartKey == cartKey,
          );
          return localItem?.quantity;
        }
        return null; // will fallback to item.quantity
      },
      builder: (context, localQty) {
        // Fallback to server/API quantity if local not found yet
        final displayQty = localQty ?? item.quantity ?? 1;

        final availableStock = item.variant?.stock ?? 0;
        if (availableStock <= 0) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Out of Stock',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }

        return Container(
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus / Remove
              _buildQtyBtn(
                icon: Icons.remove,
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (displayQty <= 1) {
                    // Remove from local
                    context.read<CartBloc>().add(RemoveFromCart(cartKey,context));
                    // Trigger server remove
                    widget.onRemoveItem(item.id.toString());
                  } else {
                    final newQty = displayQty - 1;
                    // Update local
                    context.read<CartBloc>().add(UpdateCartQty(
                      cartKey,
                      newQty,
                      item.id,
                      context
                    ));
                    // Trigger server update (in background)
                    widget.onQuantityChanged(item.id.toString(), newQty);
                  }
                },
              ),

              // Quantity display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$displayQty',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Plus
              _buildQtyBtn(
                icon: Icons.add,
                onTap: () {
                  HapticFeedback.lightImpact();
                  final newQty = displayQty + 1;
                  // Update local
                  context.read<CartBloc>().add(UpdateCartQty(
                    cartKey,
                    newQty,
                    item.id,
                    context
                  ));
                  // Trigger server update
                  widget.onQuantityChanged(item.id.toString(), newQty);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  /*Widget _buildQuantityControl(CartItems item) {
    final String cartKey = '${item.product?.id ?? 0}_${item.productVariantId}';

    return BlocSelector<CartBloc, CartState, int>(
      selector: (state) {
        if (state is CartLoaded) {
          final localItem = state.items.firstWhereOrNull(
                (i) => i.cartKey == cartKey,
          );
          return localItem?.quantity ?? item.quantity ?? 1;
        }
        return item.quantity!;
      },
      builder: (context, localQuantity) {
        final isOutOfStock = (item.variant?.stock ?? 0) <= 0;

        print('Local Quantity  $localQuantity');

        if (isOutOfStock) {
          return Container(
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: isTablet(context) ? 18 : 10.sp,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: isTablet(context) ? 40 : 30,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode(context) ? Colors.grey.shade600 : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () {
                  HapticFeedback.lightImpact();

                  if (localQuantity <= 1) {
                    // Instant local remove
                    context.read<CartBloc>().add(RemoveFromCart(cartKey, context));
                    // API remove (immediate, no throttle needed for delete)
                    widget.onRemoveItem(item.id.toString());
                  } else {
                    final newQty = localQuantity - 1;
                    // Instant local update
                    context.read<CartBloc>().add(UpdateCartQty(
                      cartKey,
                      newQty,
                      item.id,
                      context
                    ));
                    // Throttled API update
                    _updateQuantityWithThrottle(
                      itemId: item.id.toString(),
                      newQuantity: newQty,
                    );
                  }
                },
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isTablet(context) ? 10 : 5),
                child: Center(
                  child: Text(
                    '$localQuantity',
                    style: TextStyle(
                      fontSize: isTablet(context) ? 18 : 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () {
                  if (widget.totalItems! >= SettingsData.instance.system!.maximumItemsAllowedInCart) {
                    ToastManager.show(
                      context: context,
                      message: AppLocalizations.of(context)!.youHaveReachedMaximumLimitOfTheCart,
                    );
                    return;
                  }

                  _debounce.call(() {
                    final newQty = localQuantity + 1;
                    // Local update first
                    context.read<CartBloc>().add(UpdateCartQty(
                      cartKey,
                      newQty,
                      item.id,
                      context
                    ));
                    // Then API
                    widget.onQuantityChanged(item.id.toString(), newQty);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: isTablet(context) ? 34 : 24,
        height: isTablet(context) ? 34 : 24,
        child: Icon(
          icon,
          size: isTablet(context) ? 10.r : 12.r,
          fontWeight: FontWeight.bold,
          color: widget.quantityButtonColor ?? Colors.blue,
        ),
      ),
    );
  }*/

  Widget _buildPriceSection(CartItems item) {
    final inclusivePrice = item.variant?.specialPrice ?? item.variant?.price ?? 0;
    final inclusiveOriginalPrice = item.variant?.price ?? 0;
    final v = item.variant;
    final effectivePrice = v?.specialPriceExcludeTax ?? v?.priceExcludeTax ?? GstUtils.getBasePrice(inclusivePrice.toDouble());
    final effectiveOriginal = v?.priceExcludeTax ?? GstUtils.getBasePrice(inclusiveOriginalPrice.toDouble());
    return SizedBox(
      width: isTablet(context) ? 90.w : 75.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.variant != null && inclusiveOriginalPrice != inclusivePrice) ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${AppConstant.currency}$effectiveOriginal',
                style: TextStyle(
                  fontSize: isTablet(context) ? 16 : 9.sp,
                  fontFamily: AppTheme.fontFamily,
                  color: widget.originalPriceColor ?? Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.grey[500],
                ),
              ),
            ),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${AppConstant.currency}$effectivePrice',
              style: TextStyle(
                fontSize: isTablet(context) ? 20 : 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
