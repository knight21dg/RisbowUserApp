import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchProductDetail extends ProductDetailEvent {
  final String productSlug;
  final String? storeSlug;
  FetchProductDetail({required this.productSlug, this.storeSlug});
  @override
  List<Object?> get props => [productSlug, storeSlug];
}