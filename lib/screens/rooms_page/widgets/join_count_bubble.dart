import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class JoinCountBubble extends StatefulWidget {
  final int memberCount;
  final bool isLive;
  final double size;

  const JoinCountBubble({
    super.key,
    required this.memberCount,
    this.isLive = true,
    this.size = 60,
  });

  @override
  State<JoinCountBubble> createState() => _JoinCountBubbleState();
}

class _JoinCountBubbleState extends State<JoinCountBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _displayedCount = 0;

  @override
  void initState() {
    super.initState();
    _displayedCount = widget.memberCount;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(JoinCountBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberCount != widget.memberCount) {
      setState(() {
        _displayedCount = widget.memberCount;
      });
      if (widget.isLive) {
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLive ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: widget.size.w,
        height: widget.size.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isLive)
              Positioned(
                top: 6.h,
                right: 6.w,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _displayedCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (widget.size / 3).sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'members',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: (widget.size / 6).sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveMemberCount extends StatelessWidget {
  final int currentCount;
  final bool showPulse;
  final Color? color;

  const LiveMemberCount({
    super.key,
    required this.currentCount,
    this.showPulse = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPulse) ...[
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color ?? Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (color ?? Colors.green).withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
        ],
        Text(
          '$currentCount joined',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}