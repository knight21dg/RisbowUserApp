import 'package:flutter/material.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class ErrorMessageHelper {
  static String getErrorMessage(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context);
    return _getFriendlyMessage(error.toString(), l10n?.somethingWentWrong ?? 'Something went wrong. Please try again.');
  }

  static String getErrorMessageFromString(String errorMessage) {
    return _getFriendlyMessage(errorMessage, 'Something went wrong. Please try again.');
  }

  static String _getFriendlyMessage(String error, String fallback) {
    if (error.isEmpty) {
      return fallback;
    }

    final lower = error.toLowerCase();

    if (lower.contains('network') && lower.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (lower.contains('no internet') || lower.contains('socket')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (lower.contains('timeout') || lower.contains('server not responding')) {
      return 'Connection timed out. Please check your network and try again.';
    }
    if (lower.contains('server error') || lower.contains('500') || lower.contains('503')) {
      return 'Something went wrong on our end. Please try again later.';
    }
    if (lower.contains('unauthorized') || lower.contains('unauthenticated') || lower == '401') {
      return 'Your session has expired. Please sign in again.';
    }

    return error;
  }
}
