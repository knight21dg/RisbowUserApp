class StoryModel {
  final int id;
  final int sellerId;
  final int? storeId;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final String? link;
  final int? productId;
  final int viewCount;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final dynamic seller;
  final dynamic store;
  final dynamic product;

  StoryModel({
    required this.id,
    required this.sellerId,
    this.storeId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.link,
    this.productId,
    required this.viewCount,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.seller,
    this.store,
    this.product,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      storeId: json['store_id'],
      mediaUrl: json['media_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      caption: json['caption'],
      link: json['link'],
      productId: json['product_id'],
      viewCount: json['view_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      seller: json['seller'],
      store: json['store'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'store_id': storeId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
      'link': link,
      'product_id': productId,
      'view_count': viewCount,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class ReelModel {
  final int id;
  final int sellerId;
  final int? storeId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? caption;
  final String? link;
  final int? productId;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isActive;
  final bool isFeatured;
  final bool isLiked;
  final DateTime createdAt;
  final dynamic seller;
  final dynamic store;
  final dynamic product;
  final List<ReelCommentModel> comments;

  ReelModel({
    required this.id,
    required this.sellerId,
    this.storeId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.caption,
    this.link,
    this.productId,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.isActive,
    required this.isFeatured,
    this.isLiked = false,
    required this.createdAt,
    this.seller,
    this.store,
    this.product,
    this.comments = const [],
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      storeId: json['store_id'],
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      link: json['link'],
      productId: json['product_id'],
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      isLiked: json['is_liked'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      seller: json['seller'],
      store: json['store'],
      product: json['product'],
      comments: json['comments'] != null 
          ? (json['comments'] as List).map((c) => ReelCommentModel.fromJson(c)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'store_id': storeId,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'link': link,
      'product_id': productId,
      'view_count': viewCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_active': isActive,
      'is_featured': isFeatured,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ReelModel copyWith({
    bool? isLiked,
    int? likeCount,
    int? commentCount,
  }) {
    return ReelModel(
      id: id,
      sellerId: sellerId,
      storeId: storeId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      link: link,
      productId: productId,
      viewCount: viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isActive: isActive,
      isFeatured: isFeatured,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      seller: seller,
      store: store,
      product: product,
      comments: comments,
    );
  }
}

class ReelCommentModel {
  final int id;
  final int reelId;
  final int userId;
  final String comment;
  final DateTime createdAt;
  final dynamic user;

  ReelCommentModel({
    required this.id,
    required this.reelId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    this.user,
  });

  factory ReelCommentModel.fromJson(Map<String, dynamic> json) {
    return ReelCommentModel(
      id: json['id'] ?? 0,
      reelId: json['reel_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      user: json['user'],
    );
  }
}
