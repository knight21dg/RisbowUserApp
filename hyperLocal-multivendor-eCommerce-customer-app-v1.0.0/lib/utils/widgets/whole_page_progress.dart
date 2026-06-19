import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/smooth_loading_overlay.dart';

class WholePageProgress extends StatelessWidget {
  const WholePageProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmoothLoadingOverlay();
  }
}