import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/kyc_model.dart';

class KycRepository {
  Future<List<SellerDocumentModel>> fetchDocuments({int page = 1, int perPage = 20, String? status, String? sellerId}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null) queryParams['status'] = status;
      if (sellerId != null) queryParams['seller_id'] = sellerId;
      
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.kycDocumentsApi,
        queryParams,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<SellerDocumentModel> documents = [];
        if (response.data['data'] != null && response.data['data']['data'] != null) {
          for (var item in response.data['data']['data']) {
            documents.add(SellerDocumentModel.fromJson(item));
          }
        }
        return documents;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required int sellerId,
    required String documentType,
    required String documentName,
    required String documentUrl,
    String? documentNumber,
  }) async {
    try {
      final response = await AppConstant.apiBaseHelper.postAPICall(
        ApiRoutes.kycUploadDocumentApi,
        {
          'seller_id': sellerId,
          'document_type': documentType,
          'document_name': documentName,
          'document_url': documentUrl,
          if (documentNumber != null) 'document_number': documentNumber,
        },
      );
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<KycStatusModel> fetchDashboard() async {
    try {
      final response = await AppConstant.apiBaseHelper.getAPICall(
        ApiRoutes.kycDashboardApi,
        {},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return KycStatusModel.fromJson(response.data['data']);
      }
      return KycStatusModel();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}