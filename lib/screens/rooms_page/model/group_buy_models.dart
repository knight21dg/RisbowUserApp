
class RoomDiscountSlabModel {
  final int id;
  final int memberTarget;
  final double discountPercentage;

  const RoomDiscountSlabModel({
    required this.id,
    required this.memberTarget,
    required this.discountPercentage,
  });

  factory RoomDiscountSlabModel.fromJson(Map<String, dynamic> json) {
    return RoomDiscountSlabModel(
      id: json['id'] ?? 0,
      memberTarget: _toInt(json['member_target']) ?? 0,
      discountPercentage: _toDouble(json['discount_percentage']) ?? 0,
    );
  }
}

class GroupBuyMember {
  final int id;
  final String name;
  final String? avatarUrl;
  final bool isOwner;

  const GroupBuyMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOwner = false,
  });

  factory GroupBuyMember.fromJson(Map<String, dynamic> json) {
    final nestedUser = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return GroupBuyMember(
      id: _toInt(json['user_id'] ?? nestedUser['id'] ?? json['id']) ?? 0,
      name: _toStringValue(
        nestedUser['name'] ?? json['name'],
        fallback: 'User',
      ) ?? 'User',
      avatarUrl: _nullableString(
        nestedUser['avatar'] ??
            nestedUser['avatar_url'] ??
            json['avatar'] ??
            json['avatar_url'],
      ),
      isOwner: _toBool(json['is_owner']) || _toBool(json['owner']),
    );
  }
}

class GroupBuyCartItem {
  final int id;
  final int productId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final String addedByName;
  final bool inStock;

  const GroupBuyCartItem({
    required this.id,
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.addedByName,
    this.inStock = true,
  });

  double get totalPrice => unitPrice * quantity;

  GroupBuyCartItem copyWith({
    int? id,
    int? productId,
    String? name,
    String? imageUrl,
    int? quantity,
    double? unitPrice,
    String? addedByName,
    bool? inStock,
  }) {
    return GroupBuyCartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      addedByName: addedByName ?? this.addedByName,
      inStock: inStock ?? this.inStock,
    );
  }

  factory GroupBuyCartItem.fromJson(Map<String, dynamic> json) {
    final product = (json['product'] is Map<String, dynamic>)
        ? json['product'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final addedBy = (json['added_by'] is Map<String, dynamic>)
        ? json['added_by'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return GroupBuyCartItem(
      id: _toInt(json['id']) ?? 0,
      productId: _toInt(json['product_id'] ?? product['id']) ?? 0,
      name: _toStringValue(
        json['name'] ?? json['product_name'] ?? product['name'] ?? product['title'],
        fallback: 'Product',
      ) ?? 'Product',
      imageUrl: _nullableString(json['image'] ?? product['image'] ?? product['main_image']),
      quantity: _toInt(json['quantity']) ?? 1,
      unitPrice: _toDouble(json['unit_price'] ?? json['price'] ?? product['price'] ?? product['special_price']) ?? 0.0,
      addedByName: _toStringValue(
        json['added_by_name'] ?? addedBy['name'] ?? user['name'],
        fallback: 'Someone',
      ) ?? 'Someone',
      inStock: _toBool(json['in_stock'] ?? json['is_available'] ?? product['stock']) ?? true,
    );
  }
}

class GroupBuyActivity {
  final int id;
  final String type;
  final String message;
  final GroupBuyMember? user;
  final DateTime createdAt;
  final DateTime timestamp;
  final String iconKey;

  const GroupBuyActivity({
    required this.id,
    required this.type,
    required this.message,
    this.user,
    required this.createdAt,
    DateTime? timestamp,
    this.iconKey = 'info',
  }) : timestamp = timestamp ?? createdAt;

  factory GroupBuyActivity.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now();
    return GroupBuyActivity(
      id: _toInt(json['id']) ?? 0,
      type: _toStringValue(json['type']) ?? 'info',
      message: _toStringValue(json['message']) ?? '',
      user: json['user'] != null ? GroupBuyMember.fromJson(json['user']) : null,
      createdAt: created,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      iconKey: _toStringValue(json['icon'] ?? json['icon_key']) ?? 'info',
    );
  }
}

class GroupBuyRoom {
  final int id;
  final String code;
  final String name;
  final bool isPublic;
  final int maxMembers;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final GroupBuyMember owner;
  final List<GroupBuyMember> members;
  final List<GroupBuyCartItem> cartItems;
  final List<GroupBuyActivity> activities;

  final int? unlockThreshold;
  final int? minMembers;
  final int? maxMembersCapacity;
  final double? currentDiscount;
  final bool? dynamicDiscountEnabled;
  final bool? isLocked;
  final DateTime? unlockedAt;
  final String? bannerUrl;
  final String? description;
  final String? sellerId;
  final String? sellerName;
  final double? discount;
  final String? roomType;
  final int? minimumOrderQuantity;
  final List<RoomDiscountSlabModel>? discountSlabs;

  const GroupBuyRoom({
    required this.id,
    required this.code,
    required this.name,
    required this.isPublic,
    required this.maxMembers,
    required this.status,
    this.expiresAt,
    required this.createdAt,
    required this.owner,
    required this.members,
    required this.cartItems,
    required this.activities,
    this.unlockThreshold,
    this.minMembers,
    this.maxMembersCapacity,
    this.currentDiscount,
    this.dynamicDiscountEnabled,
    this.isLocked,
    this.unlockedAt,
    this.bannerUrl,
    this.description,
    this.sellerId,
    this.sellerName,
    this.discount,
    this.roomType,
    this.minimumOrderQuantity,
    this.discountSlabs,
  });

  int get membersJoined => members.length;
  bool get isExpired => expiresAt?.isBefore(DateTime.now()) ?? false;
  bool get isFull => membersJoined >= maxMembers;
  bool get isClosed =>
      status.toLowerCase() == 'closed' ||
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'expired' ||
      isExpired;
  bool get isOpen => !isClosed && !isFull;
  double get memberProgress => maxMembers <= 0 ? 0.0 : membersJoined / maxMembers;
  double get cartTotal =>
      cartItems.fold(0.0, (double sum, item) => sum + item.totalPrice);

  int get effectiveThreshold => unlockThreshold ?? minMembers ?? 20;
  bool get shouldUnlock => membersJoined >= effectiveThreshold;
  int get membersNeededToUnlock => (effectiveThreshold - membersJoined).clamp(0, effectiveThreshold);
  double get unlockProgress => effectiveThreshold > 0 ? (membersJoined / effectiveThreshold).clamp(0.0, 1.0) : 0.0;
  
  bool get canAddToCart => isUnlocked;
  
  double get currentDiscountValue => currentDiscount ?? discount ?? 0;
  
  double getDynamicPrice(double basePrice) {
    final discountVal = currentDiscountValue;
    if (discountVal <= 0) return basePrice;
    return basePrice * (1 - discountVal / 100);
  }

  RoomDiscountSlabModel? get nextDiscountSlab {
    if (discountSlabs == null || discountSlabs!.isEmpty) return null;
    final sorted = discountSlabs!.where((s) => s.memberTarget > membersJoined).toList()
      ..sort((a, b) => a.memberTarget.compareTo(b.memberTarget));
    return sorted.isNotEmpty ? sorted.first : null;
  }
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }

  RoomState get roomState {
    if (isLocked == true) return RoomState.locked;
    if (unlockedAt != null) return RoomState.unlocked;
    if (isExpired) return RoomState.expired;
    if (status.toLowerCase() == 'teasing') return RoomState.teasing;
    return RoomState.active;
  }

  bool get canJoin => roomState.allowJoining;
  bool get isUnlocked {
    if (isLocked == true) return false;
    if (unlockedAt != null) return true;
    return membersJoined >= effectiveThreshold;
  }
  bool get showPrice => roomState.showPrice;
  bool get showProducts => roomState.showProducts;
  bool get isBlurred => roomState == RoomState.active;

  String get stateMessage {
    switch (roomState) {
      case RoomState.teasing:
        return 'Coming soon!';
      case RoomState.active:
        if (shouldUnlock) return 'About to unlock!';
        return '$membersNeededToUnlock more needed to unlock';
      case RoomState.unlocked:
        return 'Deal unlocked! Order now';
      case RoomState.locked:
        return 'Room locked';
      case RoomState.expired:
        return 'Deal expired';
    }
  }

  GroupBuyRoom copyWith({
    int? id,
    String? code,
    String? name,
    bool? isPublic,
    int? maxMembers,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    GroupBuyMember? owner,
    List<GroupBuyMember>? members,
    List<GroupBuyCartItem>? cartItems,
    List<GroupBuyActivity>? activities,
    int? unlockThreshold,
    bool? isLocked,
    DateTime? unlockedAt,
    String? bannerUrl,
    String? description,
    String? sellerId,
    String? sellerName,
    double? discount,
  }) {
    return GroupBuyRoom(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      owner: owner ?? this.owner,
      members: members ?? this.members,
      cartItems: cartItems ?? this.cartItems,
      activities: activities ?? this.activities,
      unlockThreshold: unlockThreshold ?? this.unlockThreshold,
      isLocked: isLocked ?? this.isLocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      description: description ?? this.description,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      discount: discount ?? this.discount,
    );
  }

  factory GroupBuyRoom.fromJson(Map<String, dynamic> json) {
    final ownerMap = (json['creator'] is Map<String, dynamic>)
        ? json['creator'] as Map<String, dynamic>
        : (json['owner'] is Map<String, dynamic>)
        ? json['owner'] as Map<String, dynamic>
        : <String, dynamic>{'id': json['owner_id'], 'name': json['owner_name']};

    return GroupBuyRoom(
      id: _toInt(json['id']) ?? 0,
      code: _toStringValue(json['room_code'] ?? json['code']) ?? '',
      name: _toStringValue(json['title'] ?? json['name']) ?? 'Group Deal',
      isPublic: _toBool(json['is_public'] ?? json['isPublic']) ?? true,
      maxMembers: _toInt(json['max_members'] ?? json['required_members'] ?? 50) ?? 50,
      status: _toStringValue(json['status']) ?? 'active',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      owner: GroupBuyMember.fromJson(ownerMap),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => GroupBuyMember.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      cartItems: (json['cart_items'] as List<dynamic>?)
          ?.map((e) => GroupBuyCartItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      activities: (json['activities'] as List<dynamic>?)
          ?.map((e) => GroupBuyActivity.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      unlockThreshold: _toInt(json['unlock_threshold']),
      minMembers: _toInt(json['min_members']),
      maxMembersCapacity: _toInt(json['max_members']),
      currentDiscount: _toDouble(json['current_discount']),
      dynamicDiscountEnabled: _toBool(json['dynamic_discount_enabled']),
      isLocked: _toBool(json['is_locked']),
      unlockedAt: json['unlocked_at'] != null ? DateTime.tryParse(json['unlocked_at'].toString()) : null,
      bannerUrl: _nullableString(json['banner'] ?? json['banner_url']),
      description: _nullableString(json['description']),
      sellerId: _nullableString(json['seller_id']),
      sellerName: _nullableString(json['seller_name']),
      discount: _toDouble(json['discount']),
      roomType: _nullableString(json['room_type']),
      minimumOrderQuantity: _toInt(json['minimum_order_quantity']),
      discountSlabs: (json['slabs'] as List<dynamic>?)
          ?.map((e) => RoomDiscountSlabModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'status': status,
  };
}

class GroupBuyProduct {
  final int id;
  final String name;
  final String? imageUrl;
  final double price;
  final double? specialPrice;
  final int stock;
  final bool inStock;
  final String category;
  final double groupPrice;
  bool inCart;

  GroupBuyProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.specialPrice,
    required this.stock,
    this.inStock = true,
    this.category = '',
    double? groupPrice,
    this.inCart = false,
  }) : groupPrice = groupPrice ?? specialPrice ?? price;

  double get displayPrice => specialPrice ?? price;
  bool get hasDiscount => specialPrice != null && specialPrice! < price;
  double get discountPercentage => hasDiscount ? ((price - specialPrice!) / price * 100) : 0;

  GroupBuyProduct copyWith({bool? inCart}) => GroupBuyProduct(
    id: id,
    name: name,
    imageUrl: imageUrl,
    price: price,
    specialPrice: specialPrice,
    stock: stock,
    inStock: inStock,
    category: category,
    inCart: inCart ?? this.inCart,
  );

  factory GroupBuyProduct.fromJson(Map<String, dynamic> json) {
    return GroupBuyProduct(
      id: _toInt(json['id']) ?? 0,
      name: _toStringValue(json['name'] ?? json['title']) ?? 'Product',
      imageUrl: _nullableString(json['image'] ?? json['image_url'] ?? json['main_image']),
      price: _toDouble(json['price'] ?? json['original_price']) ?? 0.0,
      specialPrice: _toDouble(json['special_price'] ?? json['discounted_price']),
      stock: _toInt(json['stock'] ?? json['stock_count']) ?? 0,
      inStock: _toBool(json['in_stock'] ?? json['is_available']) ?? true,
      category: _toStringValue(json['category']) ?? '',
    );
  }
}

class GroupBuyCheckoutItem {
  final GroupBuyProduct product;
  final int quantity;
  final GroupBuyMember addedBy;
  final int productId;

  GroupBuyCheckoutItem({
    GroupBuyProduct? product,
    this.quantity = 1,
    GroupBuyMember? addedBy,
    this.productId = 0,
  }) : product = product ?? GroupBuyProduct(id: 0, name: '', price: 0, stock: 0),
       addedBy = addedBy ?? const GroupBuyMember(id: 0, name: '');

  double get totalPrice => product.displayPrice * quantity;
  int get qty => quantity;

  factory GroupBuyCheckoutItem.fromJson(Map<String, dynamic> json) {
    return GroupBuyCheckoutItem(
      product: GroupBuyProduct.fromJson(json['product'] ?? {}),
      quantity: _toInt(json['quantity']) ?? 1,
      addedBy: GroupBuyMember.fromJson(json['added_by'] ?? json['user'] ?? {}),
      productId: _toInt(json['product_id'] ?? json['product']?['id']) ?? 0,
    );
  }
}

class GroupBuyCheckoutPayload {
  final GroupBuyRoom room;
  final List<GroupBuyCheckoutItem> items;
  final double totalAmount;
  final double savedAmount;
  final String roomCode;
  final dynamic address;
  final String paymentToken;

  GroupBuyCheckoutPayload({
    GroupBuyRoom? room,
    this.items = const [],
    this.totalAmount = 0,
    this.savedAmount = 0,
    this.roomCode = '',
    this.address = '',
    this.paymentToken = '',
  }) : room = room ?? GroupBuyRoom(
    id: 0, code: '', name: '', isPublic: true, maxMembers: 0,
    status: '', createdAt: DateTime.now(),
    owner: const GroupBuyMember(id: 0, name: ''),
    members: const [], cartItems: const [], activities: const [],
  );

  factory GroupBuyCheckoutPayload.fromJson(Map<String, dynamic> json) {
    final room = GroupBuyRoom.fromJson(json['room'] ?? {});
    final items = (json['items'] as List<dynamic>?)
        ?.map((e) => GroupBuyCheckoutItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return GroupBuyCheckoutPayload(
      room: room,
      items: items,
      totalAmount: _toDouble(json['total_amount'] ?? json['total']) ?? 0.0,
      savedAmount: _toDouble(json['saved_amount'] ?? json['discount']) ?? 0.0,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null || value == "") return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null || value == "") return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _toStringValue(dynamic value, {String fallback = ''}) {
  if (value == null || value == "") return fallback.isEmpty ? null : fallback;
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null || value == "") return null;
  return value.toString();
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

enum RoomState {
  teasing,
  active,
  unlocked,
  locked,
  expired;

  static RoomState fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'teasing':
        return RoomState.teasing;
      case 'active':
        return RoomState.active;
      case 'unlocked':
        return RoomState.unlocked;
      case 'locked':
        return RoomState.locked;
      case 'expired':
      case 'closed':
      case 'completed':
        return RoomState.expired;
      default:
        return RoomState.active;
    }
  }

  String get displayName {
    switch (this) {
      case RoomState.teasing:
        return 'Coming Soon';
      case RoomState.active:
        return 'Active';
      case RoomState.unlocked:
        return 'Unlocked';
      case RoomState.locked:
        return 'Locked';
      case RoomState.expired:
        return 'Expired';
    }
  }

  bool get showProducts {
    switch (this) {
      case RoomState.teasing:
        return false;
      case RoomState.active:
        return true;
      case RoomState.unlocked:
        return true;
      case RoomState.locked:
        return false;
      case RoomState.expired:
        return false;
    }
  }

  bool get showPrice {
    switch (this) {
      case RoomState.teasing:
        return false;
      case RoomState.active:
        return false;
      case RoomState.unlocked:
        return true;
      case RoomState.locked:
        return false;
      case RoomState.expired:
        return false;
    }
  }

  bool get allowJoining {
    switch (this) {
      case RoomState.teasing:
        return false;
      case RoomState.active:
        return true;
      case RoomState.unlocked:
        return true;
      case RoomState.locked:
        return false;
      case RoomState.expired:
        return false;
    }
  }
}