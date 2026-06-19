
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_state.dart';
import 'package:hyper_local/screens/home_page/model/category_model.dart';
import 'package:hyper_local/screens/home_page/repo/category_repo.dart';
import '../../../../utils/widgets/cache_manager.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState>{
  CategoryBloc() : super(CategoryInitial()){
    on<FetchCategory>(_onFetchCategory);
    on<FetchMoreCategory>(_onFetchMoreCategory);
  }
  int currentPage = 0;
  int perPage = 0;
  int? lastPage;
  bool loadMore = false;
  bool selectedIsHome = false;
  final CategoryRepository repository = CategoryRepository();
  final DefaultCacheManager cacheManager = DefaultCacheManager();

  Future<void> _onFetchCategory(FetchCategory event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try{
      List<CategoryData> categoryData = [];
      perPage = 30;
      currentPage = 1;
      loadMore = false;
      selectedIsHome = event.isHome;
      final response = await repository.fetchCategory(perPage: perPage, currentPage: currentPage, isHome: event.isHome);

      if (response['success'] != true) {
        emit(CategoryFailed(error: response['message'] ?? 'Failed to load categories'));
        return;
      }

      final data = response['data'];
      List<dynamic>? categoriesData;
      
      if (data is List) {
        categoriesData = data;
      } else if (data is Map<String, dynamic>) {
        categoriesData = data['data'] as List<dynamic>?;
      }

      if (categoriesData != null && categoriesData.isNotEmpty) {
        categoryData = List<CategoryData>.from(categoriesData.map((data) => CategoryData.fromJson(data)));
        for (var category in categoryData) {
          final urls = [
            category.backgroundImage,
            category.icon,
            category.banner,
            category.image,
          ];
          for (var url in urls) {
            if (url?.isNotEmpty == true) {
              customCacheManager.downloadFile(url!);
            }
          }
        }
      }

      currentPage += 1;
      emit(CategoryLoaded(
          message: response['message'] ?? 'Categories loaded',
          categoryData: categoryData
      ));
    } catch (e, stacktrace) {
      print('CategoryBloc Error: $e\n$stacktrace');
      emit(CategoryFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchMoreCategory(FetchMoreCategory event, Emitter<CategoryState> emit) async {
    if (loadMore) return;
    loadMore = true;
    try{
      final currentState = state;
      if (currentState is! CategoryLoaded) {
        loadMore = false;
        return;
      }

      currentPage += 1;
      final response = await repository.fetchCategory(perPage: perPage, currentPage: currentPage, isHome: selectedIsHome);

      if (response['success'] != true) {
        loadMore = false;
        return;
      }

      final data = response['data'];
      List<dynamic>? categoriesData;
      
      if (data is List) {
        categoriesData = data;
      } else if (data is Map<String, dynamic>) {
        categoriesData = data['data'] as List<dynamic>?;
      }

      if (categoriesData != null && categoriesData.isNotEmpty) {
        final newCategories = List<CategoryData>.from(categoriesData.map((data) => CategoryData.fromJson(data)));
        final updatedCategories = List<CategoryData>.from(currentState.categoryData);

        for (final newCategory in newCategories) {
          if (!updatedCategories.any((existing) => existing.id == newCategory.id)) {
            updatedCategories.add(newCategory);
          }
        }

        emit(CategoryLoaded(
            message: response['message'],
            categoryData: updatedCategories
        ));
      } else {
        loadMore = false;
      }
    }catch(e){
      currentPage -= 1;
      loadMore = false;
      emit(CategoryFailed(error: e.toString()));
    }
  }


}
