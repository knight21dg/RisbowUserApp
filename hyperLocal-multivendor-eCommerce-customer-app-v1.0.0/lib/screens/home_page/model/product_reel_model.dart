class ProductReelsModel {
  bool? success;
  String? message;
  ProductReelsData? data;

  ProductReelsModel({this.success, this.message, this.data});

  ProductReelsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? ProductReelsData.fromJson(json['data']) : null;
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

class ProductReelsData {
  List<ProductReel>? reels;
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;

  ProductReelsData({this.reels, this.currentPage, this.lastPage, this.perPage, this.total});

  ProductReelsData.fromJson(Map<String, dynamic> json) {
    if (json['reels'] != null || json['data'] != null) {
      final list = json['reels'] ?? json['data'] ?? [];
      reels = <ProductReel>[];
      if (list is List) {
        for (var v in list) {
          reels!.add(ProductReel.fromJson(v));
        }
      }
    }
    currentPage = parseInt(json['current_page']);
    lastPage = parseInt(json['last_page']);
    perPage = parseInt(json['per_page']);
    total = parseInt(json['total']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (reels != null) {
      data['reels'] = reels!.map((v) => v.toJson()).toList();
    }
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    return data;
  }
}

class ProductReel {
  int? id;
  String? videoUrl;
  String? thumbnail;
  String? sellerId;
  String? sellerName;
  String? sellerAvatar;
  int? productId;
  String? productSlug;
  String? productName;
  double? productPrice;
  String? productImage;
  int? views;
  int? likes;
  int? shares;
  int? comments;
  int? duration;
  String? caption;
  List<String>? tags;
  bool? isLiked;
  bool? isBookmarked;
  DateTime? createdAt;
  String? status;

  ProductReel({
    this.id,
    this.videoUrl,
    this.thumbnail,
    this.sellerId,
    this.sellerName,
    this.sellerAvatar,
    this.productId,
    this.productSlug,
    this.productName,
    this.productPrice,
    this.productImage,
    this.views,
    this.likes,
    this.shares,
    this.comments,
    this.duration,
    this.caption,
    this.tags,
    this.isLiked,
    this.isBookmarked,
    this.createdAt,
    this.status,
  });

  ProductReel.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    videoUrl = parseString(json['video_url'] ?? json['video']);
    thumbnail = parseString(json['thumbnail'] ?? json['thumbnail_url'] ?? json['image']);
    sellerId = parseString(json['seller_id']);
    sellerName = parseString(json['seller_name']);
    sellerAvatar = parseString(json['seller_avatar'] ?? json['seller_image']);
    productId = parseInt(json['product_id']);
    productSlug = parseString(json['product_slug']);
    productName = parseString(json['product_name']);
    productPrice = parseDouble(json['product_price'] ?? json['price']);
    productImage = parseString(json['product_image'] ?? json['image']);
    views = parseInt(json['views'] ?? json['view_count']);
    likes = parseInt(json['likes'] ?? json['like_count']);
    shares = parseInt(json['shares'] ?? json['share_count']);
    comments = parseInt(json['comments'] ?? json['comment_count']);
    duration = parseInt(json['duration']);
    caption = parseString(json['caption'] ?? json['description']);
    if (json['tags'] != null) {
      tags = <String>[];
      if (json['tags'] is List) {
        json['tags'].forEach((v) {
          tags!.add(v.toString());
        });
      }
    }
    isLiked = json['is_liked'] == true || json['is_liked'] == 1;
    isBookmarked = json['is_bookmarked'] == true || json['is_bookmarked'] == 1;
    createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null;
    status = parseString(json['status']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['video_url'] = videoUrl;
    data['thumbnail'] = thumbnail;
    data['seller_id'] = sellerId;
    data['seller_name'] = sellerName;
    data['seller_avatar'] = sellerAvatar;
    data['product_id'] = productId;
    data['product_slug'] = productSlug;
    data['product_name'] = productName;
    data['product_price'] = productPrice;
    data['product_image'] = productImage;
    data['views'] = views;
    data['likes'] = likes;
    data['shares'] = shares;
    data['comments'] = comments;
    data['duration'] = duration;
    data['caption'] = caption;
    data['tags'] = tags;
    data['is_liked'] = isLiked;
    data['is_bookmarked'] = isBookmarked;
    data['created_at'] = createdAt?.toIso8601String();
    data['status'] = status;
    return data;
  }

  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedViews {
    if (views == null) return '0';
    if (views! >= 1000000) {
      return '${(views! / 1000000).toStringAsFixed(1)}M';
    } else if (views! >= 1000) {
      return '${(views! / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String get formattedLikes {
    if (likes == null) return '0';
    if (likes! >= 1000000) {
      return '${(likes! / 1000000).toStringAsFixed(1)}M';
    } else if (likes! >= 1000) {
      return '${(likes! / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
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