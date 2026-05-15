import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';

class GroupProductsPage extends StatefulWidget {
  final String? roomCode;

  const GroupProductsPage({super.key, this.roomCode});

  @override
  State<GroupProductsPage> createState() => _GroupProductsPageState();
}

class _GroupProductsPageState extends State<GroupProductsPage> {
  final RoomRepository _repository = RoomRepository();
  final TextEditingController _searchController = TextEditingController();

  GroupBuyRoom? _room;
  List<GroupBuyProduct> _products = const <GroupBuyProduct>[];
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  bool _loadingCategories = true;
  String _selectedCategory = 'All';
  String _sort = 'popular';
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadCategories(),
      _loadRoom(),
    ]);
    _loadProducts();
  }

  Future<void> _loadRoom() async {
    if (widget.roomCode != null && widget.roomCode!.trim().isNotEmpty) {
      _room = await _repository.getRoomDetails(widget.roomCode!);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final cats = await _repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _loadingCategories = false;
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final products = await _repository.getGroupProducts(
      search: _searchController.text,
      category: _selectedCategory,
      sort: _sort,
    );
    if (!mounted) return;
    setState(() {
      _products = products.map((product) {
        if (_room == null) return product;
        final inCart = _room!.cartItems.any(
          (item) => item.productId == product.id,
        );
        return product.copyWith(inCart: inCart);
      }).toList();
      _loading = false;
    });
  }

  Future<void> _addProduct(GroupBuyProduct product) async {
    if (_room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room not available')),
      );
      return;
    }
    if (_room!.isClosed || _room!.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room closed')),
      );
      return;
    }

    final qty = await ModalDialog.showQuantityEditor(
      context,
      productName: product.name,
      initialQty: 1,
    );
    if (qty == null) return;

    final updatedRoom = await _repository.addItemToRoom(
      room: _room!,
      product: product,
      quantity: qty,
    );
    if (!mounted) return;

    if (updatedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add item')),
      );
      return;
    }

    setState(() {
      _room = updatedRoom;
      _products = _products.map((entry) {
        if (entry.id == product.id) return entry.copyWith(inCart: true);
        return entry;
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Add Items',
          style: TextStyle(
            fontWeight: FontWeight.w700, 
            fontSize: 18.sp,
            color: Colors.black,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _sort = _sort == 'price_low' ? 'price_high' : 'price_low';
              });
              _loadProducts();
            },
            icon: Icon(
              _sort == 'price_low' ? TablerIcons.sort_ascending_numbers : TablerIcons.sort_descending_numbers,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebar(),
                Container(width: 1, color: Colors.grey.shade100),
                Expanded(
                  child: _buildProductGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _room == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room Cart Total',
                          style: TextStyle(
                            fontSize: 12.sp, 
                            color: Colors.grey,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        Text(
                          '${_room!.cartItems.length} Items • ${AppConstant.currency}${_room!.cartTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16.sp, 
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150.w,
                    child: PrimaryButton(
                      label: 'Back to Room',
                      onPressed: () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _loadProducts(),
        decoration: InputDecoration(
          hintText: 'Search room products...',
          prefixIcon: const Icon(TablerIcons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 95.w,
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView.builder(
          itemCount: _categories.length + 1,
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final category = isAll ? null : _categories[index - 1];
            final String title = isAll ? 'All' : category?['name'] ?? 'Category';
            final isSelected = _selectedCategoryIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                  _selectedCategory = isAll ? 'All' : title;
                });
                _loadProducts();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      width: 3,
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: isSelected ? null : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      padding: EdgeInsets.all(8.w),
                      child: isAll 
                        ? Icon(TablerIcons.grid_dots, color: isSelected ? AppTheme.primaryColor : Colors.grey)
                        : (category?['image'] != null && category!['image'].toString().isNotEmpty)
                          ? CustomImageContainer(
                              imagePath: category!['image'],
                              fit: BoxFit.contain,
                            )
                          : Icon(TablerIcons.category, color: isSelected ? AppTheme.primaryColor : Colors.grey),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_loading) {
      return const Center(child: CustomCircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(TablerIcons.search_off, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 14.sp, 
                color: Colors.grey,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      itemCount: _products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(
          product: product,
          onAdd: () => _addProduct(product),
        );
      },
    );
  }
}
