import 'dart:ui';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/group_buy_models.dart';

class RoomProductCard extends StatelessWidget {
  final GroupBuyProduct product;
  final RoomState roomState;
  final VoidCallback? onTap;
  final bool showAddButton;

  const RoomProductCard({
    super.key,
    required this.product,
    required this.roomState,
    this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isBlurred = roomState == RoomState.active;
    final isVisible = roomState == RoomState.unlocked;
    final canShowProducts = roomState.showProducts;

    return GestureDetector(
      onTap: canShowProducts ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(isBlurred),
                _buildProductInfo(context, isVisible),
              ],
            ),
            if (!canShowProducts) _buildLockedOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isBlurred) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: product.imageUrl ?? '',
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 120.h,
                  color: Colors.grey[200],
                  child: const Center(child: CustomCircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 120.h,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
              if (isBlurred)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (product.hasDiscount)
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '-${product.discountPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (roomState == RoomState.active)
          Positioned(
            top: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open, color: Colors.white, size: 10.w),
                  SizedBox(width: 2.w),
                  Text(
                    'Locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context, bool showPrice) {
    return Padding(
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          if (showPrice) ...[
            Row(
              children: [
                Text(
                  '₹${product.displayPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (product.hasDiscount) ...[
                  SizedBox(width: 6.w),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              '${product.stock} in stock',
              style: TextStyle(
                fontSize: 10.sp,
                color: product.inStock ? Colors.green : Colors.red,
              ),
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                roomState == RoomState.active 
                    ? 'Price unlocks at ${roomState.displayName}'
                    : 'Available at ${roomState.displayName}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                roomState == RoomState.teasing ? Icons.hourglass_empty : Icons.lock,
                color: Colors.white,
                size: 32.w,
              ),
              SizedBox(height: 8.h),
              Text(
                roomState == RoomState.teasing 
                    ? 'Coming Soon' 
                    : 'Join to Unlock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomProductsGrid extends StatelessWidget {
  final List<GroupBuyProduct> products;
  final RoomState roomState;
  final void Function(GroupBuyProduct)? onProductTap;

  const RoomProductsGrid({
    super.key,
    required this.products,
    required this.roomState,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return RoomProductCard(
          product: products[index],
          roomState: roomState,
          onTap: () => onProductTap?.call(products[index]),
        );
      },
    );
  }
}