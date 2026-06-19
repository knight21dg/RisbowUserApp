import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/model/coins_model.dart';

class CoinsTransactionCard extends StatelessWidget {
  final CoinsTransactionModel transaction;

  const CoinsTransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount > 0;
    final isReferral = transaction.transactionType.contains('referral');
    final isOrder = transaction.transactionType.contains('order');
    final isReview = transaction.transactionType.contains('review');
    final isExpired = transaction.transactionType == 'expired';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? AppTheme.darkProductCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(isCredit, isReferral, isOrder, isReview, isExpired),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTransactionIcon(isCredit, isReferral, isOrder, isReview, isExpired),
              color: _getIconColor(isCredit, isReferral, isOrder, isReview, isExpired),
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDescription(transaction.transactionType),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      TablerIcons.clock,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  SizedBox(height: 3),
                  Text(
                    transaction.description!,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : ''}${transaction.amount}',
                style: TextStyle(
                  color: isCredit ? Color(0xFF10B981) : Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusBackgroundColor(transaction.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TablerIcons.coin,
                      size: 10,
                      color: _getStatusTextColor(transaction.status),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${transaction.balanceAfter}',
                      style: TextStyle(
                        color: _getStatusTextColor(transaction.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(bool isCredit, bool isReferral, bool isOrder, bool isReview, bool isExpired) {
    if (isExpired) return TablerIcons.clock;
    if (isReferral) return TablerIcons.user;
    if (isReview) return TablerIcons.star;
    if (isOrder) return TablerIcons.shopping_cart;
    if (isCredit) return TablerIcons.plus;
    return TablerIcons.minus;
  }

  Color _getIconColor(bool isCredit, bool isReferral, bool isOrder, bool isReview, bool isExpired) {
    if (isExpired) return Color(0xFF6B7280);
    if (isCredit) return Color(0xFF10B981);
    return Color(0xFFEF4444);
  }

  Color _getIconBackgroundColor(bool isCredit, bool isReferral, bool isOrder, bool isReview, bool isExpired) {
    if (isExpired) return Color(0xFF6B7280).withValues(alpha: 0.1);
    if (isCredit) return Color(0xFF10B981).withValues(alpha: 0.1);
    return Color(0xFFEF4444).withValues(alpha: 0.1);
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Color(0xFF10B981).withValues(alpha: 0.15);
      case 'pending':
        return Color(0xFFF59E0B).withValues(alpha: 0.15);
      case 'expired':
      case 'cancelled':
        return Color(0xFFEF4444).withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Color(0xFF059669);
      case 'pending':
        return Color(0xFFD97706);
      case 'expired':
      case 'cancelled':
        return Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDescription(String type) {
    switch (type) {
      case 'referral_bonus':
        return 'Referral Bonus';
      case 'referral_signup':
        return 'Signup Bonus';
      case 'order_earn':
        return 'Order Earning';
      case 'order_spent':
        return 'Order Spent';
      case 'review_bonus':
        return 'Review Bonus';
      case 'room_bonus':
        return 'Room Bonus';
      case 'seasonal_bonus':
        return 'Seasonal Bonus';
      case 'gift_redeemed':
        return 'Gift Redeemed';
      case 'banner_purchase':
        return 'Banner Purchase';
      case 'promotion_spent':
        return 'Promotion';
      case 'admin_adjustment':
        return 'Admin Adjustment';
      case 'expired':
        return 'Coins Expired';
      case 'refund':
        return 'Refund';
      default:
        return type.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
