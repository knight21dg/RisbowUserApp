import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/screens/home_page/model/custom_sale_page_model.dart';
import 'package:hyper_local/widgets/banner_media_widget.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CustomSalePageWidget extends StatelessWidget {
  final CustomSalePageModel page;

  const CustomSalePageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Colors.white;
    const txtColor = Colors.black;

    return Container(
      color: bgColor,
      child: CustomScrollView(
        slivers: [
          if (page.banners.isNotEmpty || (page.bannerImage != null && page.bannerImage!.isNotEmpty))
            SliverToBoxAdapter(
              child: page.banners.isNotEmpty 
                ? _buildBannersCarousel(context)
                : _buildBanner(context),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = page.sections[index];
                return _buildSection(context, section, txtColor);
              },
              childCount: page.sections.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildBannersCarousel(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 250.h,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: false,
      ),
      items: page.banners.map((banner) {
        return GestureDetector(
          onTap: () => _handleLink(context, banner.link ?? '', banner.linkType),
          child: BannerMediaWidget(
            url: banner.image,
            fit: BoxFit.cover,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return GestureDetector(
      onTap: page.buttonLink != null
          ? () => _handleLink(context, page.buttonLink!, page.buttonLink)
          : null,
      child: BannerMediaWidget(
        url: page.bannerImage ?? '',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSection(BuildContext context, CustomSalePageSectionModel section, Color txtColor) {
    if (section.products.isEmpty && section.categories.isEmpty && section.stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty)
            _buildMinimalistHeader(context, section),
          SizedBox(height: 24.h),
          _buildProductsList(context, section),
          if (section != page.sections.last)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 0),
              child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalistHeader(BuildContext context, CustomSalePageSectionModel section) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4.h),
                  height: 2.h,
                  width: 40.w,
                  color: Colors.black,
                ),
              ],
            ),
          ),
          if (section.categorySlug != null)
            GestureDetector(
              onTap: () => context.push('/product-listing?type=category&identifier=${section.categorySlug}'),
              child: Text(
                'VIEW ALL',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, CustomSalePageSectionModel section) {
    if (section.sectionType == 'stores' && section.stores.isNotEmpty) {
      return _buildStoresList(context, section);
    }
    if (section.sectionType == 'categories_list' && section.categories.isNotEmpty) {
      if (section.layout == 'horizontal' || section.layout == 'carousel') {
        return _buildCategoriesHorizontal(context, section);
      }
      return _buildCategoriesGrid(context, section);
    }

    final products = section.products;
    final layout = section.layout;
    
    switch (layout) {
      case 'horizontal':
      case 'compact':
        return SizedBox(
          height: 240.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: products.length > (section.limit ?? 10) ? section.limit ?? 10 : products.length,
            itemBuilder: (context, index) => _buildMinimalistProductCard(context, products[index]),
          ),
        );
      case 'carousel':
        return CarouselSlider(
          options: CarouselOptions(
            height: 280.h,
            viewportFraction: 0.85,
            autoPlay: true,
            enlargeCenterPage: true,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
          ),
          items: products.take(section.limit ?? 10).map((product) => _buildMinimalistProductCard(context, product, isCarousel: true)).toList(),
        );
      case 'list':
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: products.length > (section.limit ?? 10) ? section.limit ?? 10 : products.length,
          itemBuilder: (context, index) => _buildMinimalistListCard(context, products[index]),
        );
      case 'grid':
      default:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 24.h,
          ),
          itemCount: products.length > (section.limit ?? 10) ? section.limit ?? 10 : products.length,
          itemBuilder: (context, index) => _buildMinimalistProductCard(context, products[index]),
        );
    }
  }

  Widget _buildCategoriesGrid(BuildContext context, CustomSalePageSectionModel section) {
    final categories = section.categories;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => context.push('/product-listing?type=category&identifier=${category.slug}'),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CustomImageContainer(
                        imagePath: category.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Expanded(
                  flex: 2,
                  child: Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.grey[800],
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalistProductCard(BuildContext context, CustomSalePageProduct product, {bool isCarousel = false}) {
    return GestureDetector(
      onTap: () => context.push('/product-detail?slug=${product.slug}'),
      child: Container(
        width: isCarousel ? null : 160.w,
        margin: isCarousel ? EdgeInsets.symmetric(horizontal: 8.w) : EdgeInsets.only(right: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade100, width: 0.5),
                ),
                child: CustomImageContainer(
                  imagePath: product.mainImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              product.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                if (product.discountPrice != null && product.discountPrice! < product.price) ...[
                  SizedBox(width: 8.w),
                  Text(
                    '₹${product.discountPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistListCard(BuildContext context, CustomSalePageProduct product) {
    return GestureDetector(
      onTap: () => context.push('/product-detail?slug=${product.slug}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 24.h),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade100, width: 0.5),
              ),
              child: CustomImageContainer(
                imagePath: product.mainImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesHorizontal(BuildContext context, CustomSalePageSectionModel section) {
    return SizedBox(
      height: 120.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: section.categories.length,
        itemBuilder: (context, index) {
          final category = section.categories[index];
          return GestureDetector(
            onTap: () => context.push('/product-listing?type=category&identifier=${category.slug}'),
            child: Container(
              margin: EdgeInsets.only(right: 20.w),
              child: Column(
                children: [
                  Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: CustomImageContainer(
                        imagePath: category.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    category.title.toUpperCase(),
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoresList(BuildContext context, CustomSalePageSectionModel section) {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: section.stores.length,
        itemBuilder: (context, index) {
          final store = section.stores[index];
          return GestureDetector(
            onTap: () => context.push('/near-by-store-details?store-slug=${store.slug}'),
            child: Container(
              width: 260.w,
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomImageContainer(
                      imagePath: store.banner.isNotEmpty ? store.banner : store.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          store.title.toUpperCase(),
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(store.rating.toStringAsFixed(1), style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleLink(BuildContext context, String link, String? linkType) {
    if (linkType == 'category') {
      context.push('/product-listing?type=category&identifier=$link');
    } else if (linkType == 'product') {
      context.push('/product-detail?slug=$link');
    } else {
      context.push(link);
    }
  }
}

class CustomSalePageListItemWidget extends StatelessWidget {
  final CustomSalePageListItem page;
  final VoidCallback onTap;

  const CustomSalePageListItemWidget({
    super.key,
    required this.page,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        child: AspectRatio(
          aspectRatio: 2.5,
          child: Stack(
            children: [
              if (page.bannerImage != null && page.bannerImage!.isNotEmpty)
                Positioned.fill(
                  child: CustomImageContainer(
                    imagePath: page.bannerImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: Center(
                      child: Icon(Icons.shopping_bag_outlined, color: Colors.grey.shade200, size: 40),
                    ),
                  ),
                ),
              // Minimalist gradient (only for contrast)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              // Minimalist Floating Content
              Positioned(
                bottom: 24.h,
                left: 20.w,
                right: 20.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                        ],
                      ),
                    ),
                    if (page.description != null && page.description!.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 8.h),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        color: Colors.white,
                        child: Text(
                          page.description!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
