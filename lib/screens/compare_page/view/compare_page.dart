import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/services/feature_settings_service.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/api_routes.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _availableProducts = [];
  static const int _maxProducts = 4;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableProducts();
  }

  bool get _canAddMore => _products.length < _maxProducts;

  Future<void> _loadAvailableProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiRoutes.searchApi}?limit=50&page=1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> productsList = [];
          
          if (data['data'] is List) {
            productsList = data['data'];
          } else if (data['data'] is Map) {
            productsList = data['data']['products'] ?? data['data']['data'] ?? [];
          }

          if (productsList.isEmpty) {
            setState(() {
              _availableProducts.clear();
              _isLoading = false;
            });
          } else {
            setState(() {
              _availableProducts.addAll(List<Map<String, dynamic>>.from(
                productsList.map((p) => _mapProduct(p)),
              ));
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
      } else if (response.statusCode == 401) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Please login to view products';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
      debugPrint('Client error: $e');
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading products: $e');
    }
  }

  Map<String, dynamic> _mapProduct(dynamic p) {
    return {
      'id': p['id'] ?? p['product_id'] ?? 0,
      'name': p['name'] ?? p['product_name'] ?? 'Unknown Product',
      'image': p['image'] ?? p['thumbnail_image'] ?? p['preview_image'] ?? '',
      'price': double.tryParse(p['price']?.toString() ?? '0') ?? 0,
      'originalPrice': double.tryParse(p['original_price']?.toString() ?? p['price']?.toString() ?? '0') ?? 0,
      'rating': double.tryParse(p['rating']?.toString() ?? '0') ?? 0,
      'reviews': int.tryParse(p['reviews_count']?.toString() ?? p['review_count']?.toString() ?? '0') ?? 0,
      'brand': p['brand'] ?? p['brand_name'] ?? '',
      'specs': _extractSpecs(p),
    };
  }

  Map<String, dynamic> _extractSpecs(Map<String, dynamic> product) {
    final specs = product['specifications'];
    return {
      'storage': product['storage'] ?? (specs is Map ? specs['storage'] : null) ?? 'N/A',
      'display': product['display'] ?? (specs is Map ? specs['display'] : null) ?? 'N/A',
      'battery': product['battery'] ?? (specs is Map ? specs['battery'] : null) ?? 'N/A',
      'camera': product['camera'] ?? (specs is Map ? specs['camera'] : null) ?? 'N/A',
      'processor': product['processor'] ?? (specs is Map ? specs['processor'] : null) ?? 'N/A',
      'ram': product['ram'] ?? (specs is Map ? specs['ram'] : null) ?? 'N/A',
    };
  }

  void _addProduct(Map<String, dynamic> product) {
    if (_canAddMore && !_isProductInComparison(product['id'])) {
      setState(() {
        _products.add(product);
      });
    }
  }

  bool _isProductInComparison(int productId) {
    return _products.any((p) => p['id'] == productId);
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _products.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureSettingsService.instance.compareEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text('Compare')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Product Compare is currently unavailable',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Products'),
        actions: [
          if (_products.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text('Clear All'),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _canAddMore && !_hasError && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _showProductPicker,
              icon: Icon(Icons.add),
              label: Text('Add Product'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_availableProducts.isEmpty) {
      return _buildEmptyProductsState();
    }

    if (_products.isEmpty) {
      return _buildEmptyComparisonState();
    }

    return _buildCompareGrid();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unable to load products',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadAvailableProducts,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              'No Products Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'There are no products to compare at the moment.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: _loadAvailableProducts,
              icon: Icon(Icons.refresh),
              label: Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyComparisonState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No products to compare',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add products to compare their features',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showProductPicker,
            icon: Icon(Icons.add),
            label: Text('Add Products'),
          ),
        ],
      ),
    );
  }

  void _showProductPicker() {
    if (_availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No products available to add')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Select Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _availableProducts.isEmpty
                  ? Center(child: Text('No products available'))
                  : GridView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                      ),
                      itemCount: _availableProducts.length,
                      itemBuilder: (context, index) {
                        final product = _availableProducts[index];
                        final isAdded = _isProductInComparison(product['id']);
                        return _buildProductPickerCard(product, isAdded);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPickerCard(Map<String, dynamic> product, bool isAdded) {
    return GestureDetector(
      onTap: isAdded ? null : () {
        _addProduct(product);
        Navigator.pop(context);
      },
      child: Card(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                    child: product['image']?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: product['image'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '\$${product['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isAdded)
              Positioned(
                top: 8.w,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareGrid() {
    final allSpecs = <String>{};
    for (var product in _products) {
      final specs = product['specs'] as Map<String, dynamic>?;
      if (specs != null) {
        allSpecs.addAll(specs.keys.where((k) => specs[k] != 'N/A'));
      }
    }
    final specLabels = allSpecs.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80.w,
                child: Column(
                  children: [
                    SizedBox(height: 120.h),
                    _buildLabel('Price'),
                    _buildLabel('Rating'),
                    _buildLabel('Reviews'),
                    _buildLabel('Brand'),
                    ...specLabels.map((spec) => _buildLabel(spec)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _products.asMap().entries.map((entry) {
                      return _buildProductCard(entry.value, entry.key, specLabels);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      height: 50.h,
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index, List<String> specLabels) {
    final specs = product['specs'] as Map<String, dynamic>? ?? {};
    final originalPrice = product['originalPrice'] ?? 0;
    final price = product['price'] ?? 0;
    final discount = originalPrice > 0 ? ((originalPrice - price) / originalPrice * 100).round() : 0;

    return Container(
      width: 140.w,
      margin: EdgeInsets.only(left: 8.w),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => _removeProduct(index),
                  child: Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: product['image']?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: product['image'],
                        height: 80.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 80.h,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 80.h,
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 80.h,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              SizedBox(height: 8.h),
              Text(
                product['name'] ?? '',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  if (discount > 0) ...[
                    SizedBox(width: 4.w),
                    Text('-$discount%', style: TextStyle(fontSize: 10, color: Colors.red)),
                  ],
                ],
              ),
              if (originalPrice > price)
                Text('\$${originalPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  SizedBox(width: 4.w),
                  Text('${product['rating']}', style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 4.h),
              Text('${product['reviews']} reviews', style: TextStyle(fontSize: 10, color: Colors.grey)),
              SizedBox(height: 8.h),
              Text(product['brand'] ?? '', style: TextStyle(fontSize: 11)),
              ...specLabels.map((spec) => Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text('$spec: ${specs[spec] ?? 'N/A'}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              )),
            ],
          ),
        ),
      ),
    );
  }
}