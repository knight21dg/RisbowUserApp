import 'package:equatable/equatable.dart';
import '../../model/product_detail_model.dart';

abstract class RecommendationProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecommendationProductInitial extends RecommendationProductState {}

class RecommendationProductLoading extends RecommendationProductState {}

class FrequentlyBoughtTogetherLoaded extends RecommendationProductState {
  final List<ProductData> products;
  FrequentlyBoughtTogetherLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class RecentlyViewedLoaded extends RecommendationProductState {
  final List<ProductData> products;
  RecentlyViewedLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class ContinueShoppingLoaded extends RecommendationProductState {
  final List<ProductData> products;
  ContinueShoppingLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class RecommendationProductFailure extends RecommendationProductState {
  final String error;
  RecommendationProductFailure({required this.error});
  @override
  List<Object?> get props => [error];
}