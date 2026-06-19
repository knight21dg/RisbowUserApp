import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/model/brands_model.dart';

import '../../repo/brands_repo.dart';

part 'brands_event.dart';
part 'brands_state.dart';

class BrandsBloc extends Bloc<BrandsEvent, BrandsState> {
  BrandsBloc() : super(BrandsInitial()) {
    on<FetchBrands>(_onFetchBrands);
  }

  int currentPage = 0;
  int perPage = 0;
  int? lastPage;
  bool loadMore = false;
  final BrandsRepository repository = BrandsRepository();

  Future<void> _onFetchBrands(FetchBrands event, Emitter<BrandsState> emit) async {
    emit(BrandsLoading());
    try{
      List<BrandsData> brandsData = [];
      perPage = 18;
      currentPage = 1;
      loadMore = false;
      final response = await repository.fetchBrands(categorySlug: event.categorySlug);

      if (response['success'] != true) {
        emit(BrandsFailed(error: response['message'] ?? 'Failed to load brands'));
        return;
      }

      final data = response['data'];
      List<dynamic>? brandsDataList;
      if (data is List) {
        brandsDataList = data;
      } else if (data is Map<String, dynamic>) {
        brandsDataList = data['data'] as List<dynamic>?;
      }

      if (brandsDataList != null && brandsDataList.isNotEmpty) {
        brandsData = List<BrandsData>.from(brandsDataList.map((data) => BrandsData.fromJson(data)));
      }

      currentPage += 1;

      emit(BrandsLoaded(
          message: response['message'] ?? 'Brands loaded',
          brandsData: brandsData
      ));
    }catch(e, stacktrace){
      print('BrandsBloc Error: $e\n$stacktrace');
      emit(BrandsFailed(error: e.toString()));
    }
  }

}
