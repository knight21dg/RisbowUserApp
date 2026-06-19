import 'package:equatable/equatable.dart';

abstract class AddToCartEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class AddItemToCart extends AddToCartEvent{
  final int productVariantId;
  final int storeId;
  final int quantity;
  final int? productId;
  final int? roomInstanceId;

  AddItemToCart({
    required this.productVariantId, 
    required this.storeId, 
    required this.quantity, 
    this.productId,
    this.roomInstanceId,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [productVariantId, storeId, quantity, productId, roomInstanceId];
}
