import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RealtimeMemberProgressBar extends StatefulWidget {
  final int currentMembers;
  final int requiredMembers;
  final Duration animationDuration;
  final bool showLabel;
  final bool showCount;
  final Color? progressColor;
  final Color? backgroundColor;

  const RealtimeMemberProgressBar({
    super.key,
    required this.currentMembers,
    required this.requiredMembers,
    this.animationDuration = const Duration(milliseconds: 500),
    this.showLabel = true,
    this.showCount = true,
    this.progressColor,
    this.backgroundColor,
  });

  @override
  State<RealtimeMemberProgressBar> createState() => _RealtimeMemberProgressBarState();
}

class _RealtimeMemberProgressBarState extends State<RealtimeMemberProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _displayedMembers = 0;

  @override
  void initState() {
    super.initState();
    _displayedMembers = widget.currentMembers;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RealtimeMemberProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMembers != widget.currentMembers) {
      _animateToNewValue(oldWidget.currentMembers, widget.currentMembers);
    }
  }

  void _animateToNewValue(int from, int to) {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    setState(() {
      _displayedMembers = to;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get progress {
    if (widget.requiredMembers <= 0) return 0.0;
    return (_displayedMembers / widget.requiredMembers).clamp(0.0, 1.0);
  }

  int get membersNeeded {
    return (widget.requiredMembers - _displayedMembers).clamp(0, widget.requiredMembers);
  }

  bool get isUnlocked => _displayedMembers >= widget.requiredMembers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Stack(
            children: [
              Container(
                height: 12.h,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: AnimatedFractionallySizedBox(
                    duration: widget.animationDuration,
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlocked
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : [
                                  widget.progressColor ?? Theme.of(context).colorScheme.primary,
                                  (widget.progressColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.8),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (progress > 0 && progress < 1)
                Positioned(
                  left: (MediaQuery.of(context).size.width * progress * 0.9) - 20,
                  top: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showLabel || widget.showCount) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUnlocked
                    ? '🎉 Deal Unlocked!'
                    : '$membersNeeded more to unlock',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
              if (widget.showCount)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? Colors.green.shade50
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$_displayedMembers / ${widget.requiredMembers}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.alignment,
    super.duration = const Duration(milliseconds: 500),
    super.curve = Curves.linear,
    this.child,
  });

  @override
  AnimatedFractionallySizedBoxState createState() => AnimatedFractionallySizedBoxState();
}

class AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}