import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CustomBrandsCard extends StatelessWidget {
  final String brandImage;
  const CustomBrandsCard({super.key, required this.brandImage});

  @override
  Widget build(BuildContext context) {
    return CustomImageContainer(imagePath: brandImage, fit: BoxFit.contain);
  }
}
