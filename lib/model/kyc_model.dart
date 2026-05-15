class SellerDocumentModel {
  final int id;
  final int sellerId;
  final String documentType;
  final String documentName;
  final String documentUrl;
  final String status;
  final String? rejectionReason;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? expiryDate;
  final String? documentNumber;
  final DateTime createdAt;

  SellerDocumentModel({
    required this.id,
    required this.sellerId,
    required this.documentType,
    required this.documentName,
    required this.documentUrl,
    required this.status,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    this.expiryDate,
    this.documentNumber,
    required this.createdAt,
  });

  factory SellerDocumentModel.fromJson(Map<String, dynamic> json) {
    return SellerDocumentModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      documentType: json['document_type'] ?? '',
      documentName: json['document_name'] ?? '',
      documentUrl: json['document_url'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      documentNumber: json['document_number'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';

  String get documentTypeDisplay {
    switch (documentType) {
      case 'pan_card':
        return 'PAN Card';
      case 'gst_certificate':
        return 'GST Certificate';
      case 'aadhaar_card':
        return 'Aadhaar Card';
      case 'business_license':
        return 'Business License';
      case 'fssai_license':
        return 'FSSAI License';
      case 'shop_establishment':
        return 'Shop Establishment';
      case 'bank_statement':
        return 'Bank Statement';
      case 'cancelled_cheque':
        return 'Cancelled Cheque';
      case 'store_photo':
        return 'Store Photo';
      default:
        return documentType.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class KycStatusModel {
  final int totalPending;
  final int totalApproved;
  final int totalRejected;
  final int totalExpired;
  final int sellersPendingKyc;
  final Map<String, int> pendingByType;

  KycStatusModel({
    this.totalPending = 0,
    this.totalApproved = 0,
    this.totalRejected = 0,
    this.totalExpired = 0,
    this.sellersPendingKyc = 0,
    this.pendingByType = const {},
  });

  factory KycStatusModel.fromJson(Map<String, dynamic> json) {
    return KycStatusModel(
      totalPending: json['total_pending'] ?? 0,
      totalApproved: json['total_approved'] ?? 0,
      totalRejected: json['total_rejected'] ?? 0,
      totalExpired: json['total_expired'] ?? 0,
      sellersPendingKyc: json['sellers_pending_kyc'] ?? 0,
      pendingByType: Map<String, int>.from(json['pending_by_type'] ?? {}),
    );
  }
}
