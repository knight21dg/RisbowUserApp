class InventorySyncLogModel {
  final int id;
  final int? sellerId;
  final int? storeId;
  final int? productId;
  final int? productVariantId;
  final String syncType;
  final int oldStock;
  final int newStock;
  final int change;
  final String source;
  final String? errorMessage;
  final DateTime createdAt;

  InventorySyncLogModel({
    required this.id,
    this.sellerId,
    this.storeId,
    this.productId,
    this.productVariantId,
    required this.syncType,
    required this.oldStock,
    required this.newStock,
    required this.change,
    required this.source,
    this.errorMessage,
    required this.createdAt,
  });

  factory InventorySyncLogModel.fromJson(Map<String, dynamic> json) {
    return InventorySyncLogModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'],
      storeId: json['store_id'],
      productId: json['product_id'],
      productVariantId: json['product_variant_id'],
      syncType: json['sync_type'] ?? 'manual',
      oldStock: json['old_stock'] ?? 0,
      newStock: json['new_stock'] ?? 0,
      change: json['change'] ?? 0,
      source: json['source'] ?? 'manual',
      errorMessage: json['error_message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get syncTypeDisplay {
    switch (syncType) {
      case 'csv_upload':
        return 'CSV Upload';
      case 'manual':
        return 'Manual';
      case 'api_sync':
        return 'API Sync';
      case 'auto_adjust':
        return 'Auto Adjust';
      case 'order_deduction':
        return 'Order';
      case 'order_return':
        return 'Return';
      default:
        return syncType;
    }
  }

  bool get isPositive => change > 0;
  bool get isNegative => change < 0;
}

class InventoryDashboardModel {
  final int todaySyncs;
  final int weekSyncs;
  final int monthSyncs;
  final Map<String, int> syncsByType;
  final List<InventorySyncLogModel> recentLogs;
  final List<LowStockProductModel> lowStockProducts;

  InventoryDashboardModel({
    this.todaySyncs = 0,
    this.weekSyncs = 0,
    this.monthSyncs = 0,
    this.syncsByType = const {},
    this.recentLogs = const [],
    this.lowStockProducts = const [],
  });

  factory InventoryDashboardModel.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardModel(
      todaySyncs: json['today_syncs'] ?? 0,
      weekSyncs: json['week_syncs'] ?? 0,
      monthSyncs: json['month_syncs'] ?? 0,
      syncsByType: Map<String, int>.from(json['syncs_by_type'] ?? {}),
      recentLogs: (json['recent_logs'] as List<dynamic>?)
              ?.map((e) => InventorySyncLogModel.fromJson(e))
              .toList() ??
          [],
      lowStockProducts: (json['low_stock_products'] as List<dynamic>?)
              ?.map((e) => LowStockProductModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LowStockProductModel {
  final int id;
  final String title;
  final String seller;
  final List<LowStockVariantModel> lowStockVariants;

  LowStockProductModel({
    required this.id,
    required this.title,
    required this.seller,
    this.lowStockVariants = const [],
  });

  factory LowStockProductModel.fromJson(Map<String, dynamic> json) {
    return LowStockProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      seller: json['seller'] ?? '',
      lowStockVariants: (json['low_stock_variants'] as List<dynamic>?)
              ?.map((e) => LowStockVariantModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LowStockVariantModel {
  final String name;
  final int stock;

  LowStockVariantModel({
    required this.name,
    required this.stock,
  });

  factory LowStockVariantModel.fromJson(Map<String, dynamic> json) {
    return LowStockVariantModel(
      name: json['name'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}
