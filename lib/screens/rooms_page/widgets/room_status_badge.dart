import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../model/group_buy_models.dart';

class RoomStatusBadge extends StatelessWidget {
  final RoomState roomState;
  final bool showLabel;
  final double? fontSize;

  const RoomStatusBadge({
    super.key,
    required this.roomState,
    this.showLabel = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            color: Colors.white,
            size: (fontSize ?? 10).sp,
          ),
          if (showLabel) ...[
            SizedBox(width: 4.w),
            Text(
              roomState.displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (roomState) {
      case RoomState.teasing:
        return Colors.blue;
      case RoomState.active:
        return Colors.green;
      case RoomState.unlocked:
        return Colors.orange;
      case RoomState.locked:
        return Colors.red;
      case RoomState.expired:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (roomState) {
      case RoomState.teasing:
        return Icons.access_time;
      case RoomState.active:
        return Icons.play_circle_outline;
      case RoomState.unlocked:
        return Icons.lock_open;
      case RoomState.locked:
        return Icons.lock;
      case RoomState.expired:
        return Icons.cancel_outlined;
    }
  }
}

class RoomStateMessage extends StatelessWidget {
  final GroupBuyRoom room;
  final TextStyle? style;

  const RoomStateMessage({
    super.key,
    required this.room,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            room.stateMessage,
            style: style ?? TextStyle(
              fontSize: 12.sp,
              color: _getTextColor(),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    final state = room.roomState;
    IconData icon;
    Color color = _getTextColor();

    switch (state) {
      case RoomState.teasing:
        icon = Icons.hourglass_empty;
        color = Colors.blue;
        break;
      case RoomState.active:
        icon = Icons.group;
        color = Colors.green;
        break;
      case RoomState.unlocked:
        icon = Icons.celebration;
        color = Colors.orange;
        break;
      case RoomState.locked:
        icon = Icons.lock;
        color = Colors.red;
        break;
      case RoomState.expired:
        icon = Icons.timer_off;
        color = Colors.grey;
        break;
    }

    return Icon(icon, size: 16.sp, color: color);
  }

  Color _getTextColor() {
    switch (room.roomState) {
      case RoomState.teasing:
        return Colors.blue;
      case RoomState.active:
        return Colors.green.shade700;
      case RoomState.unlocked:
        return Colors.orange.shade700;
      case RoomState.locked:
        return Colors.red.shade700;
      case RoomState.expired:
        return Colors.grey.shade600;
    }
  }
}

class UnlockProgressIndicator extends StatelessWidget {
  final GroupBuyRoom room;
  final double height;
  final bool showLabel;

  const UnlockProgressIndicator({
    super.key,
    required this.room,
    this.height = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = room.unlockProgress;
    final isUnlocked = room.isUnlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height.r),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isUnlocked ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
            minHeight: height.h,
          ),
        ),
        if (showLabel) ...[
          SizedBox(height: 4.h),
          Text(
            isUnlocked
                ? 'Unlocked! 🎉'
                : '${room.membersNeededToUnlock} more to unlock',
            style: TextStyle(
              fontSize: 11.sp,
              color: isUnlocked ? Colors.green : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}