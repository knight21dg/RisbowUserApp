import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repo/order_repo.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc() : super(CreateOrderInitial()) {
    on<CreateOrderRequest>(_onCreateOrderRequest);
  }
  final OrderRepository repository = OrderRepository();

  bool isLoading = false;

  Future<void> _onCreateOrderRequest(CreateOrderRequest event, Emitter<CreateOrderState> emit) async {
    emit(CreateOrderProgress());
    isLoading = true;
    try{
      // Merge coins_to_use into payment details if provided so repository can include it
      final paymentDetails = <String, dynamic>{};
      if (event.paymentDetails != null) paymentDetails.addAll(event.paymentDetails!);
      if (event.coinsToUse != null) paymentDetails['coins_to_use'] = event.coinsToUse;

      final response = await repository.createOrder(
        paymentType: event.paymentType,
        promoCode: event.promoCode ?? '',
        giftCard: event.giftCard ?? '',
        addressId: event.addressId,
        rushDelivery: event.rushDelivery ?? false,
        useWallet: event.useWallet ?? false,
        useCoins: event.useCoins,
        orderNote: event.orderNote ?? '',
        paymentDetails: paymentDetails.isNotEmpty ? paymentDetails : null,
      );

      if(response['success'] == true) {
        isLoading = false;
        emit(CreateOrderSuccess(
          message:  response['message'],
          orderSlug: response['data']['slug'],
          paymentUrl: event.paymentType == 'flutterwave' ? response['data']['payment_response']['link'] : ''
        ));
      } else {
        emit(CreateOrderFailure(error: response['message']));
      }
    } catch(e) {
      isLoading = false;
      emit(CreateOrderFailure(error: e.toString()));
    }
  }
}
