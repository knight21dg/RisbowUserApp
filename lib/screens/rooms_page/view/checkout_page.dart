import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class CheckoutPage extends StatefulWidget {
  final String? roomCode;

  const CheckoutPage({super.key, this.roomCode});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final RoomRepository _repository = RoomRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  GroupBuyRoom? _room;
  bool _loading = true;
  bool _submitting = false;
  String _paymentMethod = 'razorpay';
  String? _formError;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
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
    });
  }

  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _zipController.text.trim().isNotEmpty;
  }

  double get _subtotal => _room?.cartTotal ?? 0;
  double get _discount => 0;
  double get _total => _subtotal - _discount;

  Future<void> _confirmPurchase() async {
    if (_room == null || _room!.cartItems.isEmpty) return;
    if (!_isFormValid) {
      setState(() => _formError = 'Please fill all required address fields.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final payload = GroupBuyCheckoutPayload(
      roomCode: _room!.code,
      address: {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'zip': _zipController.text.trim(),
      },
      paymentToken: _paymentMethod,
      items: _room!.cartItems
          .map(
            (item) => GroupBuyCheckoutItem(
              productId: item.productId,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );

    final result = await _repository.confirmGroupBuyPurchase(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null || result['success'] != true) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment failed'),
          content: Text(
            'Payment failed: ${result?['message'] ?? 'Unknown reason'}',
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

    context.go(
      '/checkout-success',
      extra: {
        'order_id': result['order_id'] ?? 'ORD-UNKNOWN',
        'total': _total,
        'room_code': _room!.code,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Room not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
        child: Column(
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
              controller: _zipController,
              labelText: 'ZIP',
              hintText: 'Postal code',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
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
                  _priceRow('Total', _total, isTotal: true),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Payment method',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            _paymentOption('razorpay', 'Pay with Razorpay'),
            _paymentOption('stripe', 'Pay with Stripe'),
            _paymentOption('cod', 'Cash on Delivery'),
            if (_formError != null)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Text(
                  _formError!,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
        color: Colors.white,
        child: PrimaryButton(
          label: 'Confirm Purchase',
          onPressed: _confirmPurchase,
          disabled: !_isFormValid || _room!.cartItems.isEmpty,
          loading: _submitting,
        ),
      ),
    );
  }

  Widget _paymentOption(String value, String label) {
    final selected = _paymentMethod == value;
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      title: Text(label),
      onChanged: (next) {
        if (next == null) return;
        setState(() => _paymentMethod = next);
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
