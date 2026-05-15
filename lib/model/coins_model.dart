class CoinsBalanceModel {
  final int coinsBalance;
  final double coinValue;
  final double rupeeValue;

  CoinsBalanceModel({
    this.coinsBalance = 0,
    this.coinValue = 1,
    this.rupeeValue = 0,
  });

  factory CoinsBalanceModel.fromJson(Map<String, dynamic> json) {
    return CoinsBalanceModel(
      coinsBalance: json['coins_balance'] ?? 0,
      coinValue: (json['coin_value'] ?? 1).toDouble(),
      rupeeValue: (json['rupee_value'] ?? 0).toDouble(),
    );
  }
}

class CoinsStatsModel {
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final int referralCount;
  final double coinValue;

  CoinsStatsModel({
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.referralCount = 0,
    this.coinValue = 1,
  });

  factory CoinsStatsModel.fromJson(Map<String, dynamic> json) {
    return CoinsStatsModel(
      balance: json['balance'] ?? 0,
      totalEarned: json['total_earned'] ?? 0,
      totalSpent: json['total_spent'] ?? 0,
      referralCount: json['referral_count'] ?? 0,
      coinValue: (json['coin_value'] ?? 1).toDouble(),
    );
  }
}

class CoinsTransactionModel {
  final int id;
  final int userId;
  final int? orderId;
  final String transactionType;
  final int amount;
  final int balanceAfter;
  final String? description;
  final String status;
  final DateTime createdAt;

  CoinsTransactionModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory CoinsTransactionModel.fromJson(Map<String, dynamic> json) {
    return CoinsTransactionModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      orderId: json['order_id'],
      transactionType: json['transaction_type'] ?? '',
      amount: json['amount'] ?? 0,
      balanceAfter: json['balance_after'] ?? 0,
      description: json['description'],
      status: json['status'] ?? 'completed',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class CoinsSettingsModel {
  final double coinsValue;
  final int signupBonusCoins;
  final int referralBonusCoins;
  final double coinsOrderEarnPercent;
  final int coinsExpiryDays;
  final double minOrderForReferral;
  final int reviewBonus5Star;
  final int reviewBonus3Star;

  CoinsSettingsModel({
    this.coinsValue = 1,
    this.signupBonusCoins = 10,
    this.referralBonusCoins = 50,
    this.coinsOrderEarnPercent = 1,
    this.coinsExpiryDays = 90,
    this.minOrderForReferral = 100,
    this.reviewBonus5Star = 5,
    this.reviewBonus3Star = 3,
  });

  factory CoinsSettingsModel.fromJson(Map<String, dynamic> json) {
    return CoinsSettingsModel(
      coinsValue: (json['coins_value'] ?? 1).toDouble(),
      signupBonusCoins: json['signup_bonus_coins'] ?? 10,
      referralBonusCoins: json['referral_bonus_coins'] ?? 50,
      coinsOrderEarnPercent: (json['coins_order_earn_percent'] ?? 1).toDouble(),
      coinsExpiryDays: json['coins_expiry_days'] ?? 90,
      minOrderForReferral: (json['min_order_for_referral'] ?? 100).toDouble(),
      reviewBonus5Star: json['review_bonus_5star'] ?? 5,
      reviewBonus3Star: json['review_bonus_3star'] ?? 3,
    );
  }
}
