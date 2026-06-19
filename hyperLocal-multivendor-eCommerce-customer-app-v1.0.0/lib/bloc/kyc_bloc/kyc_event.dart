import 'package:equatable/equatable.dart';

abstract class KycEvent extends Equatable {
  const KycEvent();
  @override
  List<Object?> get props => [];
}

class FetchKycDocuments extends KycEvent {
  final int page;
  final String? status;
  final String? sellerId;
  
  const FetchKycDocuments({this.page = 1, this.status, this.sellerId});
  
  @override
  List<Object?> get props => [page, status, sellerId];
}

class FetchKycDashboard extends KycEvent {}

class UploadKycDocument extends KycEvent {
  final int sellerId;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final String? documentNumber;
  
  const UploadKycDocument({
    required this.sellerId,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    this.documentNumber,
  });
  
  @override
  List<Object?> get props => [sellerId, documentType, documentName, documentUrl, documentNumber];
}