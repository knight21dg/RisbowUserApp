class UserProfileModel {
  bool? success;
  String? message;
  UserData? data;

  UserProfileModel({this.success, this.message, this.data});

  UserProfileModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class UserData {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? country;
  String? iso2;
  num? walletBalance;
  int? coinsBalance;
  String? referralCode;
  String? friendsCode;
  int? referralCount;
  int? rewardPoints;
  String? profileImage;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;

  UserData(
      {this.id,
        this.name,
        this.email,
        this.mobile,
        this.country,
        this.iso2,
        this.walletBalance,
        this.coinsBalance,
        this.referralCode,
        this.friendsCode,
        this.referralCount,
        this.rewardPoints,
        this.profileImage,
        this.emailVerifiedAt,
        this.createdAt,
        this.updatedAt});

  UserData.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    email = json['email']?.toString();
    mobile = json['mobile']?.toString();
    country = json['country']?.toString();
    iso2 = json['iso_2']?.toString();
    walletBalance = num.tryParse(json['wallet_balance']?.toString() ?? '');
    coinsBalance = int.tryParse(json['coins_balance']?.toString() ?? '');
    referralCode = json['referral_code']?.toString();
    friendsCode = json['friends_code']?.toString();
    referralCount = int.tryParse(json['referral_count']?.toString() ?? '');
    rewardPoints = int.tryParse(json['reward_points']?.toString() ?? '');
    profileImage = json['profile_image']?.toString();
    emailVerifiedAt = json['email_verified_at']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['mobile'] = mobile;
    data['country'] = country;
    data['iso_2'] = iso2;
    data['wallet_balance'] = walletBalance;
    data['coins_balance'] = coinsBalance;
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['referral_count'] = referralCount;
    data['reward_points'] = rewardPoints;
    data['profile_image'] = profileImage;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
