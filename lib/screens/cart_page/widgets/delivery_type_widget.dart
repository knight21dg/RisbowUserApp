import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import '../../../config/constant.dart';
import '../../../l10n/app_localizations.dart';

enum DeliveryType { rush, regular }

class DeliveryTypeWidget extends StatefulWidget {
  final DeliveryType? selectedDeliveryType;
  final Function(DeliveryType) onDeliveryTypeChanged;
  final double? rushDeliveryCharge;
  final bool isRushDeliveryDisabled;

  const DeliveryTypeWidget({
    super.key,
    this.selectedDeliveryType,
    required this.onDeliveryTypeChanged,
    this.rushDeliveryCharge,
    this.isRushDeliveryDisabled = false,
  });

  @override
  State<DeliveryTypeWidget> createState() => _DeliveryTypeWidgetState();
}

class _DeliveryTypeWidgetState extends State<DeliveryTypeWidget> {
  DeliveryType? _selectedDeliveryType;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryType = widget.selectedDeliveryType ?? DeliveryType.rush;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(
          left: 12.0.w,
          right: 12.0.w,
          top: 12.h,
          bottom: 12.h
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.deliveryType ?? 'Delivery Type',
            style: TextStyle(
              fontSize: isTablet(context) ? 24 : 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),

          // Rush Delivery Option
          _buildDeliveryOption(
            deliveryType: DeliveryType.rush,
            title: l10n?.rushDelivery ?? 'Rush Delivery',
            subtitle: l10n?.prioritizedDeliveryForYourUrgentNeeds ?? 'Prioritized delivery for your urgent needs.',
            extraCharge: widget.rushDeliveryCharge,
          ),

          SizedBox(height: 8.h),

          // Regular Delivery Option
          _buildDeliveryOption(
            deliveryType: DeliveryType.regular,
            title: l10n?.regularDelivery ?? 'Regular Delivery',
            subtitle: l10n?.standardDeliveryWithNoExtraCharges ?? 'Standard delivery with no extra charges.',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required DeliveryType deliveryType,
    required String title,
    required String subtitle,
    double? extraCharge,
  }) {
    final bool isRushDisabled = widget.isRushDeliveryDisabled;
    final bool isEnabled = deliveryType == DeliveryType.regular || !isRushDisabled;

    // Ensure Regular is selected if Rush is disabled and Rush was previously selected
    if (isRushDisabled && _selectedDeliveryType == DeliveryType.rush) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedDeliveryType = DeliveryType.regular;
        });
        widget.onDeliveryTypeChanged(DeliveryType.regular);
      });
    }

    final bool isSelected = _selectedDeliveryType == deliveryType;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled ? () {
          setState(() {
            if (deliveryType == DeliveryType.rush && widget.isRushDeliveryDisabled) {
              _selectedDeliveryType = DeliveryType.regular;
            } else {
              _selectedDeliveryType = deliveryType;
            }
          });
          widget.onDeliveryTypeChanged(
            deliveryType == DeliveryType.rush && widget.isRushDeliveryDisabled
                ? DeliveryType.regular
                : deliveryType,
          );
        } : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: isSelected
                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1.0)
                : Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(deliveryType == DeliveryType.rush)...[
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                      color: Color(0xFFFFAA0C),
                      borderRadius: BorderRadius.circular(6)
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 18, color: Colors.white,),
                      SizedBox(width: 2,),
                      Text(
                        'Fastest Option',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 8,)
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Radio<DeliveryType>(
                    value: deliveryType,
                    groupValue: _selectedDeliveryType,
                    onChanged: (DeliveryType? value) {
                      setState(() {
                        _selectedDeliveryType = value;
                      });
                      if (value != null) {
                        widget.onDeliveryTypeChanged(value);
                      }
                    },
                    activeColor: AppTheme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),

                  SizedBox(width: 8.h),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet(context) ? 18 : 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isTablet(context) ? 14 : 10.sp,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
