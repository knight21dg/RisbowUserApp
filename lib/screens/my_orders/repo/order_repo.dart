import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../config/api_routes.dart';
import '../model/order_detail_model.dart';
import '../model/delivery_tracking_model.dart';

class OrderRepository {
  Future<Map<String, dynamic>> createOrder({
    required String paymentType,
    required String promoCode,
    required String giftCard,
    required int addressId,
    required bool rushDelivery,
    required bool useWallet,
    bool? useCoins,
    required String orderNote,
    Map<String, dynamic>? paymentDetails
  }) async {
    try {
      String? paymenttype;
      if(paymentType.isNotEmpty){
        // Map legacy 'wallet' -> 'coins' payment type when building paymenttype
        if (paymentType == 'wallet') {
          paymenttype = 'coins';
        } else {
          paymenttype = paymentType == 'cod' ? paymentType : '${paymentType}Payment';
        }
      } else {
        paymenttype = '';
      }
        final response = await AppConstant.apiBaseHelper.postAPICall(
            ApiRoutes.createOrderApi,
            {
              'payment_type': paymenttype,
              'promo_code': promoCode,
              'gift_card': giftCard,
              'address_id': addressId,
              'rush_delivery': rushDelivery,
              // Keep legacy wallet param for compatibility and also send
              // a coins-specific flag. Backend can choose which to honour.
              'use_wallet': useWallet,
            if (useCoins != null) 'use_coins': useCoins,
            // If caller provided coins_to_use, include it here. We'll accept coin
            // count via the payload map (see CreateOrderBloc wiring).
            if (paymentDetails != null && paymentDetails.containsKey('coins_to_use'))
              'coins_to_use': paymentDetails['coins_to_use'],
              'order_note': orderNote,
              if(paymentType != 'flutterwave')
                'redirect_url': AppConstant.baseUrl,
              ...paymentType.toLowerCase() != 'cod' && paymentDetails != null
                  ? paymentDetails
                  : {},
            }
        );
        if (response.statusCode == 200) {
          return response.data;
        } else {
          return {};
        }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchMyOrderList({required int perPage, required int page}) async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.getMyOrderApi}?page=$page&per_page=$perPage',
        {}
      );
      if(response.statusCode == 200 ){
        return response.data;
      }
      return {};
    }catch(e) {
      throw ApiException('Failed to get my orders list');
    }
  }

  Future<List<OrderDetailModel>> getOrderDetail({required String orderSlug,}) async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.orderDetailApi+orderSlug,
        {},
      );

      if(response.statusCode == 200) {
        final List<OrderDetailModel> orderData = [];
        orderData.add(OrderDetailModel.fromJson(response.data));
        return orderData;
      } else {
        return [];
      }

    }catch(e){
      throw ApiException(e.toString());
    }
  }

  Future<DeliveryBoyTrackingModel?> getDeliveryTracking({required String orderSlug,}) async {
    try{
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.orderDetailApi}$orderSlug/delivery-boy-location',
        {},
      );

      if(response.statusCode == 200) {
        return DeliveryBoyTrackingModel.fromJson(response.data);
      } else {
        return null;
      }
    }catch(e){
      throw ApiException(e.toString());
    }
  }

  Future<String> downloadInvoicePdf(String invoiceUrl) async {
    try {
      final dio = AppConstant.apiBaseHelper.dio;
      final response = await dio.get(
        invoiceUrl,
        options: Options(
          headers: {'Accept': 'text/html'},
          responseType: ResponseType.plain,
          followRedirects: true,
        ),
      );
      final htmlString = response.data as String?;
      if (htmlString == null || htmlString.isEmpty) {
        throw ApiException('Empty invoice content received');
      }
      final pdfBytes = await Printing.convertHtml(html: htmlString);
      final directory = await getApplicationDocumentsDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    } catch (e) {
      throw ApiException('Failed to download invoice: $e');
    }
  }

  Future<Map<String, dynamic>> returnOrderItemRequest({
    required int orderItemId,
    required String reason,
    List<XFile> images = const [],
  }) async {
    try{

      final form = await formDataWithImages(
        fields: {
          'reason': reason,
        },
        images: images,
        imageFieldLabel: 'images'
      );

      log('Return Order Item Request ${form.files}');

      final response = await AppConstant.apiBaseHelper.postAPICall(
        '${ApiRoutes.returnOrderItemApi}$orderItemId/return',
        form
      );
      if(response.statusCode == 200) {
        return response.data;
      }
      return {};
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelReturnRequest({
    required int orderItemId,
  }) async {
    try{
      final response = await AppConstant.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelReturnRequestApi}$orderItemId/return-cancel',
          {}
      );

      if(response.statusCode == 200) {
        return response.data;
      }
      return {};
    }catch(e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> cancelOrderItem({
    required int orderItemId,
  }) async {
    try{
      final response = await AppConstant.apiBaseHelper.postAPICall(
          '${ApiRoutes.cancelOrderItemApi}$orderItemId/cancel',
          {}
      );

      if(response.statusCode == 200) {
        return response.data;
      }
      return {};
    }catch(e) {
      throw ApiException(e.toString());
    }
  }
}
