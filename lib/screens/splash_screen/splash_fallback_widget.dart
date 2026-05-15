import 'package:flutter/material.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class SplashFallbackWidget extends StatefulWidget {
  final String? customLogoUrl;
  final Color? backgroundColor;

  const SplashFallbackWidget({
    super.key,
    this.customLogoUrl,
    this.backgroundColor,
  });

  @override
  State<SplashFallbackWidget> createState() => _SplashFallbackWidgetState();
}

class _SplashFallbackWidgetState extends State<SplashFallbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? getSplashBackgroundColor(context),
          image: const DecorationImage(
            image: AssetImage('assets/images/doodle.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: CustomImageContainer(
            imagePath: widget.customLogoUrl ?? getAppLogoUrl(context),
            height: 180,
            width: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}