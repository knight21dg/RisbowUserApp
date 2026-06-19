import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/router/app_routes.dart';

class SpecialOffersPage extends StatefulWidget {
  const SpecialOffersPage({super.key});

  @override
  State<SpecialOffersPage> createState() => _SpecialOffersPageState();
}

class _SpecialOffersPageState extends State<SpecialOffersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingProducts = true;
  bool _isLoadingOnSale = true;
  bool _isLoadingCategories = true;
  bool _isLoadingRooms = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _onSaleProducts = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchProducts(),
      _fetchOnSaleProducts(),
      _fetchCategories(),
      _fetchRooms(),
    ]);
  }

  /// ── Products: delivery-zone/products ──
  Future<void> _fetchProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final uri = Uri.parse('${ApiRoutes.categoryProductApi}?per_page=50&page=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['data'] != null) {
          final items = (data['data']['data'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          setState(() => _products = items);
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  /// ── On Sale: featured-sections?section_type=on_sale ──
  Future<void> _fetchOnSaleProducts() async {
    setState(() => _isLoadingOnSale = true);
    try {
      final uri = Uri.parse(
        '${ApiRoutes.featureSectionProductApi}?section_type=on_sale',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final sections = data['data'] as List;
          final List<Map<String, dynamic>> items = [];
          for (final section in sections) {
            final products = section['products'] as List?;
            if (products != null) {
              items.addAll(
                products.map((e) => Map<String, dynamic>.from(e)).toList(),
              );
            }
          }
          setState(() => _onSaleProducts = items);
        }
      }
    } catch (e) {
      debugPrint('Error loading on sale: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOnSale = false);
    }
  }

  /// ── Categories ──
  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final uri = Uri.parse('${ApiRoutes.homeCategoriesApi}?per_page=100');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] is List
                  ? data['data']
                  : (data['data']?['data'] as List? ?? []))
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          setState(() => _categories = items);
        }
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  /// ── Rooms ──
  Future<void> _fetchRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final uri = Uri.parse('${AppConstant.baseUrl}rooms?per_page=50');
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final items = (data['data'] is List
                  ? data['data']
                  : (data['data']['data'] as List? ?? []))
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          setState(() => _rooms = items);
        }
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        appBar: AppBar(
          title: const Text(
            'Deals & Categories',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF1565C0),
            labelColor: const Color(0xFF1565C0),
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: '🔥 On Sale'),
              Tab(text: '🛍 Products'),
              Tab(text: '📂 Categories'),
              Tab(text: '🏠 Rooms'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOnSaleTab(),
            _buildProductsTab(),
            _buildCategoriesTab(),
            _buildRoomsTab(),
          ],
        ),
      ),
    );
  }

  // ── Shared grid builder ──
  Widget _build2ColGrid({
    required bool isLoading,
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    if (isLoading) {
      return GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ProductShimmer(),
      );
    }
    if (itemCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No items found', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Check back later', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }

  // ── On Sale tab ──
  Widget _buildOnSaleTab() {
    return _build2ColGrid(
      isLoading: _isLoadingOnSale,
      itemCount: _onSaleProducts.length,
      itemBuilder: (context, index) {
        final item = _onSaleProducts[index];
        final image = item['main_image'] ?? item['image'] ?? '';
        final title = item['title'] ?? 'Untitled';
        final slug = item['slug'] ?? '';
        final variants = item['variants'] as List?;
        final variant = variants != null && variants.isNotEmpty
            ? variants.firstWhere(
                (v) => v['is_default'] == true || v['isDefault'] == true,
                orElse: () => variants.first,
              )
            : null;
        final price = (variant?['price'] ?? 0).toDouble();
        final specialPrice = (variant?['special_price'] ?? 0).toDouble();
        final showDiscount = specialPrice > 0 && specialPrice < price && price > 0;
        return SpecialProductCard(
          image: image,
          title: title,
          slug: slug,
          price: price,
          specialPrice: specialPrice,
          showDiscount: showDiscount,
        );
      },
    );
  }

  // ── All Products tab ──
  Widget _buildProductsTab() {
    return _build2ColGrid(
      isLoading: _isLoadingProducts,
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final item = _products[index];
        final image = item['main_image'] ?? '';
        final title = item['title'] ?? 'Untitled';
        final slug = item['slug'] ?? '';
        final variants = item['variants'] as List?;
        final variant = variants != null && variants.isNotEmpty
            ? variants.firstWhere(
                (v) => v['is_default'] == true || v['isDefault'] == true,
                orElse: () => variants.first,
              )
            : null;
        final price = (variant?['price'] ?? 0).toDouble();
        final specialPrice = (variant?['special_price'] ?? 0).toDouble();
        final showDiscount = specialPrice > 0 && specialPrice < price && price > 0;
        return SpecialProductCard(
          image: image,
          title: title,
          slug: slug,
          price: price,
          specialPrice: specialPrice,
          showDiscount: showDiscount,
        );
      },
    );
  }

  // ── Categories tab ──
  Widget _buildCategoriesTab() {
    if (_isLoadingCategories) {
      return GridView.builder(
        padding: EdgeInsets.all(16.w),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const CategoryShimmer(),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No categories', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Check back later', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final item = _categories[index];
        final image = item['image'] ?? '';
        final title = item['title'] ?? 'Untitled';
        final slug = item['slug'] ?? '';
        return SimpleCategoryCard(
          image: image,
          title: title,
          slug: slug,
        );
      },
    );
  }

  // ── Rooms tab ──
  Widget _buildRoomsTab() {
    return _build2ColGrid(
      isLoading: _isLoadingRooms,
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final item = _rooms[index];
        final image = item['banner_image'] ?? item['image'] ?? '';
        final title = item['name'] ?? 'Room';
        final code = item['code'] ?? item['slug'] ?? '';
        return SimpleRoomCard(image: image, title: title, code: code);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Card Widgets
// ═══════════════════════════════════════════════════════════

class SpecialProductCard extends StatelessWidget {
  final String image;
  final String title;
  final String slug;
  final double price;
  final double specialPrice;
  final bool showDiscount;

  const SpecialProductCard({
    super.key,
    required this.image,
    required this.title,
    required this.slug,
    required this.price,
    required this.specialPrice,
    required this.showDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final displayPrice = showDiscount ? specialPrice : price;
    final discountPct = showDiscount
        ? ((price - specialPrice) / price * 100).toStringAsFixed(0)
        : '';

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/product-detail?slug=$slug'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image + discount badge ──
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  image.isNotEmpty
                      ? CustomImageContainer(
                          imagePath: image,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey.shade200),
                  if (showDiscount && discountPct.isNotEmpty)
                    Positioned(
                      bottom: 6.w,
                      right: 6.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 2.h,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Text(
                          '$discountPct%',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Title ──
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),
            // ── Price ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      '${AppConstant.currency}$displayPrice',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showDiscount) ...[
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        '${AppConstant.currency}$price',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}

class SimpleCategoryCard extends StatelessWidget {
  final String image;
  final String title;
  final String slug;

  const SimpleCategoryCard({
    super.key,
    required this.image,
    required this.title,
    required this.slug,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).push(
        AppRoutes.productListing,
        extra: {
          'isTheirMoreCategory': false,
          'title': title,
          'logo': image,
          'totalProduct': '',
          'type': 'category',
          'identifier': slug,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: image.isNotEmpty
                    ? CustomImageContainer(
                        imagePath: image,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey.shade200),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                alignment: Alignment.center,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleRoomCard extends StatelessWidget {
  final String image;
  final String title;
  final String code;

  const SimpleRoomCard({
    super.key,
    required this.image,
    required this.title,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/rooms/$code'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1.15,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: image.isNotEmpty
                    ? CustomImageContainer(
                        imagePath: image,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.meeting_room_outlined,
                          color: Colors.grey.shade400,
                          size: 32.sp,
                        ),
                      ),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholders ──

class ProductShimmer extends StatelessWidget {
  const ProductShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12.h,
                  width: 1.sw,
                  color: Colors.grey.shade300,
                  margin: EdgeInsets.only(bottom: 4.h),
                ),
                Container(
                  height: 12.h,
                  width: 0.6.sw,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
