import 'package:flutter/material.dart';
import '../../config/settings_data_instance.dart';
import '../../l10n/app_localizations.dart';

class CartValidation {
  CartValidation._();

  /// PRODUCT-LEVEL VALIDATIONS
  /// Used when adding/updating a single product in cart
  static String? validateProductAddToCart({
    required BuildContext context,
    required int requestedQuantity,
    required int minQty,
    required int maxQty,
    required int stock,
    bool isStoreOpen = true,
  }) {
    final l10n = AppLocalizations.of(context)!;

    // Out of stock
    if (stock <= 0) {
      return l10n.outOfStock;
    }

    // Store closed
    if (!isStoreOpen) {
      return l10n.looksLikeTheStoreCatchingSomeRest;
    }

    // Below minimum quantity
    if (requestedQuantity < minQty) {
      return l10n.minimumQuantityRequired(minQty);
    }

    // Exceeds max allowed per product
    if (requestedQuantity > maxQty) {
      return l10n.maximumQuantityAllowed(maxQty);
    }

    // Exceeds available stock
    if (requestedQuantity > stock) {
      return l10n.onlyXItemsInStock(stock);
    }

    return null; // Valid
  }

  /// CART-LEVEL VALIDATIONS
  /// Used before checkout or when showing warnings
  static String? validateCartForCheckout({
    required BuildContext context,
    required double cartTotal,
    required int totalItemsCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final system = SettingsData.instance.system!;

    // Minimum cart amount
    if (cartTotal < system.minimumCartAmount) {
      final minAmount = system.minimumCartAmount;
      return l10n.minimumCartAmountRequired(minAmount - cartTotal);
    }

    // Maximum items in cart
    if (totalItemsCount > system.maximumItemsAllowedInCart) {
      return l10n.youHaveReachedMaximumLimitOfTheCart;
    }

    // Multi-store restriction (if your app supports only single store)
    if (system.checkoutType == 'single_store') {
      return l10n.onlyOneStoreAtATime;
    }

    return null;
  }

  /// Helper: Get user-friendly stock message (not error, just info)
  static String getStockMessage({
    required int stock,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (stock <= 0) {
      return l10n.outOfStock;
    } else if (stock <= 5) {
      return l10n.onlyFewLeft(stock);
    }
    return l10n.inStock;
  }
}