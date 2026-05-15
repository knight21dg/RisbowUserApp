import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/user_cart_model/user_cart.dart';

abstract class CartEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final UserCart item;
  final BuildContext context;
  AddToCart(this.item, this.context);
}

class UpdateCartQty extends CartEvent {
  final String cartKey;
  final int quantity;
  final int? cartItemId;
  final BuildContext context;
  UpdateCartQty(this.cartKey, this.quantity, this.cartItemId, this.context);
}

class RemoveFromCart extends CartEvent {
  final String cartKey;
  final BuildContext context;
  RemoveFromCart(this.cartKey, this.context);
}

class RemoveLocally extends CartEvent {
  final String cartKey;
  final BuildContext context;
  RemoveLocally(this.cartKey, this.context);
}

class ClearCart extends CartEvent {
  final BuildContext context;
  ClearCart({required this.context});
}

class SyncLocalCart extends CartEvent {
  final BuildContext context;
  SyncLocalCart({required this.context});
  @override
  // TODO: implement props
  List<Object?> get props => [context];
}
