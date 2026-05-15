class TodayDealsModel {
  bool? success;
  String? message;
  TodayDealsData? data;

  TodayDealsModel({this.success, this.message, this.data});

  TodayDealsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? TodayDealsData.fromJson(json['data']) : null;
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

class TodayDealsData {
  List<TodayDeal>? deals;
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;

  TodayDealsData({this.deals, this.currentPage, this.lastPage, this.perPage, this.total});

  TodayDealsData.fromJson(Map<String, dynamic> json) {
    if (json['deals'] != null || json['data'] != null) {
      final list = json['deals'] ?? json['data'] ?? [];
      deals = <TodayDeal>[];
      if (list is List) {
        list.forEach((v) {
          deals!.add(TodayDeal.fromJson(v));
        });
      }
    }
    currentPage = parseInt(json['current_page']);
    lastPage = parseInt(json['last_page']);
    perPage = parseInt(json['per_page']);
    total = parseInt(json['total']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (deals != null) {
      data['deals'] = deals!.map((v) => v.toJson()).toList();
    }
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    return data;
  }
}

class TodayDeal {
  int? id;
  String? title;
  String? banner;
  int? productId;
  String? productSlug;
  String? productName;
  String? productImage;
  double? originalPrice;
  double? discountedPrice;
  int? discountPercentage;
  DateTime? expiresAt;
  String? sellerId;
  String? sellerName;
  bool? isActive;
  int? stockCount;
  String? status;

  TodayDeal({
    this.id,
    this.title,
    this.banner,
    this.productId,
    this.productSlug,
    this.productName,
    this.productImage,
    this.originalPrice,
    this.discountedPrice,
    this.discountPercentage,
    this.expiresAt,
    this.sellerId,
    this.sellerName,
    this.isActive,
    this.stockCount,
    this.status,
  });

  TodayDeal.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    title = parseString(json['title']);
    banner = parseString(json['banner'] ?? json['banner_image'] ?? json['image']);
    productId = parseInt(json['product_id']);
    productSlug = parseString(json['product_slug']);
    productName = parseString(json['product_name']);
    productImage = parseString(json['product_image'] ?? json['image']);
    originalPrice = parseDouble(json['original_price'] ?? json['price']);
    discountedPrice = parseDouble(json['discounted_price'] ?? json['special_price'] ?? json['sale_price']);
    discountPercentage = parseInt(json['discount_percentage'] ?? json['discount']);
    expiresAt = json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null;
    sellerId = parseString(json['seller_id']);
    sellerName = parseString(json['seller_name']);
    isActive = json['is_active'] == true || json['is_active'] == 1;
    stockCount = parseInt(json['stock_count'] ?? json['stock']);
    status = parseString(json['status']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['banner'] = banner;
    data['product_id'] = productId;
    data['product_slug'] = productSlug;
    data['product_name'] = productName;
    data['product_image'] = productImage;
    data['original_price'] = originalPrice;
    data['discounted_price'] = discountedPrice;
    data['discount_percentage'] = discountPercentage;
    data['expires_at'] = expiresAt?.toIso8601String();
    data['seller_id'] = sellerId;
    data['seller_name'] = sellerName;
    data['is_active'] = isActive;
    data['stock_count'] = stockCount;
    data['status'] = status;
    return data;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get timeRemaining {
    if (expiresAt == null) return Duration.zero;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

int? parseInt(dynamic value) {
  if (value == null || value == "") return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? parseDouble(dynamic value) {
  if (value == null || value == "") return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? parseString(dynamic value) {
  if (value == null || value == "") return null;
  return value.toString();
}