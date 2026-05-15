import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/repo/near_by_store_repo.dart';

import '../../model/near_by_store_model.dart';

part 'store_detail_event.dart';
part 'store_detail_state.dart';

class StoreDetailBloc extends Bloc<StoreDetailEvent, StoreDetailState> {
  StoreDetailBloc() : super(StoreDetailInitial()) {
    on<FetchStoreDetail>(_onFetchStoreDetail);
  }

  final NearByStoreRepo repository = NearByStoreRepo();

  Future<void> _onFetchStoreDetail(FetchStoreDetail event, Emitter<StoreDetailState> emit) async {
    print('STORE BLOC: Fetching store detail for ${event.storeSlug}');
    emit(StoreDetailLoading());
    try{
      final storeData = await repository.fetchStoreDetail(storeSlug: event.storeSlug);
      print('STORE BLOC: Got ${storeData.length} stores');

      if(storeData.isEmpty) {
        print('STORE BLOC: Store list is empty');
        emit(StoreDetailFailed(error: 'Store not found'));
        return;
      }

      final firstStore = storeData.first;
      print('STORE BLOC: Success=${firstStore.success}, Message=${firstStore.message}');
      if(firstStore.success == true && firstStore.data?.name != null) {
        print('STORE BLOC: Emit Loaded for ${firstStore.data?.name}');
        emit(StoreDetailLoaded(
          storeData: firstStore.data!
        ));
      } else {
        print('STORE BLOC: Emit Failed');
        emit(StoreDetailFailed(error: firstStore.message ?? 'Failed to load store'));
      }
    }catch(e) {
      print('STORE BLOC CATCH: $e');
      emit(StoreDetailFailed(error: e.toString()));
    }
  }
}
