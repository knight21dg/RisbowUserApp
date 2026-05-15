
import 'dart:developer' as developer;

import '../../home_page/model/featured_section_product_model.dart';

class ProductDetailModel {
  late bool success;
  late String message;
  ProductData? data;

  ProductDetailModel({
    bool? success,
    String? message,
    this.data,
  }) {
    this.success = success ?? false;
    this.message = message ?? '';
  }

  ProductDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      success = json['success'] ?? false;
      message = json['message'] ?? '';
      data = json['data'] != null
          ? ProductData.fromJson(json['data'] as Map<String, dynamic>)
          : null;
    } catch (e, stackTrace) {
      developer.log('Error parsing ProductDetailModel: $e', stackTrace: stackTrace);
      success = false;
      message = 'Failed to parse product data';
      data = null;
    }
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

class ProductData {
  late int id;
  late int categoryId;
  late int brandId;
  late int sellerId;
  late String title;
  late String slug;
  late String type;
  late String shortDescription;
  late String description;
  late String category;
  late String brand;
  late String seller;
  late String indicator;
  List<FavoriteItem>? favorite;
  late String estimatedDeliveryTime;
  late dynamic ratings;
  late int ratingCount;
  late String mainImage;
  late String imageFit;
  late List<String> additionalImages;
  late int minimumOrderQuantity;
  late int quantityStepSize;
  late int totalAllowedQuantity;
  late int isReturnable;
  late List<String> tags;
  late String warrantyPeriod;
  late String guaranteePeriod;
  late String madeIn;
  late String isInclusiveTax;
  late String videoType;
  late String videoLink;
  late String status;
  late String featured;
  late String metadata;
  late String createdAt;
  late String updatedAt;
  StoreStatus? storeStatus;
  late List<ProductVariants> variants;
  late List<ProductAttributes> attributes;
  // Store API fields
  late double price;
  late double specialPrice;
  late double mrp;
  late double discountAmount;
  late double finalAmount;
  late double cost;
  late int stock;
  late bool available;
  bool isGroupBuyEligible = false;
  double groupBuyPrice = 0.0;

  ProductData({
    int? id,
    int? categoryId,
    int? brandId,
    int? sellerId,
    String? title,
    String? slug,
    double? price,
    double? specialPrice,
    double? mrp,
    double? discountAmount,
    double? finalAmount,
    double? cost,
    int? stock,
    bool? available,
    String? type,
    String? shortDescription,
    String? description,
    String? category,
    String? brand,
    String? seller,
    String? indicator,
    List<FavoriteItem>? favorite,
    String? estimatedDeliveryTime,
    double? ratings,
    int? ratingCount,
    String? mainImage,
    String? imageFit,
    List<String>? additionalImages,
    int? minimumOrderQuantity,
    int? quantityStepSize,
    int? totalAllowedQuantity,
    int? isReturnable,
    List<String>? tags,
    String? warrantyPeriod,
    String? guaranteePeriod,
    String? madeIn,
    String? isInclusiveTax,
    String? videoType,
    String? videoLink,
    String? status,
    String? featured,
    String? metadata,
    String? createdAt,
    String? updatedAt,
    this.storeStatus,
    List<ProductVariants>? variants,
    List<ProductAttributes>? attributes,
  })
  {
    // Initialize all late fields in constructor body
    this.id = id ?? 0;
    this.categoryId = categoryId ?? 0;
    this.brandId = brandId ?? 0;
    this.sellerId = sellerId ?? 0;
    this.title = title ?? '';
    this.slug = slug ?? '';
    this.type = type ?? '';
    this.shortDescription = shortDescription ?? '';
    this.description = description ?? '';
    this.category = category ?? '';
    this.brand = brand ?? '';
    this.seller = seller ?? '';
    this.indicator = indicator ?? '';
    this.favorite;
    this.estimatedDeliveryTime = estimatedDeliveryTime ?? '';
    this.ratings = ratings ?? 0.0;
    this.ratingCount = ratingCount ?? 0;
    this.mainImage = mainImage ?? '';
    this.imageFit = imageFit ?? '';
    this.additionalImages = additionalImages ?? [];
    this.minimumOrderQuantity = minimumOrderQuantity ?? 0;
    this.quantityStepSize = quantityStepSize ?? 1;
    this.totalAllowedQuantity = totalAllowedQuantity ?? 0;
    this.isReturnable = isReturnable ?? 0;
    this.tags = tags ?? [];
    this.warrantyPeriod = warrantyPeriod ?? '';
    this.guaranteePeriod = guaranteePeriod ?? '';
    this.madeIn = madeIn ?? '';
    this.isInclusiveTax = isInclusiveTax ?? '';
    this.videoType = videoType ?? '';
    this.videoLink = videoLink ?? '';
    this.status = status ?? '';
    this.featured = featured ?? '';
    this.metadata = metadata ?? '';
    this.createdAt = createdAt ?? '';
    this.updatedAt = updatedAt ?? '';
    this.variants = variants ?? [];
    this.attributes = attributes ?? [];
    this.isGroupBuyEligible = false;
    this.groupBuyPrice = 0.0;
  }

  ProductData.fromJson(Map<String, dynamic> json) {
    try {
      developer.log('ProductData.fromJson: parsing JSON with keys: ${json.keys.toList()}');
      
      id = json['id'] ?? 0;
      categoryId = json['category_id'] ?? 0;
      brandId = json['brand_id'] ?? 0;
      sellerId = json['seller_id'] ?? 0;
      title = json['title']?.toString() ?? '';
      slug = json['slug']?.toString() ?? json['product_slug']?.toString() ?? '';
      type = json['type']?.toString() ?? '';
      shortDescription = json['shortDescription']?.toString() ?? json['short_description']?.toString() ?? '';
      description = json['description']?.toString() ?? '';
      category = json['category']?.toString() ?? json['category_name']?.toString() ?? json['category_title']?.toString() ?? '';
      brand = json['brand']?.toString() ?? json['brand_name']?.toString() ?? json['brand_title']?.toString() ?? '';
      seller = json['seller']?.toString() ?? '';
      indicator = json['indicator']?.toString() ?? '';
      if (json['favorite'] != null) {
        favorite = <FavoriteItem>[];
        json['favorite'].forEach((v) {
          favorite!.add(FavoriteItem.fromJson(v));
        });
      } else {
        favorite = null;
      }
      estimatedDeliveryTime = json['estimated_delivery_time']?.toString() ?? '';
      ratings = double.tryParse(json['ratings']?.toString() ?? '0') ?? 0;
      ratingCount = json['rating_count'] is double ? json['rating_count'].toInt() : (json['rating_count'] ?? 0);
      mainImage = json['main_image']?.toString() ?? json['image']?.toString() ?? '';
      imageFit = json['image_fit']?.toString() ?? json['imageFit']?.toString() ?? 'cover';
      
      // Handle potentially null lists with safe defaults
      additionalImages = json['additional_images'] != null
          ? List<String>.from(json['additional_images'])
          : [];

      minimumOrderQuantity = json['minimum_order_quantity'] ?? 0;
      quantityStepSize = json['quantity_step_size'] ?? 1;
      totalAllowedQuantity = json['total_allowed_quantity'] ?? 0;
      isReturnable = json['is_returnable'] ?? 0;

      // Handle tags - can be String or List
      if (json['tags'] != null) {
        if (json['tags'] is String) {
          tags = json['tags'].toString().split(',').map((e) => e.trim()).toList();
        } else if (json['tags'] is List) {
          tags = List<String>.from(json['tags']);
        } else {
          tags = [];
        }
      } else {
        tags = [];
      }

      warrantyPeriod = json['warranty_period'] ?? '';
      guaranteePeriod = json['guarantee_period'] ?? '';
      madeIn = json['made_in'] ?? '';
      isInclusiveTax = json['is_inclusive_tax'] ?? '';
      videoType = json['video_type'] ?? '';
      videoLink = json['video_link'] ?? '';
      status = json['status'] ?? '';
      featured = json['featured'] ?? '';
      metadata = json['metadata'] ?? '';
      createdAt = json['created_at'] ?? '';
      updatedAt = json['updated_at'] ?? '';

      // Parse top-level price fields (from store products API)
      print('DEBUG: Parsing price - json[price]=${json['price']}, json[specialPrice]=${json['specialPrice']}, json[special_price]=${json['special_price']}');
      price = (json['price'] ?? 0).toDouble();
      specialPrice = (json['specialPrice'] ?? json['special_price'] ?? json['price'] ?? 0).toDouble();
      mrp = (json['mrp'] ?? json['price'] ?? 0).toDouble();
      discountAmount = (json['discount_amount'] ?? 0).toDouble();
      finalAmount = (json['final_amount'] ?? json['special_price'] ?? json['price'] ?? 0).toDouble();
      cost = (json['cost'] ?? 0).toDouble();
      stock = (json['stock'] ?? 0).toInt();
      print('DEBUG: Before variant check - price=$price, specialPrice=$specialPrice, mrp=$mrp, stock=$stock');

      // Initialize variants and attributes with defaults first
      variants = [];
      attributes = [];
      
      // Now safely parse the rest
      try {
        storeStatus = json['store_status'] != null
            ? StoreStatus.fromJson(json['store_status'] as Map<String, dynamic>)
            : null;

        variants = json['variants'] != null
            ? (json['variants'] as List)
            .map((v) => ProductVariants.fromJson(v as Map<String, dynamic>))
            .toList()
            : [];

        attributes = json['attributes'] != null
            ? (json['attributes'] as List)
            .map((v) => ProductAttributes.fromJson(v as Map<String, dynamic>))
            .toList()
            : [];
        
        // If top level price is 0 but variants have price, use variant price
        if (price == 0 && variants.isNotEmpty) {
          final firstVariant = variants.first;
          print('DEBUG: Using variant price - variant.price=${firstVariant.price}, variant.specialPrice=${firstVariant.specialPrice}, variant.mrp=${firstVariant.mrp}, variant.stock=${firstVariant.stock}');
          price = firstVariant.price > 0 ? firstVariant.price.toDouble() : 0;
          specialPrice = firstVariant.specialPrice > 0 ? firstVariant.specialPrice.toDouble() : price;
          mrp = firstVariant.mrp > 0 ? firstVariant.mrp.toDouble() : price;
          discountAmount = firstVariant.discountAmount.toDouble();
          finalAmount = firstVariant.finalAmount > 0 ? firstVariant.finalAmount.toDouble() : price;
          cost = firstVariant.cost.toDouble();
          stock = firstVariant.stock;
        }
        print('DEBUG: Final - price=$price, specialPrice=$specialPrice, mrp=$mrp, finalAmount=$finalAmount, stock=$stock');
        available = json['available'] ?? true;
        isGroupBuyEligible = json['is_group_buy_eligible'] ?? false;
        groupBuyPrice = (json['group_buy_price'] ?? 0).toDouble();
      } catch (e2) {
        developer.log('Error in second parse block: $e2');
        // Use defaults
        price = 0;
        specialPrice = 0;
        stock = 0;
        available = true;
      }
    } catch (e, stackTrace) {
      developer.log('Error parsing ProductData: $e', stackTrace: stackTrace);
      developer.log('Error parsing ProductData JSON: $json');
      // Set all properties to safe defaults in case of error
      _initializeDefaults();
    }
  }

  void _initializeDefaults() {
    id = 0;
    categoryId = 0;
    brandId = 0;
    sellerId = 0;
    title = '';
    slug = '';
    type = '';
    shortDescription = '';
    description = '';
    category = '';
    brand = '';
    seller = '';
    indicator = '';
    favorite = [];
    estimatedDeliveryTime = '';
    ratings = 0;
    ratingCount = 0;
    mainImage = '';
    imageFit = '';
    additionalImages = [];
    minimumOrderQuantity = 0;
    quantityStepSize = 1;
    totalAllowedQuantity = 0;
    isReturnable = 0;
    tags = [];
    warrantyPeriod = '';
    guaranteePeriod = '';
    madeIn = '';
    isInclusiveTax = '';
    videoType = '';
    videoLink = '';
    status = '';
    featured = '';
    metadata = '';
    createdAt = '';
    updatedAt = '';
    storeStatus = null;
    variants = [];
    attributes = [];
    isGroupBuyEligible = false;
    groupBuyPrice = 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['category_id'] = categoryId;
    data['brand_id'] = brandId;
    data['seller_id'] = sellerId;
    data['title'] = title;
    data['slug'] = slug;
    data['type'] = type;
    data['short_description'] = shortDescription;
    data['description'] = description;
    data['category'] = category;
    data['brand'] = brand;
    data['seller'] = seller;
    data['indicator'] = indicator;
    if (favorite != null) {
      data['favorite'] = favorite!.map((v) => v.toJson()).toList();
    }
    data['estimated_delivery_time'] = estimatedDeliveryTime.toString();
    data['ratings'] = ratings;
    data['rating_count'] = ratingCount;
    data['main_image'] = mainImage;
    data['image_fit'] = imageFit;
    data['additional_images'] = additionalImages;
    data['minimum_order_quantity'] = minimumOrderQuantity;
    data['quantity_step_size'] = quantityStepSize;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['is_returnable'] = isReturnable;
    data['tags'] = tags;
    data['warranty_period'] = warrantyPeriod;
    data['guarantee_period'] = guaranteePeriod;
    data['made_in'] = madeIn;
    data['is_inclusive_tax'] = isInclusiveTax;
    data['video_type'] = videoType;
    data['video_link'] = videoLink;
    data['status'] = status;
    data['featured'] = featured;
    data['metadata'] = metadata;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (storeStatus != null) {
      data['store_status'] = storeStatus!.toJson();
    }
    data['variants'] = variants.map((v) => v.toJson()).toList();
    data['attributes'] = attributes.map((v) => v.toJson()).toList();
    data['is_group_buy_eligible'] = isGroupBuyEligible;
    data['group_buy_price'] = groupBuyPrice;
    return data;
  }
}

class StoreStatus {
  late bool isOpen;
  CurrentSlot? currentSlot;
  late String nextOpeningTime;

  StoreStatus({
    bool? isOpen,
    this.currentSlot,
    String? nextOpeningTime,
  }) {
    this.isOpen = isOpen ?? false;
    this.nextOpeningTime = nextOpeningTime ?? '';
  }

  StoreStatus.fromJson(Map<String, dynamic> json) {
    try {
      isOpen = json['is_open'] ?? false;
      currentSlot = json['current_slot'] != null
          ? CurrentSlot.fromJson(json['current_slot'] as Map<String, dynamic>)
          : null;
      nextOpeningTime = json['next_opening_time'] ?? '';
    } catch (e, stackTrace) {
      developer.log('Error parsing StoreStatus: $e', stackTrace: stackTrace);
      isOpen = false;
      currentSlot = null;
      nextOpeningTime = '';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    if (currentSlot != null) {
      data['current_slot'] = currentSlot!.toJson();
    }
    data['next_opening_time'] = nextOpeningTime;
    return data;
  }
}

class CurrentSlot {
  late String from;
  late String to;

  CurrentSlot({
    String? from,
    String? to,
  }) {
    this.from = from ?? '';
    this.to = to ?? '';
  }

  CurrentSlot.fromJson(Map<String, dynamic> json) {
    try {
      from = json['from'] ?? '';
      to = json['to'] ?? '';
    } catch (e, stackTrace) {
      developer.log('Error parsing CurrentSlot: $e', stackTrace: stackTrace);
      from = '';
      to = '';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['from'] = from;
    data['to'] = to;
    return data;
  }
}

class ProductVariants {
  late int id;
  late String title;
  late String slug;
  late String image;
  late int weight;
  late int height;
  late int breadth;
  late int length;
  late bool availability;
  late String barcode;
  late bool isDefault;
  late int price;
  late int specialPrice;
  late double mrp;
  late double discountAmount;
  late double finalAmount;
  late double cost;
  late int storeId;
  late String storeSlug;
  late String storeName;
  late int stock;
  late String sku;
  late bool isGroupBuyEnabled;
  late int groupBuyPrice;
  late Map<String, dynamic> attributes;

  ProductVariants({
    int? id,
    String? title,
    String? slug,
    String? image,
    int? weight,
    int? height,
    int? breadth,
    int? length,
    bool? availability,
    String? barcode,
    bool? isDefault,
    int? price,
    int? specialPrice,
    double? mrp,
    double? discountAmount,
    double? finalAmount,
    double? cost,
    int? storeId,
    String? storeSlug,
    String? storeName,
    int? stock,
    String? sku,
    Map<String, dynamic>? attributes,
  }) {
    this.id = id ?? 0;
    this.title = title ?? '';
    this.slug = slug ?? '';
    this.image = image ?? '';
    this.weight = weight ?? 0;
    this.height = height ?? 0;
    this.breadth = breadth ?? 0;
    this.length = length ?? 0;
    this.availability = availability ?? false;
    this.barcode = barcode ?? '';
    this.isDefault = isDefault ?? false;
    this.price = price ?? 0;
    this.specialPrice = specialPrice ?? 0;
    this.mrp = mrp ?? 0;
    this.discountAmount = discountAmount ?? 0;
    this.finalAmount = finalAmount ?? 0;
    this.cost = cost ?? 0;
    this.storeId = storeId ?? 0;
    this.storeSlug = storeSlug ?? '';
    this.storeName = storeName ?? '';
    this.stock = stock ?? 0;
    this.sku = sku ?? '';
    this.isGroupBuyEnabled = false;
    this.groupBuyPrice = 0;
    this.attributes = attributes ?? {};
  }

  ProductVariants.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    title = json['title'] ?? '';
    slug = json['slug'] ?? '';
    image = json['image'] ?? '';
    weight = json['weight'] ?? 0;
    height = json['height'] ?? 0;
    breadth = json['breadth'] ?? 0;
    length = json['length'] ?? 0;
    availability = json['availability'] ?? false;
    barcode = json['barcode'] ?? '';
    isDefault = json['is_default'] ?? false;
    price = json['price'] ?? 0;
    specialPrice = json['special_price'] ?? 0;
    mrp = (json['mrp'] ?? json['price'] ?? 0).toDouble();
    discountAmount = (json['discount_amount'] ?? 0).toDouble();
    finalAmount = (json['final_amount'] ?? json['special_price'] ?? json['price'] ?? 0).toDouble();
    cost = (json['cost'] ?? 0).toDouble();
    storeId = json['store_id'] ?? 0;
    storeSlug = json['store_slug'] ?? '';
    storeName = json['store_name'] ?? '';
    stock = json['stock'] ?? 0;
    sku = json['sku'] ?? '';
    isGroupBuyEnabled = json['is_group_buy_enabled'] ?? false;
    groupBuyPrice = json['group_buy_price'] ?? 0;
    
    // Dynamic attributes
    if (json['attributes'] is Map) {
      attributes = Map<String, dynamic>.from(json['attributes']);
    } else if (json['attributes'] is List) {
      // Convert list → map or keep empty
      attributes = {};
    } else {
      attributes = {};
    }

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['weight'] = weight;
    data['height'] = height;
    data['breadth'] = breadth;
    data['length'] = length;
    data['availability'] = availability;
    data['barcode'] = barcode;
    data['is_default'] = isDefault;
    data['price'] = price;
    data['special_price'] = specialPrice;
    data['store_id'] = storeId;
    data['store_slug'] = storeSlug;
    data['store_name'] = storeName;
    data['stock'] = stock;
    data['sku'] = sku;
    data['is_group_buy_enabled'] = isGroupBuyEnabled;
    data['group_buy_price'] = groupBuyPrice;
    data['attributes'] = attributes;
    return data;
  }
}

class ProductAttributes {
  late String name;
  late String slug;
  late String swatcheType;
  late List<String> values;
  late List<SwatchValues> swatchValues;

  ProductAttributes({
    String? name,
    String? slug,
    String? swatcheType,
    List<String>? values,
    List<SwatchValues>? swatchValues,
  }) {
    this.name = name ?? '';
    this.slug = slug ?? '';
    this.swatcheType = swatcheType ?? '';
    this.values = values ?? [];
    this.swatchValues = swatchValues ?? [];
  }

  ProductAttributes.fromJson(Map<String, dynamic> json) {
    try {
      name = json['name'] ?? '';
      slug = json['slug'] ?? '';
      swatcheType = json['swatche_type'] ?? '';
      values = json['values'] != null
          ? List<String>.from(json['values'])
          : [];
      swatchValues = json['swatch_values'] != null
          ? (json['swatch_values'] as List)
          .map((v) => SwatchValues.fromJson(v as Map<String, dynamic>))
          .toList()
          : [];
    } catch (e, stackTrace) {
      developer.log('Error parsing ProductAttributes: $e', stackTrace: stackTrace);
      name = '';
      slug = '';
      swatcheType = '';
      values = [];
      swatchValues = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['slug'] = slug;
    data['swatche_type'] = swatcheType;
    data['values'] = values;
    data['swatch_values'] = swatchValues.map((v) => v.toJson()).toList();
    return data;
  }
}

class SwatchValues {
  late String value;
  late String swatch;

  SwatchValues({
    String? value,
    String? swatch,
  }) {
    this.value = value ?? '';
    this.swatch = swatch ?? '';
  }

  SwatchValues.fromJson(Map<String, dynamic> json) {
    try {
      value = json['value'] ?? '';
      swatch = json['swatch'] ?? '';
    } catch (e, stackTrace) {
      developer.log('Error parsing SwatchValues: $e', stackTrace: stackTrace);
      value = '';
      swatch = '';
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['value'] = value;
    data['swatch'] = swatch;
    return data;
  }
}
