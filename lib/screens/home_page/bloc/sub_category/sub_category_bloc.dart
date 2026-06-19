import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_event.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_state.dart';
import '../../model/sub_category_model.dart';
import '../../repo/sub_category_repo.dart';

class SubCategoryBloc extends Bloc<SubCategoryEvent, SubCategoryState>{
  SubCategoryBloc() : super(SubCategoryInitial()){
    on<FetchSubCategory>(_onFetchSubCategory);
    on<FetchMoreSubCategory>(_onFetchMoreSubCategory);
  }
  int currentPage = 0;
  int perPage = 0;
  int? lastPage;
  bool _hasReachedMax = false;
  bool loadMore = false;
  String selectedSlug = '';
  bool selectedIsForAllCategory = false;
  bool selectedIsHome = false;
  final SubCategoryRepository repository = SubCategoryRepository();

  Future<void> _onFetchSubCategory(FetchSubCategory event, Emitter<SubCategoryState> emit) async {
    emit(SubCategoryLoading());
    try{
      List<SubCategoryData> subCategoryData = [];
      perPage = 80;
      currentPage = 1;
      _hasReachedMax = false;
      loadMore = false;
      selectedSlug = event.slug;
      selectedIsForAllCategory = event.isForAllCategory;
      selectedIsHome = event.isHome;
      final response = await repository.fetchSubCategory(
          slug: event.slug,
          isForAllCategory: event.isForAllCategory,
          perPage: perPage,
          page: currentPage,
          isFiltered: true,
          isHome: event.isHome
      );

      if (response['success'] != true) {
        emit(SubCategoryFailed(error: response['message'] ?? 'Failed to load subcategories'));
        return;
      }

      final data = response['data'];
      List<dynamic>? subCategoriesData;
      if (data is List) {
        subCategoriesData = data;
      } else if (data is Map<String, dynamic>) {
        subCategoriesData = data['data'] as List<dynamic>?;
      }

      if (subCategoriesData != null && subCategoriesData.isNotEmpty) {
        subCategoryData = List<SubCategoryData>.from(subCategoriesData.map((data) => SubCategoryData.fromJson(data)));
        _hasReachedMax = subCategoryData.length < perPage;
      } else {
        _hasReachedMax = true;
      }

      emit(SubCategoryLoaded(
          message: response['message'] ?? 'Subcategories loaded',
          subCategoryData: subCategoryData,
          isLoadingMore: false
      ));

    }catch(e, stacktrace){
      print('SubCategoryBloc Error: $e\n$stacktrace');
      emit(SubCategoryFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchMoreSubCategory(FetchMoreSubCategory event, Emitter<SubCategoryState> emit) async {
    if (_hasReachedMax || loadMore) return;

    final currentState = state;
    if (currentState is SubCategoryLoaded) {
      loadMore = true;

      emit(SubCategoryLoaded(
        message: currentState.message,
        subCategoryData: currentState.subCategoryData,
        isLoadingMore: true,
      ));

      try {
        currentPage += 1;
        final response = await repository.fetchSubCategory(
          slug: selectedSlug,
          isForAllCategory: selectedIsForAllCategory,
          page: currentPage,
          perPage: perPage,
          isFiltered: true,
          isHome: selectedIsHome
        );

        if (response['success'] != true) {
          loadMore = false;
          currentPage -= 1;
          return;
        }

        final data = response['data'];
        List<dynamic>? subCategoriesData;
        if (data is List) {
          subCategoriesData = data;
        } else if (data is Map<String, dynamic>) {
          subCategoriesData = data['data'] as List<dynamic>?;
        }

        if (subCategoriesData == null || subCategoriesData.isEmpty) {
          _hasReachedMax = true;
          loadMore = false;
          emit(SubCategoryLoaded(
            message: currentState.message,
            subCategoryData: currentState.subCategoryData,
            isLoadingMore: false,
          ));
          return;
        }

        final newSubCategoryData = List<SubCategoryData>.from(
            subCategoriesData.map((data) => SubCategoryData.fromJson(data))
        );

        final currentTotal = int.tryParse(data?['current_page']?.toString() ?? '0') ?? 0;
        final lastPageNum = int.tryParse(data?['last_page']?.toString() ?? '0') ?? 0;
        _hasReachedMax = currentTotal >= lastPageNum || newSubCategoryData.length < perPage;

        final updatedSubCategoryData = List<SubCategoryData>.from(currentState.subCategoryData);

        for (final newSubCategory in newSubCategoryData) {
          if (!updatedSubCategoryData.any((existing) => existing.id == newSubCategory.id)) {
            updatedSubCategoryData.add(newSubCategory);
          }
        }

        emit(SubCategoryLoaded(
          message: response['message'],
          subCategoryData: updatedSubCategoryData,
          isLoadingMore: false,
        ));

      } catch (e) {
        currentPage -= 1;
        emit(SubCategoryFailed(error: e.toString()));
      } finally {
        loadMore = false;
      }
    }
  }
}
