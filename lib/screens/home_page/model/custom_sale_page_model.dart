class CustomSalePageModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? metaTitle;
  final String? metaDescription;
  final String? bannerImage;
  final String? backgroundColor;
  final String? textColor;
  final String? buttonColor;
  final String? buttonTextColor;
  final String? buttonText;
  final String? buttonLink;
  final List<CustomSalePageSectionModel> sections;
  final List<CustomSalePageBannerModel> banners;

  CustomSalePageModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.metaTitle,
    this.metaDescription,
    this.bannerImage,
    this.backgroundColor,
    this.textColor,
    this.buttonColor,
    this.buttonTextColor,
    this.buttonText,
    this.buttonLink,
    this.sections = const [],
    this.banners = const [],
  });

  factory CustomSalePageModel.fromJson(Map<String, dynamic> json) {
    return CustomSalePageModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      bannerImage: json['banner_image'],
      backgroundColor: json['background_color'],
      textColor: json['text_color'],
      buttonColor: json['button_color'],
      buttonTextColor: json['button_text_color'],
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => CustomSalePageSectionModel.fromJson(e))
              .toList() ??
          [],
      banners: (json['banners'] as List<dynamic>?)
              ?.map((e) => CustomSalePageBannerModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CustomSalePageSectionModel {
  final int id;
  final String title;
  final String sectionType;
  final String style;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String layout;
  final int limit;
  final int displayOrder;
  final String? backgroundColor;
  final String? textColor;
  final List<CustomSalePageProduct> products;
  final List<CustomSalePageCategory> categories;
  final List<CustomSalePageStore> stores;

  CustomSalePageSectionModel({
    required this.id,
    required this.title,
    required this.sectionType,
    this.style = 'grid',
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.layout,
    required this.limit,
    this.displayOrder = 0,
    this.backgroundColor,
    this.textColor,
    this.products = const [],
    this.categories = const [],
    this.stores = const [],
  });

  CustomSalePageSectionModel copyWith({
    int? id,
    String? title,
    String? sectionType,
    String? style,
    int? categoryId,
    String? categoryName,
    String? categorySlug,
    String? layout,
    int? limit,
    int? displayOrder,
    String? backgroundColor,
    String? textColor,
    List<CustomSalePageProduct>? products,
    List<CustomSalePageCategory>? categories,
    List<CustomSalePageStore>? stores,
  }) {
    return CustomSalePageSectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sectionType: sectionType ?? this.sectionType,
      style: style ?? this.style,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      layout: layout ?? this.layout,
      limit: limit ?? this.limit,
      displayOrder: displayOrder ?? this.displayOrder,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      stores: stores ?? this.stores,
    );
  }

  factory CustomSalePageSectionModel.fromJson(Map<String, dynamic> json) {
    final sectionType = (json['section_type'] ?? '').toString();
    final productsFromProducts = (json['products'] as List<dynamic>?)
            ?.map((e) => CustomSalePageProduct.fromJson(e))
            .toList() ??
        const <CustomSalePageProduct>[];
    final productsFromItems = (json['items'] as List<dynamic>?)
            ?.where((e) => e is Map<String, dynamic> && (e['type']?.toString() == 'product' || sectionType != 'stores' && sectionType != 'categories_list'))
            .map((e) => CustomSalePageProduct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <CustomSalePageProduct>[];
    final categories = (json['categories'] as List<dynamic>?)
            ?.map((e) => CustomSalePageCategory.fromJson(e))
            .toList() ??
        const <CustomSalePageCategory>[];
    final categoriesFromItems = (json['items'] as List<dynamic>?)
            ?.where((e) => e is Map<String, dynamic> && e['type']?.toString() == 'category')
            .map((e) => CustomSalePageCategory.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <CustomSalePageCategory>[];
    final stores = (json['stores'] as List<dynamic>?)
            ?.map((e) => CustomSalePageStore.fromJson(e))
            .toList() ??
        const <CustomSalePageStore>[];
    final storesFromItems = (json['items'] as List<dynamic>?)
            ?.where((e) => e is Map<String, dynamic> && e['type']?.toString() == 'store')
            .map((e) => CustomSalePageStore.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <CustomSalePageStore>[];

    return CustomSalePageSectionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      sectionType: sectionType,
      style: (json['style'] ?? json['layout'] ?? 'grid').toString(),
      categoryId: json['category']?['id'] ?? json['category_id'],
      categoryName: json['category']?['title'],
      categorySlug: json['category']?['slug'],
      layout: (json['layout'] ?? json['style'] ?? 'grid').toString(),
      limit: json['limit'] ?? 10,
      displayOrder: json['display_order'] ?? 0,
      backgroundColor: json['background_color'],
      textColor: json['text_color'],
      products: productsFromProducts.isNotEmpty ? productsFromProducts : productsFromItems,
      categories: categories.isNotEmpty ? categories : categoriesFromItems,
      stores: stores.isNotEmpty ? stores : storesFromItems,
    );
  }
}

class CustomSalePageProduct {
  final int id;
  final String title;
  final String slug;
  final double price;
  final double? discountPrice;
  final int? discountPercent;
  final String mainImage;
  final double? rating;
  final int? reviewCount;
  final bool isOnSale;
  final bool featured;

  CustomSalePageProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    this.discountPrice,
    this.discountPercent,
    required this.mainImage,
    this.rating,
    this.reviewCount,
    required this.isOnSale,
    required this.featured,
  });

  factory CustomSalePageProduct.fromJson(Map<String, dynamic> json) {
    final price = _toDouble(json['price']);
    final discountPrice = _toDouble(json['discount_price'] ?? json['special_price']);
    return CustomSalePageProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      price: price,
      discountPrice: discountPrice,
      discountPercent: json['discount_percent'],
      mainImage: (json['main_image'] ?? json['image'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      reviewCount: json['review_count'],
      isOnSale: json['is_on_sale'] ?? false,
      featured: json['featured'] ?? false,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CustomSalePageCategory {
  final int id;
  final String title;
  final String slug;
  final String image;

  const CustomSalePageCategory({
    required this.id,
    required this.title,
    required this.slug,
    required this.image,
  });

  factory CustomSalePageCategory.fromJson(Map<String, dynamic> json) {
    return CustomSalePageCategory(
      id: json['id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      image: (json['image'] ?? json['main_image'] ?? '').toString(),
    );
  }
}

class CustomSalePageStore {
  final int id;
  final String title;
  final String slug;
  final String image;
  final String banner;
  final double rating;
  final bool isOnline;
  final String address;

  const CustomSalePageStore({
    required this.id,
    required this.title,
    required this.slug,
    required this.image,
    required this.banner,
    required this.rating,
    required this.isOnline,
    required this.address,
  });

  factory CustomSalePageStore.fromJson(Map<String, dynamic> json) {
    return CustomSalePageStore(
      id: json['id'] ?? 0,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      banner: (json['banner'] ?? '').toString(),
      rating: CustomSalePageProduct._toDouble(json['rating']),
      isOnline: json['is_online'] == true,
      address: (json['address'] ?? '').toString(),
    );
  }
}

class CustomSalePageBannerModel {
  final int id;
  final String? title;
  final String image;
  final String? link;
  final String? linkType;

  CustomSalePageBannerModel({
    required this.id,
    this.title,
    required this.image,
    this.link,
    this.linkType,
  });

  factory CustomSalePageBannerModel.fromJson(Map<String, dynamic> json) {
    return CustomSalePageBannerModel(
      id: json['id'] ?? 0,
      title: json['title'],
      image: json['image'] ?? '',
      link: json['link'],
      linkType: json['link_type'],
    );
  }
}

class CustomSalePageListItem {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? bannerImage;
  final String? buttonText;
  final String? buttonLink;
  final String? buttonColor;
  final String? buttonTextColor;
  final int displayOrder;
  final bool isFeatured;
  final bool isScheduled;
  final bool showInFooter;
  final DateTime? startsAt;
  final DateTime? endsAt;

  CustomSalePageListItem({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.bannerImage,
    this.buttonText,
    this.buttonLink,
    this.buttonColor,
    this.buttonTextColor,
    required this.displayOrder,
    this.isFeatured = false,
    this.isScheduled = false,
    this.showInFooter = false,
    this.startsAt,
    this.endsAt,
  });

  factory CustomSalePageListItem.fromJson(Map<String, dynamic> json) {
    return CustomSalePageListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      bannerImage: json['banner_image'],
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
      buttonColor: json['button_color'],
      buttonTextColor: json['button_text_color'],
      displayOrder: json['display_order'] ?? 0,
      isFeatured: json['is_featured'] == true,
      isScheduled: json['is_scheduled'] == true,
      showInFooter: json['show_in_footer'] == true,
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at']) : null,
    );
  }
}
