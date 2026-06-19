import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/inventory_model.dart';

class InventoryRepository {
  Future<List<InventorySyncLogModel>> fetchSyncLogs({
    int page = 1,
    int perPage = 20,
    String? syncType,
    String? sellerId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (syncType != null) queryParams['sync_type'] = syncType;
      if (sellerId != null) queryParams['seller_id'] = sellerId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.inventorySyncLogsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<InventorySyncLogModel> logs = [];
        if (response.data['data'] != null && response.data['data']['data'] != null) {
          for (var item in response.data['data']['data']) {
            logs.add(InventorySyncLogModel.fromJson(item));
          }
        }
        return logs;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<InventoryDashboardModel> fetchDashboard() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.inventoryDashboardApi,
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return InventoryDashboardModel.fromJson(response.data['data']);
      }
      return InventoryDashboardModel();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<LowStockProductModel>> fetchLowStock({int perPage = 20, int threshold = 10}) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.inventoryLowStockApi}?per_page=$perPage&threshold=$threshold',
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<LowStockProductModel> products = [];
        if (response.data['data'] != null) {
          for (var item in response.data['data']) {
            products.add(LowStockProductModel.fromJson(item));
          }
        }
        return products;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<LowStockProductModel>> fetchOutOfStock({int perPage = 20}) async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        '${ApiRoutes.inventoryOutOfStockApi}?per_page=$perPage',
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<LowStockProductModel> products = [];
        if (response.data['data'] != null) {
          for (var item in response.data['data']) {
            products.add(LowStockProductModel.fromJson(item));
          }
        }
        return products;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> bulkUpload(String csvData, {String? sellerId}) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.inventoryBulkUploadApi,
        {
          'csv_data': csvData,
          if (sellerId != null) 'seller_id': sellerId,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}