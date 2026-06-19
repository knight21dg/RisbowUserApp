import 'package:equatable/equatable.dart';
import 'package:hyper_local/model/kyc_model.dart';

abstract class KycState extends Equatable {
  const KycState();
  @override
  List<Object?> get props => [];
}

class KycInitial extends KycState {}

class KycLoading extends KycState {}

class KycDocumentsLoaded extends KycState {
  final List<SellerDocumentModel> documents;
  final int currentPage;
  final bool hasMore;
  
  const KycDocumentsLoaded({
    required this.documents,
    this.currentPage = 1,
    this.hasMore = false,
  });
  
  @override
  List<Object?> get props => [documents, currentPage, hasMore];
}

class KycDashboardLoaded extends KycState {
  final KycStatusModel dashboard;
  
  const KycDashboardLoaded(this.dashboard);
  
  @override
  List<Object?> get props => [dashboard];
}

class KycDocumentUploaded extends KycState {
  final String message;
  
  const KycDocumentUploaded(this.message);
  
  @override
  List<Object?> get props => [message];
}

class KycError extends KycState {
  final String message;
  
  const KycError(this.message);
  
  @override
  List<Object?> get props => [message];
}