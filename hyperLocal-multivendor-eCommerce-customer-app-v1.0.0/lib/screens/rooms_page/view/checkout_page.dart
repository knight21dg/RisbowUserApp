import 'dart:async';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';
import 'package:hyper_local/screens/wallet_page/repo/wallet_repository.dart';

class CheckoutPage extends StatefulWidget {
  final String? roomCode;

  const CheckoutPage({super.key, this.roomCode});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final RoomRepository _repository = RoomRepository();
  final WalletRepository _walletRepository = WalletRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  GroupBuyRoom? _room;
  bool _loading = true;
  bool _submitting = false;
  String? _formError;

  // Split-Payment State Management
  bool _isCheckoutInitiated = false;
  String _splitType = 'item'; // 'item' or 'equal'
  double _mySplitAmount = 0.0;
  String _myPaymentStatus = 'pending';
  List<dynamic> _groupPayments = [];
  double _walletBalance = 0.0;
  bool _fetchingWallet = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRoom() async {
    if (widget.roomCode == null || widget.roomCode!.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final room = await _repository.getRoomDetails(widget.roomCode!);
    if (!mounted) return;

    setState(() {
      _room = room;
      _loading = false;
      if (room != null && room.status == 'awaiting_payment') {
        _isCheckoutInitiated = true;
      }
    });

    if (_isCheckoutInitiated) {
      _fetchPaymentStatus();
      _fetchWalletBalance();
      _startPolling();
    }
  }

  int _pollCount = 0;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollCount = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pollCount >= 60) {
        timer.cancel();
        return;
      }
      _pollCount++;
      _fetchPaymentStatus();
    });
  }

  Future<void> _fetchPaymentStatus() async {
    if (_room == null) return;
    final statusResult = await _repository.getGroupPaymentStatus(_room!.code);
    if (!mounted) return;

    if (statusResult != null && statusResult['success'] == true) {
      final data = statusResult['data'];
      final String roomStatus = data['room_status'] ?? '';

      if (roomStatus == 'completed') {
        _pollingTimer?.cancel();
        context.go(
          '/checkout-success',
          extra: {
            'order_id': 'ORD-${_room!.code}',
            'total': _room!.cartTotal,
            'room_code': _room!.code,
          },
        );
        return;
      }

      setState(() {
        _groupPayments = data['payments'] ?? [];
        final myPay = data['my_payment'];
        if (myPay != null) {
          _mySplitAmount = (myPay['amount'] as num?)?.toDouble() ?? 0.0;
          _myPaymentStatus = myPay['status'] ?? 'pending';
        }
      });
    }
  }

  Future<void> _fetchWalletBalance() async {
    setState(() => _fetchingWallet = true);
    try {
      final wallets = await _walletRepository.fetchUserWallet();
      if (!mounted) return;
      if (wallets.isNotEmpty) {
        setState(() {
          _walletBalance = (wallets.first.balance ?? 0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch wallet balance: $e');
    } finally {
      if (mounted) {
        setState(() => _fetchingWallet = false);
      }
    }
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _zipController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  double get _subtotal => _room?.cartTotal ?? 0;
  double get _discount => _room?.currentDiscountValue ?? 0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _initiateCheckout() async {
    if (_room == null || _room!.cartItems.isEmpty) return;
    if (!_isFormValid) {
      setState(() => _formError = 'Please fill all required address fields.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final addressPayload = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'zip': _zipController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    final result = await _repository.initiateGroupCheckout(
      code: _room!.code,
      splitType: _splitType,
      address: addressPayload,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null || result['success'] != true) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Initiation failed'),
          content: Text(
            'Could not initiate checkout: ${result?['message'] ?? 'Unknown reason'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isCheckoutInitiated = true;
    });
    _fetchPaymentStatus();
    _fetchWalletBalance();
    _startPolling();
  }

  Future<void> _payMyShare() async {
    if (_room == null) return;
    if (_walletBalance < _mySplitAmount) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Your wallet balance (${AppConstant.currency}${_walletBalance.toStringAsFixed(2)}) is less than your share amount (${AppConstant.currency}${_mySplitAmount.toStringAsFixed(2)}). Please add money to your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/add-money');
              },
              child: const Text('Add Money'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _repository.payGroupShare(
      code: _room!.code,
      paymentMethod: 'wallet',
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null || result['success'] != true) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Failed'),
          content: Text(
            'Could not complete payment: ${result?['message'] ?? 'Unknown reason'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! Waiting for others...')),
    );

    _fetchPaymentStatus();
    _fetchWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CustomCircularProgressIndicator()));
    }
    if (_room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Room not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_isCheckoutInitiated ? 'Shared Split Payment' : 'Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
        child: _isCheckoutInitiated ? _buildSplitPaymentUI() : _buildInitiationUI(),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
        color: Colors.white,
        child: _isCheckoutInitiated ? _buildSplitPaymentButton() : _buildInitiationButton(),
      ),
    );
  }

  // PHASE 1: Initiation Form UI
  Widget _buildInitiationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping address',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10.h),
        TextFieldInput(
          controller: _nameController,
          labelText: 'Name',
          hintText: 'Enter name',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12.h),
        TextFieldInput(
          controller: _addressController,
          labelText: 'Address',
          hintText: 'Street and house number',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12.h),
        TextFieldInput(
          controller: _cityController,
          labelText: 'City',
          hintText: 'City',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12.h),
        TextFieldInput(
          controller: _phoneController,
          labelText: 'Phone',
          hintText: 'Phone number',
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12.h),
        TextFieldInput(
          controller: _zipController,
          labelText: 'ZIP',
          hintText: 'Postal code',
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        Text(
          'Split type',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              _splitOption('item', 'Itemized Split', 'Each member pays for the items they added'),
              const Divider(height: 1),
              _splitOption('equal', 'Equal Split', 'Total cart amount divided equally among members'),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Order summary',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              ..._room!.cartItems.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.name} x${item.quantity}'),
                      ),
                      Text(
                        '${AppConstant.currency}${item.totalPrice.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              _priceRow('Subtotal', _subtotal),
              _priceRow('Discount', -_discount),
              ...(() {
                final cgstPercentStr = SettingsData.instance.system?.cgstPercent ?? '0';
                final sgstPercentStr = SettingsData.instance.system?.sgstPercent ?? '0';
                final cgstPercent = double.tryParse(cgstPercentStr) ?? 0;
                final sgstPercent = double.tryParse(sgstPercentStr) ?? 0;
                final totalPercent = cgstPercent + sgstPercent;
                
                if (totalPercent > 0 && _total > 0) {
                  final basePrice = _total / (1 + totalPercent / 100);
                  final taxAmount = _total - basePrice;
                  final cgstAmount = taxAmount / 2;
                  final sgstAmount = taxAmount / 2;
                  return [
                    _priceRow('CGST ($cgstPercent%)', cgstAmount),
                    _priceRow('SGST ($sgstPercent%)', sgstAmount),
                  ];
                }
                return <Widget>[];
              })(),
              _priceRow('Total', _total, isTotal: true),
            ],
          ),
        ),
        if (_formError != null)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Text(
              _formError!,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  Widget _buildInitiationButton() {
    return PrimaryButton(
      label: 'Initiate Group Checkout',
      onPressed: _initiateCheckout,
      disabled: !_isFormValid || _room!.cartItems.isEmpty,
      loading: _submitting,
    );
  }

  // PHASE 2: Split Payment UI
  Widget _buildSplitPaymentUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Share Amount Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Split Share',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6.h),
              Text(
                '${AppConstant.currency}${_mySplitAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _myPaymentStatus == 'paid'
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _myPaymentStatus == 'paid' ? Icons.check_circle : Icons.pending,
                      color: _myPaymentStatus == 'paid' ? Colors.greenAccent : Colors.amberAccent,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _myPaymentStatus == 'paid' ? 'Payment Completed' : 'Payment Pending',
                      style: TextStyle(
                        color: _myPaymentStatus == 'paid' ? Colors.greenAccent : Colors.amberAccent,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

        // Wallet Balance Info
        Container(
          margin: EdgeInsets.only(top: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Wallet Balance',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${AppConstant.currency}${_walletBalance.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (_fetchingWallet)
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CustomCircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: () async {
                    await context.push('/add-money');
                    _fetchWalletBalance();
                  },
                  child: Text(
                    'Add Money',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),

        // Insufficient Warning
        if (_myPaymentStatus != 'paid' && _walletBalance < _mySplitAmount)
          Container(
            margin: EdgeInsets.only(top: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Insufficient balance to pay your share. Please add money to your wallet.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),

        // Status List of all room members
        SizedBox(height: 24.h),
        Text(
          'Group Members Payment Status',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _groupPayments.length,
          itemBuilder: (context, index) {
            final pay = _groupPayments[index];
            final name = pay['user_name'] ?? 'Member';
            final amount = (pay['amount'] as num?)?.toDouble() ?? 0.0;
            final isPaid = pay['status'] == 'paid';

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                    radius: 18.r,
                    child: Icon(
                      isPaid ? Icons.check : Icons.person,
                      color: isPaid ? Colors.green : Colors.amber,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                        Text(
                          'Share: ${AppConstant.currency}${amount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        color: isPaid ? Colors.green.shade800 : Colors.amber.shade800,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSplitPaymentButton() {
    if (_myPaymentStatus == 'paid') {
      return Container(
        width: double.infinity,
        height: 48.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CustomCircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
            SizedBox(width: 10.w),
            Text(
              'Waiting for other members to pay...',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13.sp),
            ),
          ],
        ),
      );
    }

    return PrimaryButton(
      label: 'Pay My Share (${AppConstant.currency}${_mySplitAmount.toStringAsFixed(2)})',
      onPressed: _payMyShare,
      disabled: _submitting,
      loading: _submitting,
    );
  }

  Widget _splitOption(String value, String title, String description) {
    final selected = _splitType == value;
    return RadioListTile<String>(
      value: value,
      groupValue: _splitType,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
      subtitle: Text(description, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
      onChanged: (next) {
        if (next == null) return;
        setState(() => _splitType = next);
      },
      activeColor: AppColors.primary,
      selected: selected,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _priceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value.isNegative ? '-' : ''}${AppConstant.currency}${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
