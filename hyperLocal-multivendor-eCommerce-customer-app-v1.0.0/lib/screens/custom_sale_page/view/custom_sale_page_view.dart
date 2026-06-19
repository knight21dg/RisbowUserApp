import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/custom_sale_page/custom_sale_page_bloc.dart';
import 'package:hyper_local/screens/home_page/model/custom_sale_page_model.dart';
import 'package:hyper_local/screens/home_page/widgets/custom_sale_page_widget.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/content_shimmer.dart';

class CustomSalePageView extends StatelessWidget {
  final String slug;

  const CustomSalePageView({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomSalePageBloc()..add(FetchCustomSalePageBySlug(slug: slug)),
      child: Scaffold(
        body: BlocBuilder<CustomSalePageBloc, CustomSalePageState>(
          builder: (context, state) {
            if (state is CustomSalePageDetailLoading) {
              return ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  Container(
                    height: 190.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  ...List.generate(
                    3,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Container(
                        height: 120.h,
                        decoration: BoxDecoration(
                          color: AppColors.grey.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            
            if (state is CustomSalePageFailed) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Page not found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.error),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<CustomSalePageBloc>().add(FetchCustomSalePageBySlug(slug: slug));
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is CustomSalePageDetailLoaded) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 88.h,
                    backgroundColor: AppColors.white,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.headingColor),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(left: 56.w, bottom: 14.h),
                      title: Text(
                        state.page.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.headingColor,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: CustomSalePageWidget(page: state.page)),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class CustomSalePageListView extends StatefulWidget {
  final bool footerOnly;

  const CustomSalePageListView({super.key, this.footerOnly = false});

  @override
  State<CustomSalePageListView> createState() => _CustomSalePageListViewState();
}

class _CustomSalePageListViewState extends State<CustomSalePageListView> {
  String _activeFilter = 'all';

  List<CustomSalePageListItem> _applyFilter(List<CustomSalePageListItem> pages) {
    if (_activeFilter == 'featured') {
      return pages.where((p) => p.isFeatured).toList();
    }
    if (_activeFilter == 'scheduled') {
      return pages.where((p) => p.isScheduled).toList();
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CustomSalePageBloc()..add(FetchCustomSalePages()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.footerOnly ? 'Special Offers' : 'Custom Pages'),
        ),
        body: BlocBuilder<CustomSalePageBloc, CustomSalePageState>(
          builder: (context, state) {
            if (state is CustomSalePageListLoading) {
              return ContentShimmer(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: 5,
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              );
            }
            
            if (state is CustomSalePageFailed) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(state.error),
                  ],
                ),
              );
            }
            
            if (state is CustomSalePageListLoaded) {
              if (state.pages.isEmpty) {
                return const Center(
                  child: Text('No pages available'),
                );
              }

              final filteredPages = _applyFilter(state.pages);
               
              return Column(
                children: [
                  Container(
                    color: AppColors.white,
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _TopFilterChip(
                            label: 'All',
                            selected: _activeFilter == 'all',
                            onTap: () => setState(() => _activeFilter = 'all'),
                          ),
                          _TopFilterChip(
                            label: 'Featured',
                            selected: _activeFilter == 'featured',
                            onTap: () => setState(() => _activeFilter = 'featured'),
                          ),
                          _TopFilterChip(
                            label: 'Scheduled',
                            selected: _activeFilter == 'scheduled',
                            onTap: () => setState(() => _activeFilter = 'scheduled'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredPages.isEmpty
                        ? Center(
                            child: Text(
                              'No pages for this filter',
                              style: TextStyle(fontSize: 13.sp, color: AppColors.subtitleColor),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            itemCount: filteredPages.length,
                            separatorBuilder: (context, index) => SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final page = filteredPages[index];
                              return CustomSalePageListItemWidget(
                                page: page,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomSalePageView(slug: page.slug),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _TopFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TopFilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label filter',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: 40.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.grey.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: selected ? Colors.white : AppColors.headingColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
