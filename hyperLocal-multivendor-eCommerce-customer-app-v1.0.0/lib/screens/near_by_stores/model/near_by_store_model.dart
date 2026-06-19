class NearByStoreModel {
  bool? success;
  String? message;
  Data? data;

  NearByStoreModel({this.success, this.message, this.data});

  NearByStoreModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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

class Data {
  int? currentPage;
  List<StoreData>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
  String? path;
  int? perPage;
  String? prevPageUrl;
  int? to;
  int? total;

  Data({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  Data.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = <StoreData>[];
      json['data'].forEach((v) {
        data!.add(StoreData.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = <Links>[];
      json['links'].forEach((v) {
        links!.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['first_page_url'] = firstPageUrl;
    data['from'] = from;
    data['last_page'] = lastPage;
    data['last_page_url'] = lastPageUrl;
    if (links != null) {
      data['links'] = links!.map((v) => v.toJson()).toList();
    }
    data['next_page_url'] = nextPageUrl;
    data['path'] = path;
    data['per_page'] = perPage;
    data['prev_page_url'] = prevPageUrl;
    data['to'] = to;
    data['total'] = total;
    return data;
  }
}

class StoreData {
  int? id;
  String? name;
  String? slug;
  int? productCount;
  String? description;
  String? contactNumber;
  String? contactEmail;
  String? address;
  String? latitude;
  String? longitude;
  double? distance;
  String? timing;
  String? logo;
  String? banner;
  String? createdAt;
  String? updatedAt;
  String? verificationStatus;
  String? visibilityStatus;
  Status? status;
  String? avgProductsRating;
  List<StoreCategoryData>? categories;
  List<StoreBannerData>? banners;
  bool? isOwner;
  bool? isPromoted;

  StoreData({
    this.id,
    this.name,
    this.slug,
    this.productCount,
    this.description,
    this.contactNumber,
    this.contactEmail,
    this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.timing,
    this.logo,
    this.banner,
    this.createdAt,
    this.updatedAt,
    this.verificationStatus,
    this.visibilityStatus,
    this.status,
    this.avgProductsRating,
    this.categories,
    this.banners,
    this.isOwner,
    this.isPromoted,
  });

  StoreData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    productCount = json['product_count'];
    description = json['description'];
    contactNumber = json['contact_number'];
    contactEmail = json['contact_email'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    distance = json['distance'] != null
        ? double.tryParse(json['distance'].toString())
        : null;
    timing = json['timing'];
    logo = json['logo'];
    banner = json['banner'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    verificationStatus = json['verification_status'];
    visibilityStatus = json['visibility_status'];
    status = json['status'] != null ? Status.fromJson(json['status']) : null;
    avgProductsRating = json['avg_products_rating'];
    isOwner = json['is_owner'];
    isPromoted = json['is_promoted'] ?? json['is_featured'] ?? false;
    if (json['categories'] != null) {
      categories = List<StoreCategoryData>.from(
        json['categories'].map((x) => StoreCategoryData.fromJson(x)),
      );
    }
    if (json['banners'] != null) {
      banners = List<StoreBannerData>.from(
        json['banners'].map((x) => StoreBannerData.fromJson(x)),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['product_count'] = productCount;
    data['description'] = description;
    data['contact_number'] = contactNumber;
    data['contact_email'] = contactEmail;
    data['address'] = address;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['distance'] = distance;
    data['timing'] = timing;
    data['logo'] = logo;
    data['banner'] = banner;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['verification_status'] = verificationStatus;
    data['visibility_status'] = visibilityStatus;
    data['avg_products_rating'] = avgProductsRating;
    data['is_owner'] = isOwner;
    data['is_promoted'] = isPromoted;
    if (status != null) {
      data['status'] = status!.toJson();
    }
    if (categories != null) {
      data['categories'] = categories!.map((x) => x.toJson()).toList();
    }
    return data;
  }
}

class Status {
  bool? isOpen;
  String? status;

  Status({this.isOpen, this.status});

  Status.fromJson(Map<String, dynamic> json) {
    isOpen = json['is_open'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}

class Links {
  String? url;
  String? label;
  bool? active;

  Links({this.url, this.label, this.active});

  Links.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['label'] = label;
    data['active'] = active;
    return data;
  }
}

class StoreCategoryData {
  int? id;
  String? title;
  String? slug;
  String? image;
  int? productCount;
  int? parentId;

  StoreCategoryData({
    this.id,
    this.title,
    this.slug,
    this.image,
    this.productCount,
    this.parentId,
  });

  StoreCategoryData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    slug = json['slug'];
    image = json['image'];
    productCount = json['products_count'] ?? json['product_count'];
    parentId = json['parent_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['product_count'] = productCount;
    data['parent_id'] = parentId;
    return data;
  }
}

class StoreBannerData {
  int? id;
  String? image;
  String? targetUrl;
  String? targetAudience;

  StoreBannerData({this.id, this.image, this.targetUrl, this.targetAudience});

  StoreBannerData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'] ?? json['banner_image'] ?? json['banner'];
    targetUrl = json['target_url'];
    targetAudience = json['target_audience'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['image'] = image;
    data['target_url'] = targetUrl;
    data['target_audience'] = targetAudience;
    return data;
  }
}
