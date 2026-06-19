import 'package:equatable/equatable.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class FetchInventoryLogs extends InventoryEvent {
  final int page;
  final String? syncType;
  final String? sellerId;
  final String? startDate;
  final String? endDate;
  
  const FetchInventoryLogs({
    this.page = 1,
    this.syncType,
    this.sellerId,
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [page, syncType, sellerId, startDate, endDate];
}

class FetchInventoryDashboard extends InventoryEvent {}

class FetchLowStockProducts extends InventoryEvent {
  final int threshold;
  
  const FetchLowStockProducts({this.threshold = 10});
  
  @override
  List<Object?> get props => [threshold];
}

class FetchOutOfStockProducts extends InventoryEvent {}

class BulkUploadInventory extends InventoryEvent {
  final String csvData;
  final String? sellerId;
  
  const BulkUploadInventory({required this.csvData, this.sellerId});
  
  @override
  List<Object?> get props => [csvData, sellerId];
}