import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/connectivity_service.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class CreateRoomPage extends StatefulWidget {
  final String? initialRoomName;

  const CreateRoomPage({super.key, this.initialRoomName});

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final RoomRepository _repository = RoomRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _maxController = TextEditingController(text: '5');

  bool _isPublic = true;
  bool _submitting = false;
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));

  String? _nameError;
  String? _maxError;
  String? _expiryError;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomName != null &&
        widget.initialRoomName!.trim().isNotEmpty) {
      _nameController.text = widget.initialRoomName!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxController.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  bool get _isValid {
    _validateFields(showErrors: false);
    return _nameError == null && _maxError == null && _expiryError == null;
  }

  void _validateFields({bool showErrors = true}) {
    final roomName = _nameController.text.trim();
    final max = int.tryParse(_maxController.text.trim());
    final isFutureExpiry = _expiresAt.isAfter(DateTime.now());

    final nameError = roomName.isEmpty
        ? 'Required'
        : (roomName.length > 50 ? 'Max 50 characters' : null);
    final maxError = max == null
        ? 'Enter a number'
        : (max < 2 || max > 10 ? 'Must be between 2 and 10' : null);
    final expiryError = isFutureExpiry
        ? null
        : 'Expiration must be in the future';

    if (!showErrors) {
      _nameError = nameError;
      _maxError = maxError;
      _expiryError = expiryError;
      return;
    }
    setState(() {
      _nameError = nameError;
      _maxError = maxError;
      _expiryError = expiryError;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiresAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _expiresAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _validateFields();
  }

  Future<void> _createRoom() async {
    _validateFields();
    if (!_isValid) return;

    setState(() => _submitting = true);
    final isOnline = await _connectivity.refreshStatus();
    if (!isOnline && mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please try again.')),
      );
      return;
    }

    final room = await _repository.createRoom(
      name: _nameController.text.trim(),
      maxMembers: int.parse(_maxController.text.trim()),
      isPublic: _isPublic,
      expiresAt: _expiresAt,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create room. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Global.setActiveRoomCode(room.code);
    context.go('/rooms/${room.code}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Create Room'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFieldInput(
                controller: _nameController,
                labelText: 'Room Name',
                hintText: "e.g. Alice's Lunch",
                errorText: _nameError,
                maxLength: 50,
                onChanged: (_) {
                  _validateFields();
                },
              ),
              SizedBox(height: 16.h),
              TextFieldInput(
                controller: _maxController,
                labelText: 'Max People',
                hintText: 'e.g. 5',
                errorText: _maxError,
                keyboardType: TextInputType.number,
                maxLength: 2,
                onChanged: (_) {
                  _validateFields();
                },
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public Room',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _isPublic
                                ? 'This room will be visible to others.'
                                : 'Private rooms require invite code.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      activeColor: AppColors.primary,
                      onChanged: (value) => setState(() => _isPublic = value),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: _pickExpiry,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _expiryError != null
                          ? Colors.red
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Expires on ${_expiresAt.toLocal()}'.split('.').first,
                          style: TextStyle(fontSize: 13.sp, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expiryError != null)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    _expiryError!,
                    style: TextStyle(color: Colors.red, fontSize: 11.sp),
                  ),
                ),
              SizedBox(height: 24.h),
              PrimaryButton(
                label: 'Create Room',
                onPressed: _createRoom,
                disabled: !_isValid,
                loading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
