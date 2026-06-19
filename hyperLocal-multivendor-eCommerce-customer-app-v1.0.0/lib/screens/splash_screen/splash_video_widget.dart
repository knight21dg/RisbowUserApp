import 'package:flutter/material.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class SplashVideoWidget extends StatefulWidget {
  final String? videoUrl;
  final VoidCallback? onComplete;
  final void Function(String)? onError;

  const SplashVideoWidget({
    super.key,
    this.videoUrl,
    this.onComplete,
    this.onError,
  });

  @override
  State<SplashVideoWidget> createState() => _SplashVideoWidgetState();
}

class _SplashVideoWidgetState extends State<SplashVideoWidget>
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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return _buildTestPattern();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildTestPattern(),
    );
  }

  Widget _buildTestPattern() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: getSplashBackgroundColor(context),
        image: const DecorationImage(
          image: AssetImage('assets/images/doodle.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: CustomImageContainer(
          imagePath: getAppLogoUrl(context),
          height: 180,
          width: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}