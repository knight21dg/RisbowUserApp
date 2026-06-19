import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hyper_local/config/constant.dart';

class FlashSalesPage extends StatefulWidget {
  const FlashSalesPage({super.key});

  @override
  State<FlashSalesPage> createState() => _FlashSalesPageState();
}

class _FlashSalesPageState extends State<FlashSalesPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.featureSectionProductApi}?limit=30'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final transformed = _transformProducts(data['data']);
          if (transformed.isEmpty) {
            setState(() {
              _hasError = true;
              _errorMessage = 'No flash sales found';
              _isLoading = false;
            });
          } else {
            setState(() {
              _products = transformed;
              _isLoading = false;
            });
          }
        } else {
            setState(() {
              _hasError = true;
              _errorMessage = data['message'] ?? 'Failed to load products';
              _isLoading = false;
            });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }


  List<Map<String, dynamic>> _transformProducts(dynamic data) {
    if (data is List) {
      return data.map((p) => _mapProduct(p)).toList();
    } else if (data is Map) {
      final list = data['products'] ?? data['data'] ?? [];
      if (list is List) return list.map((p) => _mapProduct(p)).toList();
    }
    return [];
  }

  Map<String, dynamic> _mapProduct(dynamic p) {
    final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
    final originalPrice = double.tryParse(p['original_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0;
    final discount = originalPrice > 0 ? ((originalPrice - price) / originalPrice * 100).round() : 0;
    
    return {
      'id': p['id'] ?? p['product_id'] ?? 0,
      'slug': p['slug'] ?? '',
      'name': p['name'] ?? p['product_name'] ?? 'Unknown',
      'image': p['image'] ?? p['thumbnail_image'] ?? p['preview_image'] ?? '',
      'price': price,
      'originalPrice': originalPrice,
      'discount': discount,
      'rating': double.tryParse(p['rating']?.toString() ?? '0') ?? 0,
      'reviews': int.tryParse(p['reviews_count']?.toString() ?? '0') ?? 0,
      'sold': p['sold_count'] ?? 0,
      'stock': p['stock'] ?? 100,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureSettingsService.instance.flashSalesEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text('Flash Sales')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Flash Sales are currently unavailable', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContent();
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(child: Center(child: CustomCircularProgressIndicator())),
      ],
    );
  }

  Widget _buildErrorState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: 16.h),
                  Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text(_errorMessage ?? 'Unable to load deals', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(onPressed: _loadData, icon: Icon(Icons.refresh), label: Text('Try Again')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_off, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text('No deals available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text('Check back later', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 24.h),
                  OutlinedButton.icon(onPressed: _loadData, icon: Icon(Icons.refresh), label: Text('Refresh')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final flashDeals = _products.where((p) => (p['discount'] as int) > 10).toList();
    
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        
        // Flash Deals Section
        if (flashDeals.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.orange, size: 20),
                  SizedBox(width: 8.w),
                  Text('Flash Deals', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                  Spacer(),
                  TextButton(onPressed: () {}, child: Text('See All')),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: flashDeals.length,
                itemBuilder: (context, index) => _buildFlashDealCard(flashDeals[index]),
              ),
            ),
          ),
        ],
        
        // Hot Deals Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.whatshot, color: Colors.red, size: 20),
                SizedBox(width: 8.w),
                Text('Hot Deals', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        
        // Products Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCard(_products[index]),
              childCount: _products.length,
            ),
          ),
        ),
        
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 60.h, left: 16.w, right: 16.w),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                SizedBox(width: 8.w),
                Text('Flash Sales', style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashDealCard(Map<String, dynamic> deal) {
    final sold = deal['sold'] as int? ?? 0;
    final total = deal['stock'] as int? ?? 100;
    final progress = total > 0 ? sold / total : 0.0;

    return GestureDetector(
      onTap: () => context.push('/product-detail?slug=${deal['slug']}'),
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildImage(deal['image'], 100.h),
                  Positioned(
                    top: 8.w, left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4.r)),
                      child: Text('-${deal['discount']}%', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal['name'] ?? '', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    _buildPrice(deal['price'], deal['originalPrice']),
                    SizedBox(height: 8.h),
                    ClipRRect(borderRadius: BorderRadius.circular(4.r), child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(Colors.orange), minHeight: 6.h)),
                    SizedBox(height: 4.h),
                    Text('$sold sold', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => context.push('/product-detail?slug=${product['slug']}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(product['image'], 120.h),
                if ((product['discount'] as int) > 0)
                  Positioned(
                    top: 8.w, left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4.r)),
                      child: Text('-${product['discount']}%', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? '', style: TextStyle(fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4.h),
                  _buildPrice(product['price'], product['originalPrice']),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2.w),
                      Text('${product['rating']}', style: TextStyle(fontSize: 10.sp)),
                      Text(' | ${product['reviews']} sold', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(dynamic url, double height) {
    if (url?.toString().isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: url.toString(),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(height: height, color: Colors.grey[200], child: Center(child: CustomCircularProgressIndicator())),
        errorWidget: (context, url, error) => Container(height: height, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    return Container(height: height, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey));
  }

  Widget _buildPrice(dynamic price, dynamic originalPrice) {
    final p = (price ?? 0).toDouble();
    final op = (originalPrice ?? 0).toDouble();
    return Row(
      children: [
        Text('${AppConstant.currency}${p.toStringAsFixed(2)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        if (op > p) ...[
          SizedBox(width: 4.w),
          Text('${AppConstant.currency}${op.toStringAsFixed(2)}', style: TextStyle(fontSize: 10.sp, decoration: TextDecoration.lineThrough, color: Colors.grey)),
        ],
      ],
    );
  }
}