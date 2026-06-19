/// Model for a vendor-purchased banner slot ad returned by
/// GET /api/advertising/slot-banners?position=POSITION
class SlotBannerModel {
  final int id;
  final String? position;
  final String? title;
  final String? imageUrl;
  final String? targetUrl;
  final String? dimensions;
  final String? startDate;
  final String? endDate;
  final SlotBannerSeller? seller;
  final Map<String, dynamic>? store;
  final Map<String, dynamic>? product;

  const SlotBannerModel({
    required this.id,
    this.position,
    this.title,
    this.imageUrl,
    this.targetUrl,
    this.dimensions,
    this.startDate,
    this.endDate,
    this.seller,
    this.store,
    this.product,
  });

  factory SlotBannerModel.fromJson(Map<String, dynamic> json) {
    return SlotBannerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      position: json['position'] as String?,
      title: json['title'] as String?,
      imageUrl: json['image_url'] as String? ?? json['banner_image'] as String? ?? json['image'] as String? ?? json['banner'] as String?,
      targetUrl: json['target_url'] as String?,
      dimensions: json['dimensions'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      seller: json['seller'] != null
          ? SlotBannerSeller.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      store: json['store'] as Map<String, dynamic>?,
      product: json['product'] as Map<String, dynamic>?,
    );
  }
}

class SlotBannerSeller {
  final int id;
  final String? businessName;

  const SlotBannerSeller({required this.id, this.businessName});

  factory SlotBannerSeller.fromJson(Map<String, dynamic> json) {
    return SlotBannerSeller(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: json['business_name'] as String?,
    );
  }
}

/// Full API response wrapper
class SlotBannerResponse {
  final bool success;
  final List<SlotBannerModel> banners;

  const SlotBannerResponse({required this.success, required this.banners});

  factory SlotBannerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final list = data?['banners'] as List<dynamic>? ?? [];
    return SlotBannerResponse(
      success: json['success'] == true,
      banners: list
          .whereType<Map<String, dynamic>>()
          .map(SlotBannerModel.fromJson)
          .toList(),
    );
  }
}
