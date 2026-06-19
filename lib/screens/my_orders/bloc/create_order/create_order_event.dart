part of 'create_order_bloc.dart';

abstract class CreateOrderEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class CreateOrderRequest extends CreateOrderEvent {
  final String paymentType;
  final String? promoCode;
  final String? giftCard;
  final int addressId;
  final bool? rushDelivery;
  final bool? useWallet;
  final bool? useCoins;
  final String? orderNote;
  final Map<String, dynamic>? paymentDetails;
  final int? coinsToUse;

  CreateOrderRequest({
    required this.paymentType,
    this.promoCode,
    this.giftCard,
    required this.addressId,
    this.rushDelivery,
    this.useWallet,
    this.useCoins,
    this.coinsToUse,
    this.orderNote,
    this.paymentDetails
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    paymentType,
    promoCode,
    giftCard,
    addressId,
    rushDelivery,
    useWallet,
    useCoins,
    coinsToUse,
    orderNote,
    paymentDetails
  ];
}
