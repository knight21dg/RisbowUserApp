import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_shimmer.dart';
import '../../../utils/widgets/custom_sub_category_card.dart';
import '../../product_listing_page/model/product_listing_type.dart';
import '../bloc/sub_category/sub_category_bloc.dart';
import '../bloc/sub_category/sub_category_state.dart';

class SubCategoryFeatureSectionWidget extends StatefulWidget {
  const SubCategoryFeatureSectionWidget({super.key});

  @override
  State<SubCategoryFeatureSectionWidget> createState() => _SubCategoryFeatureSectionWidgetState();
}

class _SubCategoryFeatureSectionWidgetState extends State<SubCategoryFeatureSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubCategoryBloc, SubCategoryState>(
      builder: (BuildContext context, SubCategoryState state) {
        if (state is SubCategoryLoaded) {
          if (state.subCategoryData.isEmpty) return const SizedBox.shrink();
          final hasMore = state.subCategoryData.length > 8;

          return Container(
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
                        AppLocalizations.of(context)?.shopByCategories ?? 'Shop by categories',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      if (hasMore) ...[
                        SizedBox(width: 8.w),
                        InkWell(
                          borderRadius: BorderRadius.circular(6.r),
                          onTap: () {
                            final navigationShell = StatefulNavigationShell.of(context);
                            navigationShell.goBranch(1, initialLocation: false);
                          },
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
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: state.subCategoryData.take(8).map((data) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => GoRouter.of(context).push(
                          AppRoutes.nearbyStores,
                          extra: {'categorySlug': data.slug, 'categoryTitle': data.title},
                        ),
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 16.w * 2 - 12.w * 3) / 4,
                          child: CustomSubCategoryCard(
                            categoryImage: data.image!,
                            categoryName: data.title!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        } else if (state is SubCategoryLoading) {
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) => ShimmerWidget.rectangular(isBorder: true, width: 56.w, height: 78.h)),
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
