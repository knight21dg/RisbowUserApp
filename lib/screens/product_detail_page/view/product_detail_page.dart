import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/app_bar_widget.dart';
import 'package:hyper_local/screens/product_detail_page/widgets/review_rating_card.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_delivery_time_widget.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/dominant_colors.dart';
import '../../../config/global.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../services/auth_guard.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/custom_toast.dart';
import '../bloc/product_detail_bloc/product_detail_event.dart';
import '../bloc/product_detail_bloc/product_detail_state.dart';
import '../bloc/product_faq_bloc/product_faq_bloc.dart';
import '../widgets/rating_info_card.dart';
import '../widgets/similar_product_widget.dart';
import '../widgets/price_row_widget.dart';
import '../widgets/specification_row_widget.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_local/model/user_cart_model/user_cart.dart';
import '../repo/recommendations_repository.dart';
import '../bloc/recommendation_product_bloc/recommendation_product_bloc.dart';
import '../bloc/recommendation_product_bloc/recommendation_product_event.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';

class ProductDetailPage extends StatefulWidget {
  final String productSlug;
  final ProductInitialData initialData;
  final VoidCallback? closeContainer;

  const ProductDetailPage({
    super.key,
    required this.productSlug,
    required this.initialData,
    this.closeContainer,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final RoomRepository _roomRepository = RoomRepository();
  Map<String, SwatchValues> selectedVariants = {};
  bool _showTitle = false;

  List<String> productSlugList = [];

  // Product view tracking
  late DateTime _viewStartTime;
  int _productIdToTrack = 0;
  final RecommendationsRepository _recommendationsRepository =
      RecommendationsRepository();

  @override
  void initState() {
    super.initState();
    productSlugList.add(widget.productSlug);
    _scrollController.addListener(_onScroll);
    _viewStartTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach once when the tree is built
    PrimaryScrollController.of(context).addListener(_onScroll);
  }

  void _onScroll() {
    final offset = PrimaryScrollController.of(context).offset;
    final show = offset > 200;
    if (_showTitle != show) {
      setState(() => _showTitle = show);
    }
  }

  Widget _buildGroupBuyInfoBox(
    ProductData product,
    ProductVariants activeVariant,
  ) {
    if (!product.isGroupBuyEligible && !activeVariant.isGroupBuyEnabled) {
      return const SizedBox.shrink();
    }

    final gpPrice = activeVariant.isGroupBuyEnabled
        ? activeVariant.groupBuyPrice.toDouble()
        : product.groupBuyPrice;

    if (gpPrice <= 0) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              TablerIcons.users,
              color: AppTheme.primaryColor,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Buy & Save More!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Start a group and get this product for ${AppConstant.currency}${gpPrice.toStringAsFixed(0)} when 4 people place the order.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateGroupBuy(int productId) async {
    // Auth check
    if (Global.userData == null) {
      AuthGuard.ensureLoggedIn(context);
      return;
    }

    final state = context.read<ProductDetailBloc>().state;
    if (state is ProductDetailLoaded && state.productData.isNotEmpty) {
      final product = state.productData[0];

      // Navigate to Create Room Configuration Page
      context.push(
        AppRoutes.createGroupBuy,
        extra: {'product': product, 'selectedVariants': selectedVariants},
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Track product view when leaving the page
    if (_productIdToTrack > 0) {
      _trackProductView();
    }

    super.dispose();
  }

  /// Track product view to recommendations API
  void _trackProductView() {
    final timeSpentSeconds = DateTime.now()
        .difference(_viewStartTime)
        .inSeconds;

    try {
      _recommendationsRepository.recordProductView(
        productId: _productIdToTrack,
        timeSpent: timeSpentSeconds,
        completed: true,
        source: 'product_detail',
      );
    } catch (e) {
      // Silent fail - don't disrupt user experience
      debugPrint('Error tracking product view: $e');
    }
  }

  /// Track add to cart event
  void _trackAddToCart() {
    // This could be recorded as a product view with an action flag
    // For now, we're just recording that they added to cart
    // The main view tracking happens when they leave the page
  }

  Map<String, String> getSelectedVariantsForApi() {
    return selectedVariants.map((key, value) => MapEntry(key, value.value));
  }

  UserCart? _getCartItem(
    CartState state,
    int productId,
    int productVariantId,
    int storeId,
  ) {
    if (state is CartLoaded) {
      try {
        return state.items.firstWhere(
          (item) =>
              int.parse(item.productId) == productId &&
              int.parse(item.variantId) == productVariantId &&
              int.parse(item.vendorId) == storeId,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ProductDetailBloc()
            ..add(
              FetchProductDetail(
                productSlug: widget.productSlug,
                storeSlug: widget.initialData.storeSlug,
              ),
            ),
        ),
        BlocProvider(
          create: (_) =>
              ProductReviewBloc()
                ..add(FetchProductReview(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) =>
              ProductFAQBloc()
                ..add(FetchProductFAQ(productSlug: widget.productSlug)),
        ),
        BlocProvider(
          create: (_) => SimilarProductBloc()
            ..add(
              FetchSimilarProduct(excludeProductSlug: [widget.productSlug]),
            ),
        ),
        BlocProvider(create: (_) => RecommendationProductBloc()),
      ],
      child: CustomScaffold(
        showViewCart: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (BuildContext context, ProductDetailState state) {
            if (state is ProductDetailLoading ||
                state is ProductDetailInitial) {
              return NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        AppBarWidget(
                          showTitle: false,
                          initialData: widget.initialData,
                          loadedProduct: null,
                        ),
                      ];
                    },
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (state is ProductDetailLoaded &&
                state.productData.isNotEmpty) {
              final product = state.productData[0];

              // Capture product ID for tracking
              if (_productIdToTrack == 0) {
                _productIdToTrack = product.id;
                _viewStartTime = DateTime.now();

                // Fetch frequently bought together after product loads
                context.read<RecommendationProductBloc>().add(
                  FetchFrequentlyBoughtTogether(
                    productId: product.id,
                    limit: 10,
                  ),
                );
              }

              ProductVariants activeVariant = product.variants.isEmpty
                  ? ProductVariants()
                  : product.variants.firstWhere(
                      (v) => v.isDefault,
                      orElse: () => product.variants.first,
                    );

              if (selectedVariants.isNotEmpty && product.variants.isNotEmpty) {
                final selectedTitle = selectedVariants.values.first.value
                    .toString();

                activeVariant = product.variants.firstWhere(
                  (v) {
                    final attrValue = v.attributes.values.first.toString();
                    return attrValue.toLowerCase().trim() ==
                        selectedTitle.toLowerCase().trim();
                  },
                  orElse: () => product.variants.firstWhere(
                    (v) => v.isDefault,
                    orElse: () => product.variants.first,
                  ),
                );
              }

              final bool isSpecialSale =
                  product.indicator.toLowerCase() == 'special' ||
                  product.type.toLowerCase() == 'banner_sale' ||
                  product.type.toLowerCase() == 'landing' ||
                  product.type.toLowerCase() == 'landing_page';

              return NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        AppBarWidget(
                          showTitle: _showTitle,
                          initialData: widget.initialData, // from card
                          loadedProduct: product,
                        ),
                      ];
                    },
                body: isSpecialSale
                    ? CustomScrollView(
                        clipBehavior: Clip.antiAlias,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Html(
                              data: product.description,
                              shrinkWrap: true,
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                ),
                                "p": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  lineHeight: LineHeight.number(0),
                                ),
                                "figure": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  width: Width(100, Unit.percent),
                                ),
                                "img": Style(
                                  width: Width(100, Unit.percent),
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  display: Display.block,
                                ),
                              },
                            ),
                          ),
                        ],
                      )
                    : CustomScrollView(
                        clipBehavior: Clip.antiAlias,
                        physics: ClampingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.only(
                                    top: 15,
                                    left: 12,
                                    right: 12,
                                    bottom: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: isTablet(context)
                                                    ? 24
                                                    : 14.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsGeometry.directional(
                                                  top: 4,
                                                  start: 4,
                                                ),
                                            child: DeliveryTimeWidget(
                                              time: product
                                                  .estimatedDeliveryTime
                                                  .toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  RatingBar.builder(
                                                    initialRating: double.parse(
                                                      product.ratings
                                                          .toString(),
                                                    ),
                                                    minRating: 1,
                                                    direction: Axis.horizontal,
                                                    allowHalfRating: true,
                                                    itemCount: 5,
                                                    itemSize: 18,
                                                    itemBuilder: (context, _) =>
                                                        Icon(
                                                          AppTheme
                                                              .ratingStarIconFilled,
                                                          color: AppTheme
                                                              .ratingStarColor,
                                                        ),
                                                    ignoreGestures: true,
                                                    onRatingUpdate: (rating) {},
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${product.ratings}/5 ',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '(${product.ratingCount})',
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10.h),
                                              _buildGroupBuyInfoBox(
                                                product,
                                                activeVariant,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // VARIANTS
                                      ListView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: product.attributes.length,
                                        itemBuilder: (context, index) {
                                          return variantWidget(
                                            label:
                                                product.attributes[index].name,
                                            variantType: product
                                                .attributes[index]
                                                .swatcheType,
                                            selectedValue:
                                                selectedVariants[product
                                                    .attributes[index]
                                                    .name],
                                            onSelected: (SwatchValues value) {
                                              setState(() {
                                                selectedVariants[product
                                                        .attributes[index]
                                                        .name] =
                                                    value;
                                              });
                                            },
                                            productAttributes: product
                                                .attributes[index]
                                                .swatchValues,
                                          );
                                        },
                                      ),
                                      Divider(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),

                                      // Expandable description
                                      ExpansionTile(
                                        expansionAnimationStyle: AnimationStyle(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          curve: Curves.easeInOutCubic,
                                          reverseDuration: const Duration(
                                            milliseconds: 250,
                                          ),
                                        ),
                                        title: Text(
                                          l10n.viewProductDetails,
                                          style: TextStyle(
                                            fontSize: isTablet(context)
                                                ? 18
                                                : 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                          ),
                                        ),
                                        collapsedIconColor: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                        iconColor: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                        initiallyExpanded: false,
                                        tilePadding: EdgeInsets.symmetric(
                                          horizontal: 0.w,
                                        ),
                                        childrenPadding: EdgeInsets.symmetric(
                                          horizontal: 0.w,
                                        ),
                                        shape: const Border(),
                                        children: [
                                          Divider(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.5),
                                            thickness: 1,
                                          ),
                                          if (product.brand.isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.brand,
                                              value: product.brand,
                                            ),
                                          if (product.category.isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.category,
                                              value: product.category,
                                            ),
                                          SpecificationRowWidget(
                                            label: l10n.packOf,
                                            value: product.quantityStepSize
                                                .toString(),
                                          ),
                                          if (product.madeIn.isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.madeIn,
                                              value: product.madeIn,
                                            ),
                                          if (product.indicator.isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.indicator,
                                              value: removeUnderscores(
                                                capitalizeFirstLetter(
                                                  product.indicator,
                                                ),
                                              ),
                                            ),
                                          if (product
                                              .guaranteePeriod
                                              .isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.guaranteePeriod,
                                              value:
                                                  product.guaranteePeriod
                                                          .toString() ==
                                                      '0'
                                                  ? l10n.na
                                                  : product.guaranteePeriod,
                                            ),
                                          if (product.warrantyPeriod.isNotEmpty)
                                            SpecificationRowWidget(
                                              label: l10n.warrantyPeriod,
                                              value:
                                                  product.guaranteePeriod
                                                          .toString() ==
                                                      '0'
                                                  ? l10n.na
                                                  : product.guaranteePeriod,
                                            ),
                                          SpecificationRowWidget(
                                            label: l10n.returnable,
                                            value:
                                                product.isReturnable
                                                        .toString() ==
                                                    '0'
                                                ? l10n.na
                                                : l10n.yes,
                                          ),
                                          Html(
                                            data: product.description,
                                            shrinkWrap: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 9.h),

                                // Store Name
                                sellerStoreName(
                                  storeName: activeVariant.storeName.isNotEmpty
                                      ? activeVariant.storeName
                                      : '',
                                  storeSlug: activeVariant.storeSlug.isNotEmpty
                                      ? activeVariant.storeSlug
                                      : '',
                                  sellerName: product.seller,
                                ),

                                // Customer Review
                                BlocBuilder<
                                  ProductReviewBloc,
                                  ProductReviewState
                                >(
                                  builder: (BuildContext context, ProductReviewState state) {
                                    if (state is ProductReviewLoaded) {
                                      if (state
                                                  .productReview
                                                  .first
                                                  .data
                                                  .totalReviews >
                                              0 ||
                                          state
                                              .productReview
                                              .first
                                              .data
                                              .reviews
                                              .isNotEmpty) {
                                        return Column(
                                          children: [
                                            Card(
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(0.r),
                                              ),
                                              margin: EdgeInsets.only(
                                                left: 0.w,
                                                right: 0.w,
                                                top: 12,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 10.w,
                                                      right: 10.w,
                                                      top: 10.w,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          l10n.customerReviews,
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .tertiary,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () {
                                                            GoRouter.of(
                                                              context,
                                                            ).push(
                                                              AppRoutes
                                                                  .reviewRatingPage,
                                                              extra: {
                                                                'productSlug':
                                                                    product
                                                                        .slug,
                                                              },
                                                            );
                                                          },
                                                          child: Text(
                                                            l10n.seeAll,
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  if (state
                                                          .productReview
                                                          .first
                                                          .data
                                                          .totalReviews >
                                                      0)
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 15.w,
                                                            vertical: 8.h,
                                                          ),
                                                      child: RatingInfoCard(
                                                        reviewModel: state
                                                            .productReview
                                                            .first,
                                                      ),
                                                    ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 0.w,
                                                          vertical: 12.w,
                                                        ),
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        return SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          physics:
                                                              BouncingScrollPhysics(),
                                                          padding:
                                                              EdgeInsets.only(
                                                                right: 12.w,
                                                              ),
                                                          child: IntrinsicHeight(
                                                            child: Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: state
                                                                  .productReview
                                                                  .first
                                                                  .data
                                                                  .reviews
                                                                  .take(5)
                                                                  .toList()
                                                                  .asMap()
                                                                  .entries
                                                                  .map((entry) {
                                                                    int index =
                                                                        entry
                                                                            .key;
                                                                    var review =
                                                                        entry
                                                                            .value;
                                                                    return SizedBox(
                                                                      width:
                                                                          280.w,
                                                                      child: ReviewRatingCard(
                                                                        rating: review
                                                                            .rating
                                                                            .toDouble(),
                                                                        date: review
                                                                            .createdAt,
                                                                        reviewText:
                                                                            review.comment,
                                                                        index:
                                                                            index,
                                                                        images:
                                                                            review.reviewImages,
                                                                        maxLines:
                                                                            10,
                                                                      ),
                                                                    );
                                                                  })
                                                                  .toList(),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 9.h),
                                          ],
                                        );
                                      }
                                      return SizedBox.shrink();
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),

                                BlocBuilder<ProductFAQBloc, ProductFAQState>(
                                  builder: (BuildContext context, ProductFAQState state) {
                                    if (state is ProductFAQLoaded) {
                                      final faqData =
                                          state.productData.first.data;
                                      return faqData.isNotEmpty
                                          ? Column(
                                              children: [
                                                Card(
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          0.r,
                                                        ),
                                                  ),
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                    vertical: 0.h,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              left: 10.w,
                                                              right: 10.w,
                                                              top: 10.w,
                                                            ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              l10n.questionAndAnswers,
                                                              style: TextStyle(
                                                                fontSize: 14.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.tertiary,
                                                              ),
                                                            ),
                                                            GestureDetector(
                                                              onTap: () {
                                                                GoRouter.of(
                                                                  context,
                                                                ).push(
                                                                  AppRoutes
                                                                      .faqPage,
                                                                  extra: {
                                                                    'productSlug':
                                                                        product
                                                                            .slug,
                                                                  },
                                                                );
                                                              },
                                                              child: Text(
                                                                l10n.seeAll,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: AppTheme
                                                                      .primaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 0.w,
                                                              vertical: 12.w,
                                                            ),
                                                        child: SingleChildScrollView(
                                                          scrollDirection:
                                                              Axis.horizontal,
                                                          physics:
                                                              BouncingScrollPhysics(),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: List.generate(
                                                              faqData.length > 5
                                                                  ? 5
                                                                  : faqData
                                                                        .length,
                                                              (index) {
                                                                final qa =
                                                                    faqData[index];
                                                                return Padding(
                                                                  padding: EdgeInsets.only(
                                                                    right:
                                                                        index ==
                                                                            (faqData.length -
                                                                                1)
                                                                        ? 0.w
                                                                        : 12.w,
                                                                    left:
                                                                        index ==
                                                                            0
                                                                        ? 12.w
                                                                        : 0.w,
                                                                  ),
                                                                  child: GestureDetector(
                                                                    onTap: () {
                                                                      GoRouter.of(
                                                                        context,
                                                                      ).push(
                                                                        AppRoutes
                                                                            .faqPage,
                                                                        extra: {
                                                                          'productSlug':
                                                                              product.slug,
                                                                        },
                                                                      );
                                                                    },
                                                                    child: _buildQAItem(
                                                                      question:
                                                                          qa.question,
                                                                      answer: qa
                                                                          .answer,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : SizedBox.shrink();
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),

                                SizedBox(height: 9.h),

                                BlocBuilder<
                                  SimilarProductBloc,
                                  SimilarProductState
                                >(
                                  builder: (context, state) {
                                    if (state is SimilarProductLoaded) {
                                      return SimilarProductWidget(
                                        product: state.similarProduct,
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              );
            }
            if (state is ProductDetailFailed || state is ProductDetailInitial) {
              // Show simple text with product name from initial data
              return Scaffold(
                appBar: AppBar(title: Text(widget.initialData.title)),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        widget.initialData.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Loading product details...'),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
        bottomNavigationBar: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is! ProductDetailLoaded || state.productData.isEmpty) {
              return SizedBox.shrink();
            }

            final product = state.productData[0];
            ProductVariants activeVariant = product.variants.isEmpty
                ? ProductVariants()
                : product.variants.firstWhere(
                    (v) => v.isDefault,
                    orElse: () => product.variants.first,
                  );

            if (selectedVariants.isNotEmpty && product.variants.isNotEmpty) {
              final selectedTitle = selectedVariants.values.first.value
                  .toString();
              activeVariant = product.variants.firstWhere(
                (v) {
                  final attrValue = v.attributes.values.first.toString();
                  return attrValue.toLowerCase().trim() ==
                      selectedTitle.toLowerCase().trim();
                },
                orElse: () => product.variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => product.variants.first,
                ),
              );
            }

            // Fallback to product-level price if variant price is 0
            final displayPrice = activeVariant.price > 0
                ? activeVariant.price.toDouble()
                : product.price;
            final displaySpecialPrice = (activeVariant.specialPrice > 0
                ? activeVariant.specialPrice.toDouble()
                : product.specialPrice);
            final groupBuyPrice = activeVariant.isGroupBuyEnabled
                ? activeVariant.groupBuyPrice.toDouble()
                : product.groupBuyPrice;

            // Check for active room session
            if (Global.activeRoomCode != null) {
              return _buildRoomCartFooter(product, activeVariant);
            }

            if (product.isGroupBuyEligible && groupBuyPrice > 0) {
              return _buildDualButtonFooter(
                product,
                activeVariant,
                displaySpecialPrice,
                groupBuyPrice,
              );
            }

            return _buildStandardFooter(
              product,
              activeVariant,
              displayPrice,
              displaySpecialPrice,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDualButtonFooter(
    ProductData product,
    ProductVariants activeVariant,
    double normalPrice,
    double gpPrice,
  ) {
    return Container(
      height: 100.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                // Add to cart normally
                _addToCart(product, activeVariant);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppConstant.currency}${normalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: InkWell(
              onTap: () => _handleCreateGroupBuy(product.id),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${AppConstant.currency}${gpPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Start Group Buy',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCartFooter(
    ProductData product,
    ProductVariants activeVariant,
  ) {
    return Container(
      height: 90.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      TablerIcons.users,
                      size: 14.r,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Group Shopping',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Room: ${Global.activeRoomCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      Global.setActiveRoomCode(null);
                    });
                  },
                  child: Text(
                    'Exit Session',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 1,
            child: CustomButton(
              onPressed: () => _addToRoomCart(product, activeVariant),
              child: Text(
                'Add to Room',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToRoomCart(
    ProductData product,
    ProductVariants activeVariant,
  ) async {
    if (Global.userData == null) {
      AuthGuard.ensureLoggedIn(context);
      return;
    }

    if (Global.activeRoomCode == null) return;

    // Variant Selection Validation
    if (product.attributes.isNotEmpty && selectedVariants.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ToastManager.show(
        context: context,
        message: l10n.pleaseSelectVariant,
        type: ToastType.error,
      );
      return;
    }

    final room = await _roomRepository.getRoomDetails(Global.activeRoomCode!);
    if (room == null) {
      ToastManager.show(
        context: context,
        message: 'Room not found. Rejoin your room and try again.',
        type: ToastType.error,
      );
      return;
    }

    if (room.isClosed || room.isFull) {
      ToastManager.show(
        context: context,
        message: 'This room is closed for new items.',
        type: ToastType.error,
      );
      return;
    }

    final quantity = product.quantityStepSize > 0
        ? product.quantityStepSize
        : 1;
    final groupPrice = activeVariant.isGroupBuyEnabled
        ? activeVariant.groupBuyPrice.toDouble()
        : product.groupBuyPrice;
    final fallbackPrice = activeVariant.specialPrice > 0
        ? activeVariant.specialPrice.toDouble()
        : product.specialPrice;

    final updatedRoom = await _roomRepository.addItemToRoom(
      room: room,
      product: GroupBuyProduct(
        id: product.id,
        name: product.title,
        imageUrl: product.mainImage,
        category: product.category,
        price: fallbackPrice,
        groupPrice: groupPrice > 0 ? groupPrice : fallbackPrice,
        inStock: activeVariant.stock > 0,
        stock: activeVariant.stock,
      ),
      quantity: quantity,
    );

    if (updatedRoom == null) {
      ToastManager.show(
        context: context,
        message: 'Unable to add product to room cart.',
        type: ToastType.error,
      );
      return;
    }

    Global.setActiveRoomCode(updatedRoom.code);
    ToastManager.show(
      context: context,
      message: 'Added to room cart',
      type: ToastType.success,
    );
  }

  Widget _buildStandardFooter(
    ProductData product,
    ProductVariants activeVariant,
    double displayPrice,
    double displaySpecialPrice,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.onPrimary
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PriceRowWidget(
                  originalPrice: displayPrice,
                  salePrice: displaySpecialPrice,
                  fontSize: 12.sp,
                  originalFontSize: 10.sp,
                  discountFontSize: 8.sp,
                  fontWeight: FontWeight.w700,
                  originalPriceColor: Colors.grey.shade600,
                ),
              ),
              Text(
                l10n.inclusiveOfAllTax,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(width: 8),
          if (activeVariant.stock > 0)
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 120, minWidth: 80),
                  child: BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      final int productId = product.id;
                      int productVariantId = activeVariant.id;
                      final int storeId = activeVariant.storeId;
                      final cartItem = _getCartItem(
                        cartState,
                        productId,
                        productVariantId,
                        storeId,
                      );
                      final isInCart = cartItem != null;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 45,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isInCart
                              ? AppTheme.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: isInCart
                              ? _buildCartStepper(cartItem)
                              : _buildAddToCartButton(product, activeVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          else
            _buildOutOfStockBadge(),
        ],
      ),
    );
  }

  Widget _buildCartStepper(UserCart cartItem) {
    return Container(
      key: const ValueKey('stepper_inner'),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () async {
              await HapticFeedback.lightImpact();
              if (cartItem.quantity > 1) {
                context.read<CartBloc>().add(
                  UpdateCartQty(
                    cartItem.cartKey,
                    cartItem.quantity - 1,
                    cartItem.serverCartItemId,
                    context,
                  ),
                );
              } else {
                context.read<CartBloc>().add(
                  RemoveFromCart(cartItem.cartKey, context),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Icon(TablerIcons.minus, size: 20.r, color: Colors.white),
            ),
          ),
          Text(
            cartItem.quantity.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await HapticFeedback.lightImpact();
              context.read<CartBloc>().add(
                UpdateCartQty(
                  cartItem.cartKey,
                  cartItem.quantity + 1,
                  cartItem.serverCartItemId,
                  context,
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Icon(TablerIcons.plus, size: 20.r, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(
    ProductData product,
    ProductVariants activeVariant,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      key: const ValueKey('add_button_inner'),
      height: 45,
      width: double.infinity,
      child: CustomButton(
        onPressed: () => _addToCart(product, activeVariant),
        child: Text(
          l10n.add,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOutOfStockBadge() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.primaryColor, width: 1.w),
      ),
      child: Text(
        l10n.outOfStock,
        style: TextStyle(color: AppTheme.errorColor),
      ),
    );
  }

  void _addToCart(ProductData product, ProductVariants activeVariant) {
    if (Global.userData == null) {
      AuthGuard.ensureLoggedIn(context);
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // Variant Selection Validation
    if (product.attributes.isNotEmpty && selectedVariants.isEmpty) {
      ToastManager.show(
        context: context,
        message: l10n.pleaseSelectVariant,
        type: ToastType.error,
      );
      return;
    }

    final isStoreOpen = product.storeStatus?.isOpen ?? true;

    // Resolve selected variant (if any)
    ProductVariants? selectedVariant = activeVariant;

    // Check quantity and validation logic
    final cartBloc = context.read<CartBloc>();
    final requestedQty = product.quantityStepSize;

    final productError = CartValidation.validateProductAddToCart(
      context: context,
      requestedQuantity: requestedQty,
      minQty: product.minimumOrderQuantity,
      maxQty: product.totalAllowedQuantity,
      stock: selectedVariant.stock,
      isStoreOpen: isStoreOpen,
    );

    if (productError != null) {
      ToastManager.show(
        context: context,
        message: productError,
        type: ToastType.error,
      );
      return;
    }

    final item = UserCart(
      productId: product.id.toString(),
      variantId: selectedVariant.id.toString(),
      variantName: selectedVariant.title,
      vendorId: selectedVariant.storeId.toString(),
      name: product.title,
      image: product.mainImage,
      price: selectedVariant.specialPrice.toDouble(),
      originalPrice: selectedVariant.price.toDouble(),
      quantity: product.quantityStepSize,
      serverCartItemId: null,
      syncAction: CartSyncAction.add,
      updatedAt: DateTime.now(),
      minQty: product.minimumOrderQuantity,
      maxQty: product.totalAllowedQuantity,
      isOutOfStock: selectedVariant.stock <= 0,
      isSynced: false,
    );

    cartBloc.add(AddToCart(item, context));
    _trackAddToCart();
  }

  Widget variantWidget({
    required String label,
    required String variantType,
    required SwatchValues? selectedValue,
    required Function(SwatchValues) onSelected,
    required List<SwatchValues> productAttributes,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.8),
                ),
              ),
              Text(
                selectedValue?.value ?? '',
                style: TextStyle(
                  fontSize: isTablet(context) ? 20 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: variantType == 'color' ? 35.h : 25.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productAttributes.length,
              itemBuilder: (BuildContext context, int index) {
                final currentValue = productAttributes[index];
                final isSelected = selectedValue == currentValue;
                final color = getColorFromHex(currentValue.swatch);
                return GestureDetector(
                  onTap: () => onSelected(currentValue),
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: variantType == 'color'
                        ? Container(
                            width: 35.w,
                            height: 45.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              currentValue.value,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildQAItem({required String question, required String answer}) {
    return Container(
      width: 250.w,
      height: 135.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          // Question Section (Top Partition)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11.r),
                topRight: Radius.circular(11.r),
              ),
            ),
            child: Text(
              question,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
          ),
          // Divider
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w300,
                  height: 1.4,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sellerStoreName({
    required String storeName,
    required String storeSlug,
    required String sellerName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push(
          AppRoutes.nearbyStoreDetails,
          extra: {'store-slug': storeSlug, 'store-name': storeName},
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.r)),
        margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 0.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.soldBy} ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isTablet(context) ? 20 : 14.sp,
                ),
              ),
              Expanded(
                child: Text(
                  storeName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isTablet(context) ? 20 : 14.sp,
                  ),
                ),
              ),
              Directionality.of(context) == TextDirection.ltr
                  ? const Icon(TablerIcons.chevron_right, color: Colors.grey)
                  : const Icon(TablerIcons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingBarWidget extends StatelessWidget {
  final int score;
  final double percentage;
  const RatingBarWidget({
    required this.score,
    required this.percentage,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$score',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${percentage.toInt()}%',
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class ProductInitialData {
  final String title;
  final String mainImage;
  final List<String> additionalImages;
  final String videoUrl;
  final String storeSlug;

  ProductInitialData({
    required this.title,
    required this.mainImage,
    this.additionalImages = const [],
    this.videoUrl = '',
    this.storeSlug = '',
  });
}
