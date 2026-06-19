

import 'package:hive_flutter/hive_flutter.dart';

part 'user_data_model.g.dart';

@HiveType(typeId: 1)
class UserDataModel extends HiveObject {
  @HiveField(0)
  final String token;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String mobile;

  @HiveField(5)
  final String country;

  @HiveField(6)
  final String iso2;

  @HiveField(7)
  final String profileImage;

  @HiveField(8)
  final String referralCode;

  @HiveField(9)
  final String language;

  @HiveField(10)
  final int coinsBalance;

  @HiveField(11)
  final int totalCoinsEarned;

  @HiveField(12)
  final int totalCoinsSpent;

  @HiveField(13)
  final int referralCount;

  UserDataModel({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.country,
    required this.iso2,
    required this.profileImage,
    required this.referralCode,
    required this.language,
    this.coinsBalance = 0,
    this.totalCoinsEarned = 0,
    this.totalCoinsSpent = 0,
    this.referralCount = 0,
  });

  UserDataModel copyWith({
    String? token,
    String? userId,
    String? name,
    String? email,
    String? mobile,
    String? country,
    String? iso2,
    String? profileImage,
    String? referralCode,
    String? language,
    int? coinsBalance,
    int? totalCoinsEarned,
    int? totalCoinsSpent,
    int? referralCount,
  }) {
    return UserDataModel(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      country: country ?? this.country,
      iso2: iso2 ?? this.iso2,
      profileImage: profileImage ?? this.profileImage,
      referralCode: referralCode ?? this.referralCode,
      language: language ?? this.language,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
      referralCount: referralCount ?? this.referralCount,
    );
  }
}
