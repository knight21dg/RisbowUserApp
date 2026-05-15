import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

import '../model/order_detail_model.dart';

Map<String, List<OrderItems>> groupCartItemsByStore(List<OrderItems> items) {
  Map<String, List<OrderItems>> groupedItems = {};

  for (var item in items) {
    String storeKey = item.store?.name ?? 'Unknown Store';
    if (!groupedItems.containsKey(storeKey)) {
      groupedItems[storeKey] = [];
    }
    groupedItems[storeKey]!.add(item);
  }
  return groupedItems;
}


class OrderItemsCard extends StatelessWidget {
  final List<OrderItems> items;
  final String totalItems;
  final VoidCallback? onAddMoreItems;
  final Color? priceColor;
  final Color? originalPriceColor;

  const OrderItemsCard({
    super.key,
    required this.items,
    required this.totalItems,
    this.onAddMoreItems,
    this.priceColor,
    this.originalPriceColor,
  });

  @override
  Widget build(BuildContext context) {
    final groupedItems = groupCartItemsByStore(items);
    return Column(
      children: groupedItems.entries.map((entry) {
        final storeName = entry.key;
        final storeItems = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: StoreCartSection(
            storeName: storeName,
            items: storeItems,
            deliveryTime: totalItems,
            onAddMoreItems: onAddMoreItems,
            priceColor: priceColor,
            originalPriceColor: originalPriceColor,
          ),
        );
      }).toList(),
    );
  }
}


class StoreCartSection extends StatelessWidget {
  final String storeName;
  final List<OrderItems> items;
  final String deliveryTime;
  final VoidCallback? onAddMoreItems;
  final Color? priceColor;
  final Color? originalPriceColor;

  const StoreCartSection({
    super.key,
    required this.storeName,
    required this.items,
    required this.deliveryTime,
    this.onAddMoreItems,
    this.priceColor,
    this.originalPriceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStoreHeader(context),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: _buildCartItem(context, item),
        )),
      ],
    );
  }

  Widget _buildStoreHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                storeName,
                style: TextStyle(
                      fontSize: isTablet(context) ? 24 : 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
              ),
            ],
          ),
          Text(
            '${items.length} Product${items.length != 1 ? 's' : ''}',
            style: TextStyle(
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

  Widget _buildCartItem(BuildContext context, OrderItems item) {

    final status = getItemStatus(item);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row with image, info, price
          Opacity(
            opacity: 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                _buildProductImage(item.product?.image ?? item.variant?.image ?? ''),
                SizedBox(width: 10.w),

                // Product Name and Details
                Expanded(child: _buildProductInfo(item, context)),
                SizedBox(width: 10.w),

                // Price Section
                _buildPriceSection(item, context),
              ],
            ),
          ),

          // Status message below (only if applicable)
          if (status.message != null ) ...[
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8.r)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status.icon,
                      size: 18.sp,
                      color: status.color,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        status.message!,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomImageContainer(
          imagePath:  imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildProductInfo(OrderItems item, BuildContext context) {
    return SizedBox(
      width: 125.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title ?? item.variant?.title ?? item.product?.name ?? 'Unknown Product',
            style: TextStyle(
                fontSize: isTablet(context) ? 18 : 12.sp,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.fontFamily
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          Text(
            'Qty: ${item.quantity}',
            style: TextStyle(
                fontSize: isTablet(context) ? 18 : 12.sp,
                color: Colors.grey[500],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if(item.product!.requiresOtp == 1)
            Text(
              'OTP: ${item.otp}',
              style: TextStyle(
                  fontSize: isTablet(context) ? 18 : 12.sp,
                  color: Colors.grey[500],
                  fontFamily: AppTheme.fontFamily
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(OrderItems item, BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppConstant.currency}${item.price}',
            style: TextStyle(
              fontSize: isTablet(context) ? 18 : 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}