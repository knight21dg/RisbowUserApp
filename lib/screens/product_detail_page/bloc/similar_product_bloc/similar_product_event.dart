part of 'similar_product_bloc.dart';

abstract class SimilarProductEvent extends Equatable {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class FetchSimilarProduct extends SimilarProductEvent {
  final List<String> excludeProductSlug;
  FetchSimilarProduct({required this.excludeProductSlug});
  @override
  // TODO: implement props
  List<Object?> get props => [excludeProductSlug];
}

class FetchRecommendedSimilarProduct extends SimilarProductEvent {
  final int productId;
  final int limit;
  FetchRecommendedSimilarProduct({required this.productId, this.limit = 20});
  @override
  List<Object?> get props => [productId, limit];
}