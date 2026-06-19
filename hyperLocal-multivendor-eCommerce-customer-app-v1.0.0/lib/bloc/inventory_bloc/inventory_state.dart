import 'package:equatable/equatable.dart';
import 'package:hyper_local/model/inventory_model.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLogsLoaded extends InventoryState {
  final List<InventorySyncLogModel> logs;
  final int currentPage;
  final bool hasMore;
  
  const InventoryLogsLoaded({
    required this.logs,
    this.currentPage = 1,
    this.hasMore = false,
  });
  
  @override
  List<Object?> get props => [logs, currentPage, hasMore];
}

class InventoryDashboardLoaded extends InventoryState {
  final InventoryDashboardModel dashboard;
  
  const InventoryDashboardLoaded(this.dashboard);
  
  @override
  List<Object?> get props => [dashboard];
}

class LowStockProductsLoaded extends InventoryState {
  final List<LowStockProductModel> products;
  
  const LowStockProductsLoaded(this.products);
  
  @override
  List<Object?> get props => [products];
}

class OutOfStockProductsLoaded extends InventoryState {
  final List<LowStockProductModel> products;
  
  const OutOfStockProductsLoaded(this.products);
  
  @override
  List<Object?> get props => [products];
}

class InventoryBulkUploadSuccess extends InventoryState {
  final String message;
  final int successCount;
  final int failureCount;
  
  const InventoryBulkUploadSuccess({
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
  });
  
  @override
  List<Object?> get props => [message, successCount, failureCount];
}

class InventoryError extends InventoryState {
  final String message;
  
  const InventoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}