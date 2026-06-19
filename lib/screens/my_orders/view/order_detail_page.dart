
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_local/screens/my_orders/bloc/download_invoice/download_invoice_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'package:hyper_local/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_local/utils/widgets/gst_utils.dart';
import 'package:hyper_local/screens/my_orders/widgets/return_dialog.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'package:hyper_local/utils/widgets/animated_button.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/whole_page_progress.dart';
import 'package:open_filex/open_filex.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/dialog_box_animation.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/order_detail/order_detail_bloc.dart';
import '../widgets/order_detail_widget.dart';
import '../widgets/order_items_card.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/product_video_player.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderSlug;
  const OrderDetailPage({super.key, required this.orderSlug});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {

  @override
  void initState() {
    apiCall();
    super.initState();
  }

  Future<void> apiCall() async {
    context.read<OrderDetailBloc>().add(FetchOrderDetail(orderSlug: widget.orderSlug));
  }

  void _showReturnDialog(List<OrderItems> items, String orderSlug, bool isDelivered) {
    openSlideUpDialog(
      context,
      ReturnItemsDialog(
        items: items,
        orderSlug: orderSlug,
        isDelivered: isDelivered
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReturnOrderItemBloc, ReturnOrderItemState>(
          listener: (context, ReturnOrderItemState state) {
            if(state is ReturnOrderItemSuccess) {
              ToastManager.show(
                context: context,
                message: state.message,
              );
              apiCall();
            } else if(state is ReturnOrderItemFailed){
              ToastManager.show(
                context: context,
                message: state.error,
              );
            }
          }
        ),
        BlocListener<DownloadInvoiceBloc, DownloadInvoiceState>(
          listener: (context, state) {
            if (state is DownloadInvoiceSuccess) {
              OpenFilex.open(state.filePath);
              ToastManager.show(
                context: context,
                message: 'Invoice saved',
                type: ToastType.success,
              );
            } else if (state is DownloadInvoiceFailure) {
              ToastManager.show(
                context: context,
                message: state.error,
                type: ToastType.error,
              );
            }
          }
        )
      ],
      child: BlocConsumer<DownloadInvoiceBloc, DownloadInvoiceState>(
        listener: (context, state) {},
        builder: (context, state) {
          return Stack(
            children: [
              Builder(
                builder: (context) {
                  return CustomScaffold(
                    showViewCart: false,
                    title: AppLocalizations.of(context)!.orderSummary,
                    showAppBar: true,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
                      builder: (context, state) {
                        if (state is OrderDetailLoaded) {
                          final orderData = state.cartData.first.data;
                          if (orderData == null) {
                            return Center(child: Text('Failed to load order data'));
                          }
                          return SingleChildScrollView(
                            child: RefreshIndicator(
                              onRefresh: apiCall,
                              child: Padding(
                                padding: EdgeInsets.all(12.0.h),
                                child: Column(
                                  children: [
                                    OrderItemsCard(
                                      items: orderData.items ?? [],
                                      totalItems: (orderData.items?.length ?? 0).toString(),
                                      priceColor: Colors.black,
                                      originalPriceColor: Colors.grey[500],
                                    ),
                                    if(orderData.status == 'delivered')...[
                                      rateWidget(orderData.id ?? 0, orderData.slug ?? '', orderData),
                                      SizedBox(height: 10.h),
                                    ],
                                    trackDeliveryAndReturnProduct(
                                      orderSlug: orderData.slug ?? '',
                                      items: orderData.items ?? [],
                                      isDelivered: orderData.status == 'delivered' ? true : false,
                                      isDeliveryBoyAssigned: orderData.deliveryBoyId != null,
                                    ),
                                    SizedBox(height: 10.h),
                                    if (orderData.proofOfQualityVideo != null && orderData.proofOfQualityVideo!.isNotEmpty) ...[
                                      proofOfQualityWidget(orderData.proofOfQualityVideo!),
                                      SizedBox(height: 10.h),
                                    ],
                                    if (orderData.coinsEarned != null && orderData.coinsEarned! > 0) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(TablerIcons.coin, color: Colors.amber.shade700, size: 24.w),
                                            SizedBox(width: 12.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Coins Earned',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14.sp,
                                                      color: Colors.amber.shade900,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    'You earned ${orderData.coinsEarned} coins from this order!',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.amber.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                    ],
                                      BillSummaryWidget(
                                        itemsOriginalPrice: double.tryParse(orderData.totalPayable ?? '0') ?? 0,
                                         itemsDiscountedPrice: GstUtils.getBasePrice(double.tryParse(orderData.subtotal ?? '0') ?? 0),
                                         itemsSavings: (double.tryParse(orderData.totalPayable ?? '0') ?? 0) - (double.tryParse(orderData.subtotal ?? '0') ?? 0),
                                         deliveryChargeOriginal: double.tryParse(orderData.deliveryCharge ?? '0') ?? 0,
                                       handlingCharge: double.tryParse(orderData.handlingCharges ?? '0') ?? 0,
                                       perStoreDropOffFees: double.tryParse(orderData.perStoreDropOffFee ?? '0') ?? 0,
                                       grandTotal: double.tryParse(orderData.finalTotal ?? '0') ?? 0,
                                       totalSavings: (double.tryParse(orderData.totalPayable ?? '0') ?? 0) - (double.tryParse(orderData.subtotal ?? '0') ?? 0),
                                      isFromOrderDetail: true,
                                      downloadInvoice: () {
                                        if (orderData.invoice != null && orderData.invoice!.isNotEmpty) {
                                          context.read<DownloadInvoiceBloc>().add(
                                            DownloadInvoice(invoiceUrl: orderData.invoice!),
                                          );
                                        }
                                      },
                                       promoCode: orderData.promoCode,
                                       promoDiscount: double.tryParse(orderData.promoDiscount ?? '0.0') ?? 0.0,
                                       platformCharge: double.tryParse(orderData.platformCharge ?? '') ?? 0.0,
                                       cgst: double.tryParse(orderData.cgst ?? '') ?? 0.0,
                                       sgst: double.tryParse(orderData.sgst ?? '') ?? 0.0,
                                     ),
                                    SizedBox(height: 10.h),
                                    OrderDetailCard(
                                      orderId: orderData.id?.toString() ?? '',
                                      paymentMethod: orderData.paymentMethod ?? '',
                                      deliveryAddress: orderData.shippingAddress1 ?? '',
                                      orderDate: orderData.createdAt ?? '',
                                    ),
                                    SizedBox(height: 10.h),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        else if (state is OrderDetailLoading) {
                          return CustomCircularProgressIndicator();
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  );
                }
              ),
              if (state is DownloadInvoiceLoading) WholePageProgress(),
            ],
          );
        },
      ),
    );
  }

  Widget rateWidget(int orderId, String orderSlug, OrderDetailData? orderData) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.howWasYourShoppingExperience ?? 'How was your shopping experience?',
                    style: TextStyle(fontSize: 12.sp),
                  );
                }
              ),
            ),
            SizedBox(width: 5.w),
            CustomButton(
              onPressed: () async {
                final storeMap = {
                  "orderSlug": orderSlug,
                  "orderId": orderId,
                };

                final result = await GoRouter.of(context).push(
                  AppRoutes.rateYourExp,
                  extra: storeMap,
                );

                if (result == true && mounted) {
                  context.read<ProductFeedbackBloc>().add(ResetProductFeedback());

                  await apiCall();

                  if (mounted) {
                    final l10n = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.orderDetailsRefreshed ?? 'Order details refreshed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(l10n?.rateOrder ?? 'Rate Order');
                }
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget proofOfQualityWidget(String videoUrl) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(TablerIcons.video, color: AppTheme.primaryColor, size: 20.w),
                SizedBox(width: 8.w),
                Text(
                  'Proof of Quality',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ProductVideoPlayer(
                  videoUrl: videoUrl,
                  isActive: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget trackDeliveryAndReturnProduct(
      {
        required String orderSlug,
        required List<OrderItems> items,
        required bool isDelivered,
        required bool isDeliveryBoyAssigned,
      }) {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            onTap: () {
              _showReturnDialog(items, orderSlug, isDelivered);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: isDarkMode(context) ? Theme.of(context).colorScheme.surface
                    : Colors.white,
              ),

              margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        textAlign: TextAlign.center,
                        isDelivered ? AppLocalizations.of(context)!.returnItem : AppLocalizations.of(context)!.cancelItem,
                        style: TextStyle(fontSize: isTablet(context) ? 18 : 12.sp, color: Colors.red),
                      ),
                    ),
                    Icon(
                      Directionality.of(context) == TextDirection.ltr ?
                      TablerIcons.chevron_right : TablerIcons.chevron_left,
                      size: 20,
                      color: Colors.red,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),

        if(!isDelivered && isDeliveryBoyAssigned)...[
          SizedBox(width: 12.w,),
          Expanded(
            child: AnimatedButton(
              onTap: () {
                GoRouter.of(context)
                    .push(AppRoutes.deliveryTracking, extra: {'order-slug': orderSlug});
              },
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.trackYourDelivery,
                              style: TextStyle(
                                fontSize: isTablet(context) ? 18 : 12.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
