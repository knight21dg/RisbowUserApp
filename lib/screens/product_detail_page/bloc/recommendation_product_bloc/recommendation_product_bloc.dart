import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/repo/recommendations_repository.dart';
import '../../model/product_detail_model.dart';
import 'recommendation_product_event.dart';
import 'recommendation_product_state.dart';

class RecommendationProductBloc extends Bloc<RecommendationProductEvent, RecommendationProductState> {
  RecommendationProductBloc() : super(RecommendationProductInitial()) {
    on<FetchFrequentlyBoughtTogether>(_onFetchFrequentlyBoughtTogether);
    on<FetchRecentlyViewedProducts>(_onFetchRecentlyViewedProducts);
    on<FetchContinueShoppingProducts>(_onFetchContinueShoppingProducts);
  }

  final RecommendationsRepository repository = RecommendationsRepository();

  Future<void> _onFetchFrequentlyBoughtTogether(
    FetchFrequentlyBoughtTogether event,
    Emitter<RecommendationProductState> emit,
  ) async {
    emit(RecommendationProductLoading());
    try {
      final response = await repository.getFrequentlyBoughtTogether(
        productId: event.productId,
        limit: event.limit,
      );

      if (response['success'] == true) {
        final List<ProductData> products = List<ProductData>.from(
          (response['data'] as List).map((data) {
            if (data is Map) {
              final productData = data['product'];
              if (productData != null) {
                return ProductData.fromJson(productData);
              }
            }
            return null;
          }).whereType<ProductData>(),
        );

        emit(FrequentlyBoughtTogetherLoaded(products: products));
      } else {
        emit(RecommendationProductFailure(error: response['message'] ?? 'Failed to load'));
      }
    } catch (e) {
      emit(RecommendationProductFailure(error: e.toString()));
    }
  }

  Future<void> _onFetchRecentlyViewedProducts(
    FetchRecentlyViewedProducts event,
    Emitter<RecommendationProductState> emit,
  ) async {
    emit(RecommendationProductLoading());
    try {
      final response = await repository.getRecentlyViewed(limit: event.limit);

      if (response['success'] == true) {
        final List<ProductData> products = List<ProductData>.from(
          (response['data'] as List).map((data) {
            if (data is Map) {
              final productData = data['product'];
              if (productData != null) {
                return ProductData.fromJson(productData);
              }
            }
            return null;
          }).whereType<ProductData>(),
        );

        emit(RecentlyViewedLoaded(products: products));
      } else {
        emit(RecommendationProductFailure(error: response['message'] ?? 'Failed to load'));
      }
    } catch (e) {
      emit(RecommendationProductFailure(error: e.toString()));
    }
  }

  Future<void> _onFetchContinueShoppingProducts(
    FetchContinueShoppingProducts event,
    Emitter<RecommendationProductState> emit,
  ) async {
    emit(RecommendationProductLoading());
    try {
      final response = await repository.getContinueShopping(limit: event.limit);

      if (response['success'] == true) {
        final List<ProductData> products = List<ProductData>.from(
          (response['data'] as List).map((data) {
            if (data is Map) {
              final productData = data['product'];
              if (productData != null) {
                return ProductData.fromJson(productData);
              }
            }
            return null;
          }).whereType<ProductData>(),
        );

        emit(ContinueShoppingLoaded(products: products));
      } else {
        emit(RecommendationProductFailure(error: response['message'] ?? 'Failed to load'));
      }
    } catch (e) {
      emit(RecommendationProductFailure(error: e.toString()));
    }
  }
}