

class AuthModel {
  bool? success;
  String? message;
  String? accessToken;
  String? tokenType;
  Data? data;

  AuthModel(
      {this.success,
        this.message,
        this.accessToken,
        this.tokenType,
        this.data});

  AuthModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      data = Data.fromJson(json['data'] as Map<String, dynamic>);
    } else {
      data = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? country;
  String? iso2;
  int? walletBalance;
  String? referralCode;
  String? friendsCode;
  int? rewardPoints;
  String? profileImage;
  String? emailVerifiedAt;
  String? createdAt;
  String? updatedAt;

  Data(
      {this.id,
        this.name,
        this.email,
        this.mobile,
        this.country,
        this.iso2,
        this.walletBalance,
        this.referralCode,
        this.friendsCode,
        this.rewardPoints,
        this.profileImage,
        this.emailVerifiedAt,
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    email = json['email']?.toString();
    mobile = json['mobile']?.toString();
    country = json['country']?.toString();
    iso2 = json['iso_2']?.toString();
    walletBalance = json['wallet_balance'] is int ? json['wallet_balance'] : int.tryParse(json['wallet_balance']?.toString() ?? '');
    referralCode = json['referral_code']?.toString();
    friendsCode = json['friends_code']?.toString();
    rewardPoints = json['reward_points'] is int ? json['reward_points'] : int.tryParse(json['reward_points']?.toString() ?? '');
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
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['reward_points'] = rewardPoints;
    data['profile_image'] = profileImage;
    data['email_verified_at'] = emailVerifiedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
