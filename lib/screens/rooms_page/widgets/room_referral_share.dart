import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../model/room_referral_model.dart';
import '../services/room_referral_service.dart';

class RoomReferralShareButton extends StatelessWidget {
  final String roomCode;
  final String roomName;
  final VoidCallback? onShareComplete;

  const RoomReferralShareButton({
    super.key,
    required this.roomCode,
    required this.roomName,
    this.onShareComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () => _handleShare(context),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Share Room',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final referralService = RoomReferralService.instance;
      final referralLink = await referralService.generateReferralLink(roomCode);

      if (referralLink != null) {
        final message = referralService.formatShareMessage(roomName, referralLink.referralCode);

        await Share.share(
          message,
          subject: 'Join my group buy room: $roomName',
        );

        onShareComplete?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate referral link: $e')),
        );
      }
    }
  }
}

class RoomReferralCard extends StatelessWidget {
  final RoomReferral referral;
  final VoidCallback? onTap;

  const RoomReferralCard({
    super.key,
    required this.referral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.2),
          child: Icon(
            referral.isCompleted ? Icons.check_circle : Icons.pending,
            color: _getStatusColor(),
            size: 20.sp,
          ),
        ),
        title: Text(
          'Ref: ${referral.referralCode}',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          referral.isCompleted
              ? 'Completed'
              : referral.isPending
                  ? 'Pending'
                  : 'Cancelled',
          style: TextStyle(
            fontSize: 12.sp,
            color: _getStatusColor(),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (referral.isCompleted) return Colors.green;
    if (referral.isPending) return Colors.orange;
    return Colors.red;
  }
}

class CopyReferralCodeButton extends StatelessWidget {
  final String referralCode;
  final bool showCopiedFeedback;

  const CopyReferralCodeButton({
    super.key,
    required this.referralCode,
    this.showCopiedFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showCopiedFeedback ? Icons.check : Icons.copy,
                size: 16.sp,
                color: showCopiedFeedback ? Colors.green : Colors.grey.shade700,
              ),
              SizedBox(width: 6.w),
              Text(
                showCopiedFeedback ? 'Copied!' : referralCode,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: showCopiedFeedback ? Colors.green : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}