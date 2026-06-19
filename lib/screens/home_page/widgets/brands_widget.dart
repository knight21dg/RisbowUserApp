import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_brands_card.dart';
import '../../../utils/widgets/custom_shimmer.dart';
import '../../product_listing_page/model/product_listing_type.dart';

class BrandsSection extends StatefulWidget {
  final String brandsSectionTitle;
  final String categorySlug;

  const BrandsSection({super.key, required this.brandsSectionTitle, required this.categorySlug});

  @override
  State<BrandsSection> createState() => _BrandsSectionState();
}

class _BrandsSectionState extends State<BrandsSection> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _scrollForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startInfiniteScroll());
  }

  void _startInfiniteScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (maxExtent <= 0) return;
        _scrollController.animateTo(
          _scrollForward ? maxExtent : _scrollController.position.minScrollExtent,
          duration: const Duration(seconds: 12),
          curve: Curves.linear,
        );
        _scrollForward = !_scrollForward;
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrandsBloc, BrandsState>(
      builder: (context, state) {
        if (state is BrandsLoaded) {
          return state.brandsData.isNotEmpty
              ? Container(
                  color: const Color(0xFFF7F7F7),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Text(
                              widget.brandsSectionTitle,
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                            SizedBox(width: 8.w),
                            InkWell(
                              borderRadius: BorderRadius.circular(6.r),
                              onTap: () => GoRouter.of(context).push(AppRoutes.brandsListPage, extra: {'category-slug': widget.categorySlug}),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('See All', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                                    Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF1565C0)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        height: 80.h,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: state.brandsData.length,
                          itemBuilder: (context, index) {
                            final brandsData = state.brandsData[index];
                            return Padding(
                              padding: EdgeInsets.only(right: 16.w),
                              child: GestureDetector(
                                onTap: () => GoRouter.of(context).push(
                                  AppRoutes.productListing,
                                  extra: {
                                    'isTheirMoreCategory': false,
                                    'title': brandsData.title,
                                    'logo': brandsData.logo,
                                    'totalProduct': 10,
                                    'type': ProductListingType.brand,
                                    'identifier': brandsData.slug,
                                  },
                                ),
                                child: Container(
                                  width: 72.w,
                                  height: 72.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                  ),
                                  padding: EdgeInsets.all(10.w),
                                  child: CustomBrandsCard(
                                  brandImage: state.brandsData[index].logo ?? '',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink();
        } else if (state is BrandsLoading) {
          return Container(
            color: const Color(0xFFF7F7F7),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ShimmerWidget.rectangular(isBorder: true, height: 18, width: 200, borderRadius: 15),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 80.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: 6,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: ShimmerWidget.rectangular(isBorder: true, width: 72.w, height: 72.w, borderRadius: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
