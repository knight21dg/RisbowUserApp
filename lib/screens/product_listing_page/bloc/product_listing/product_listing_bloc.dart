import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart' as dio;
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
//
import '../../../../model/sorting_model/sorting_model.dart';
import '../../repo/category_product_repo.dart';
import '../../model/product_listing_type.dart';

part 'product_listing_event.dart';
part 'product_listing_state.dart';

class ProductListingBloc extends Bloc<ProductListingEvent, ProductListingState> {
  ProductListingBloc() : super(ProductListingInitial()) {
    on<FetchListingProducts>(_onFetchListingProducts);
    on<FetchMoreListingProducts>(_onFetchMoreListingProducts);
    on<FetchSortedListingProducts>(_onFetchSortedListingProducts);
    on<ResetSearchKeywords>(_onResetSearchKeywords);
  }

  int currentPage = 1;
  int perPage = 15;
  int? lastPage;
  bool hasReachedMax = false;
  bool isLoadingMore = false;
  final CategoryProductRepository repository = CategoryProductRepository();
  SortType currentSortType = SortType.relevance;
  int totalProducts = 0;
  ProductListingType type = ProductListingType.search;
  String selectedSortingType = '';
  dio.CancelToken? _cancelToken;


  Future<void> _onFetchListingProducts(FetchListingProducts event, Emitter<ProductListingState> emit) async {
    emit(ProductListingLoading());
    try {
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      currentSortType = SortType.relevance;
      List<dynamic> keywords = [];
      type = event.type;
      totalProducts = 0;
      selectedSortingType = event.sortType ?? 'default';

      _cancelToken?.cancel('new_request');
      _cancelToken = dio.CancelToken();

      final response = await repository.fetchProductsByType(
        type: event.type,
        identifier: event.identifier,
        sortType: selectedSortingType,
        currentPage: currentPage,
        perPage: perPage,
        isSearchInStore: event.isSearchInStore ?? false,
        storeSlug: event.storeSlug ?? '',
        includeChildCategories: event.includeChildCategories,
        cancelToken: _cancelToken,
      ).catchError((e) {
        if (e.toString().contains('cancel') || (e is dio.DioException && e.type == dio.DioExceptionType.cancel)) {
           print('BLOC: Request cancelled');
           return <String, dynamic>{'cancelled': true};
        }
        print('BLOC: Repository error: $e');
        emit(ProductListingFailed(error: e.toString()));
        return <String, dynamic>{};
      });

      if (response['cancelled'] == true) return;

      // Handle both nested format (response.data.data) and flat format (response.data as list)
      List? productsData;
      Map<String, dynamic>? data;
      
      final responseData = response['data'];
      
      // If response is empty or not a valid map, emit failed state
      if (responseData == null || responseData is! Map<String, dynamic>) {
        print('BLOC: Invalid response format - ${response.toString() ?? "empty"}');
        emit(ProductListingFailed(error: 'No products found'));
        return;
      }
      
      data = responseData;
      productsData = data['data'] as List?;
      
      print('BLOC: Response success=${response['success']}, productsCount=${productsData?.length ?? 0}');
      
      if (productsData != null && productsData.isNotEmpty) {
        print('BLOC: First raw JSON: ${productsData.first}');
      }

      if (response['success'] == true && productsData != null && productsData.isNotEmpty) {
        List<ProductData> products;
        try {
          products = List<ProductData>.from(productsData.map((item) => ProductData.fromJson(item)));
          print('BLOC: Parsed ${products.length} products, first id=${products.first.id}, title=${products.first.title}');
          print('BLOC: First raw: ${productsData.first}');
        } catch (e) {
          print('BLOC: Parse error: $e');
          emit(ProductListingFailed(error: 'Failed to parse products'));
          return;
        }
        
        totalProducts = int.tryParse(
              data['total']?.toString() ??
                  data['total_products']?.toString() ??
                  data['products_count']?.toString() ??
                  '${productsData.length}',
            ) ??
            productsData.length;
        final currentTotal = int.tryParse(data['current_page']?.toString() ?? '0') ?? 0;
        final lastPageNum = int.tryParse(data['last_page']?.toString() ?? '0') ?? 0;

        if(event.type == ProductListingType.search){
          keywords = (data['keywords'] as List<dynamic>?) ?? [];
        }

        hasReachedMax = currentTotal >= lastPageNum || products.length < perPage;

        emit(ProductListingLoaded(
          message: response['message'],
          productList: products,
          hasReachedMax: hasReachedMax,
          isFilterLoading: false,
          isLoading: false,
          currentSortType: currentSortType,
          totalProducts: totalProducts,
          keywords: keywords
        ));
      }
      else {
        emit(ProductListingFailed(error: response['message'] ?? 'No products found'));
      }
    } catch (e) {
      emit(ProductListingFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchMoreListingProducts(FetchMoreListingProducts event, Emitter<ProductListingState> emit) async {
    if (hasReachedMax || isLoadingMore) return;

    final currentState = state;
    if (currentState is ProductListingLoaded) {
      isLoadingMore = true;
      try {
        currentPage += 1;
        List<dynamic> keywords = currentState.keywords ?? [];

        _cancelToken?.cancel('new_request');
        _cancelToken = dio.CancelToken();

        final response = await repository.fetchProductsByType(
          type: type,
          identifier: event.identifier,
          sortType: selectedSortingType,
          currentPage: currentPage,
          perPage: perPage,
          isSearchInStore: event.isSearchInStore ?? false,
          storeSlug: event.storeSlug ?? '',
          cancelToken: _cancelToken,
        );

        final data = response['data'] as Map<String, dynamic>?;
        final productsData = data != null ? data['data'] as List? : null;

        if (response['success'] == true && productsData != null && productsData.isNotEmpty) {
          final newProducts = List<ProductData>.from(
              productsData.map((item) => ProductData.fromJson(item))
          );
          if(type == ProductListingType.search){
            keywords = (data?['keywords'] as List<dynamic>?) ?? [];
          }
          // ✅ Update hasReachedMax based on response
          final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
          final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
          hasReachedMax = currentTotal >= lastPageNum || newProducts.length < perPage;

          // ✅ Remove duplicates when combining lists
          final updatedProductList = List<ProductData>.from(currentState.productList);

          // ✅ Update totalProducts
          totalProducts = int.tryParse(
                data?['total']?.toString() ??
                    data?['total_products']?.toString() ??
                    data?['products_count']?.toString() ??
                    '${updatedProductList.length}',
              ) ??
              totalProducts;

          // Add only unique products
          for (final newProduct in newProducts) {
            if (!updatedProductList.any((existing) => existing.id == newProduct.id)) {
              updatedProductList.add(newProduct);
            }
          }

          emit(ProductListingLoaded(
              message: response['message'],
              productList: updatedProductList,
              hasReachedMax: hasReachedMax,
              isFilterLoading: false,
              isLoading: false,
              currentSortType: currentSortType,
              totalProducts: totalProducts,
              keywords: keywords
          ));
        } else {
          emit(ProductListingFailed(error: response['message'] ?? 'No products found'));
        }

      } catch (e) {
        // ✅ Reset page on error
        currentPage -= 1;
        emit(ProductListingFailed(error: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }
  }

  Future<void> _onFetchSortedListingProducts(FetchSortedListingProducts event, Emitter<ProductListingState> emit) async {
    final currentState = state;
    if (currentState is ProductListingLoaded) {
      emit(ProductListingLoaded(
          message: currentState.message,
          productList: [],
          hasReachedMax: false,
          isFilterLoading: true,
          isLoading: false,
          currentSortType: currentState.currentSortType,
          totalProducts: 0
      ));
    }

    try {
      // ✅ Reset pagination for sorting
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;
      List<dynamic> keywords = [];
      selectedSortingType = event.sortType;

      _cancelToken?.cancel('new_request');
      _cancelToken = dio.CancelToken();

      final response = await repository.fetchProductsByType(
        type: type,
        identifier: event.identifier,
        sortType: event.sortType,
        currentPage: currentPage,
        perPage: perPage,
        isSearchInStore: event.isSearchInStore ?? false,
        storeSlug: event.storeSlug ?? '',
        cancelToken: _cancelToken,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final productsData = data != null ? data['data'] as List? : null;

      if (response['success'] != true || productsData == null) {
        emit(ProductListingFailed(error: response['message'] ?? 'No products found'));
        return;
      }

      final products = List<ProductData>.from(
          productsData.map((item) => ProductData.fromJson(item))
      );

      // ✅ Update pagination state
      final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
      final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
      hasReachedMax = currentTotal >= lastPageNum || products.length < perPage;
      totalProducts = int.tryParse(data?['total']?.toString() ?? '0') ?? totalProducts;
      if(type == ProductListingType.search){
        keywords = (data?['keywords'] as List<dynamic>?) ?? [];
      }
      currentSortType = SortOption.getSortOptionByApiValue(event.sortType).type;

      if (response['success'] == true) {
        emit(ProductListingLoaded(
          message: response['message'],
          productList: products,
          hasReachedMax: hasReachedMax,
          isFilterLoading: false,
          isLoading: false,
          currentSortType: currentSortType,
          totalProducts: totalProducts,
          keywords: keywords
        ));
      } else {
        emit(ProductListingFailed(error: response['message']));
      }
    } catch (e) {
      emit(ProductListingFailed(error: e.toString()));
    }
  }

  Future<void> _onResetSearchKeywords (ResetSearchKeywords event, Emitter<ProductListingState> emit) async {
    emit(ProductListingInitial());
  }
}
