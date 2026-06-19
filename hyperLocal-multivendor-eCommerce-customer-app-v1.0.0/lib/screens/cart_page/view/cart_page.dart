import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/payment_config.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_event.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_state.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_state.dart';
import 'package:hyper_local/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/delivery_address_widget.dart';
import 'package:hyper_local/screens/cart_page/widgets/address_selection_bottom_sheet.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/constant.dart';
import '../../../config/global.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/whole_page_progress.dart';
import '../../../utils/widgets/gst_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../config/settings_data_instance.dart';
import '../../my_orders/bloc/create_order/create_order_bloc.dart';
import '../../payment_options/bloc/payment_bloc.dart';
import '../../payment_options/bloc/payment_event.dart';
import '../../payment_options/bloc/payment_state.dart';
import '../../payment_options/widgets/webview_payment.dart';
import '../../product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import '../../address_list_page/model/get_address_list_model.dart';
import '../../address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/bloc/coins_bloc/coins_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_state.dart';
import '../../../router/app_routes.dart';
import '../bloc/cart_ui_bloc/cart_ui_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_event.dart';
import '../bloc/cart_ui_bloc/cart_ui_state.dart';
import '../bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/promo_code/promo_code_bloc.dart';
import '../bloc/promo_code/promo_code_event.dart';
import '../bloc/promo_code/promo_code_state.dart';
import '../bloc/clear_cart/clear_cart_state.dart';
import '../model/get_cart_model.dart';
import '../widgets/cart_product_item.dart';
import '../widgets/delivery_type_widget.dart';
import '../widgets/removed_items_widget.dart';
import '../widgets/wallet_usage_widget.dart';
import '../widgets/you_might_also_like_product_widget.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  AddressListData? selectedAddress;
  double totalAmount = 0.0;
  String? selectedPaymentMethod;
  dynamic selectedPaymentMethodType;
  bool isCartLoading = true;
  bool isClearingCart = false;
  bool isWholePageProgress = false;
  DeliveryType selectedDeliveryType = DeliveryType.regular;
  int? cartId;
  bool useWallet = false;
  int? coinsToUse;
  double? coinsRupeeValue;
  int coinsAvailable = 0;
  List<GetCartModel> stateData = [];
  int? deliveryZoneId;
  int? previousDeliveryZoneId;
  String? promoCode;

  @override
  void initState() {
    super.initState();
    final hiveAddress = HiveSelectedAddressHelper.getSelectedAddress();
    if (hiveAddress != null && hiveAddress.id != null) {
      selectedAddress = AddressListData(
        id: hiveAddress.id,
        userId: hiveAddress.userId,
        addressLine1: hiveAddress.addressLine1,
        addressLine2: hiveAddress.addressLine2,
        city: hiveAddress.city,
        landmark: hiveAddress.landmark,
        state: hiveAddress.state,
        zipcode: hiveAddress.zipcode,
        mobile: hiveAddress.mobile,
        addressType: hiveAddress.addressType,
        country: hiveAddress.country,
        countryCode: hiveAddress.countryCode,
        latitude: hiveAddress.latitude,
        longitude: hiveAddress.longitude,
        createdAt: hiveAddress.createdAt,
        updatedAt: hiveAddress.updatedAt,
      );
    }
    
    // context.read<GetUserCartBloc>().add(SyncCart());
    context.read<GetUserCartBloc>().add(FetchUserCart(addressId: selectedAddress?.id));
    context.read<SettingsBloc>().add(FetchSettingsData());
    context.read<SimilarProductBloc>().add(FetchSimilarProduct(
        excludeProductSlug: context.read<GetUserCartBloc>().productSlug)
    );
    context.read<PromoCodeBloc>().add(RemovePromoCode());
    // Fetch coins balance (wallet-money feature removed)
    context.read<CoinsBloc>().add(FetchCoinsBalance());
  }

  Widget _buildCoinSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coins to use',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6.h),
                Text(
                  coinsToUse != null ? '$coinsToUse coins' : 'Apply coins to reduce payable amount',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () async {
              // Allow user to pick number of coins to use. For now, open a simple dialog to enter an integer.
              final result = await showDialog<int?>(
                context: context,
                builder: (ctx) {
                  int? picked = coinsToUse ?? coinsAvailable;
                  return AlertDialog(
                    title: Text('Select coins to use'),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Available: $coinsAvailable coins'),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (picked != null && picked! > 0) picked = picked! - 1;
                                    });
                                  },
                                  icon: Icon(Icons.remove),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: (picked ?? 0).toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      final parsed = int.tryParse(v) ?? 0;
                                      setState(() {
                                        picked = parsed;
                                      });
                                    },
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      picked = (picked ?? 0) + 1;
                                    });
                                  },
                                  icon: Icon(Icons.add),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(picked), child: Text('Apply')),
                    ],
                  );
                },
              );

              if (result != null) {
                final coinsToTry = result.clamp(0, coinsAvailable);
                // Save and request redemption calculation
                setState(() {
                  coinsToUse = coinsToTry;
                });
                context.read<CoinsBloc>().add(CalculateRedemption(coinsToTry));
                // Refresh cart to include use_wallet flag for backward compatibility
                context.read<GetUserCartBloc>().add(FetchUserCart(
                  addressId: selectedAddress?.id,
                  rushDelivery: selectedDeliveryType == DeliveryType.rush,
                  useWallet: useWallet,
                  promoCode: promoCode,
                ));
              }
            },
            child: Text('Choose'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (BuildContext context, PaymentState state) {
        return Stack(
          children: [
            CustomScaffold(
                showViewCart: false,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                title: l10n?.cart ?? 'Cart',
                appBarActions: [
                  BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      bool hasItems = true;

                      if(state is GetUserCartLoaded && state.cartData.isNotEmpty){
                        hasItems = state.cartData.first.data?.items != null;
                      }
                      if(state is GetUserCartLoaded && state.cartData.isEmpty){
                        hasItems = false;
                      }
                      if(hasItems) {
                        return Container(
                          padding: EdgeInsets.only(right: 10),
                          child: TextButton(
                              onPressed: () async {
                                final shouldClear = await _showClearCartConfirmDialog(context);
                                if (shouldClear) {
                                  if(context.mounted) {
                                    context.read<ClearCartBloc>().add(ClearCartRequest());
                                    context.read<CartBloc>().add(ClearCart(context: context));
                                  }
                                  Future.delayed(Duration(milliseconds: 200),(){
                                    if(context.mounted) {
                                      context.read<GetUserCartBloc>().add(FetchUserCart(
                                          addressId: selectedAddress?.id,
                                          rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                          useWallet: useWallet,
                                          promoCode: promoCode
                                      ));
                                    }
                                  });
                                }
                              },

                              child: Text(
                                AppLocalizations.of(context)!.clearCart,
                                style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 14
                                ),
                              )
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ],
                showAppBar: true,
                body: MultiBlocListener(
                  listeners: [
                    BlocListener<GetAddressListBloc, GetAddressListState>(
                      listener: (context, addressState) {
                        log('Get Address List Bloc  $state');
                        // Auto-select first address when addresses are loaded
                        if (addressState is GetAddressListLoaded &&
                            selectedAddress == null &&
                            addressState.addressList.isNotEmpty) {
                          setState(() {
                            selectedAddress = addressState.addressList.first;
                            isCartLoading = true;
                          });
                          // Save selected address to Hive
                          HiveSelectedAddressHelper.setSelectedAddress(addressState.addressList.first);
                          // Update cart with selected address
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                        }
                      },
                    ),
                    BlocListener<GetUserCartBloc, GetUserCartState>(
                        listener: (context, state) {
                          log('Get User Cart Bloc  $state');

                          if(state is GetUserCartLoaded) {
                            setState(() {
                              isCartLoading = false;
                              // Extract deliveryZoneId from cart data
                              if(state.cartData.isNotEmpty &&
                                  state.cartData.first.data?.deliveryZone != null) {
                                final newDeliveryZoneId = state.cartData.first.data?.deliveryZone!.zoneId;
                                // Only fetch addresses if deliveryZoneId changed or is first time set
                                if(newDeliveryZoneId != null && newDeliveryZoneId != previousDeliveryZoneId) {
                                  deliveryZoneId = newDeliveryZoneId;
                                  previousDeliveryZoneId = newDeliveryZoneId;
                                  // Fetch address list with deliveryZoneId for checkout (only when zone changes)
                                  context.read<GetAddressListBloc>().add(
                                      FetchUserAddressList(deliveryZoneId: deliveryZoneId)
                                  );
                                } else if(newDeliveryZoneId != null) {
                                  // Update deliveryZoneId but don't fetch addresses if it hasn't changed
                                  deliveryZoneId = newDeliveryZoneId;
                                }
                              }
                            });
                            context.read<CartUIBloc>().add(SetWalletLoading(false));
                          }
                          else if(state is GetUserCartLoading) {
                            setState(() {
                              isCartLoading = true;
                            });
                            context.read<CartUIBloc>().add(SetWalletLoading(false));
                          }
                          else if(state is GetUserCartFailed) {
                            final localCartState = context.read<CartBloc>().state;
                            bool hasLocalItems = false;
                            if (localCartState is CartLoaded) {
                              hasLocalItems = localCartState.items.isNotEmpty;
                            }
                            setState(() {
                              isCartLoading = hasLocalItems;
                            });
                            context.read<CartUIBloc>().add(SetWalletLoading(false));
                          }
                        }
                    ),
                    // Listen to coins updates (balance & redemption calculation)
                    BlocListener<CoinsBloc, CoinsState>(
                      listener: (context, state) {
                        if (state is CoinsBalanceLoaded) {
                          // cache coins available for use
                          setState(() {
                            coinsAvailable = state.balance.coinsBalance;
                          });
                        }
                        if (state is CoinsRedemptionCalculated) {
                          setState(() {
                            coinsToUse = state.coinsToUse;
                            coinsRupeeValue = state.rupeeValue;
                          });
                        }
                        if (state is CoinsRedeemed) {
                          // refresh cart and balance after redemption
                          context.read<CoinsBloc>().add(FetchCoinsBalance());
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                        }
                      },
                    ),
                    BlocListener<RemoveItemFromCartBloc, RemoveItemFromCartState>(
                      listener: (context, state){

                        log('Remove Item From Cart Bloc  $state');
                        if(state is RemoveItemFromCartLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is RemoveItemFromCartSuccess){
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                        }
                        if(state is RemoveItemFromCartFailed) {
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<ClearCartBloc, ClearCartState>(
                      listener: (context, state) {
                        log('Clear Cart Bloc  $state');
                        if(state is ClearCartLoading) {
                          setState(() {
                            isCartLoading = true;
                            isClearingCart = true;
                          });
                        } else if(state is ClearCartSuccess || state is ClearCartFailed) {
                          context.read<GetUserCartBloc>().add(RefreshUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode ?? ''
                          ));
                          setState(() {
                            isCartLoading = false;
                            isClearingCart = false;
                          });
                        }
                      },
                    ),
                    BlocListener<SaveForLaterBloc, SaveForLaterState>(
                      listener: (context, state) {
                        log('Save For Later Bloc  $state');
                        if(state is SaveForLaterLoading) {
                          setState(() {
                            isCartLoading = true;
                          });
                        } else if(state is ProductSavedSuccess) {
                          // Cart will be refreshed automatically
                          setState(() {
                            isCartLoading = false;
                          });
                          
                          // CRITICAL: Remove from local active cart so it doesn't sync back as active
                          if(state.productId != null && state.variantId != null) {
                            final cartKey = '${state.productId}_${state.variantId}';
                            context.read<CartBloc>().add(RemoveLocally(cartKey, context));
                          }

                          ToastManager.show(
                              context: context,
                              message: '${state.productName} is saved for later'
                          );
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                        } else if(state is SaveForLaterFailed) {
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<CreateOrderBloc, CreateOrderState>(
                      listener: (context, state) {
                        log('Create Order Bloc  $state');
                        if (state is CreateOrderSuccess) {

                          context.read<CartUIBloc>().add(SetWholePageProgress(true));
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          setState(() {
                            isWholePageProgress = true;
                            isCartLoading = true;
                          });
                          if(selectedPaymentMethodType == PaymentMethodType.flutterwave) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => WebViewPaymentPage(
                                  paymentUrl: state.paymentUrl!,
                                  onPaymentSuccess: () {
                                    final displayAddress = selectedAddress != null
                                        ? formatAddressFromModel(selectedAddress!)
                                        : null;

                                    GoRouter.of(context).pop();
                                    log('Payment successful: ${state.message}');

                                    // Navigate to order success page
                                    GoRouter.of(context).push(
                                      AppRoutes.orderSuccess,
                                      extra: {
                                        'address': displayAddress,
                                        'addressType': selectedAddress!.addressType,
                                        'orderSlug': state.orderSlug,
                                      },
                                    );
                                  },
                                  onPaymentFailure: () {
                                    context.read<GetUserCartBloc>().add(FetchUserCart(
                                        addressId: selectedAddress?.id,
                                        rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                        useWallet: useWallet,
                                        promoCode: promoCode
                                    ));
                                  },
                                ))
                            );
                          } else {
                            final displayAddress = selectedAddress != null
                                ? formatAddressFromModel(selectedAddress!)
                                : null;

                            GoRouter.of(context).pop();
                            log('Payment successful: ${state.message}');

                            // Navigate to order success page
                            GoRouter.of(context).push(
                              AppRoutes.orderSuccess,
                              extra: {
                                'address': displayAddress,
                                'addressType': selectedAddress!.addressType,
                                'orderSlug': state.orderSlug,
                              },
                            );
                          }

                        }
                        else if (state is CreateOrderFailure) {
                          setState(() {
                            isWholePageProgress = false;
                            isCartLoading = false;
                          });
                          ToastManager.show(
                            context: context,
                            message: state.error,
                            type: ToastType.error,
                          );
                        }
                        else if (state is CreateOrderProgress) {
                          setState(() {
                            isWholePageProgress = true;
                          });
                        }
                      },
                    ),
                    // Payment BLoC Listener
                    BlocListener<PaymentBloc, PaymentState>(
                      listener: (context, state) {
                        log('Payment Bloc  $state');
                        log('Payment Success  $state');
                        if (state is PaymentSuccess) {
                          setState(() {
                            isWholePageProgress = false;
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          _initiatePayment(
                              paymentId: state.transactionId,
                              signature: state.signature,
                              orderId: state.orderId
                          );
                        }
                        else if (state is PaymentFailure) {
                          setState(() {
                            isWholePageProgress = false;
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                          ToastManager.show(
                              context: context,
                              message: state.error,
                              type: ToastType.error
                          );
                        }
                        else if(state is PaymentLoading) {
                          setState(() {
                            isWholePageProgress = true;
                          });
                        }
                      },
                    ),
                    BlocListener<UpdateItemQuantityBloc, UpdateItemQuantityState>(
                      listener: (context, state){
                        log('Update Item Quantity Bloc  $state');
                        if(state is UpdateItemQuantityLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is UpdateItemQuantitySuccess) {
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                        }
                        if(state is UpdateItemQuantityFailed){
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<PromoCodeBloc, PromoCodeState>(
                      listener: (context, state){
                        if(state is PromoCodeRemoving || state is PromoCodeApplying || state is PromoCodeLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is PromoCodeFailed){
                          setState(() {
                            isCartLoading = false;
                          });
                          ToastManager.show(
                              context: context,
                              message: AppLocalizations.of(context)!.promoCodeAppliedOnYourCart
                          );
                        }
                        if(state is PromoCodeSelected){
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                          if(state.promoCode.isNotEmpty) {
                            ToastManager.show(
                                context: context,
                                message: AppLocalizations.of(context)!.promoCodeAppliedOnYourCart
                            );
                          }
                        }
                        if(state is PromoCodeRemoved){
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                        }
                      },
                    )
                  ],
                  child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      if(state is UserCartInitialLoading){
                        return CustomCircularProgressIndicator();
                      }
                      if (state is GetUserCartFailed) {
                        final localCartState = context.read<CartBloc>().state;
                        bool hasLocalItems = false;
                        if (localCartState is CartLoaded) {
                          hasLocalItems = localCartState.items.isNotEmpty;
                        }
                        if (hasLocalItems) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 50.h),
                                CustomCircularProgressIndicator(),
                                SizedBox(height: 10.h),
                                Text("Loading your cart...", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                      }
                      return CustomRefreshIndicator(
                        onRefresh: () async {
                          context.read<GetUserCartBloc>().add(RefreshUserCart(
                              addressId: selectedAddress?.id,
                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                              useWallet: useWallet,
                              promoCode: promoCode
                          ));
                          context.read<SettingsBloc>().add(FetchSettingsData());
                          context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: deliveryZoneId));
                          // wallet-money feature removed — fetch coins balance instead
                          context.read<CoinsBloc>().add(FetchCoinsBalance());
                        },
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                            builder: (BuildContext context, GetUserCartState state) {
                              if(state is GetUserCartLoaded) {
                                stateData = state.cartData;
                              }
                              if (isClearingCart) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 50.h),
                                      CustomCircularProgressIndicator(),
                                      SizedBox(height: 10.h),
                                      Text("Clearing your cart...", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }
                              if (stateData.isEmpty) {
                                final localCartState = context.read<CartBloc>().state;
                                bool hasLocalItems = false;
                                if (localCartState is CartLoaded) {
                                  hasLocalItems = localCartState.items.isNotEmpty;
                                }

                                if (hasLocalItems || isCartLoading) {
                                  // We have local items but server/stateData is empty => SYNCING
                                  // OR we are just generically loading (isCartLoading = true) and have no data yet
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 50.h),
                                        CustomCircularProgressIndicator(),
                                        SizedBox(height: 10.h),
                                        Text(hasLocalItems ? "Syncing your cart..." : "Loading...", style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }

                                isCartLoading = false;
                                return _buildEmptyCartState();
                              }

                              isCartLoading = false;
                              if(stateData.first.data != null) {
                                isCartLoading = false;
                                cartId = stateData.first.data?.id;
                                final cartData = stateData;
                                final billSummaryData = cartData.first.data?.paymentSummary;
                                deliveryZoneId = cartData.first.data?.deliveryZone?.zoneId;
                                totalAmount = billSummaryData?.payableAmount?.toDouble() ?? 0.0;
                                return Column(
                                  children: [
                                    RemovedItemsWidget(
                                      removedItems: cartData.first.data?.removedItems ?? [],
                                    ),
                                    CartWidget(
                                      items: cartData.first.data?.items ?? [],
                                      deliveryTime: cartData.first.data?.paymentSummary?.estimatedDeliveryTime?.toString() ?? '',
                                      onQuantityChanged: _handleQuantityChanged,
                                      onRemoveItem: _handleRemoveItem,
                                      onAddMoreItems: _handleAddMoreItems,
                                      // Customization options
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      quantityButtonColor: AppTheme.primaryColor,
                                      priceColor: Colors.black,
                                      originalPriceColor: Colors.grey[500],
                                      totalItem: cartData.first.data?.totalQuantity,
                                    ),
                                    offerAndCouponButton(),
                                    SizedBox(height: 9.h,),
                                    BlocBuilder<SimilarProductBloc, SimilarProductState>(
                                        builder: (context, state) {
                                          if(state is SimilarProductLoaded) {
                                            return YouMightAlsoLikeProductWidget(
                                              productData: state.similarProduct,
                                            );
                                          } else if(state is SimilarProductLoading) {
                                            return productListShimmer(3);
                                          }
                                          return SizedBox.shrink();
                                        }
                                    ),
                                    SizedBox(height: 9.h,),
                                    DeliveryTypeWidget(
                                      selectedDeliveryType: selectedDeliveryType,
                                      rushDeliveryCharge: 50.0,
                                      isRushDeliveryDisabled: billSummaryData?.isRushDeliveryAvailable == false,
                                      onDeliveryTypeChanged: (DeliveryType type) {
                                        setState(() {
                                          selectedDeliveryType = type;
                                        });
                                        // Update cart with new delivery type
                                        _updateCartWithDeliveryType(type);
                                      },
                                    ),
                                    SizedBox(height: 9.h,),
                                    BlocBuilder<CartUIBloc, CartUIState>(
                                      builder: (context, state) {
                                        return WalletUsageWidget(
                                          isWalletEnabled: useWallet,
                                          isLoading: isCartLoading,
                                          onWalletToggle: state.isWalletLoading ? (value){} : (value) {
                                            context.read<CartUIBloc>().add(SetWalletLoading(true));
                                            setState(() {
                                              isCartLoading = true;
                                              useWallet = value;
                                            });
                                            // When toggling coins usage ON, ask CoinsBloc to calculate redemption
                                              if (value == true) {
                                               // Use all available coins by default when toggled
                                               final coinsToTry = coinsAvailable;
                                               setState((){ coinsToUse = coinsToTry; });
                                               context.read<CoinsBloc>().add(CalculateRedemption(coinsToTry));
                                             } else {
                                               // clearing coin usage
                                               setState(() {
                                                 coinsToUse = null;
                                                 coinsRupeeValue = null;
                                               });
                                             }

                                            context.read<GetUserCartBloc>().add(FetchUserCart(
                                              addressId: selectedAddress?.id,
                                              promoCode: billSummaryData?.promoCode,
                                              rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                              useWallet: value,
                                            ));
                                          },
                                        );
                                      },
                                    ),

                                    SizedBox(height: 10.h,),
                                    BillSummaryWidget(
                                      itemsOriginalPrice: 0,
                                      itemsDiscountedPrice: GstUtils.getBasePrice(billSummaryData?.itemsTotal?.toDouble() ?? 0),
                                      itemsSavings: 0,
                                      deliveryChargeOriginal: billSummaryData?.totalDeliveryCharges?.toDouble() ?? 0,
                                      handlingCharge: billSummaryData?.handlingCharges?.toDouble() ?? 0,
                                      grandTotal: billSummaryData?.payableAmount?.toDouble() ?? 0,
                                      totalSavings: 0,
                                      perStoreDropOffFees: billSummaryData?.perStoreDropOffFee?.toDouble() ?? 0.0,
                                      promoCode: billSummaryData?.promoCode,
                                      promoDiscount: double.tryParse(billSummaryData?.promoDiscount ?? '0') ?? 0.0,
                                      promoError: billSummaryData?.promoError,
                                      removeCoupon: (){
                                        setState(() {
                                          isCartLoading = true;
                                          promoCode = '';
                                        });
                                        context.read<PromoCodeBloc>().add(RemovePromoCode());
                                        context.read<GetUserCartBloc>().add(FetchUserCart(
                                            addressId: selectedAddress?.id,
                                            rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                            useWallet: useWallet,
                                            promoCode: promoCode ?? ''
                                        ));
                                      },
                                      promoMode: billSummaryData?.promoApplied?.promoMode ?? '',
                                      discountAmount: billSummaryData?.promoApplied?.discountAmount ?? '',
                                      isRushDelivery: billSummaryData?.isRushDelivery ?? false,
                                      // Show coin redemption preview if calculated
                                      coinsToUse: coinsToUse,
                                      coinsDiscountRupee: coinsRupeeValue,
                                      platformCharge: billSummaryData?.platformCharge?.toDouble(),
                                      cgst: billSummaryData?.cgst?.toDouble(),
                                      sgst: billSummaryData?.sgst?.toDouble(),
                                    )
                                    ,
                                    // Coin selector (visible when coins usage is enabled)
                                    if (useWallet)
                                      SizedBox(height: 8.h),
                                    if (useWallet)
                                      _buildCoinSelector(),
                                  ],
                                );
                              }
                              else {
                                isCartLoading = false;
                                return _buildEmptyCartState();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomNavigationBar: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                  builder: (context, state) {
                    bool hasItems = true;
                    // Update total amount from cart data
                    if (state is GetUserCartLoaded) {
                      stateData = state.cartData;
                      if (stateData.isNotEmpty) {
                        hasItems = stateData.first.data?.items != null;
                      } else {
                        hasItems = false;
                      }
                    }

                    if(hasItems){
                      // if(stateData.first.data!.paymentSummary!.itemsTotal! > SettingsData.instance.system!.minimumCartAmount){
                      //   return minimumCartAmountAlertWidget();
                      // }
                      if (stateData.isNotEmpty) {
                        totalAmount = stateData.first.data?.paymentSummary!.payableAmount?.toDouble() ?? 0.0;
                      } else {
                        totalAmount = 0.0;
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if(selectedAddress != null)
                            DeliveryAddressWidget(
                              selectedAddress: selectedAddress,
                              onTap: () {
                                _showAddressSelectionBottomSheet();
                              },
                            ),
                          _buildCheckoutSection(),
                        ],
                      );
                    }
                    else {
                      return SizedBox.shrink();
                    }
                  },
                )
            ),
            if(isWholePageProgress)
              WholePageProgress(),
          ],
        );
      },
    );
  }

  Future<bool> _showClearCartConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.clearAllItems,
            textAlign: TextAlign.center,
          ),
          content: Text(
            AppLocalizations.of(context)!.allItemsWillBeRemovedCannotBeUndone,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n?.no ?? 'No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n?.yesClear ?? 'Yes, clear',
                style: TextStyle(
                    color: AppTheme.primaryColor
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _updateCartWithDeliveryType(DeliveryType type) {
    // Update your cart with the selected delivery type
    context.read<GetUserCartBloc>().add(FetchUserCart(
        addressId: selectedAddress?.id,
        rushDelivery: type == DeliveryType.rush,
        useWallet: useWallet,
        promoCode: promoCode ?? ''
    ));
  }

  Widget offerAndCouponButton (){
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () async {
        final result = await GoRouter.of(context).push(AppRoutes.promoCode);
        if(result != null && result is String && result.isNotEmpty){
          if(mounted){
            context.read<CartUIBloc>().add(SetCartLoading(true));
            promoCode = result;
            context.read<GetUserCartBloc>().add(FetchUserCart(
              addressId: selectedAddress?.id,
              promoCode: promoCode,
              rushDelivery: selectedDeliveryType == DeliveryType.rush,
              useWallet: useWallet,
            ));
          }
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  TablerIcons.rosette_discount_filled, color: Color(0xFF149400),
                  size: isTablet(context) ? 18.r : 26.r,
                ),
                SizedBox(width: 5.w,),
                Text(
                  l10n?.viewCouponOffers ?? 'View Coupon & Offers',
                  style: TextStyle(
                      fontSize: isTablet(context) ? 22 : 15.sp,
                      fontWeight: FontWeight.w600
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right)
          ],
        ),
      ),
    );
  }

  void _handleQuantityChanged(String itemId, int newQuantity) {
    setState(() {
      isCartLoading = true;
    });
    context.read<UpdateItemQuantityBloc>().add(UpdateItemQuantityRequest(
        cartItemId: int.parse(itemId),
        quantity: newQuantity
    ));
  }

  void _handleRemoveItem(String itemId) {
    setState(() {
      isCartLoading = true;
    });
    context.read<RemoveItemFromCartBloc>().add(RemoveItemFromCartRequest(cartItemId: int.parse(itemId)));
  }

  void _handleAddMoreItems() {
    final l10n = AppLocalizations.of(context);
    // Navigate to products page or show add items dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n?.addMoreItemsTapped ?? 'Add more items tapped!')),
    );
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => AddressSelectionBottomSheet(
        selectedAddress: selectedAddress,
        deliveryZoneId: deliveryZoneId,
        onAddressSelected: (address) {
          if(address.id != selectedAddress?.id) {
            setState(() {
              selectedAddress = address;
              selectedDeliveryType = DeliveryType.regular;
              isCartLoading = true;
            });
            // Save selected address to Hive
            HiveSelectedAddressHelper.setSelectedAddress(address);
            context.read<GetUserCartBloc>().add(FetchUserCart(
                addressId: address.id,
                useWallet: useWallet,
                rushDelivery: selectedDeliveryType == DeliveryType.rush,
                promoCode: promoCode
            ));
          }
        },
      ),
    );
  }

  void _navigateToPaymentOptions() async {
    final l10n = AppLocalizations.of(context);
    if (selectedAddress == null) {
      ToastManager.show(
          context: context,
          message: l10n?.pleaseSelectADeliveryAddressFirst ?? 'Please select a delivery address first',
          type: ToastType.error
      );
      return;
    }

    final paymentMethodType = await context.push(
      AppRoutes.paymentOptions,
      extra: {
        'totalAmount': totalAmount,
      },
    );

    if (paymentMethodType != null && paymentMethodType is PaymentMethodType) {
      final paymentMethod = PaymentConfig.getPaymentMethodByType(paymentMethodType);
      if (paymentMethod != null) {
        setState(() {
          selectedPaymentMethod = paymentMethod.id;
          selectedPaymentMethodType = paymentMethod.type;
        });
      }
    }
  }

  void _processOrder(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (totalAmount <= 0) {
      _initiatePayment();
      return;
    }

    if (selectedPaymentMethod == null) {
      ToastManager.show(
          context: context,
          message: l10n?.selectPaymentMethod ?? 'Please select a payment method first',
          type: ToastType.error
      );
      return;
    }

    // Process payment based on method
    if(selectedPaymentMethod != 'cod' && selectedPaymentMethodType != PaymentMethodType.flutterwave) {
      context.read<PaymentBloc>().add(
        InitiatePaymentEvent(
            paymentMethodType: selectedPaymentMethodType!,
            amount: totalAmount,
            additionalData: {
              'userId': Global.userData?.userId.toString() ?? '',
              'customerName': Global.userData?.name.toString() ?? '',
              'email': Global.userData?.email.toString() ?? '',
              'phone': Global.userData?.mobile.toString() ?? '',
              'deliveryAddress': formatAddressFromModel(selectedAddress!),
            },
            addMoneyToWallet: false,
            context: context
        ),
      );
    } else {
      _initiatePayment();
    }
  }

  void _initiatePayment({String? paymentId, String? signature, String? orderId,}) {
    final l10n = AppLocalizations.of(context);
    if(totalAmount <= 0) {
      // If coins are being used, include coins_to_use in paymentDetails
      final Map<String, dynamic> paymentDetailsWithCoins = {};
      if (selectedPaymentMethod == 'razorpay') {
        paymentDetailsWithCoins.addAll({
          'razorpay_order_id': orderId,
          'razorpay_signature': signature,
          'transaction_id': paymentId,
        });
      } else if (selectedPaymentMethodType != PaymentMethodType.flutterwave) {
        paymentDetailsWithCoins.addAll({'transaction_id': paymentId});
      }

      if (coinsToUse != null) paymentDetailsWithCoins['coins_to_use'] = coinsToUse;

      context.read<CreateOrderBloc>().add(CreateOrderRequest(
        // switched to coins for zero-payable orders
        paymentType: 'coins',
        addressId: selectedAddress!.id!,
        rushDelivery: selectedDeliveryType == DeliveryType.rush,
        promoCode: promoCode,
        useCoins: useWallet,
        coinsToUse: coinsToUse,
        paymentDetails: paymentDetailsWithCoins,
      ));
      return;
    }
    if (selectedPaymentMethod == null && selectedPaymentMethodType == null) {
      ToastManager.show(
        context: context,
        message: l10n?.paymentMethodNotSelected ?? 'Payment method not selected',
        type: ToastType.error,
      );
      return;
    }

    final Map<String, dynamic> paymentDetails = {};
    if (selectedPaymentMethod == 'razorpay') {
      paymentDetails.addAll({
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'transaction_id': paymentId,
      });
    } else if (selectedPaymentMethodType != PaymentMethodType.flutterwave) {
      paymentDetails.addAll({'transaction_id': paymentId});
    }

    if (coinsToUse != null) paymentDetails['coins_to_use'] = coinsToUse;

    context.read<CreateOrderBloc>().add(CreateOrderRequest(
      paymentType: selectedPaymentMethod!,
      addressId: selectedAddress!.id!,
      rushDelivery: selectedDeliveryType == DeliveryType.rush,
      promoCode: promoCode,
      useCoins: useWallet,
      coinsToUse: coinsToUse,
      paymentDetails: paymentDetails,
    ));
  }

  Widget _buildCheckoutSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
      child: selectedAddress != null
          ? Row(
        children: [
          if(totalAmount > 0.0)
            if(selectedPaymentMethod != null && selectedPaymentMethodType != null)...[
              // Selected payment method on the left
              InkWell(
                onTap: _navigateToPaymentOptions,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (selectedPaymentMethod != null && selectedPaymentMethodType != null) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: PaymentConfig.getPaymentMethodWidget(selectedPaymentMethod!, size: 24),
                          ),
                          SizedBox(width: 8),
                          Text(
                            (l10n?.payUsing ?? 'Pay Using').toUpperCase(),
                            style: TextStyle(
                                fontSize: 10.sp,
                                letterSpacing: 1.1
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Icon(
                            Icons.arrow_drop_up,
                          ),
                        ]
                      ],
                    ),
                    Text(
                      PaymentConfig.getPaymentMethodName(selectedPaymentMethod!),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
            ],
          SizedBox(height: 5),
          // Pay button on the right
          Expanded(
            child: SizedBox(
              height: 50,
              child: CustomButton(
                onPressed: () {
                  final cartValidationError = CartValidation.validateCartForCheckout(
                    context: context,
                    cartTotal: totalAmount,
                    totalItemsCount: stateData.first.data!.totalQuantity!,
                  );
                  if(cartValidationError != null) {
                    ToastManager.show(
                        context: context,
                        message: cartValidationError
                    );
                  } else {
                    if (isCartLoading) return;
                    if (totalAmount <= 0 || selectedPaymentMethod != null) {
                      _processOrder(context);
                    } else {
                      _navigateToPaymentOptions();
                    }
                  }
                },
                child: isCartLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CustomCircularProgressIndicator(),
                )
                    : Text(
                  (selectedPaymentMethod != null || totalAmount <= 0.0) ? (l10n?.placeOrder ?? 'Place Order') : (l10n?.selectPaymentMethod ?? 'Select payment method'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      )
          : SizedBox(
        height: 50,
        width: double.infinity,
        child: CustomButton(
          onPressed: (){
            _navigateToAddAddress();
          },
          child: Text(
            AppLocalizations.of(context)!.chooseAddressForDelivery,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCartState() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.yourCartIsEmpty ?? 'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.looksLikeYouHaventAddedAnythingYet ?? 'Looks like you haven\'t added anything yet',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: CustomButton(
                onPressed: () {
                  GoRouter.of(context).pop();
                },
                child: Text(
                  l10n?.browseProducts ?? 'Browse products',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.locationPicker,
      extra: {
        'isFromAddressPage': true,
        'isEdit': false,
        'isFromCartPage': true,
        'deliveryZoneId': deliveryZoneId
      },
    );
  }

  Widget minimumCartAmountAlertWidget() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.minimumCartAmountRequired(SettingsData.instance.system?.minimumCartAmount ?? 0),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white
              ),
            ),
          ),
        ],
      ),
    );
  }
}
