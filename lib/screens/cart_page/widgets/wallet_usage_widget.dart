import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import '../../../config/constant.dart';

class WalletUsageWidget extends StatefulWidget {
  final bool isWalletEnabled;
  final Function(bool) onWalletToggle;
  final bool isLoading;

  const WalletUsageWidget({
    super.key,
    required this.isWalletEnabled,
    required this.onWalletToggle,
    this.isLoading = false,
  });

  @override
  State<WalletUsageWidget> createState() => _WalletUsageWidgetState();
}

class _WalletUsageWidgetState extends State<WalletUsageWidget> {
  double balance = 0.00;
  double remainingBalance = 0.00;
  double usedBalance = 0.00;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 12.0.w,
          right: 12.0.w,
          top: 12.h,
          bottom: 12.h
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Use Wallet Balance',
                    style: TextStyle(
                      fontSize: isTablet(context) ? 24 : 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              BlocBuilder<GetUserCartBloc, GetUserCartState>(
                builder: (context, state) {
                  // We no longer rely on wallet fields here; switch enabled state
                  // is controlled by parent via isWalletEnabled and isLoading.
                  return state is GetUserCartLoading
                      ? CustomCircularProgressIndicator()
                      : SizedBox(
                    height: 25,
                    child: Switch(
                      value: widget.isWalletEnabled,
                      onChanged: (widget.isLoading) ? (value) {} : (value) {
                        widget.onWalletToggle(value);
                      },
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor;
                        }
                        return null;
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12.h),
            // Wallet money feature removed — show coins balance instead
            BlocBuilder<CoinsBloc, CoinsState>(
              builder: (context, state) {
                int coins = 0;
                double coinValue = 1.0;
                if (state is CoinsBalanceLoaded) {
                  coins = state.balance.coinsBalance;
                  coinValue = state.balance.coinValue;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Available Coins',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '$coins coins',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Equivalent: ${AppConstant.currency}${(coins * coinValue).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
