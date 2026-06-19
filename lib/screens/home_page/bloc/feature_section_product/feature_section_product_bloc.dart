import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_state.dart';
import 'package:hyper_local/screens/home_page/repo/feature_section_product_repo.dart';

import '../../model/featured_section_product_model.dart';

class FeatureSectionProductBloc extends Bloc<FeatureSectionProductEvent, FeatureSectionProductState> {
  FeatureSectionProductBloc() : super(FeatureSectionProductInitial()){
    on<FetchFeatureSectionProducts>(_onFetchFeatureSectionProducts);
    on<FetchMoreFeatureSectionProducts>(_onFetchMoreFeatureSectionProducts);
    on<ClearFeatureSectionProducts>(_onClearProducts);
    on<RefreshFeatureSectionProducts>(_onRefreshFeatureSectionProducts);
  }

  int currentPage = 0;
  int perPage = 0;
  int? lastPage;
  bool hasReachedMax = false;
  bool isLoadingMore = false;
  final repository = FeatureSectionProductRepository();
  String selectedCategory = '';

  void _onClearProducts(ClearFeatureSectionProducts event, Emitter<FeatureSectionProductState> emit) {
    currentPage = 0;
    hasReachedMax = false;
    emit(FeatureSectionProductLoading());
  }

  Future<void> _onFetchFeatureSectionProducts(FetchFeatureSectionProducts event, Emitter<FeatureSectionProductState> emit) async {
    emit(FeatureSectionProductLoading());
    try{
      List<FeatureSectionData> featureSectionProductData = [];
      perPage = 12;
      currentPage = 1;
      hasReachedMax = false;
      selectedCategory = event.slug;

      final response = await repository.fetchFeatureSectionProduct(
        slug: event.slug,
        perPage: perPage,
        page: currentPage
      );

      if (response['success'] != true) {
        emit(FeatureSectionProductFailed(error: response['message'] ?? 'Failed to load products'));
        return;
      }

      final data = response['data'];
      List<dynamic>? productsData;
      if (data is List) {
        productsData = data;
      } else if (data is Map<String, dynamic>) {
        productsData = data['data'] as List<dynamic>?;
      }

      if (productsData == null || productsData.isEmpty) {
        emit(FeatureSectionProductLoaded(
          featureSectionProductData: [],
          message: response['message'] ?? 'No products found',
          hasReachedMax: true
        ));
        return;
      }

      featureSectionProductData = List<FeatureSectionData>.from(productsData.map((data) => FeatureSectionData.fromJson(data)));
      final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
      final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
      hasReachedMax = currentTotal >= lastPageNum || featureSectionProductData.length < perPage;

      emit(FeatureSectionProductLoaded(
        featureSectionProductData: featureSectionProductData,
        message: response['message'],
        hasReachedMax: hasReachedMax
      ));

    }catch(e, stacktrace){
      print('FeatureSectionProductBloc Error: $e\n$stacktrace');
      emit(FeatureSectionProductFailed(error: e.toString()));
    }
  }


  Future<void> _onFetchMoreFeatureSectionProducts(FetchMoreFeatureSectionProducts event, Emitter<FeatureSectionProductState> emit) async {
    if (hasReachedMax || isLoadingMore) return;

    final currentState = state;
    if (currentState is FeatureSectionProductLoaded) {
      isLoadingMore = true;
      try {
        currentPage += 1;

        final response = await repository.fetchFeatureSectionProduct(
            slug: event.slug,
            perPage: perPage,
            page: currentPage
        );

        if (response['success'] != true) {
          emit(FeatureSectionProductFailed(error: response['message'] ?? 'Failed to load more products'));
          return;
        }

        final data = response['data'];
        List<dynamic>? productsData;
        if (data is List) {
          productsData = data;
        } else if (data is Map<String, dynamic>) {
          productsData = data['data'] as List<dynamic>?;
        }

        if (productsData == null || productsData.isEmpty) {
          hasReachedMax = true;
          emit(FeatureSectionProductLoaded(
            featureSectionProductData: currentState.featureSectionProductData,
            message: response['message'] ?? 'No more products',
            hasReachedMax: true
          ));
          return;
        }

        final featureSectionProductData = List<FeatureSectionData>.from(productsData.map((data) => FeatureSectionData.fromJson(data)));

        final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
        final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
        hasReachedMax = currentTotal >= lastPageNum || featureSectionProductData.length < perPage;

        final updatedFeatureSectionList = List<FeatureSectionData>.from(currentState.featureSectionProductData);

        for (final newData in featureSectionProductData) {
          if (!updatedFeatureSectionList.any((existing) => existing.id == newData.id)) {
            updatedFeatureSectionList.add(newData);
          }
        }

        emit(FeatureSectionProductLoaded(
          featureSectionProductData: updatedFeatureSectionList,
          message: response['message'],
          hasReachedMax: hasReachedMax
        ));

      } catch (e) {
        currentPage -= 1;
        emit(FeatureSectionProductFailed(error: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }
  }

  Future<void> _onRefreshFeatureSectionProducts(RefreshFeatureSectionProducts event, Emitter<FeatureSectionProductState> emit) async {
    emit(FeatureSectionProductLoading());
    try{
      add(FetchFeatureSectionProducts(slug: selectedCategory));
    }catch(e){
      emit(FeatureSectionProductFailed(error: e.toString()));
    }
  }
}
