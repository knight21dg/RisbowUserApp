import 'package:equatable/equatable.dart';

import '../../model/save_for_later_model.dart';

abstract class SaveForLaterState extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class SaveForLaterInitial extends SaveForLaterState {}

class SaveForLaterLoading extends SaveForLaterState {}

class ProductSavedSuccess extends SaveForLaterState {
  final String productName;
  final String? productId;
  final String? variantId;

  ProductSavedSuccess({
    required this.productName,
    this.productId,
    this.variantId,
  });

  @override
  List<Object?> get props => [productName, productId, variantId];
}

class SaveForLaterLoaded extends SaveForLaterState {
  final String message;
  final List<SavedItems> savedItems;
  final int totalProducts;
  final bool hasReachedMax;

  SaveForLaterLoaded({
    required this.message,
    required this.savedItems,
    required this.totalProducts,
    required this.hasReachedMax,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [
    message,
    savedItems,
    totalProducts,
    hasReachedMax,
  ];
}

class SaveForLaterFailed extends SaveForLaterState {
  final String error;

  SaveForLaterFailed({required this.error});

  @override
  // TODO: implement props
  List<Object?> get props => [error];
}