import 'package:equatable/equatable.dart';

abstract class RecommendationProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchFrequentlyBoughtTogether extends RecommendationProductEvent {
  final int productId;
  final int limit;
  FetchFrequentlyBoughtTogether({required this.productId, this.limit = 10});
  @override
  List<Object?> get props => [productId, limit];
}

class FetchRecentlyViewedProducts extends RecommendationProductEvent {
  final int limit;
  FetchRecentlyViewedProducts({this.limit = 10});
  @override
  List<Object?> get props => [limit];
}

class FetchContinueShoppingProducts extends RecommendationProductEvent {
  final int limit;
  FetchContinueShoppingProducts({this.limit = 10});
  @override
  List<Object?> get props => [limit];
}