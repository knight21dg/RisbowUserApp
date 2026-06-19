import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/inventory_bloc/inventory_event.dart';
import 'package:hyper_local/bloc/inventory_bloc/inventory_state.dart';
import 'package:hyper_local/repositories/inventory_repository.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repository;

  InventoryBloc({InventoryRepository? repository})
      : _repository = repository ?? InventoryRepository(),
        super(InventoryInitial()) {
    on<FetchInventoryLogs>(_onFetchLogs);
    on<FetchInventoryDashboard>(_onFetchDashboard);
    on<FetchLowStockProducts>(_onFetchLowStock);
    on<FetchOutOfStockProducts>(_onFetchOutOfStock);
    on<BulkUploadInventory>(_onBulkUpload);
  }

  Future<void> _onFetchLogs(
    FetchInventoryLogs event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final logs = await _repository.fetchSyncLogs(
        page: event.page,
        syncType: event.syncType,
        sellerId: event.sellerId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(InventoryLogsLoaded(
        logs: logs,
        currentPage: event.page,
        hasMore: logs.length >= 20,
      ));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onFetchDashboard(
    FetchInventoryDashboard event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final dashboard = await _repository.fetchDashboard();
      emit(InventoryDashboardLoaded(dashboard));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onFetchLowStock(
    FetchLowStockProducts event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final products = await _repository.fetchLowStock(threshold: event.threshold);
      emit(LowStockProductsLoaded(products));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onFetchOutOfStock(
    FetchOutOfStockProducts event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final products = await _repository.fetchOutOfStock();
      emit(OutOfStockProductsLoaded(products));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> _onBulkUpload(
    BulkUploadInventory event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    try {
      final response = await _repository.bulkUpload(
        event.csvData,
        sellerId: event.sellerId,
      );
      if (response['success'] == true) {
        emit(InventoryBulkUploadSuccess(
          message: response['message'] ?? 'Upload completed',
          successCount: response['data']?['success_count'] ?? 0,
          failureCount: response['data']?['failure_count'] ?? 0,
        ));
      } else {
        emit(InventoryError(response['message'] ?? 'Failed to upload'));
      }
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}