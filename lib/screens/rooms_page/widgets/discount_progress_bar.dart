import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../model/group_buy_models.dart';
import '../services/room_discount_service.dart';

class DiscountProgressBar extends StatelessWidget {
  final GroupBuyRoom room;
  final RoomDiscountInfo? discountInfo;
  final double height;
  final bool showLabels;
  final bool showDiscount;

  const DiscountProgressBar({
    super.key,
    required this.room,
    this.discountInfo,
    this.height = 12,
    this.showLabels = true,
    this.showDiscount = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = room.unlockProgress;
    final currentDiscount = discountInfo?.currentDiscount ?? room.currentDiscountValue;
    final isUnlocked = room.isUnlocked;
    final membersNeeded = room.membersNeededToUnlock;
    final nextSlab = room.nextDiscountSlab;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height.r),
          child: Stack(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUnlocked ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                minHeight: height.h,
              ),
              if (isUnlocked && currentDiscount > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.3),
                          Colors.orange.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showLabels) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUnlocked
                        ? '${room.membersJoined} / ${room.effectiveThreshold} members'
                        : '${room.membersJoined} / ${room.effectiveThreshold} joined',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (!isUnlocked && membersNeeded > 0)
                    Text(
                      '$membersNeeded more to unlock',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                ],
              ),
              if (showDiscount && isUnlocked)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${currentDiscount.toStringAsFixed(0)}% OFF',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
          if (isUnlocked && nextSlab != null && showDiscount) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14.sp,
                  color: Colors.orange,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${nextSlab.discountPercentage.toStringAsFixed(0)}% at ${nextSlab.memberTarget} members',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class DynamicPriceDisplay extends StatelessWidget {
  final double originalPrice;
  final GroupBuyRoom room;
  final TextStyle? originalStyle;
  final TextStyle? discountedStyle;
  final TextStyle? discountBadgeStyle;

  const DynamicPriceDisplay({
    super.key,
    required this.originalPrice,
    required this.room,
    this.originalStyle,
    this.discountedStyle,
    this.discountBadgeStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (!room.isUnlocked) {
      return Text(
        'Unlock to see price',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final discount = room.currentDiscountValue;
    final finalPrice = room.getDynamicPrice(originalPrice);
    final hasDiscount = discount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount) ...[
          Text(
            '₹${originalPrice.toStringAsFixed(0)}',
            style: originalStyle ?? TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(height: 2.h),
        ],
        Text(
          '₹${finalPrice.toStringAsFixed(0)}',
          style: discountedStyle ?? TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        if (hasDiscount) ...[
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '${discount.toStringAsFixed(0)}% OFF',
              style: discountBadgeStyle ?? TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class NextDiscountBanner extends StatelessWidget {
  final RoomDiscountSlabModel? nextSlab;
  final int currentMembers;

  const NextDiscountBanner({
    super.key,
    this.nextSlab,
    required this.currentMembers,
  });

  @override
  Widget build(BuildContext context) {
    if (nextSlab == null) {
      return const SizedBox.shrink();
    }

    final membersNeeded = nextSlab!.memberTarget - currentMembers;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nextSlab!.discountPercentage.toStringAsFixed(0)}% OFF coming soon!',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  '$membersNeeded more member${membersNeeded == 1 ? '' : 's'} to unlock',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}