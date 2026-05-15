import 'dart:core';

import 'package:hyper_local/config/constant.dart';

class ApiRoutes {
  static String verifyUserApi = '${AppConstant.baseUrl}verify-user';
  static String googleAuthApi = '${AppConstant.baseUrl}auth/google/callback';
  static String phoneAuthApi = '${AppConstant.baseUrl}auth/phone/callback';
  static String linkGooglePhoneApi = '${AppConstant.baseUrl}auth/link-google-phone';
  static String logoutApi = '${AppConstant.baseUrl}logout';
  static String fcmTokenApi = '${AppConstant.baseUrl}user/fcm-token';
  static String notificationsApi = '${AppConstant.baseUrl}user/notifications';
  static String unreadNotificationCountApi = '${AppConstant.baseUrl}user/notifications/unread-count';
  static String markNotificationReadApi(int id) => '${AppConstant.baseUrl}user/notifications/$id/mark-read';
  static String markAllNotificationsReadApi = '${AppConstant.baseUrl}user/notifications/mark-all-read';
  static String categoryApi = '${AppConstant.baseUrl}categories';
  static String homeCategoriesApi = '${AppConstant.baseUrl}home/categories';
  static String homeMainCategoriesApi = '${AppConstant.baseUrl}home/main-categories';
  static String homeSectionsApi = '${AppConstant.baseUrl}home/sections';
  static String bannerApi = '${AppConstant.baseUrl}banners';
  static String featureSectionProductApi = '${AppConstant.baseUrl}featured-sections';
  static String subCategoryApi = '${AppConstant.baseUrl}categories';
  static String allTabSubCategoryApi = '${AppConstant.baseUrl}categories/sub-categories';
  static String productDetailApi = '${AppConstant.baseUrl}products/';
  static String brandsApi = '${AppConstant.baseUrl}brands';
  static String addToCartApi = '${AppConstant.baseUrl}user/cart/add';
  static String categoryProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String storeProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String getCartApi = '${AppConstant.baseUrl}user/cart';
  static String removeItemFromCartApi = '${AppConstant.baseUrl}user/cart/item/';
  static String clearCartApi = '${AppConstant.baseUrl}user/cart/clear-cart';
  static String getSimilarProductApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String getRecommendedSimilarProductApi = '${AppConstant.baseUrl}recommendations/similar/';
  static String addAddressApi = '${AppConstant.baseUrl}user/addresses';
  static String getAddressesApi = '${AppConstant.baseUrl}user/addresses';
  static String removeAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String updateAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String checkDeliveryZoneApi = '${AppConstant.baseUrl}delivery-zone/check';
  // Settings API
  static String settingsApi = '${AppConstant.baseUrl}settings';
  static String featureSettingsApi = '${AppConstant.baseUrl}settings/feature_settings';
  static String createOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getMyOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String updateUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String deleteUserApi = '${AppConstant.baseUrl}user/delete-account';
  static String getPromoCodeApi = '${AppConstant.baseUrl}user/promos/available';
  static String validatePromoCodeApi = '${AppConstant.baseUrl}user/promos/validate';
  static String orderDetailApi = '${AppConstant.baseUrl}user/orders/';
  static String addDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback';
  static String updateDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback/';
  static String deleteDeliveryBoyFeedbackApi = '${AppConstant.baseUrl}delivery-boy/feedback/';
  static String razorpayApi = '${AppConstant.baseUrl}razorpay/create-order';
  static String stripeCreatePaymentIntentApi = '${AppConstant.baseUrl}stripe/create-order';
  static String paystackCreateOrderApi = '${AppConstant.baseUrl}paystack/create-order';
  static String prepareWalletRechargeApi = '${AppConstant.baseUrl}user/wallet/prepare-wallet-recharge';
  static String userWalletApi = '${AppConstant.baseUrl}user/wallet';
  static String walletTransactionsApi = '${AppConstant.baseUrl}user/wallet/transactions';
  static String addProductFeedbackApi = '${AppConstant.baseUrl}reviews';
  static String updateProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String deleteProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String addSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback';
  static String updateSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback/';
  static String deleteSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback/';
  static String shoppingListApi = '${AppConstant.baseUrl}products/search-by-keywords';
  static String getWishlistApi = '${AppConstant.baseUrl}wishlists';
  static String createWishlistApi = '${AppConstant.baseUrl}wishlists/create';
  static String addItemInWishlistApi = '${AppConstant.baseUrl}wishlists';
  static String updateWishlistApi = '${AppConstant.baseUrl}wishlists/';
  static String deleteWishlistApi = '${AppConstant.baseUrl}wishlists/';
  static String removeItemFromWishlistApi = '${AppConstant.baseUrl}wishlists/items/';
  static String moveItemToAnotherWishlistApi = '${AppConstant.baseUrl}wishlists/items/';
  // Fallback routes for backward compatibility
  static String getWishlistApiAlt = '${AppConstant.baseUrl}wishlist';
  static String addItemInWishlistApiAlt = '${AppConstant.baseUrl}wishlist';
  static String searchApi = '${AppConstant.baseUrl}delivery-zone/products';
  static String advancedSearchApi = '${AppConstant.baseUrl}products/search';
  static String suggestionsApi = '${AppConstant.baseUrl}products/suggestions';
  static String filterOptionsApi = '${AppConstant.baseUrl}products/filter-options';
  static String wishlistProductApi = '${AppConstant.baseUrl}wishlists/';
  static String saveForLaterApi = '${AppConstant.baseUrl}user/cart/item/save-for-later';
  static String saveProductApi = '${AppConstant.baseUrl}user/cart/item/save-for-later/';
  static String specificFeatureSectionProductApi = '${AppConstant.baseUrl}featured-sections/';
  static String nearByStores = '${AppConstant.baseUrl}delivery-zone/stores';
  static String returnOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String cancelReturnRequestApi = '${AppConstant.baseUrl}user/orders/items/';
  static String cancelOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String storeDetailApi = '${AppConstant.baseUrl}stores/';
  static String storeProductsApi = '${AppConstant.baseUrl}products/store-products';
  static String flutterwaveApi = '${AppConstant.baseUrl}flutterwave/create-order';
  static String cartSyncApi = '${AppConstant.baseUrl}user/cart/sync';
  static String updateStoreBannerApi = '${AppConstant.baseUrl}seller/store/banner';

  // Advertising / Banner Slots API
  static String slotBannersApi = '${AppConstant.baseUrl}advertising/slot-banners';
  static String slotBannerImpressionApi = '${AppConstant.baseUrl}advertising/slot-banners/track';

  static String coinsBalanceApi = '${AppConstant.baseUrl}coins/balance';
  static String coinsStatsApi = '${AppConstant.baseUrl}coins/stats';
  static String coinsSettingsApi = '${AppConstant.baseUrl}coins/settings';
  static String coinsTransactionsApi = '${AppConstant.baseUrl}coins/transactions';
  static String validateReferralApi = '${AppConstant.baseUrl}coins/validate-referral';
  static String applyReferralApi = '${AppConstant.baseUrl}coins/apply-referral';
  static String trackAttributionApi = '${AppConstant.baseUrl}coins/track-attribution';
  static String calculateRedemptionApi = '${AppConstant.baseUrl}coins/calculate-redemption';
  static String redeemForOrderApi = '${AppConstant.baseUrl}coins/redeem-for-order';

  // Rooms API (new backend contract)
  static String roomsApi = '${AppConstant.baseUrl}rooms';
  static String publicRoomsApi = '${AppConstant.baseUrl}rooms/public';
  static String roomApi(String code) => '${AppConstant.baseUrl}rooms/$code';
  static String joinRoomApi(String code) => '${AppConstant.baseUrl}rooms/$code/join';
  static String leaveRoomApi(String code) => '${AppConstant.baseUrl}rooms/$code/leave';
  static String roomItemsApi(String code) => '${AppConstant.baseUrl}rooms/$code/items';
  static String roomItemApi(String code, int itemId) =>
      '${AppConstant.baseUrl}rooms/$code/items/$itemId';
  static String completeRoomApi(String code) => '${AppConstant.baseUrl}rooms/$code/complete';
  static String roomSummaryApi(String code) => '${AppConstant.baseUrl}rooms/$code/summary';
  static String roomItemsByCategoryApi(String code) =>
      '${AppConstant.baseUrl}rooms/$code/items/by-category';
  static String roomItemsByMemberApi(String code) =>
      '${AppConstant.baseUrl}rooms/$code/items/by-member';
  static String roomMemberContributionApi(String code) =>
      '${AppConstant.baseUrl}rooms/$code/member-contribution';
  static String roomSavingsApi(String code) => '${AppConstant.baseUrl}rooms/$code/savings';
  static String roomStatsApi(String code) => '${AppConstant.baseUrl}rooms/$code/stats';
  static String roomCheckoutApi(String code) => '${AppConstant.baseUrl}rooms/$code/checkout';
  static String healthApi = '${AppConstant.baseUrl}health';
  
  // Room Types API
  static String weeklyRoomsApi = '${AppConstant.baseUrl}user/rooms/weekly';
  static String vendorRoomsApi = '${AppConstant.baseUrl}user/rooms/vendor';
  static String groupRoomsApi = '${AppConstant.baseUrl}user/rooms/group';
  static String roomTypesApi = '${AppConstant.baseUrl}user/rooms/types';
  static String joinWeeklyRoomApi = '${AppConstant.baseUrl}user/rooms/weekly/join';
  static String joinVendorRoomApi = '${AppConstant.baseUrl}user/rooms/vendor/join';

// AI Chat (Bow) API
  // Bow AI Shopping Assistant
  // Bow AI Shopping Assistant
  static String bowChatApi = '${AppConstant.baseUrl}user/bow/chat';
  static String bowConfigApi = '${AppConstant.baseUrl}user/bow/config';
  static String bowSuggestionsApi = '${AppConstant.baseUrl}user/bow/suggestions';
  static String bowExecuteActionApi = '${AppConstant.baseUrl}user/bow/execute';
  static String bowTextToSpeechApi = '${AppConstant.baseUrl}user/bow/tts';
  static String bowSpeechToTextApi = '${AppConstant.baseUrl}user/bow/stt';
  static String bowConversationHistoryApi = '${AppConstant.baseUrl}user/bow/history';
  static String bowClearHistoryApi = '${AppConstant.baseUrl}user/bow/clear';
  static String bowPreferencesApi = '${AppConstant.baseUrl}user/bow/preferences';
  static String bowUserInsightsApi = '${AppConstant.baseUrl}user/bow/insights';
  static String bowVisualSearchApi = '${AppConstant.baseUrl}user/bow/visual-search';

  // General Chat API
  // General Chat API
  static String chatApi = '${AppConstant.baseUrl}user/chat';
  static String chatConversationsApi = '${AppConstant.baseUrl}user/chat/conversations';
  static String chatConversationDetailApi(String id) => '${AppConstant.baseUrl}user/chat/conversations/$id';
  static String chatDeleteConversationApi(String id) => '${AppConstant.baseUrl}user/chat/conversations/$id';
  static String chatModelsApi = '${AppConstant.baseUrl}user/chat/models';

  // Seller Membership API
  static String membershipTiersApi = '${AppConstant.baseUrl}membership/tiers';
  static String membershipCurrentApi = '${AppConstant.baseUrl}membership/current';
  static String membershipSubscribeApi = '${AppConstant.baseUrl}membership/subscribe';
  static String membershipCancelApi = '${AppConstant.baseUrl}membership/cancel';
  static String membershipHistoryApi = '${AppConstant.baseUrl}membership/history';
  static String membershipCheckFeatureApi = '${AppConstant.baseUrl}membership/check-feature/';

  static String storiesApi = '${AppConstant.baseUrl}stories';
  static String reelsApi = '${AppConstant.baseUrl}reels';

  // KYC API
  static String kycDocumentsApi = '${AppConstant.baseUrl}admin/kyc/documents';
  static String kycUploadDocumentApi = '${AppConstant.baseUrl}admin/kyc/documents/upload';
  static String kycDashboardApi = '${AppConstant.baseUrl}admin/kyc/dashboard';

  // Commission API
  static String commissionRulesApi = '${AppConstant.baseUrl}admin/commission/rules';
  static String commissionStatsApi = '${AppConstant.baseUrl}admin/commission/stats';
  static String commissionCreateRuleApi = '${AppConstant.baseUrl}admin/commission/rules/create';
  static String commissionUpdateRuleApi = '${AppConstant.baseUrl}admin/commission/rules/';

  // Inventory API
  static String inventorySyncLogsApi = '${AppConstant.baseUrl}admin/inventory/sync-logs';
  static String inventoryBulkUploadApi = '${AppConstant.baseUrl}admin/inventory/bulk-upload';
  static String inventoryDashboardApi = '${AppConstant.baseUrl}admin/inventory/dashboard';
  static String inventoryLowStockApi = '${AppConstant.baseUrl}admin/inventory/low-stock';
  static String inventoryOutOfStockApi = '${AppConstant.baseUrl}admin/inventory/out-of-stock';

  // Analytics API
  static String analyticsOverviewApi = '${AppConstant.baseUrl}admin/analytics/overview';
  static String analyticsCohortApi = '${AppConstant.baseUrl}admin/analytics/cohort';
  static String analyticsClvApi = '${AppConstant.baseUrl}admin/analytics/clv';
  static String analyticsRfmApi = '${AppConstant.baseUrl}admin/analytics/rfm';
  static String analyticsVendorScorecardsApi = '${AppConstant.baseUrl}admin/analytics/vendor-scorecards';
  static String analyticsCategoryPerformanceApi = '${AppConstant.baseUrl}admin/analytics/category-performance';
  static String analyticsOrderMetricsApi = '${AppConstant.baseUrl}admin/analytics/order-metrics';
  static String analyticsRevenueMetricsApi = '${AppConstant.baseUrl}admin/analytics/revenue-metrics';

  // Homepage Dynamic Sections
  static String homepageApi = '${AppConstant.baseUrl}homepage';

  // Custom Sale Pages
  static String customPagesApi = '${AppConstant.baseUrl}custom-pages';
  static String customPagesFooterApi = '${AppConstant.baseUrl}custom-pages/footer';
  static String customPageBySlug(String slug) => '${AppConstant.baseUrl}custom-pages/$slug';
  static String customPageFull(String slug) => '${AppConstant.baseUrl}custom-pages/$slug/full';
  static String customPageBanners(String slug) => '${AppConstant.baseUrl}custom-pages/$slug/banners';
  static String customPageSections(String slug) => '${AppConstant.baseUrl}custom-pages/$slug/sections';
  static String customPageGrids(String slug) => '${AppConstant.baseUrl}custom-pages/$slug/grids';

  // Advanced Rooms with Selective Products/Categories
  static String advancedRoomBySlug(String slug) => '${AppConstant.baseUrl}user/rooms/advanced/$slug';
  static String roomBannersApi(String slug) => '${AppConstant.baseUrl}user/rooms/$slug/banners';
  static String roomSectionsApi(String slug) => '${AppConstant.baseUrl}user/rooms/$slug/sections';
  static String roomProductsApi = '${AppConstant.baseUrl}user/rooms/products';

   // Collaborative Rooms
  static String collaborativeRoomsApi = '${AppConstant.baseUrl}user/rooms/collaborative';
  static String joinCollaborativeRoomApi = '${AppConstant.baseUrl}user/rooms/collaborative/join';

  // Recommendations API
  static String recordProductViewApi = '${AppConstant.baseUrl}recommendations/view';
  static String recordSearchApi = '${AppConstant.baseUrl}recommendations/search';
  static String personalizedRecommendationsApi = '${AppConstant.baseUrl}recommendations/personalized';
  static String trendingRecommendationsApi = '${AppConstant.baseUrl}recommendations/trending';
  static String recentlyViewedApi = '${AppConstant.baseUrl}recommendations/recently-viewed';
  static String continueShoppingApi = '${AppConstant.baseUrl}recommendations/continue-shopping';
  static String cartRecommendationsApi = '${AppConstant.baseUrl}recommendations/cart';
  static String frequentlyBoughtTogetherApi = '${AppConstant.baseUrl}recommendations/frequently-bought-together/';
  static String similarProductsApi = '${AppConstant.baseUrl}recommendations/similar/';
  static String popularSearchesApi = '${AppConstant.baseUrl}recommendations/popular-searches';

  // Collaborative Group Cart
  static String roomCartApi(String code) => '${AppConstant.baseUrl}user/rooms/$code/cart';
  static String deleteRoomCartItemApi(int id) => '${AppConstant.baseUrl}user/rooms/cart/$id';
}
