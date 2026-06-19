import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/weekly_rooms_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import '../../cart_page/bloc/add_to_cart/add_to_cart_event.dart';
import '../../cart_page/bloc/add_to_cart/add_to_cart_state.dart';
import '../../cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';

class PrivateRoomDetailsPage extends StatefulWidget {
  final Map<String, dynamic> roomData;

  const PrivateRoomDetailsPage({
    super.key,
    required this.roomData,
  });

  @override
  _PrivateRoomDetailsPageState createState() => _PrivateRoomDetailsPageState();
}

class _PrivateRoomDetailsPageState extends State<PrivateRoomDetailsPage> with TickerProviderStateMixin {
  late bool isUnlocked;
  late Map<String, dynamic> room;
  late List<dynamic> products;
  late Map<String, dynamic> userInstance;

  Timer? _pollingTimer;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _parseData();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (userInstance['id'] != null) {
        context.read<WeeklyRoomsBloc>().add(FetchInstanceDetails(userInstance['id']));
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _parseData({Map<String, dynamic>? newData}) {
    final data = newData ?? widget.roomData;
    final previouslyLocked = !(userInstance['is_unlocked'] ?? false);
    
    room = data['room'] ?? {};
    products = data['products'] ?? [];
    userInstance = data['user_instance'] ?? {};
    isUnlocked = userInstance['is_unlocked'] ?? false;

    if (isUnlocked && previouslyLocked) {
      _confettiController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WeeklyRoomsBloc, WeeklyRoomsState>(
          listener: (context, state) {
            if (state is InstanceDetailsLoaded) {
              setState(() {
                _parseData(newData: state.data);
              });
            }
          },
        ),
        BlocListener<AddToCartBloc, AddToCartState>(
          listener: (context, state) {
            if (state is AddToCartSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to cart!'),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<GetUserCartBloc>().add(FetchUserCart());
            } else if (state is AddToCartFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFD),
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildProgressHeader(),
                      _buildProductList(),
                      SizedBox(height: 120.h), 
                    ],
                  ),
                ),
              ],
            ),
            if (isUnlocked)
              Align(
                alignment: Alignment.topCenter,
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_u4yrau.json',
                  controller: _confettiController,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  repeat: false,
                ),
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: isUnlocked ? null : _buildInviteButton(),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final bannerUrl = room['banner'] ?? '';

    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56.w, bottom: 16.h),
        title: Text(
          room['name'] ?? 'Private Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2))
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: bannerUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                ),
                child: Icon(Icons.room_preferences_rounded, size: 64.sp, color: Colors.white24),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () {
            final inviteCode = userInstance['invite_code'] ?? '---';
            HapticFeedback.mediumImpact();
            Clipboard.setData(ClipboardData(text: inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invite code copied! Share it with your friends.')),
            );
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final progress = (userInstance['progress'] ?? 0.0).toDouble();
    final currentMembers = userInstance['current_members'] ?? 1;
    final membersNeeded = userInstance['members_needed'] ?? 5;
    final remaining = membersNeeded - currentMembers;

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isUnlocked ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              ),
              child: Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.verified_rounded : Icons.lock_clock_rounded,
                    color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isUnlocked ? "EXCLUSIVE DEALS UNLOCKED" : "LOCKED ROOM",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: isUnlocked ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "$currentMembers/$membersNeeded",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 12.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        height: 12.h,
                        width: MediaQuery.of(context).size.width * (progress.clamp(0, 1)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUnlocked 
                              ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                              : [const Color(0xFFFF8F00), const Color(0xFFFFB300)],
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                          boxShadow: [
                            BoxShadow(
                              color: (isUnlocked ? Colors.green : Colors.orange).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    isUnlocked 
                      ? "Congratulations! You can now purchase items at special member prices." 
                      : "Invite $remaining more friend${remaining > 1 ? 's' : ''} to unlock group-buy discounts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Curated Selection",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (products.isNotEmpty)
                Text(
                  "${products.length} Items",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (products.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) => _buildProductCard(products[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final showPrice = product['show_price'] ?? false;
    final imageUrl = product['image'] ?? '';
    final discount = product['discount_percent'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 130.w,
                  height: 130.w,
                  padding: EdgeInsets.all(8.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                          child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 32.sp),
                        ),
                      ),
                    ),
                  ),
                if (isUnlocked && discount > 0)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "-$discount%",
                        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 16.h, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['title'] ?? 'Room Product',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (showPrice)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${(product['special_price'] ?? 0).toInt()}",
                                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: const Color(0xFF2E7D32)),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "₹${(product['original_price'] ?? 0).toInt()}",
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Material(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(10.r),
                            child: InkWell(
                              onTap: () {
                                if (product['id'] != null) {
                                  HapticFeedback.mediumImpact();
                                  context.read<AddToCartBloc>().add(
                                    AddItemToCart(
                                      productVariantId: product['default_variant_id'] ?? product['variant_id'] ?? 0,
                                      storeId: product['vendor_id'] ?? product['store_id'] ?? 0,
                                      quantity: 1,
                                      productId: product['id'],
                                      roomInstanceId: userInstance['id'],
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(10.r),
                              child: Container(
                                height: 36.h,
                                alignment: Alignment.center,
                                child: Text(
                                  "ADD TO CART",
                                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12.sp, color: Colors.grey),
                            SizedBox(width: 6.w),
                            Text("Join to see price", style: TextStyle(fontSize: 11.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Icon(Icons.shopping_basket_outlined, size: 64.sp, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text("No products added yet", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInviteButton() {
    final inviteCode = userInstance['invite_code'] ?? '---';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(30.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.vibrate();
            Clipboard.setData(ClipboardData(text: inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invite code copied to clipboard!')),
            );
          },
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share_rounded, color: Colors.white),
                SizedBox(width: 12.w),
                Text(
                  "INVITE: $inviteCode",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
