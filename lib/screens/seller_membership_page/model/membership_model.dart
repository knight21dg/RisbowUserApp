class MembershipTierModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int commissionPercent;
  final int productsLimit;
  final int storesLimit;
  final bool analytics;
  final bool prioritySupport;
  final bool customDomain;
  final bool apiAccess;
  final bool featured;
  final int sortOrder;
  final bool isActive;

  MembershipTierModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.commissionPercent,
    required this.productsLimit,
    required this.storesLimit,
    required this.analytics,
    required this.prioritySupport,
    required this.customDomain,
    required this.apiAccess,
    required this.featured,
    required this.sortOrder,
    required this.isActive,
  });

  factory MembershipTierModel.fromJson(Map<String, dynamic> json) {
    return MembershipTierModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      monthlyPrice: (json['monthly_price'] ?? 0).toDouble(),
      yearlyPrice: (json['yearly_price'] ?? 0).toDouble(),
      commissionPercent: json['commission_percent'] ?? 0,
      productsLimit: json['products_limit'] ?? 0,
      storesLimit: json['stores_limit'] ?? 1,
      analytics: json['analytics'] ?? false,
      prioritySupport: json['priority_support'] ?? false,
      customDomain: json['custom_domain'] ?? false,
      apiAccess: json['api_access'] ?? false,
      featured: json['featured'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
      'commission_percent': commissionPercent,
      'products_limit': productsLimit,
      'stores_limit': storesLimit,
      'analytics': analytics,
      'priority_support': prioritySupport,
      'custom_domain': customDomain,
      'api_access': apiAccess,
      'featured': featured,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  double getPrice(String billingCycle) {
    return billingCycle == 'yearly' ? yearlyPrice : monthlyPrice;
  }

  String get billingCycleLabel => 'monthly';
}

class VendorSubscriptionModel {
  final int id;
  final int sellerId;
  final int tierId;
  final String billingCycle;
  final double amountPaid;
  final int commissionRate;
  final int productsUsed;
  final int storesUsed;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final String status;
  final String? cancellationReason;
  final MembershipTierModel? tier;

  VendorSubscriptionModel({
    required this.id,
    required this.sellerId,
    required this.tierId,
    required this.billingCycle,
    required this.amountPaid,
    required this.commissionRate,
    required this.productsUsed,
    required this.storesUsed,
    required this.startsAt,
    this.expiresAt,
    required this.status,
    this.cancellationReason,
    this.tier,
  });

  factory VendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return VendorSubscriptionModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      tierId: json['tier_id'] ?? 0,
      billingCycle: json['billing_cycle'] ?? 'monthly',
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      commissionRate: json['commission_rate'] ?? 0,
      productsUsed: json['products_used'] ?? 0,
      storesUsed: json['stores_used'] ?? 1,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      status: json['status'] ?? 'active',
      cancellationReason: json['cancellation_reason'],
      tier: json['tier'] != null ? MembershipTierModel.fromJson(json['tier']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'tier_id': tierId,
      'billing_cycle': billingCycle,
      'amount_paid': amountPaid,
      'commission_rate': commissionRate,
      'products_used': productsUsed,
      'stores_used': storesUsed,
      'starts_at': startsAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': status,
      'cancellation_reason': cancellationReason,
      'tier': tier?.toJson(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class CurrentSubscriptionModel {
  final bool hasSubscription;
  final MembershipTierModel? tier;
  final VendorSubscriptionModel? subscription;

  CurrentSubscriptionModel({
    required this.hasSubscription,
    this.tier,
    this.subscription,
  });

  factory CurrentSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return CurrentSubscriptionModel(
      hasSubscription: json['has_subscription'] ?? false,
      tier: json['tier'] != null ? MembershipTierModel.fromJson(json['tier']) : null,
      subscription: json['subscription'] != null 
          ? VendorSubscriptionModel.fromJson(json['subscription'])
          : null,
    );
  }
}

class SubscriptionHistoryModel {
  final List<VendorSubscriptionModel> subscriptions;
  final int currentPage;
  final int totalPages;
  final int total;

  SubscriptionHistoryModel({
    required this.subscriptions,
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  factory SubscriptionHistoryModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryModel(
      subscriptions: json['data'] != null
          ? (json['data'] as List).map((s) => VendorSubscriptionModel.fromJson(s)).toList()
          : [],
      currentPage: json['current_page'] ?? 1,
      totalPages: json['last_page'] ?? 1,
      total: json['total'] ?? 0,
    );
  }
}

class FeatureAccessModel {
  final bool hasAccess;
  final MembershipTierModel? tier;

  FeatureAccessModel({
    required this.hasAccess,
    this.tier,
  });

  factory FeatureAccessModel.fromJson(Map<String, dynamic> json) {
    return FeatureAccessModel(
      hasAccess: json['has_access'] ?? false,
      tier: json['tier'] != null ? MembershipTierModel.fromJson(json['tier']) : null,
    );
  }
}
