import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/animated_button.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CouponCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String couponCode;
  final bool isCollected;
  final VoidCallback? onTap;

  const CouponCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.couponCode,
    this.isCollected = false,
    this.onTap,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool _isApplying = false;

  Future<void> _handleTap() async {
    if (_isApplying) return;
    setState(() {
      _isApplying = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (widget.onTap != null) widget.onTap!();
    if (mounted) {
      setState(() {
        _isApplying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        children: [
          // Main card container
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.blue.shade50]),
              borderRadius: BorderRadius.circular(0),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  child: CustomImageContainer(
                      imagePath: 'assets/images/Group.png'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 25.w, vertical: 15.h),
                      child: Row(
                        children: [
                          CustomImageContainer(
                            imagePath: getAppLogoUrl(context),
                            height: 50.h,
                            width: 80.w,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(
                            width: 10.w,
                          ),

                          // Text content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.title ,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                      color: AppTheme.couponCollectBgColor,
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: DashedBorderPainter(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.couponCode,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 1.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Collected status
                                  AnimatedButton(
                                    onTap:
                                        !widget.isCollected ? _handleTap : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: widget.isCollected
                                            ? Colors.transparent
                                            : const Color(0xFF007933),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isApplying) ...[
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                          ] else ...[
                                            Text(
                                              widget.isCollected
                                                  ? 'Applied'
                                                  : 'Apply',
                                              style: TextStyle(
                                                fontSize: widget.isCollected
                                                    ? 14
                                                    : 12,
                                                fontWeight: FontWeight.w600,
                                                color: widget.isCollected
                                                    ? const Color(0xFF007933)
                                                    : Colors.white,
                                              ),
                                            ),
                                            if (widget.isCollected) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF007933),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: widget.isCollected
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ]
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          circleCard(
                              top: 0.h,
                              left: -12,
                              bottom: 0,
                              isSemiCircleRight: true),
                          circleCard(
                              top: 0.h,
                              right: -12,
                              bottom: 0,
                              isSemiCircleLeft: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// TOP
          circleCard(top: -8.h, right: 80.w, isTopOnCard: true),

          /// BOTTOM
          circleCard(bottom: -8.h, right: 80.w, isBottomOnCard: true),

          /// First
          circleCard(
            top: 5.h,
            left: -8,
          ),
          circleCard(
            top: 5.h,
            right: -8,
          ),

          /// Second
          circleCard(
            top: 25.h,
            left: -8,
          ),
          circleCard(
            top: 25.h,
            right: -8,
          ),

          /// Third
          circleCard(
            top: 45.h,
            left: -8,
          ),
          circleCard(
            top: 45.h,
            right: -8,
          ),

          /// Fourth
          circleCard(
            top: 65.h,
            left: -8,
          ),
          circleCard(
            top: 65.h,
            right: -8,
          ),

          /// Fifth
          circleCard(
            top: 85.h,
            left: -8,
          ),
          circleCard(
            top: 85.h,
            right: -8,
          ),

          /// Sixth
          circleCard(
            top: 105.h,
            left: -8,
          ),
          circleCard(
            top: 105.h,
            right: -8,
          ),

          /// Seventh
          circleCard(
            top: 125.h,
            left: -8,
          ),
          circleCard(
            top: 125.h,
            right: -8,
          ),
        ],
      ),
    );
  }

  Widget circleCard({
    double? top,
    double? left,
    double? bottom,
    double? right,
    bool isSemiCircleLeft = false,
    bool isSemiCircleRight = false,
    bool isTopOnCard = false,
    bool isBottomOnCard = false,
  }) {
    final bool isSemiCircle = isSemiCircleLeft || isSemiCircleRight;

    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      right: right,
      child: CustomPaint(
        painter: DashedCirclePainter(
          isSemiCircle: isSemiCircle,
          isLeft: isSemiCircleLeft,
        ),
        child: Container(
          width: isTopOnCard || isBottomOnCard
              ? 24
              : isSemiCircle
                  ? 24
                  : 16,
          height: isTopOnCard || isBottomOnCard
              ? 24
              : isSemiCircle
                  ? 24
                  : 16,
          decoration: BoxDecoration(
            gradient: isSemiCircle
                ? LinearGradient(
                    begin: isSemiCircleLeft
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: isSemiCircleLeft
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    colors: [Colors.blue.shade50, Colors.white])
                : null,
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SemiCircleClipper extends CustomClipper<Path> {
  final bool isLeft;

  SemiCircleClipper({required this.isLeft});

  @override
  Path getClip(Size size) {
    Path path = Path();

    if (isLeft) {
      // LEFT vertical half
      path.addRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    } else {
      // RIGHT vertical half
      path.addRect(
          Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 2.0;
    const dashSpace = 2.0;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
    );

    // Create dashed effect
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final nextDistance = distance + dashWidth;
        final segment = pathMetric.extractPath(
          distance,
          nextDistance > pathMetric.length ? pathMetric.length : nextDistance,
        );
        canvas.drawPath(segment, paint);
        distance = nextDistance + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedCirclePainter extends CustomPainter {
  final bool isSemiCircle;
  final bool isLeft;

  DashedCirclePainter({required this.isSemiCircle, this.isLeft = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSemiCircle ? AppTheme.primaryColor : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (isSemiCircle) {
      const dashWidth = 2.0;
      const dashSpace = 2.0;
      final circumference = 2 * 3.1415926535 * radius;
      final dashCount = (circumference / (dashWidth + dashSpace)).ceil();

      canvas.save();

      final clipRect = isLeft
          ? Rect.fromLTWH(0, 0, size.width / 2 + 1, size.height)
          : Rect.fromLTWH(
              size.width / 2 - 1, 0, size.width / 2 + 1, size.height);
      canvas.clipRect(clipRect);

      for (int i = 0; i < dashCount; i++) {
        final angle =
            (i * (dashWidth + dashSpace)) / radius * (180 / 3.1415926535);
        final startAngle = angle * 3.1415926535 / 180;
        final sweepAngle = dashWidth / radius;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }

      canvas.restore();
    } else {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
