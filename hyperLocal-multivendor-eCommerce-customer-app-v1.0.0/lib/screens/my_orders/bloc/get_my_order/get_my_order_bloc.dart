import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/my_order_model.dart';
import '../../repo/order_repo.dart';
import 'get_my_order_event.dart';
import 'get_my_order_state.dart';

class GetMyOrderBloc extends Bloc<GetMyOrderEvent, GetMyOrderState> {
  GetMyOrderBloc() : super(GetMyOrderInitial()) {
    on<FetchMyOrder>(_onFetchMyOrder);
    on<FetchMoreMyOrder>(_onFetchMoreMyOrder);
  }

  int currentPage = 1;
  int perPage = 15;
  bool _hasReachedMax = false;
  bool isLoadingMore = false;
  final OrderRepository repository = OrderRepository();

  Future<void> _onFetchMyOrder(FetchMyOrder event,
      Emitter<GetMyOrderState> emit) async {
    emit(GetMyOrderLoading());
    try {
      // Reset pagination state
      currentPage = 1;
      _hasReachedMax = false;
      isLoadingMore = false;

      final response = await repository.fetchMyOrderList(
        page: currentPage,
        perPage: perPage,
      );

      final myOrderData = List<MyOrdersData>.from(
          response['data']['data'].map((data) =>
              MyOrdersData.fromJson(data)));

      // Update pagination state
      final currentTotal = int.parse(response['data']['current_page'].toString());
      final lastPageNum = int.parse(response['data']['last_page'].toString());
      _hasReachedMax = currentTotal >= lastPageNum || myOrderData.length < perPage;

      if (response['success'] == true) {
        emit(GetMyOrderLoaded(
            message: response['message'],
            myOrderData: myOrderData,
            hasReachedMax: _hasReachedMax
        ));
      } else if (response['error'] == true) {
        emit(GetMyOrderFailed(error: response['message']));
      }
    } catch (e) {
      emit(GetMyOrderFailed(error: e.toString()));
    }
  }

  /// Load more orders
  Future<void> _onFetchMoreMyOrder(FetchMoreMyOrder event,
      Emitter<GetMyOrderState> emit) async {
    // Prevent multiple simultaneous calls
    if (_hasReachedMax || isLoadingMore) return;

    final currentState = state;
    if (currentState is GetMyOrderLoaded) {
      // Set loading state
      isLoadingMore = true;

      try {
        // Increment page BEFORE API call
        currentPage += 1;
        final response = await repository.fetchMyOrderList(
          page: currentPage,
          perPage: perPage,
        );

        final newOrderData = List<MyOrdersData>.from(
            response['data']['data'].map((data) =>
                MyOrdersData.fromJson(data)));

        // Update hasReachedMax
        final currentTotal = int.parse(response['data']['current_page'].toString());
        final lastPageNum = int.parse(response['data']['last_page'].toString());
        _hasReachedMax = currentTotal >= lastPageNum || newOrderData.length < perPage;

        // Remove duplicates when combining lists
        final updatedOrderData = List<MyOrdersData>.from(currentState.myOrderData);

        // Add only unique orders
        for (final newOrder in newOrderData) {
          if (!updatedOrderData.any((existing) => existing.id == newOrder.id)) {
            updatedOrderData.add(newOrder);
          }
        }

        if (response['success'] == true) {
          emit(GetMyOrderLoaded(
            message: response['message'],
            myOrderData: updatedOrderData,
            hasReachedMax: _hasReachedMax,
          ));
        } else {
          emit(GetMyOrderFailed(error: response['message']));
        }

      } catch (e) {
        // Reset page on error
        currentPage -= 1;
        emit(GetMyOrderFailed(error: e.toString()));
      } finally {
        isLoadingMore = false;
      }
    }
  }
}