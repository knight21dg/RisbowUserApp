import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final double total;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              const Spacer(),
              Semantics(
                label: 'Success icon',
                child: Container(
                  width: 92.w,
                  height: 92.w,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 54.w,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Success!',
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6.h),
              Text(
                'Your group order is placed.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.subtitleColor,
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  children: [
                    _row('Order Number', orderId),
                    Divider(color: Colors.grey.shade200),
                    _row(
                      'Total',
                      '${AppConstant.currency}${total.toStringAsFixed(0)}',
                    ),
                    Divider(color: Colors.grey.shade200),
                    _row('Status', 'Placed'),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Back to Rooms',
                onPressed: () => context.go('/rooms'),
              ),
              SizedBox(height: 10.h),
              SecondaryButton(
                label: 'View Order',
                onPressed: () => context.go('/my-orders'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: TextStyle(fontSize: 13.sp, color: AppColors.subtitleColor),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
