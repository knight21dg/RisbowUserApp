class RoomReferral {
  final String id;
  final String referralCode;
  final String roomCode;
  final String? referrerId;
  final String? referrerName;
  final String? refereeId;
  final String? refereeName;
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  RoomReferral({
    required this.id,
    required this.referralCode,
    required this.roomCode,
    this.referrerId,
    this.referrerName,
    this.refereeId,
    this.refereeName,
    required this.status,
    this.createdAt,
    this.completedAt,
  });

  factory RoomReferral.fromJson(Map<String, dynamic> json) {
    return RoomReferral(
      id: json['id']?.toString() ?? '',
      referralCode: json['referral_code'] ?? json['referralCode'] ?? '',
      roomCode: json['room_code'] ?? json['roomCode'] ?? '',
      referrerId: json['referrer_id'] ?? json['referrerId'],
      referrerName: json['referrer_name'] ?? json['referrerName'],
      refereeId: json['referee_id'] ?? json['refereeId'],
      refereeName: json['referee_name'] ?? json['refereeName'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : (json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null),
      completedAt: json['completed_at'] != null 
          ? DateTime.tryParse(json['completed_at']) 
          : (json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referral_code': referralCode,
      'room_code': roomCode,
      'referrer_id': referrerId,
      'referrer_name': referrerName,
      'referee_id': refereeId,
      'referee_name': refereeName,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
}

class ReferralLink {
  final String referralCode;
  final String shareUrl;
  final String roomCode;

  ReferralLink({
    required this.referralCode,
    required this.shareUrl,
    required this.roomCode,
  });

  factory ReferralLink.fromJson(Map<String, dynamic> json) {
    return ReferralLink(
      referralCode: json['referral_code'] ?? '',
      shareUrl: json['share_url'] ?? '',
      roomCode: json['room_code'] ?? '',
    );
  }

  String getdeeplink() {
    if (shareUrl.contains('risbow://')) {
      return shareUrl;
    }
    return 'risbow://room/$roomCode?ref=$referralCode';
  }

  String getShareText(String roomName) {
    return 'Join my group buy room "$roomName" on RisBow! Use my referral: $referralCode';
  }
}