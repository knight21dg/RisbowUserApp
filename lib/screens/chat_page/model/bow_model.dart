
class BowMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final MessageType type;
  final String? imageUrl;
  final DateTime createdAt;
  final BowIntent? intent;
  final List<BowProduct>? suggestedProducts;
  final BowAction? action;

  BowMessage({
    required this.id,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    required this.createdAt,
    this.intent,
    this.suggestedProducts,
    this.action,
  });

  factory BowMessage.fromJson(Map<String, dynamic> json) {
    return BowMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      intent: json['intent'] != null ? BowIntent.fromJson(json['intent']) : null,
      suggestedProducts: json['suggested_products'] != null
          ? (json['suggested_products'] as List)
              .map((e) => BowProduct.fromJson(e))
              .toList()
          : null,
      action: json['action'] != null ? BowAction.fromJson(json['action']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'type': type.name,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'intent': intent?.toJson(),
      'suggested_products': suggestedProducts?.map((e) => e.toJson()).toList(),
      'action': action?.toJson(),
    };
  }
}

enum MessageType {
  text,
  image,
  voice,
  product,
  action,
  suggestion,
}

class BowIntent {
  final String type; // 'search', 'recommendation', 'action', 'conversation', 'help'
  final String? query;
  final Map<String, dynamic>? parameters;

  BowIntent({
    required this.type,
    this.query,
    this.parameters,
  });

  factory BowIntent.fromJson(Map<String, dynamic> json) {
    return BowIntent(
      type: json['type'] ?? 'conversation',
      query: json['query'],
      parameters: json['parameters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'query': query,
      'parameters': parameters,
    };
  }
}

class BowAction {
  final String type; // 'add_to_cart', 'search', 'navigate', 'apply_coupon', 'show_offers'
  final Map<String, dynamic>? data;

  BowAction({
    required this.type,
    this.data,
  });

  factory BowAction.fromJson(Map<String, dynamic> json) {
    return BowAction(
      type: json['type'] ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
}

class BowProduct {
  final int id;
  final String title;
  final String slug;
  final double price;
  final double? mrp;
  final int? discount;
  final String? url;
  final String mainImage;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final bool inStock;

  BowProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    this.mrp,
    this.discount,
    this.url,
    required this.mainImage,
    this.rating,
    this.reviewCount,
    this.category,
    this.inStock = true,
  });

  factory BowProduct.fromJson(Map<String, dynamic> json) {
    return BowProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      mrp: json['mrp']?.toDouble(),
      discount: json['discount']?.toInt(),
      url: json['url'],
      mainImage: (json['main_image'] ?? json['image'] ?? '').toString(),
      rating: json['rating']?.toDouble(),
      reviewCount: json['review_count']?.toInt(),
      category: json['category'],
      inStock: json['in_stock'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'price': price,
      'mrp': mrp,
      'discount': discount,
      'url': url,
      'main_image': mainImage,
      'rating': rating,
      'review_count': reviewCount,
      'category': category,
      'in_stock': inStock,
    };
  }
}

class BowConversation {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  BowConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory BowConversation.fromJson(Map<String, dynamic> json) {
    return BowConversation(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'New Conversation',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      messageCount: json['message_count'] ?? 0,
    );
  }
}

class BowConfig {
  final String apiUrl;
  final String apiKey;
  final String model;
  final String language;
  final bool voiceEnabled;
  final bool imageEnabled;

  BowConfig({
    required this.apiUrl,
    required this.apiKey,
    required this.model,
    this.language = 'en',
    this.voiceEnabled = true,
    this.imageEnabled = true,
  });

  factory BowConfig.fromJson(Map<String, dynamic> json) {
    return BowConfig(
      apiUrl: json['api_url'] ?? '',
      apiKey: json['api_key'] ?? '',
      model: json['model'] ?? 'openai/gpt-4o-mini',
      language: json['language'] ?? 'en',
      voiceEnabled: json['voice_enabled'] ?? true,
      imageEnabled: json['image_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'api_url': apiUrl,
      'api_key': apiKey,
      'model': model,
      'language': language,
      'voice_enabled': voiceEnabled,
      'image_enabled': imageEnabled,
    };
  }
}

class BowSuggestion {
  final String id;
  final String text;
  final String icon;
  final String type;

  BowSuggestion({
    required this.id,
    required this.text,
    required this.icon,
    required this.type,
  });

  static List<BowSuggestion> getDefaultSuggestions() {
    return [
      BowSuggestion(id: '1', text: 'Show me deals & offers', icon: '🔥', type: 'deals'),
      BowSuggestion(id: '2', text: 'Show best sellers', icon: '⭐', type: 'trending'),
      BowSuggestion(id: '3', text: 'Apply coupon code', icon: '🏷️', type: 'coupon'),
      BowSuggestion(id: '4', text: 'What offers today?', icon: '🎁', type: 'offers'),
      BowSuggestion(id: '5', text: 'Show group deals/rooms', icon: '🏠', type: 'rooms'),
      BowSuggestion(id: '6', text: 'Track my order', icon: '📦', type: 'order'),
      BowSuggestion(id: '7', text: 'View my cart', icon: '🛒', type: 'cart'),
      BowSuggestion(id: '8', text: 'View my wishlist', icon: '❤️', type: 'wishlist'),
      BowSuggestion(id: '9', text: 'My order history', icon: '📋', type: 'orders'),
      BowSuggestion(id: '10', text: 'Browse categories', icon: '📂', type: 'categories'),
      BowSuggestion(id: '11', text: 'Search for...', icon: '🔍', type: 'search'),
      BowSuggestion(id: '12', text: 'Help me choose', icon: '💡', type: 'help'),
    ];
  }
}