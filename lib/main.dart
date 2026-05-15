import 'dart:io' as io;
import 'dart:io';
import 'package:hyper_local/utils/widgets/cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/firebase_options.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/bloc/cart_state_bloc/cart_state_bloc.dart';
import 'package:hyper_local/model/user_cart_model/user_cart.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/address_list_page/bloc/check_delivery_zone_bloc/check_delivery_zone_bloc.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';

import 'package:hyper_local/screens/cart_page/bloc/cart_ui_bloc/cart_ui_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/promo_code/promo_code_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:hyper_local/screens/category_list_page/bloc/all_category_bloc/all_category_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/create_order/create_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/delivery_boy_feedback/delivery_boy_feedback_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/delivery_tracking/delivery_tracking_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/download_invoice/download_invoice_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/get_my_order/get_my_order_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/order_detail/order_detail_bloc.dart';
import 'package:hyper_local/screens/my_orders/bloc/return_order_item/return_order_item_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/store_detail/store_detail_bloc.dart';
import 'package:hyper_local/screens/payment_options/bloc/payment_bloc.dart';
import 'package:hyper_local/screens/payment_options/repo/payment_repository.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_review_bloc/product_review_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/nested_category/nested_category_bloc.dart';
import 'package:hyper_local/screens/product_listing_page/bloc/product_listing/product_listing_bloc.dart';
import 'package:hyper_local/screens/save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import 'package:hyper_local/screens/seller_page/bloc/seller_feedback/seller_feedback_bloc.dart';
import 'package:hyper_local/screens/shopping_list_page/bloc/shopping_list_bloc/shopping_list_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/prepare_wallet_recharge/prepare_recharge_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'package:hyper_local/screens/wallet_page/bloc/wallect_transactions/wallet_transactions_bloc.dart';
import 'package:hyper_local/screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';
import 'package:hyper_local/screens/wishlist_page/bloc/wishlist_product_bloc/wishlist_product_bloc.dart';
import 'package:hyper_local/services/address/selected_address_hive.dart';
import 'package:hyper_local/services/group_buy/group_buy_hive_service.dart';
import 'package:hyper_local/services/location/user_location_hive.dart';
import 'package:hyper_local/services/shopping_list_hive.dart';
import 'package:hyper_local/services/user_cart/user_cart_local.dart';
import 'package:hyper_local/services/user_cart/user_cart_remote.dart';
import 'package:hyper_local/widgets/cart_state_listener.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/add_to_cart/add_to_cart_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_event.dart';
import 'package:hyper_local/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_event.dart';
import 'package:hyper_local/screens/home_page/bloc/homepage_section/homepage_section_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/custom_sale_page/custom_sale_page_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_event.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_bloc.dart';
import 'bloc/user_cart_bloc/user_cart_bloc.dart';
import 'bloc/user_details_bloc/user_details_bloc.dart';
import 'bloc/kyc_bloc/kyc_bloc.dart';
import 'bloc/coins_bloc/coins_bloc.dart';
import 'bloc/commission_bloc/commission_bloc.dart';
import 'bloc/inventory_bloc/inventory_bloc.dart';
import 'bloc/analytics_bloc/analytics_bloc.dart';
import 'config/global.dart';
import 'config/notification_service.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/chat_page/bloc/bow/bow_bloc.dart';
import 'model/user_cart_model/cart_sync_action.dart';
import 'services/feature_settings_service.dart';
import 'services/install_attribution_service.dart';
import 'package:flutter/services.dart';
import 'config/settings_data_instance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;
  await FastCachedImageConfig.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  Hive.registerAdapter(CartSyncActionAdapter());
  Hive.registerAdapter(UserCartAdapter());

  await Hive.openBox<UserCart>('cartBox');

  await HiveLocationHelper.init();
  await HiveSelectedAddressHelper.init();
  await ShoppingListHiveHelper.init();
  await GroupBuyHiveService.init();
  await Global.initialize();
  await Global.initializePrefs();
  await Hive.openBox('themebox');

  await FeatureSettingsService.instance.fetchFeatureSettings();

  // Capture any pending deep link or initial URL for referral attribution
  try {
    // This would be set by the platform when app is opened via deep link
    // For now, we rely on splash screen to capture from stored preferences
  } catch (e) {
    debugPrint('Error initializing deep link handling: $e');
  }

  if (kDebugMode) {
    io.HttpClient.enableTimelineLogging = true;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    _initializeNotification();
    super.initState();
  }

  Future<void> _initializeNotification() async {
    await NotificationService(context: context).initFirebaseMessaging(context);
  }

  void _updateStatusBarColor(ThemeMode themeMode) {
    final webSettings = SettingsData.instance.web;
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    
    final statusBarColor = isDark 
        ? (webSettings?.statusBarDarkColor ?? '#000000')
        : (webSettings?.statusBarLightColor ?? '#f8f9fa');
    
    final color = Color(int.parse(statusBarColor.replaceFirst('#', '0xFF')));
    final brightness = isDark ? Brightness.light : Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc(UserDataBloc())),
        BlocProvider(
          create: (context) => CartBloc(
            CartLocalRepository(Hive.box<UserCart>('cartBox')),
            CartRemoteRepository(),
          ),
        ),
        BlocProvider(create: (context) => ThemeBloc()),
        BlocProvider(create: (context) => CategoryBloc()..add(FetchCategory(isHome: true))),
        BlocProvider(create: (context) => BannerBloc()..add(FetchBanner(categorySlug: ''))),
        BlocProvider(create: (context) => LanguageBloc()..add(const LoadLanguage())),
        BlocProvider(create: (context) => FeatureSectionProductBloc()..add(FetchFeatureSectionProducts(slug: ''))),
        BlocProvider(create: (context) => SubCategoryBloc()..add(FetchSubCategory(slug: '',  isForAllCategory: true, isHome: true))),
        BlocProvider(create: (context) => UserDataBloc()),
        BlocProvider(create: (context) => BrandsBloc()..add(FetchBrands(categorySlug: ''))),
        BlocProvider(create: (context) => ProductDetailBloc()),
        BlocProvider(create: (context) => ProductListingBloc()),
        BlocProvider(create: (context) => NestedCategoryBloc()),
        BlocProvider(create: (context) => AddToCartBloc()),
        BlocProvider(create: (context) => GetUserCartBloc(context.read<CartBloc>(),)..add(FetchUserCart())),
        BlocProvider(create: (context) => CartStateBloc()),
        BlocProvider(create: (context) => ProductReviewBloc()),
        BlocProvider(create: (context) => ProductFAQBloc()),
        BlocProvider(create: (context) => RemoveItemFromCartBloc()),
        BlocProvider(create: (context) => ClearCartBloc()),
        BlocProvider(create: (context) => UpdateItemQuantityBloc()),
        BlocProvider(create: (context) => SimilarProductBloc()),
        BlocProvider(create: (context) => CheckDeliveryZoneBloc()),
        BlocProvider(create: (context) => GetAddressListBloc()),
        BlocProvider(create: (context) => SettingsBloc()..add(FetchSettingsData())),
        BlocProvider(create: (context) => CreateOrderBloc()),
        BlocProvider(create: (context) => UserProfileBloc()..add(FetchUserProfile())),
        BlocProvider(create: (context) => PromoCodeBloc()),
        BlocProvider(create: (context) => GetMyOrderBloc()),
        BlocProvider(create: (context) => OrderDetailBloc()),
        BlocProvider(create: (context) => DeliveryBoyFeedbackBloc()),
        BlocProvider(create: (context) => PaymentBloc(paymentRepository: PaymentRepository(), context: context)),
        BlocProvider(create: (context) => DownloadInvoiceBloc()),
        BlocProvider(create: (context) => PrepareRechargeBloc()),
        BlocProvider(create: (context) => UserWalletBloc()),
        BlocProvider(create: (context) => WalletTransactionsBloc()),
        BlocProvider(create: (context) => ShoppingListBloc()),
        BlocProvider(create: (context) => UserWishlistBloc()),
        BlocProvider(create: (context) => WishlistProductBloc()),
        BlocProvider(create: (context) => SaveForLaterBloc()),
        BlocProvider(create: (context) => NearByStoreBloc()),
        BlocProvider(create: (context) => ProductFeedbackBloc()),
        BlocProvider(create: (context) => SellerFeedbackBloc()),
        BlocProvider(create: (context) => ReturnOrderItemBloc()),
        BlocProvider(create: (context) => DeliveryTrackingBloc()),
        BlocProvider(create: (context) => StoreDetailBloc()),
        BlocProvider(create: (context) => CartUIBloc()),
        BlocProvider(create: (context) => AllCategoriesBloc()),
        BlocProvider(create: (context) => KycBloc()),
        BlocProvider(create: (context) => CommissionBloc()),
        BlocProvider(create: (context) => InventoryBloc()),
        BlocProvider(create: (context) => AnalyticsBloc()),
        BlocProvider(create: (context) => HomepageSectionBloc()..add(FetchHomepageSections())),
        BlocProvider(create: (context) => CustomSalePageBloc()..add(FetchCustomSalePages())),
        BlocProvider(create: (context) => BowBloc()..add(BowInitialize())),
        BlocProvider(create: (context) => CoinsBloc()),
      ],
      child: CartStateListener(
        child: BlocListener<ThemeBloc, ThemeMode>(
          listener: (context, themeMode) {
            _updateStatusBarColor(themeMode);
          },
          child: BlocBuilder<ThemeBloc, ThemeMode>(
            builder: (BuildContext context, themeMode) {
            return BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, languageState) {
                return GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ScreenUtilInit(
                    child: SafeArea(
                      top: false,
                      bottom: Platform.isIOS ? false : true,
                      left: false,
                      right: false,
                      child: MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.lightTheme,
                        darkTheme: AppTheme.darkTheme,
                        themeMode: themeMode,
                        builder: FToastBuilder(),
                        routerConfig: MyAppRoute.router,
                        localizationsDelegates: AppLocalizations.localizationsDelegates,
                        supportedLocales: AppLocalizations.supportedLocales,
                        locale: languageState is LanguageLoaded
                            ? languageState.locale
                            : const Locale('en'),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          ),
        ),
      ),
    );
  }
}
