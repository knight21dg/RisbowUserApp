class CommissionRuleModel {
  final int id;
  final String name;
  final String? description;
  final String scope;
  final int? sellerId;
  final int? categoryId;
  final int? productId;
  final double commissionRate;
  final double? fixedAmount;
  final double? minAmount;
  final double? maxAmount;
  final int priority;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  CommissionRuleModel({
    required this.id,
    required this.name,
    this.description,
    required this.scope,
    this.sellerId,
    this.categoryId,
    this.productId,
    required this.commissionRate,
    this.fixedAmount,
    this.minAmount,
    this.maxAmount,
    this.priority = 0,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
  });

  factory CommissionRuleModel.fromJson(Map<String, dynamic> json) {
    return CommissionRuleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      scope: json['scope'] ?? 'global',
      sellerId: json['seller_id'],
      categoryId: json['category_id'],
      productId: json['product_id'],
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      fixedAmount: json['fixed_amount']?.toDouble(),
      minAmount: json['min_amount']?.toDouble(),
      maxAmount: json['max_amount']?.toDouble(),
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  String get scopeDisplay {
    switch (scope) {
      case 'global':
        return 'All Sellers';
      case 'seller':
        return 'Specific Seller';
      case 'category':
        return 'Category';
      case 'product':
        return 'Product';
      default:
        return scope;
    }
  }

  String get commissionDisplay {
    if (fixedAmount != null && fixedAmount! > 0) {
      return '₹${fixedAmount!.toStringAsFixed(2)}';
    }
    return '${commissionRate.toStringAsFixed(2)}%';
  }

  bool get isValid {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return isActive;
  }
}

class CommissionStatsModel {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final double totalCommission;
  final double pendingCommission;
  final double settledCommission;
  final List<CommissionRuleModel> rules;

  CommissionStatsModel({
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.avgOrderValue = 0,
    this.totalCommission = 0,
    this.pendingCommission = 0,
    this.settledCommission = 0,
    this.rules = const [],
  });

  factory CommissionStatsModel.fromJson(Map<String, dynamic> json) {
    return CommissionStatsModel(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      avgOrderValue: (json['avg_order_value'] ?? 0).toDouble(),
      totalCommission: (json['total_commission'] ?? 0).toDouble(),
      pendingCommission: (json['pending_commission'] ?? 0).toDouble(),
      settledCommission: (json['settled_commission'] ?? 0).toDouble(),
      rules: (json['rules'] as List<dynamic>?)
              ?.map((e) => CommissionRuleModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
