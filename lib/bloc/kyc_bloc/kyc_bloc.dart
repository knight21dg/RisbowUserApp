import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/bloc/kyc_bloc/kyc_event.dart';
import 'package:hyper_local/bloc/kyc_bloc/kyc_state.dart';
import 'package:hyper_local/repositories/kyc_repository.dart';

class KycBloc extends Bloc<KycEvent, KycState> {
  final KycRepository _repository;

  KycBloc({KycRepository? repository})
      : _repository = repository ?? KycRepository(),
        super(KycInitial()) {
    on<FetchKycDocuments>(_onFetchDocuments);
    on<FetchKycDashboard>(_onFetchDashboard);
    on<UploadKycDocument>(_onUploadDocument);
  }

  Future<void> _onFetchDocuments(
    FetchKycDocuments event,
    Emitter<KycState> emit,
  ) async {
    emit(KycLoading());
    try {
      final documents = await _repository.fetchDocuments(
        page: event.page,
        status: event.status,
        sellerId: event.sellerId,
      );
      emit(KycDocumentsLoaded(
        documents: documents,
        currentPage: event.page,
        hasMore: documents.length >= 20,
      ));
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }

  Future<void> _onFetchDashboard(
    FetchKycDashboard event,
    Emitter<KycState> emit,
  ) async {
    emit(KycLoading());
    try {
      final dashboard = await _repository.fetchDashboard();
      emit(KycDashboardLoaded(dashboard));
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }

  Future<void> _onUploadDocument(
    UploadKycDocument event,
    Emitter<KycState> emit,
  ) async {
    emit(KycLoading());
    try {
      final response = await _repository.uploadDocument(
        sellerId: event.sellerId,
        documentType: event.documentType,
        documentName: event.documentName,
        documentUrl: event.documentUrl,
        documentNumber: event.documentNumber,
      );
      if (response['success'] == true) {
        emit(KycDocumentUploaded(response['message'] ?? 'Document uploaded successfully'));
      } else {
        emit(KycError(response['message'] ?? 'Failed to upload document'));
      }
    } catch (e) {
      emit(KycError(e.toString()));
    }
  }
}