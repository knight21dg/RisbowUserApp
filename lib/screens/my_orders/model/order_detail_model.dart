class OrderDetailModel {
  bool? success;
  String? message;
  OrderDetailData? data;

  OrderDetailModel({this.success, this.message, this.data});

  OrderDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? OrderDetailData.fromJson(json['data']) : null;
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

class OrderDetailData {
  int? id;
  String? uuid;
  String? slug;
  int? userId;
  String? email;
  String? currencyCode;
  String? currencyRate;
  String? paymentMethod;
  String? paymentStatus;
  String? status;
  String? invoice;
  String? fulfillmentType;
  int? estimatedDeliveryTime;
  String? deliveryTimeSlotId;
  dynamic deliveryBoyId;
  String? deliveryBoyName;
  int? deliveryBoyPhone;
  String? deliveryBoyProfile;
  bool? isDeliveryFeedbackGiven;
  List<DeliveryFeedback>? deliveryFeedback;
  String? walletBalance;
  String? promoCode;
  String? promoDiscount;
  String? giftCard;
  String? giftCardDiscount;
  String? deliveryCharge;
  String? handlingCharges;
  String? perStoreDropOffFee;
  String? subtotal;
  String? totalPayable;
  String? finalTotal;
  String? platformCharge;
  String? cgst;
  String? sgst;
  String? shippingName;
  String? shippingAddress1;
  String? shippingAddress2;
  String? shippingLandmark;
  String? shippingZip;
  String? shippingPhone;
  String? shippingAddressType;
  String? shippingLatitude;
  String? shippingLongitude;
  String? shippingCity;
  String? shippingState;
  String? shippingCountry;
  String? shippingCountryCode;
  String? orderNote;
  List<OrderItems>? items;
  List<SellerFeedbacks>? sellerFeedbacks;
  String? createdAt;
  String? updatedAt;
  int? coinsEarned;
  String? proofOfQualityVideo;

  OrderDetailData(
      {this.id,
        this.uuid,
        this.slug,
        this.userId,
        this.email,
        this.currencyCode,
        this.currencyRate,
        this.paymentMethod,
        this.paymentStatus,
        this.status,
        this.invoice,
        this.fulfillmentType,
        this.estimatedDeliveryTime,
        this.deliveryTimeSlotId,
        this.deliveryBoyId,
        this.deliveryBoyName,
        this.deliveryBoyPhone,
        this.deliveryBoyProfile,
        this.isDeliveryFeedbackGiven,
        this.deliveryFeedback,
        this.walletBalance,
        this.promoCode,
        this.promoDiscount,
        this.giftCard,
        this.giftCardDiscount,
        this.deliveryCharge,
        this.handlingCharges,
        this.perStoreDropOffFee,
        this.subtotal,
        this.totalPayable,
        this.finalTotal,
        this.platformCharge,
        this.cgst,
        this.sgst,
        this.shippingName,
        this.shippingAddress1,
        this.shippingAddress2,
        this.shippingLandmark,
        this.shippingZip,
        this.shippingPhone,
        this.shippingAddressType,
        this.shippingLatitude,
        this.shippingLongitude,
        this.shippingCity,
        this.shippingState,
        this.shippingCountry,
        this.shippingCountryCode,
        this.orderNote,
        this.items,
        this.sellerFeedbacks,
        this.createdAt,
        this.updatedAt,
        this.coinsEarned,
        this.proofOfQualityVideo});

  OrderDetailData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    slug = json['slug'];
    userId = json['user_id'];
    email = json['email'];
    currencyCode = json['currency_code'];
    currencyRate = json['currency_rate'];
    paymentMethod = json['payment_method'];
    paymentStatus = json['payment_status'];
    status = json['status'];
    invoice = json['invoice'];
    fulfillmentType = json['fulfillment_type'];
    estimatedDeliveryTime = json['estimated_delivery_time'];
    deliveryTimeSlotId = json['delivery_time_slot_id'];
    deliveryBoyId = json['delivery_boy_id'];
    deliveryBoyName = json['delivery_boy_name'];
    deliveryBoyPhone = json['delivery_boy_phone'];
    deliveryBoyProfile = json['delivery_boy_profile'];
    isDeliveryFeedbackGiven = json['is_delivery_feedback_given'];
       if (json['delivery_feedback'] != null && json['delivery_feedback'] is Map<String, dynamic>) {
          deliveryFeedback = [DeliveryFeedback.fromJson(json['delivery_feedback'])];
        } else if (json['delivery_feedback'] != null && json['delivery_feedback'] is List) {
          deliveryFeedback = (json['delivery_feedback'] as List)
              .map((v) => DeliveryFeedback.fromJson(v as Map<String, dynamic>))
              .toList();
        } else {
          deliveryFeedback = <DeliveryFeedback>[];
        }
    walletBalance = json['wallet_balance'];
    promoCode = json['promo_code'];
    promoDiscount = json['promo_discount'];
    giftCard = json['gift_card'];
    giftCardDiscount = json['gift_card_discount'];
    deliveryCharge = json['delivery_charge'];
    handlingCharges = json['handling_charges'];
    perStoreDropOffFee = json['per_store_drop_off_fee'];
    subtotal = json['subtotal'];
    totalPayable = json['total_payable'];
    finalTotal = json['final_total'];
    platformCharge = json['platform_charge']?.toString();
    cgst = json['cgst']?.toString();
    sgst = json['sgst']?.toString();
    shippingName = json['shipping_name'];
    shippingAddress1 = json['shipping_address_1'];
    shippingAddress2 = json['shipping_address_2'];
    shippingLandmark = json['shipping_landmark'];
    shippingZip = json['shipping_zip'];
    shippingPhone = json['shipping_phone'];
    shippingAddressType = json['shipping_address_type'];
    shippingLatitude = json['shipping_latitude'];
    shippingLongitude = json['shipping_longitude'];
    shippingCity = json['shipping_city'];
    shippingState = json['shipping_state'];
    shippingCountry = json['shipping_country'];
    shippingCountryCode = json['shipping_country_code'];
    orderNote = json['order_note'];
    if (json['items'] != null) {
      items = <OrderItems>[];
      json['items'].forEach((v) {
        items!.add(OrderItems.fromJson(v));
      });
    }
    if (json['seller_feedbacks'] != null) {
      sellerFeedbacks = <SellerFeedbacks>[];
      json['seller_feedbacks'].forEach((v) {
        sellerFeedbacks!.add(SellerFeedbacks.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    coinsEarned = json['coins_earned'];
    proofOfQualityVideo = json['proof_of_quality_video'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['slug'] = slug;
    data['user_id'] = userId;
    data['email'] = email;
    data['currency_code'] = currencyCode;
    data['currency_rate'] = currencyRate;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['status'] = status;
    data['invoice'] = invoice;
    data['fulfillment_type'] = fulfillmentType;
    data['estimated_delivery_time'] = estimatedDeliveryTime;
    data['delivery_time_slot_id'] = deliveryTimeSlotId;
    data['delivery_boy_id'] = deliveryBoyId;
    data['delivery_boy_name'] = deliveryBoyName;
    data['delivery_boy_phone'] = deliveryBoyPhone;
    data['delivery_boy_profile'] = deliveryBoyProfile;
    data['is_delivery_feedback_given'] = isDeliveryFeedbackGiven;
    if (deliveryFeedback != null) {
      data['delivery_feedback'] = deliveryFeedback!.toString();
    }
    data['wallet_balance'] = walletBalance;
    data['promo_code'] = promoCode;
    data['promo_discount'] = promoDiscount;
    data['gift_card'] = giftCard;
    data['gift_card_discount'] = giftCardDiscount;
    data['delivery_charge'] = deliveryCharge;
    data['handling_charges'] = handlingCharges;
    data['per_store_drop_off_fee'] =  perStoreDropOffFee;
    data['subtotal'] = subtotal;
    data['total_payable'] = totalPayable;
    data['final_total'] = finalTotal;
    data['platform_charge'] = platformCharge;
    data['cgst'] = cgst;
    data['sgst'] = sgst;
    data['shipping_name'] = shippingName;
    data['shipping_address_1'] = shippingAddress1;
    data['shipping_address_2'] = shippingAddress2;
    data['shipping_landmark'] = shippingLandmark;
    data['shipping_zip'] = shippingZip;
    data['shipping_phone'] = shippingPhone;
    data['shipping_address_type'] = shippingAddressType;
    data['shipping_latitude'] = shippingLatitude;
    data['shipping_longitude'] = shippingLongitude;
    data['shipping_city'] = shippingCity;
    data['shipping_state'] = shippingState;
    data['shipping_country'] = shippingCountry;
    data['shipping_country_code'] = shippingCountryCode;
    data['order_note'] = orderNote;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (sellerFeedbacks != null) {
      data['seller_feedbacks'] =
          sellerFeedbacks!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['coins_earned'] = coinsEarned;
    data['proof_of_quality_video'] = proofOfQualityVideo;
    return data;
  }
}


class DeliveryFeedback {
  final int? id;
  final String? title;
  final String? slug;
  final String? description;
  final int? rating;
  final String? createdAt;

  DeliveryFeedback({
    this.id,
    this.title,
    this.slug,
    this.description,
    this.rating,
    this.createdAt,
  });

  factory DeliveryFeedback.fromJson(Map<String, dynamic> json) {
    return DeliveryFeedback(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      description: json['description'],
      rating: json['rating'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'rating': rating,
      'created_at': createdAt,
    };
  }
}

class SellerFeedbacks {
  int? sellerId;
  bool? isFeedbackGiven;
  SellerFeedbackData? feedback;

  SellerFeedbacks({this.sellerId, this.isFeedbackGiven, this.feedback});

  SellerFeedbacks.fromJson(Map<String, dynamic> json) {
    sellerId = json['seller_id'];
    isFeedbackGiven = json['is_feedback_given'];
    if (json['feedback'] is Map<String, dynamic>) {
      feedback = SellerFeedbackData.fromJson(json['feedback']);
    } else {
      feedback = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['seller_id'] = sellerId;
    data['is_feedback_given'] = isFeedbackGiven;
    if (feedback != null) {
      data['feedback'] = feedback!.toJson();
    }
    return data;
  }
}

class SellerFeedbackData {
  int? id;
  int? userId;
  int? sellerId;
  int? orderId;
  int? orderItemId;
  int? storeId;
  int? rating;
  String? title;
  String? slug;
  String? description;
  String? createdAt;
  String? updatedAt;

  SellerFeedbackData(
      {this.id,
        this.userId,
        this.sellerId,
        this.orderId,
        this.orderItemId,
        this.storeId,
        this.rating,
        this.title,
        this.slug,
        this.description,
        this.createdAt,
        this.updatedAt});

  SellerFeedbackData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    sellerId = json['seller_id'];
    orderId = json['order_id'];
    orderItemId = json['order_item_id'];
    storeId = json['store_id'];
    rating = json['rating'];
    title = json['title'];
    slug = json['slug'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['seller_id'] = sellerId;
    data['order_id'] = orderId;
    data['order_item_id'] = orderItemId;
    data['store_id'] = storeId;
    data['rating'] = rating;
    data['title'] = title;
    data['slug'] = slug;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}



class OrderItems {
  int? id;
  int? orderId;
  int? productId;
  int? productVariantId;
  int? storeId;
  int? sellerId;
  String? title;
  String? variantTitle;
  String? giftCardDiscount;
  String? adminCommissionAmount;
  String? sellerCommissionAmount;
  String? commissionSettled;
  String? discountedPrice;
  String? promoDiscount;
  String? discount;
  String? taxAmount;
  String? taxPercent;
  String? sku;
  int? quantity;
  String? price;
  String? subtotal;
  String? status;
  String? otp;
  int? otpVerified;
  bool? isUserReviewGiven;
  UserReview? userReview;
  OrderDetailProduct? product;
  OrderDetailVariant? variant;
  Store? store;
  List<ItemReturnsData>? returns;
  String? createdAt;
  String? updatedAt;

  OrderItems(
      {this.id,
        this.orderId,
        this.productId,
        this.productVariantId,
        this.storeId,
        this.sellerId,
        this.title,
        this.variantTitle,
        this.giftCardDiscount,
        this.adminCommissionAmount,
        this.sellerCommissionAmount,
        this.commissionSettled,
        this.discountedPrice,
        this.promoDiscount,
        this.discount,
        this.taxAmount,
        this.taxPercent,
        this.sku,
        this.quantity,
        this.price,
        this.subtotal,
        this.status,
        this.otp,
        this.otpVerified,
        this.isUserReviewGiven,
        this.userReview,
        this.product,
        this.variant,
        this.store,
        this.createdAt,
        this.updatedAt});

  OrderItems.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse('${json['id']}');
    orderId = json['order_id'] is int ? json['order_id'] : int.tryParse('${json['order_id']}');
    productId = json['product_id'] is int ? json['product_id'] : int.tryParse('${json['product_id']}');
    productVariantId = json['product_variant_id'] is int ? json['product_variant_id'] : int.tryParse('${json['product_variant_id']}');
    storeId = json['store_id'] is int ? json['store_id'] : int.tryParse('${json['store_id']}');
    sellerId = json['seller_id'] is int ? json['seller_id'] : int.tryParse('${json['seller_id']}');
    title = json['title']?.toString();
    variantTitle = json['variant_title']?.toString();
    giftCardDiscount = json['gift_card_discount']?.toString();
    adminCommissionAmount = json['admin_commission_amount']?.toString();
    sellerCommissionAmount = json['seller_commission_amount']?.toString();
    commissionSettled = json['commission_settled']?.toString();
    discountedPrice = json['discounted_price']?.toString();
    promoDiscount = json['promo_discount']?.toString();
    discount = json['discount']?.toString();
    taxAmount = json['tax_amount']?.toString();
    taxPercent = json['tax_percent']?.toString();
    sku = json['sku']?.toString();
    quantity = json['quantity'] is int ? json['quantity'] : int.tryParse('${json['quantity']}');
    price = json['price']?.toString();
    subtotal = json['subtotal']?.toString();
    status = json['status']?.toString();
    otp = json['otp']?.toString();
    otpVerified = json['otp_verified'] is int ? json['otp_verified'] : int.tryParse('${json['otp_verified']}');
    if (json['is_user_review_given'] is bool) {
      isUserReviewGiven = json['is_user_review_given'];
    } else if (json['is_user_review_given'] != null) {
      isUserReviewGiven = json['is_user_review_given'].toString() == '1';
    } else {
      isUserReviewGiven = null;
    }
    if (json['user_review'] != null && json['user_review'] is Map<String, dynamic>) {
      userReview = UserReview.fromJson(json['user_review']);
    } else {
      userReview = null;
    }
    product =
    json['product'] != null ? OrderDetailProduct.fromJson(json['product']) : null;
    variant =
    json['variant'] != null ? OrderDetailVariant.fromJson(json['variant']) : null;
    store = json['store'] != null ? Store.fromJson(json['store']) : null;
    if (json['returns'] != null && json['returns'] is List) {
      returns = (json['returns'] as List)
          .map((v) => ItemReturnsData.fromJson(v as Map<String, dynamic>))
          .toList();
    } else {
      returns = null;
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['product_id'] = productId;
    data['product_variant_id'] = productVariantId;
    data['store_id'] = storeId;
    data['seller_id'] = sellerId;
    data['title'] = title;
    data['variant_title'] = variantTitle;
    data['gift_card_discount'] = giftCardDiscount;
    data['admin_commission_amount'] = adminCommissionAmount;
    data['seller_commission_amount'] = sellerCommissionAmount;
    data['commission_settled'] = commissionSettled;
    data['discounted_price'] = discountedPrice;
    data['promo_discount'] = promoDiscount;
    data['discount'] = discount;
    data['tax_amount'] = taxAmount;
    data['tax_percent'] = taxPercent;
    data['sku'] = sku;
    data['quantity'] = quantity;
    data['price'] = price;
    data['subtotal'] = subtotal;
    data['status'] = status;
    data['otp'] = otp;
    data['otp_verified'] = otpVerified;
    data['is_user_review_given'] = isUserReviewGiven;
    if (userReview != null) {
      data['user_review'] = userReview!.toJson();
    }
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (variant != null) {
      data['variant'] = variant!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }

    if (returns != null) {
      data['returns'] = returns!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class OrderDetailProduct {
  int? id;
  String? name;
  String? slug;
  bool? isReturnable;
  int? returnableDays;
  bool? isCancelable;
  String? cancelableTill;
  String? image;
  int? requiresOtp;

  OrderDetailProduct(
      {this.id,
        this.name,
        this.slug,
        this.isReturnable,
        this.returnableDays,
        this.isCancelable,
        this.cancelableTill,
        this.image,
        this.requiresOtp});

  OrderDetailProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    isReturnable = json['is_returnable'];
    returnableDays = json['returnable_days'];
    isCancelable = json['is_cancelable'];
    cancelableTill = json['cancelable_till'];
    image = json['image'];
    requiresOtp = json['requires_otp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['is_returnable'] = isReturnable;
    data['returnable_days'] = returnableDays;
    data['is_cancelable'] = isCancelable;
    data['cancelable_till'] = cancelableTill;
    data['image'] = image;
    data['requires_otp'] = requiresOtp;
    return data;
  }
}

class OrderDetailVariant {
  int? id;
  String? title;
  String? slug;
  String? image;

  OrderDetailVariant({this.id, this.title, this.slug, this.image});

  OrderDetailVariant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    slug = json['slug'];
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? slug;

  Store({this.id, this.name, this.slug});

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    return data;
  }
}

class ItemReturnsData {
  int? id;
  int? orderItemId;
  int? orderId;
  int? userId;
  int? sellerId;
  int? storeId;
  String? deliveryBoyId;
  String? reason;
  String? sellerComment;
  List<String>? images;
  int? refundAmount;
  String? pickupStatus;
  String? returnStatus;
  String? sellerApprovedAt;
  String? pickedUpAt;
  String? receivedAt;
  String? refundProcessedAt;
  String? createdAt;
  String? updatedAt;

  ItemReturnsData(
      {this.id,
        this.orderItemId,
        this.orderId,
        this.userId,
        this.sellerId,
        this.storeId,
        this.deliveryBoyId,
        this.reason,
        this.sellerComment,
        this.images,
        this.refundAmount,
        this.pickupStatus,
        this.returnStatus,
        this.sellerApprovedAt,
        this.pickedUpAt,
        this.receivedAt,
        this.refundProcessedAt,
        this.createdAt,
        this.updatedAt});

  ItemReturnsData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderItemId = json['order_item_id'];
    orderId = json['order_id'];
    userId = json['user_id'];
    sellerId = json['seller_id'];
    storeId = json['store_id'];
    deliveryBoyId = json['delivery_boy_id'];
    reason = json['reason'];
    sellerComment = json['seller_comment'];
    images = _parseImagesList(json['images']);
    refundAmount = json['refund_amount'];
    pickupStatus = json['pickup_status'];
    returnStatus = json['return_status'];
    sellerApprovedAt = json['seller_approved_at'];
    pickedUpAt = json['picked_up_at'];
    receivedAt = json['received_at'];
    refundProcessedAt = json['refund_processed_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_item_id'] = orderItemId;
    data['order_id'] = orderId;
    data['user_id'] = userId;
    data['seller_id'] = sellerId;
    data['store_id'] = storeId;
    data['delivery_boy_id'] = deliveryBoyId;
    data['reason'] = reason;
    data['seller_comment'] = sellerComment;
    if (images != null) {
      data['images'] = images!;
    }
    data['refund_amount'] = refundAmount;
    data['pickup_status'] = pickupStatus;
    data['return_status'] = returnStatus;
    data['seller_approved_at'] = sellerApprovedAt;
    data['picked_up_at'] = pickedUpAt;
    data['received_at'] = receivedAt;
    data['refund_processed_at'] = refundProcessedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
  static List<String>? _parseImagesList(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;

    try {
      return raw
          .cast<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      return null;
    }
  }
}



class ReviewVideo {
  String? url;
  String? thumbnail;
  String? duration;

  ReviewVideo({this.url, this.thumbnail, this.duration});

  ReviewVideo.fromJson(Map<String, dynamic> json) {
    url = json['url']?.toString();
    thumbnail = json['thumbnail']?.toString();
    duration = json['duration']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['thumbnail'] = thumbnail;
    data['duration'] = duration;
    return data;
  }
}

class UserReview {
  int? id;
  int? productId;
  int? rating;
  String? title;
  String? slug;
  String? comment;
  List<String>? reviewImages;
  List<ReviewVideo>? reviewVideos;
  User? user;
  String? createdAt;

  UserReview(
      {this.id,
        this.productId,
        this.rating,
        this.title,
        this.slug,
        this.comment,
        this.reviewImages,
        this.reviewVideos,
        this.user,
        this.createdAt});

  UserReview.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse('${json['id']}');
    productId = json['product_id'] is int ? json['product_id'] : int.tryParse('${json['product_id']}');
    rating = json['rating'] is int ? json['rating'] : int.tryParse('${json['rating']}');
    title = json['title']?.toString();
    slug = json['slug']?.toString();
    comment = json['comment']?.toString();
    reviewImages = json['review_images'] != null
        ? List<String>.from(json['review_images'].map((e) => e.toString()))
        : [];
    if (json['review_videos'] != null) {
      reviewVideos = <ReviewVideo>[];
      json['review_videos'].forEach((v) {
        reviewVideos!.add(ReviewVideo.fromJson(v));
      });
    } else {
      reviewVideos = [];
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['rating'] = rating;
    data['title'] = title;
    data['slug'] = slug;
    data['comment'] = comment;
    data['review_images'] = reviewImages;
    if (reviewVideos != null) {
      data['review_videos'] = reviewVideos!.map((v) => v.toJson()).toList();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['created_at'] = createdAt;
    return data;
  }
}

class User {
  int? id;
  String? name;

  User({this.id, this.name});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}