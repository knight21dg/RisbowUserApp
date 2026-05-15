import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global_keys.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local/screens/auth/bloc/auth/auth_state.dart';

import 'package:hyper_local/screens/auth/view/login_page.dart';
import 'package:hyper_local/screens/auth/view/google_phone_link_page.dart';
import 'package:hyper_local/screens/auth/view/otp_verification_page.dart';

import 'package:hyper_local/screens/cart_page/view/cart_page.dart';
import 'package:hyper_local/screens/cart_page/view/promo_code_page.dart';
import 'package:hyper_local/screens/category_list_page/view/category_list_page.dart';
import 'package:hyper_local/screens/home_page/view/home_page.dart';
import 'package:hyper_local/screens/introduction_pages/view/introduction_page.dart';
import 'package:hyper_local/screens/my_orders/view/delivery_tracking_page.dart';
import 'package:hyper_local/screens/my_orders/view/order_detail_page.dart';
import 'package:hyper_local/screens/my_orders/view/rate_your_exp_comments.dart';
import 'package:hyper_local/screens/notification_page/view/notification_page.dart';
import 'package:hyper_local/screens/my_orders/view/rate_your_exp_page.dart';
import 'package:hyper_local/screens/near_by_stores/view/nearby_store_details.dart';
import 'package:hyper_local/screens/near_by_stores/view/nearyby_stores_page.dart';
import 'package:hyper_local/screens/product_detail_page/view/faq_list_page/faq_list_page.dart';
import 'package:hyper_local/screens/product_detail_page/view/review_rating_list_page/review_rating_list_page.dart';
import 'package:hyper_local/screens/shopping_list_page/view/shopping_list_result_page.dart';
import 'package:hyper_local/screens/splash_screen/splash_screen.dart';
import 'package:hyper_local/screens/support_page/view/support_page.dart';
import 'package:hyper_local/screens/user_profile/view/user_profile_page.dart';
import 'package:hyper_local/screens/wallet_page/view/transaction_page.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/utils/widgets/no_internet_connection.dart';
import '../config/map_code.dart';
import '../screens/account_page/view/account_page.dart';
import '../screens/brand_list_page/view/brands_list_page.dart';
import '../screens/dashboard/view/dashboard.dart';
import '../screens/my_orders/view/my_orders_page.dart';
import '../screens/my_orders/view/order_success_page.dart' as my_orders;
import '../screens/policies/view/app_policies_page.dart';
import '../screens/product_detail_page/view/product_detail_page.dart';
import '../screens/address_list_page/view/address_list_page.dart';
import '../screens/payment_options/view/payment_options_page.dart';
import '../screens/product_listing_page/model/product_listing_type.dart';
import '../screens/product_listing_page/view/product_listing_page.dart';
import '../screens/save_for_later_page/view/save_for_later_page.dart';
import '../screens/search_page/view/search_page.dart';
import '../screens/shopping_list_page/view/shopping_list_page.dart';
import '../screens/wallet_page/view/add_money_page.dart';
import '../screens/wallet_page/view/wallet_page.dart';
import '../screens/wallet_page/view/coins_page.dart';
import '../screens/wallet_page/view/referral_page.dart';
import '../screens/wallet_page/view/coins_transactions_page.dart';
import '../screens/chat_page/view/chat_page.dart';
import '../screens/social_page/view/social_page.dart';
import '../screens/seller_membership_page/view/membership_page.dart';
import '../screens/wishlist_page/view/wishlist_page.dart';
import '../screens/wishlist_page/view/wishlist_product_listing_page.dart';
import '../screens/admin_page/view/kyc_verification_page.dart';
import '../screens/admin_page/view/commission_config_page.dart';
import '../screens/admin_page/view/inventory_sync_page.dart';
import '../screens/admin_page/view/analytics_dashboard_page.dart';
import '../screens/custom_sale_page/view/custom_sale_page_view.dart';
import '../screens/compare_page/view/compare_page.dart';
import '../screens/flash_sales_page/view/flash_sales_page.dart';
import '../screens/live_chat_page/view/live_chat_page.dart';
import '../screens/stories_page/view/stories_page.dart';
import '../screens/rooms_page/view/rooms_home_page.dart';
import '../screens/rooms_page/view/room_details_page.dart';
import '../screens/rooms_page/view/create_room_page.dart';
import '../screens/rooms_page/view/join_room_page.dart';
import '../screens/rooms_page/view/discover_rooms_page.dart';
import '../screens/rooms_page/view/group_products_page.dart';
import '../screens/rooms_page/view/checkout_page.dart';
import '../screens/rooms_page/view/order_success_page.dart';

Page platformPage(Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(child: child);
  } else {
    return MaterialPage(child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String introSlider = '/intro-slider';
  static const String login = '/login';

  static const String otpVerification = '/otp-verification';
  static const String googlePhoneLink = '/google-phone-link';
  static const String home = '/home';
  static const String orderAgain = '/order-again';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String locationPicker = '/location-picker';
  static const String account = '/account';
  static const String productListing = '/product-listing';
  static const String productDetailPage = '/product-detail';
  static const String reviewRatingPage = '/review-rating';
  static const String faqPage = '/faq';
  static const String addressList = '/address-list';
  static const String paymentOptions = '/payment-options';
  static const String orderSuccess = '/order-success';
  static const String userProfile = '/user-profile';
  static const String promoCode = '/promo-code';
  static const String myOrders = '/my-orders';
  static const String orderDetail = '/order-detail';
  static const String shoppingList = '/shopping-list';
  static const String wallet = '/wallet';
  static const String addMoney = '/add-money';
  static const String transactions = '/transactions';
  static const String coins = '/coins';
  static const String coinsTransactions = '/coins-transactions';
  static const String referral = '/referral';
  static const String chat = '/chat';
  static const String social = '/social';
  static const String membership = '/membership';
  static const String deliveryTracking = '/delivery-tracking';
  static const String shoppingListResult = '/shopping-list-result';
  static const String notifications = '/notifications';
  static const String wishlistPage = '/wishlist';
  static const String noInternet = '/no-internet';
  static const String search = '/search';
  static const String wishlistProduct = '/wishlist-product';
  static const String saveForLater = '/save-for-later';
  static const String policyPage = '/policy-page';
  static const String supportPage = '/support-page';
  static const String nearbyStores = '/near-by-store';
  static const String nearbyStoreDetails = '/near-by-store-details';
  static const String rateYourExp = '/rate-your-exp';
  static const String rateYourExpComments = '/rate-your-exp-comments';
  // Deep link routes
  static const String productDeepLink = '/p';
  static const String categoryDeepLink = '/c';
  static const String storeDeepLink = '/s';

  static const String maintenancePage = '/maintenance-page';
  static const String brandsListPage = '/brands-list-page';
  static const String kycVerification = '/kyc-verification';
  static const String commissionConfig = '/commission-config';
  static const String inventorySync = '/inventory-sync';
  static const String analyticsDashboard = '/analytics-dashboard';
  static const String customSalePages = '/custom-sale-pages';
  static const String customSalePage = '/custom-sale-page/:slug';
  static const String compare = '/compare';
  static const String flashSales = '/flash-sales';
  static const String liveChat = '/live-chat';
  static const String stories = '/stories';

  // Group Buy Routes
  static const String rooms = '/rooms';
  static const String roomDetail = '/rooms/:code';
  static const String createGroupBuy = '/rooms/create';
  static const String discoverRooms = '/rooms/discover';
  static const String joinRoom = '/rooms/join';
  static const String groupProducts = '/rooms/products';
  static const String roomCheckout = '/rooms/checkout';
  static const String checkoutSuccess = '/checkout-success';
}

class MyAppRoute {
  static const List<String> _groupBuySubPaths = [
    '/rooms/create',
    '/rooms/discover',
    '/rooms/join',
    '/rooms/products',
    '/rooms/checkout',
  ];

  static GoRouter router = GoRouter(
    navigatorKey: GlobalKeys.navigatorKey,
    initialLocation: AppRoutes.splashScreen,
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.toString();
      final uri = Uri.tryParse(path);
      final pathSegments = uri?.pathSegments ?? [];

      // Handle deep links like risbow://room/CODE
      if (path.contains('/room/')) {
        final parts = path.split('/room/');
        if (parts.length > 1) {
          final code = parts[1].split('?').first.trim().toUpperCase();
          if (code.isNotEmpty && path != '/rooms/$code') {
            return '/rooms/$code';
          }
        }
      }

      // Handle referral deep links like risbow://ref/CODE or risbow://referral/CODE
      if (path.contains('/ref/') || path.contains('/referral/')) {
        final regex = RegExp(
          r'/(?:ref|referral)/([A-Za-z0-9]+)',
          caseSensitive: false,
        );
        final match = regex.firstMatch(path);
        if (match != null) {
          final referralCode = match.group(1)?.toUpperCase();
          if (referralCode != null && referralCode.isNotEmpty) {}
        }
      }

      if (path.contains('/rooms/')) {
        final isGroupBuySubPath = _groupBuySubPaths.any((p) => path == p || path.startsWith('$p?'));
        if (isGroupBuySubPath) {
          return null;
        }
        final parts = path.split('/rooms/');
        if (parts.length > 1) {
          final code = parts[1].split('?').first.trim().toUpperCase();
          if (code.isNotEmpty && path != '/rooms/$code') {
            return '/rooms/$code';
          }
        }
      }

      // Handle risbow:// links
      if (path.startsWith('risbow://')) {
        final uri = path.replaceFirst('risbow://', '/');
        return uri;
      }

      // Handle custom page URLs: /api/custom-pages/slug or /custom-pages/slug
      if (pathSegments.length >= 3 &&
          pathSegments[0] == 'api' &&
          pathSegments[1] == 'custom-pages' &&
          pathSegments[2].isNotEmpty) {
        return '/custom-sale-page/${pathSegments[2]}';
      }
      if (pathSegments.length >= 2 &&
          pathSegments[0] == 'custom-pages' &&
          pathSegments[1].isNotEmpty) {
        return '/custom-sale-page/${pathSegments[1]}';
      }

      // Handle short URL slugs: /p/slug, /c/slug, /s/slug
      if (pathSegments.isNotEmpty) {
        final prefix = pathSegments.first;
        final slug = pathSegments.length > 1
            ? pathSegments[1]
            : (pathSegments.first == prefix ? '' : prefix);

        if (prefix == 'p' && slug.isNotEmpty) {
          return '/product-detail?slug=$slug';
        }
        if (prefix == 'c' && slug.isNotEmpty) {
          return '/product-listing?type=category&identifier=$slug';
        }
        if (prefix == 's' && slug.isNotEmpty) {
          return '/near-by-store-details?store-slug=$slug';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        name: '/',
        path: AppRoutes.splashScreen,
        pageBuilder: (context, state) => platformPage(SplashScreen()),
      ),

      GoRoute(
        name: '/intro-slider',
        path: AppRoutes.introSlider,
        pageBuilder: (context, state) => platformPage(IntroductionPage()),
      ),

      GoRoute(
        path: '/link',
        name: 'firebase-link',
        redirect: (context, state) {
          final authBloc = BlocProvider.of<AuthBloc>(
            GlobalKeys.navigatorKey.currentContext!,
          );
          final authState = authBloc.state;

          // If we have pending registration data → go to OTP
          if (authState is LoginPhoneCodeSentState) {
            final pendingData = authBloc.getPendingRegistrationData();
            if (pendingData != null) {
              // Don't redirect here — let the pageBuilder push to OTP
              return null; // stay on /link temporarily
            } else {
              // No pending data → redirect to register
              return AppRoutes.login;
            }
          }

          // If auth failed → go to register
          if (authState is AuthFailed) {
            return AppRoutes.login;
          }

          // Otherwise stay on /link to show loading
          return null;
        },
        pageBuilder: (context, state) {
          return platformPage(
            BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) async {
                if (authState is LoginPhoneCodeSentState) {
                  final bloc = context.read<AuthBloc>();
                  final pendingData = bloc.getPendingRegistrationData();

                  if (pendingData != null && context.mounted) {
                    context.pushReplacement(
                      // ← Use pushReplacement!
                      AppRoutes.otpVerification,
                      extra: {
                        'phoneNumber': bloc.getPendingPhoneNumber(),
                        'registrationData': pendingData,
                        'verificationId': authState.verificationId,
                        'userNumber': bloc.getPendingPhoneNumber(),
                        'countryCode': bloc.getPendingCountryCode(),
                        'isoCode': bloc.getPendingIsoCode(),
                      },
                    );
                  }
                  // No else needed — redirect will handle going to register
                }

                if (authState is AuthFailed && context.mounted) {
                  ToastManager.show(
                    context: context,
                    message: authState.error,
                    type: ToastType.error,
                  );

                  // This will now work reliably because redirect handles fallback
                  context.go(AppRoutes.login);
                }
              },
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [CustomCircularProgressIndicator()],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      GoRoute(
        name: 'otp-verification',
        path: AppRoutes.otpVerification,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            OTPVerificationPage(
              phoneNumber: extra['phoneNumber'] ?? '',
              registrationData: extra['registrationData'] ?? {},
              verificationId: extra['verificationId'] ?? '',
              number: extra['userNumber'] ?? '',
              countryCode: extra['countryCode'] ?? '',
              isoCode: extra['isoCode'] ?? '',
              isGoogleLinking: extra['isGoogleLinking'] ?? false,
              googleToken: extra['googleToken'] ?? '',
            ),
          );
        },
      ),

      GoRoute(
        name: 'login',
        path: AppRoutes.login,
        pageBuilder: (context, state) => platformPage(LoginPage()),
      ),

      GoRoute(
        name: 'googlePhoneLink',
        path: AppRoutes.googlePhoneLink,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            GooglePhoneLinkPage(
              googleName: extra['googleName'] ?? '',
              googleEmail: extra['googleEmail'] ?? '',
              googleProfileImage: extra['googleProfileImage'] ?? '',
              googleToken: extra['googleToken'] ?? '',
            ),
          );
        },
      ),

      GoRoute(
        name: 'no-internet',
        path: AppRoutes.noInternet,
        pageBuilder: (context, state) =>
            platformPage(const NoInternetConnection()),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Dashboard(
            index: navigationShell.currentIndex,
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'home',
                path: AppRoutes.home,
                pageBuilder: (context, state) => platformPage(HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'category-list-page',
                path: AppRoutes.categories,
                pageBuilder: (context, state) =>
                    platformPage(CategoryListPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'chat',
                path: AppRoutes.chat,
                pageBuilder: (context, state) => platformPage(ChatPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'near-by-store',
                path: AppRoutes.nearbyStores,
                pageBuilder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return platformPage(NearbyStoresPage(
                    categorySlug: extra?['categorySlug'] as String?,
                    categoryTitle: extra?['categoryTitle'] as String?,
                  ));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'account',
                path: AppRoutes.account,
                pageBuilder: (context, state) => platformPage(AccountPage()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        name: 'cart',
        path: AppRoutes.cart,
        pageBuilder: (context, state) => platformPage(CartPage()),
      ),
      GoRoute(
        name: 'location-picker',
        path: AppRoutes.locationPicker,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return LocationPickerWidget(
            initialLatitude: args?['lat'],
            initialLongitude: args?['lng'],
            initialAddress: args?['address'],
            isFromAddressPage: args?['isFromAddressPage'],
            isEdit: args?['isEdit'],
            addressId: args?['addressId'],
            addressType: args?['addressType'],
            isFromCartPage: args?['isFromCartPage'],
            deliveryZoneId: args?['deliveryZoneId'],
          );
        },
      ),
      GoRoute(
        name: 'product-listing',
        path: AppRoutes.productListing,
        pageBuilder: (context, state) {
          // Support both extra and query params (for deep linking)
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final queryParams = state.uri.queryParameters;
          final isTheirMoreCategory =
              extra['isTheirMoreCategory'] as bool? ??
              (queryParams['isTheirMoreCategory'] == 'true') || false;
          final dynamic rawType = extra['type'] ?? queryParams['type'];
          final ProductListingType listingType = rawType is ProductListingType
              ? rawType
              : rawType is String
              ? ProductListingType.values.firstWhere(
                  (e) => e.name == rawType,
                  orElse: () => ProductListingType.category,
                )
              : ProductListingType.category;
          final String identifier =
              (extra['identifier']?.toString() ??
              extra['categorySlug']?.toString() ??
              queryParams['identifier']?.toString() ??
              queryParams['categorySlug']?.toString() ??
              '');
          final String title =
              (extra['title']?.toString() ??
              queryParams['title']?.toString() ??
              '');
          return platformPage(
            ProductListingPage(
              isTheirMoreCategory: isTheirMoreCategory,
              title: title,
              logo:
                  extra['logo']?.toString() ??
                  queryParams['logo']?.toString() ??
                  '',
              totalProduct:
                  extra['totalProduct']?.toString() ??
                  queryParams['totalProduct']?.toString() ??
                  '',
              type: listingType,
              identifier: identifier,
            ),
          );
        },
      ),
      // Route for /products - maps to product listing with sort
      GoRoute(
        name: 'products',
        path: '/products',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          final sortType = queryParams['sort'] ?? 'relevance';
          return platformPage(
            ProductListingPage(
              isTheirMoreCategory: false,
              title: 'Products',
              logo: '',
              totalProduct: '',
              type: ProductListingType.all,
              identifier: '',
              sortType: sortType,
            ),
          );
        },
      ),
      GoRoute(
        name: 'product-detail',
        path: AppRoutes.productDetailPage,
        pageBuilder: (context, state) {
          // Support both extra and query params (for deep linking)
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final queryParams = state.uri.queryParameters;
          final productSlug =
              extra['productSlug']?.toString() ??
              queryParams['slug']?.toString() ??
              queryParams['productSlug']?.toString() ??
              '';
          return platformPage(
            ProductDetailPage(
              key: ValueKey('product-detail-$productSlug'),
              productSlug: productSlug,
              initialData: ProductInitialData(title: 'title', mainImage: ''),
            ),
          );
        },
      ),
      GoRoute(
        name: 'review-rating',
        path: AppRoutes.reviewRatingPage,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return platformPage(
            ReviewRatingListPage(productSlug: extra['productSlug'] ?? ''),
          );
        },
      ),
      GoRoute(
        name: 'faq',
        path: AppRoutes.faqPage,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return platformPage(
            FaqListPage(productSlug: extra['productSlug'] ?? ''),
          );
        },
      ),
      GoRoute(
        name: 'address-list',
        path: AppRoutes.addressList,
        pageBuilder: (context, state) => platformPage(AddressListPage()),
      ),
      GoRoute(
        name: 'payment-options',
        path: AppRoutes.paymentOptions,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            PaymentOptionsPage(
              totalAmount: extra['totalAmount']?.toDouble() ?? 0.0,
              isFromAddMoney: extra['isFromAddMoney'] as bool? ?? false,
            ),
          );
        },
      ),
      GoRoute(
        name: 'order-success',
        path: AppRoutes.orderSuccess,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            my_orders.OrderSuccessPage(
              address: extra['address'].toString(),
              addressType: extra['addressType'].toString(),
              orderSlug: extra['orderSlug'].toString(),
            ),
          );
        },
      ),

      GoRoute(
        name: 'user-profile',
        path: AppRoutes.userProfile,
        pageBuilder: (context, state) => platformPage(UserProfilePage()),
      ),

      GoRoute(
        name: 'promo-code',
        path: AppRoutes.promoCode,
        pageBuilder: (context, state) => platformPage(PromoCodePage()),
      ),

      GoRoute(
        name: 'my-orders',
        path: AppRoutes.myOrders,
        pageBuilder: (context, state) => platformPage(MyOrdersPage()),
      ),

      GoRoute(
        name: 'order-detail',
        path: AppRoutes.orderDetail,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(OrderDetailPage(orderSlug: extra['order-slug']));
        },
      ),

      GoRoute(
        name: 'shopping-list',
        path: AppRoutes.shoppingList,
        pageBuilder: (context, state) => platformPage(ShoppingListPage()),
      ),

      GoRoute(
        name: 'wallet',
        path: AppRoutes.wallet,
        pageBuilder: (context, state) => platformPage(WalletPage()),
      ),

      GoRoute(
        name: 'add-money',
        path: AppRoutes.addMoney,
        pageBuilder: (context, state) => platformPage(AddMoneyPage()),
      ),

      GoRoute(
        name: 'transactions',
        path: AppRoutes.transactions,
        pageBuilder: (context, state) => platformPage(TransactionPage()),
      ),

      GoRoute(
        name: 'coins',
        path: AppRoutes.coins,
        pageBuilder: (context, state) => platformPage(CoinsPage()),
      ),

      GoRoute(
        name: 'coins-transactions',
        path: AppRoutes.coinsTransactions,
        pageBuilder: (context, state) => platformPage(CoinsTransactionsPage()),
      ),

      GoRoute(
        name: 'referral',
        path: AppRoutes.referral,
        pageBuilder: (context, state) => platformPage(const ReferralPage()),
      ),

      GoRoute(
        name: 'rooms',
        path: AppRoutes.rooms,
        pageBuilder: (context, state) => platformPage(const RoomsHomePage()),
      ),

      GoRoute(
        name: 'create-group-buy',
        path: AppRoutes.createGroupBuy,
        pageBuilder: (context, state) => platformPage(const CreateRoomPage()),
      ),

      GoRoute(
        name: 'discover-rooms',
        path: AppRoutes.discoverRooms,
        pageBuilder: (context, state) =>
            platformPage(const DiscoverRoomsPage()),
      ),

      GoRoute(
        name: 'join-room',
        path: AppRoutes.joinRoom,
        pageBuilder: (context, state) => platformPage(const JoinRoomPage()),
      ),

      GoRoute(
        name: 'group-products',
        path: AppRoutes.groupProducts,
        pageBuilder: (context, state) {
          final roomCode = state.extra as String?;
          return platformPage(GroupProductsPage(roomCode: roomCode));
        },
      ),

      GoRoute(
        name: 'room-checkout',
        path: AppRoutes.roomCheckout,
        pageBuilder: (context, state) {
          final code = state.extra as String?;
          return platformPage(CheckoutPage(roomCode: code));
        },
      ),

      GoRoute(
        name: 'room-detail',
        path: AppRoutes.roomDetail,
        pageBuilder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return platformPage(RoomDetailsPage(roomCode: code));
        },
      ),

      GoRoute(
        name: 'checkout-success',
        path: AppRoutes.checkoutSuccess,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            OrderSuccessPage(
              orderId: extra['order_id'] ?? 'ORD-12345',
              total: extra['total'] ?? 0.0,
            ),
          );
        },
      ),

      GoRoute(
        name: 'social',
        path: AppRoutes.social,
        pageBuilder: (context, state) => platformPage(const SocialPage()),
      ),

      GoRoute(
        name: 'membership',
        path: AppRoutes.membership,
        pageBuilder: (context, state) => platformPage(const MembershipPage()),
      ),

      GoRoute(
        name: 'delivery-tracking',
        path: AppRoutes.deliveryTracking,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            DeliveryTrackingPage(orderSlug: extra['order-slug']),
          );
        },
      ),

      GoRoute(
        name: 'shopping-list-result',
        path: AppRoutes.shoppingListResult,
        pageBuilder: (context, state) => platformPage(ShoppingListResultPage()),
      ),

      GoRoute(
        name: 'wishlist',
        path: AppRoutes.wishlistPage,
        pageBuilder: (context, state) => platformPage(WishlistPage()),
      ),

      GoRoute(
        name: 'search',
        path: AppRoutes.search,
        pageBuilder: (context, state) => platformPage(SearchPage()),
      ),

      GoRoute(
        name: 'wishlist-product',
        path: AppRoutes.wishlistProduct,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            WishlistProductListingPage(wishlistId: extra['wishlist-id']),
          );
        },
      ),

      GoRoute(
        name: 'save-for-later',
        path: AppRoutes.saveForLater,
        pageBuilder: (context, state) => platformPage(SaveForLaterPage()),
      ),

      GoRoute(
        name: 'policy-page',
        path: AppRoutes.policyPage,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return platformPage(
            PolicyPage(policyType: extra['policy-type'] ?? PolicyType.aboutUs),
          );
        },
      ),

      GoRoute(
        name: 'support-page',
        path: AppRoutes.supportPage,
        pageBuilder: (context, state) => platformPage(SupportPage()),
      ),

      GoRoute(
        name: 'near-by-store-details',
        path: AppRoutes.nearbyStoreDetails,
        pageBuilder: (context, state) {
          // Support both extra and query params
          final map = state.extra as Map<String, dynamic>? ?? {};
          final queryParams = state.uri.queryParameters;
          final storeSlug =
              map['store-slug'] ?? queryParams['store-slug'] ?? '';
          final storeName =
              map['store-name'] ?? queryParams['store-name'] ?? '';
          return platformPage(
            NearbyStoreDetails(storeSlug: storeSlug, storeName: storeName),
          );
        },
      ),

      GoRoute(
        name: 'rate-your-exp',
        path: AppRoutes.rateYourExp,
        pageBuilder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          final orderSlug = map["orderSlug"];
          final orderId = map["orderId"];
          return platformPage(
            RateYourExpPage(orderSlug: orderSlug, orderId: orderId),
          );
        },
      ),

      GoRoute(
        name: 'rate-your-exp-comments',
        path: AppRoutes.rateYourExpComments,
        pageBuilder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          final orderSlug = map["orderSlug"];
          final items = map["items"];
          return platformPage(
            RateYourExpComments(orderSlug: orderSlug, items: items),
          );
        },
      ),

      GoRoute(
        name: 'maintenance-page',
        path: AppRoutes.maintenancePage,
        pageBuilder: (context, state) => platformPage(MaintenancePage()),
      ),

      GoRoute(
        name: 'brands-list-page',
        path: AppRoutes.brandsListPage,
        pageBuilder: (context, state) {
          final map = state.extra as Map<String, dynamic>;
          final categorySlug = map["category-slug"];
          return platformPage(BrandsListPage(categorySlug: categorySlug));
        },
      ),

      GoRoute(
        name: 'kyc-verification',
        path: AppRoutes.kycVerification,
        pageBuilder: (context, state) =>
            platformPage(const KycVerificationPage()),
      ),

      GoRoute(
        name: 'commission-config',
        path: AppRoutes.commissionConfig,
        pageBuilder: (context, state) =>
            platformPage(const CommissionConfigPage()),
      ),

      GoRoute(
        name: 'inventory-sync',
        path: AppRoutes.inventorySync,
        pageBuilder: (context, state) =>
            platformPage(const InventorySyncPage()),
      ),

      GoRoute(
        name: 'analytics-dashboard',
        path: AppRoutes.analyticsDashboard,
        pageBuilder: (context, state) =>
            platformPage(const AnalyticsDashboardPage()),
      ),
      GoRoute(
        name: 'notifications',
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => platformPage(const NotificationPage()),
      ),

      GoRoute(
        name: 'custom-sale-pages',
        path: AppRoutes.customSalePages,
        pageBuilder: (context, state) =>
            platformPage(const CustomSalePageListView()),
      ),

      GoRoute(
        name: 'custom-sale-page',
        path: AppRoutes.customSalePage,
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          return platformPage(CustomSalePageView(slug: slug));
        },
      ),

      GoRoute(
        name: 'compare',
        path: AppRoutes.compare,
        pageBuilder: (context, state) => platformPage(const ComparePage()),
      ),

      GoRoute(
        name: 'flash-sales',
        path: AppRoutes.flashSales,
        pageBuilder: (context, state) => platformPage(const FlashSalesPage()),
      ),

      GoRoute(
        name: 'live-chat',
        path: AppRoutes.liveChat,
        pageBuilder: (context, state) => platformPage(const LiveChatPage()),
      ),

      GoRoute(
        name: 'stories',
        path: AppRoutes.stories,
        pageBuilder: (context, state) => platformPage(const StoriesPage()),
      ),

      // Short URL slugs: /p/product-slug -> product detail
      GoRoute(
        name: 'product-slug',
        path: '/p/:slug',
        redirect: (context, state) =>
            '/product-detail?slug=${state.pathParameters["slug"]}',
      ),
      GoRoute(
        name: 'category-slug',
        path: '/c/:slug',
        redirect: (context, state) =>
            '/product-listing?type=category&identifier=${state.pathParameters["slug"]}',
      ),
      GoRoute(
        name: 'store-slug',
        path: '/s/:slug',
        redirect: (context, state) =>
            '/near-by-store-details?store-slug=${state.pathParameters["slug"]}',
      ),
      GoRoute(
        name: 'not-found',
        path: '/:path(.*)',
        redirect: (context, state) => AppRoutes.home,
      ),
    ],
  );
}
