import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';
import '../model/today_deal_model.dart';

class TodayDealsSection extends StatefulWidget {
  final List<TodayDeal> deals;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const TodayDealsSection({
    super.key,
    required this.deals,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  State<TodayDealsSection> createState() => _TodayDealsSectionState();
}

class _TodayDealsSectionState extends State<TodayDealsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) return _buildLoadingState();
    if (widget.deals.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFF7F7F7),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: 12.h),
          SizedBox(
            height: 240.h,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: widget.deals.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: _TodayDealCard(
                  deal: widget.deals[index],
                  onTap: () {
                    final slug = widget.deals[index].productSlug;
                    if (slug != null) context.push('${AppRoutes.productDetailPage}?slug=$slug');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4444)]),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: Colors.white, size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  'Today Deals',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          if (widget.onViewAll != null) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: widget.onViewAll,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(width: 100.w, height: 24.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4.r))),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 240.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: Container(
                  width: 150.w,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayDealCard extends StatefulWidget {
  final TodayDeal deal;
  final VoidCallback? onTap;

  const _TodayDealCard({required this.deal, this.onTap});

  @override
  State<_TodayDealCard> createState() => _TodayDealCardState();
}

class _TodayDealCardState extends State<_TodayDealCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.deal.timeRemaining;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _timeRemaining = widget.deal.timeRemaining);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final discount = deal.discountPercentage ?? 0;
    final isUrgent = _timeRemaining.inHours < 2;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 140.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(aspectRatio: 1, child: Stack(children: [
            CachedNetworkImage(
              imageUrl: deal.banner ?? deal.productImage ?? '',
              fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              placeholder: (_, __) => Container(color: Colors.grey.shade100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100, child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade300)),
            ),
            if (discount > 0)
              Positioned(bottom: 6.w, right: 6.w, child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(4.r)),
                child: Text('-$discount%', style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              )),
          ])),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 6.w, 8.w, 2.w),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(deal.productName ?? '', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${AppConstant.currency}${deal.discountedPrice?.toStringAsFixed(0) ?? ''}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                if (deal.originalPrice != null && deal.originalPrice! > (deal.discountedPrice ?? 0)) ...[
                  SizedBox(width: 4.w),
                  Text('${AppConstant.currency}${deal.originalPrice?.toStringAsFixed(0) ?? ''}', style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                ],
              ]),
              SizedBox(height: 2.h),
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  decoration: BoxDecoration(color: isUrgent ? Colors.red.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(3.r)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.access_time, size: 10.sp, color: isUrgent ? const Color(0xFFE53935) : Colors.grey.shade500),
                    SizedBox(width: 2.w),
                    Text('${_timeRemaining.inHours}h ${_timeRemaining.inMinutes.remainder(60)}m', style: TextStyle(fontSize: 9.sp, color: isUrgent ? const Color(0xFFE53935) : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                Container(width: 26.w, height: 26.w, decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(6.r)),
                  child: Icon(Icons.add, color: Colors.white, size: 16.w)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
