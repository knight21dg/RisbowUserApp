import 'package:equatable/equatable.dart';

abstract class SaveForLaterEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchSavedProducts extends SaveForLaterEvent {}

class FetchMoreSavedProducts extends SaveForLaterEvent {}


class SaveForLaterRequest extends SaveForLaterEvent {
  final int cartItemId;
  final String? productId;
  final String? variantId;

  SaveForLaterRequest({
    required this.cartItemId,
    this.productId,
    this.variantId
  });

  @override
  List<Object?> get props => [cartItemId, productId, variantId];
}
