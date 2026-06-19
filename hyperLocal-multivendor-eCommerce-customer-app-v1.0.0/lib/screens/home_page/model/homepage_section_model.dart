import 'package:flutter/foundation.dart';
import 'package:hyper_local/screens/home_page/model/banner_model.dart';

class HomepageSectionModel {
  final int id;
  final String title;
  final String sectionType;
  final int position;
  final int limit;
  final String? backgroundColor;
  final String? textColor;
  final bool showViewAll;
  final String? viewAllRoute;
  final List<HomepageProduct> products;
  final List<Top>? banners;

  HomepageSectionModel({
    required this.id,
    required this.title,
    required this.sectionType,
    required this.position,
    required this.limit,
    this.backgroundColor,
    this.textColor,
    required this.showViewAll,
    this.viewAllRoute,
    required this.products,
    this.banners,
  });

  factory HomepageSectionModel.fromJson(Map<String, dynamic> json) {
    final sectionType = json['section_type'] ?? '';
    debugPrint('Parsing section: ${json['title']} -> section_type: $sectionType');
    return HomepageSectionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      sectionType: sectionType,
      position: json['position'] ?? 0,
      limit: json['limit'] ?? 10,
      backgroundColor: json['background_color'],
      textColor: json['text_color'],
      showViewAll: json['show_view_all'] ?? true,
      viewAllRoute: json['view_all_route'],
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => HomepageProduct.fromJson(e))
              .toList() ??
          [],
      banners: (json['banners'] as List<dynamic>?)
              ?.map((e) => Top.fromJson(e))
              .toList(),
    );
  }
}

class HomepageProduct {
  final int id;
  final String title;
  final String slug;
  final double price;
  final double mrp;
  final double discountAmount;
  final double finalAmount;
  final double cost;
  final String mainImage;
  final bool isOnSale;
  final int? discountPercent;
  final int? sellerId;
  final int? variantId;

  HomepageProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.price,
    required this.mrp,
    this.discountAmount = 0,
    this.finalAmount = 0,
    this.cost = 0,
    required this.mainImage,
    required this.isOnSale,
    this.discountPercent,
    this.sellerId,
    this.variantId,
  });

  factory HomepageProduct.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? 0).toDouble();
    final mrp = (json['mrp'] ?? json['price'] ?? 0).toDouble();
    final specialPrice = (json['specialPrice'] ?? json['special_price'] ?? json['price'] ?? 0).toDouble();
    final finalAmount = (json['final_amount'] ?? specialPrice ?? price).toDouble();
    final discountAmount = (json['discount_amount'] ?? 0).toDouble();
    final cost = (json['cost'] ?? 0).toDouble();
    
    // Calculate discount percentage if not provided
    int? discountPercent;
    if (mrp > 0 && finalAmount > 0 && mrp > finalAmount) {
      discountPercent = (((mrp - finalAmount) / mrp) * 100).round();
    } else if (json['discount_percent'] != null) {
      discountPercent = json['discount_percent'];
    }
    
    return HomepageProduct(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      price: price,
      mrp: mrp,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      cost: cost,
      mainImage: json['main_image'] ?? '',
      isOnSale: json['is_on_sale'] ?? (mrp > 0 && finalAmount > 0 && mrp > finalAmount),
      discountPercent: discountPercent,
      sellerId: json['seller_id'],
      variantId: json['variants'] != null && (json['variants'] as List).isNotEmpty 
          ? json['variants'][0]['id'] 
          : null,
    );
  }
}