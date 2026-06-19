import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CustomSubCategoryCard extends StatelessWidget {
  final String categoryImage;
  final String categoryName;
  final bool isSelected;

  const CustomSubCategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryImage,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          padding: EdgeInsets.all(10.w),
          child: CustomImageContainer(
            imagePath: categoryImage,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          categoryName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
