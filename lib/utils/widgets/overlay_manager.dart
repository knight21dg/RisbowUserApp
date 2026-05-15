import 'package:flutter/material.dart';

class OverlayManager {
  static OverlayEntry? _overlayEntry;

  static void showLoading(BuildContext context) {
    hideLoading();
    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black45,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hideLoading() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}