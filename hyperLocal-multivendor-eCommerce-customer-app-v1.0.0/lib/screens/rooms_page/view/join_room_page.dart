import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class JoinRoomPage extends StatefulWidget {
  const JoinRoomPage({super.key});

  @override
  State<JoinRoomPage> createState() => _JoinRoomPageState();
}

class _JoinRoomPageState extends State<JoinRoomPage> {
  final RoomRepository _repository = RoomRepository();
  final TextEditingController _codeController = TextEditingController();

  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _normalizedCode => _codeController.text.trim().toUpperCase();

  bool get _isValidCode {
    return RegExp(r'^(GRP-[A-Z0-9]{6}|[A-Z0-9]{8})$').hasMatch(_normalizedCode);
  }

  Future<void> _joinRoom() async {
    if (!_isValidCode) {
      setState(
        () => _error = 'Enter invite code (8 chars) or room code (GRP-XXXXXX).',
      );
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });
    final room = await _repository.joinRoom(_normalizedCode);

    if (!mounted) return;
    setState(() => _joining = false);

    if (room == null) {
      setState(() => _error = 'Cannot join this room.');
      return;
    }
    if (room.isExpired || room.isFull) {
      setState(() => _error = 'Cannot join this room.');
      return;
    }

    Global.setActiveRoomCode(room.code);
    context.go('/rooms/${room.code}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Join Room'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter Room Code',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: 280.w,
                child: TextFieldInput(
                  controller: _codeController,
                  labelText: 'Room Code',
                  hintText: 'Invite or room code',
                  errorText: _error,
                  maxLength: 10,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    final upper = value.toUpperCase();
                    if (value != upper) {
                      _codeController.value = _codeController.value.copyWith(
                        text: upper,
                        selection: TextSelection.collapsed(
                          offset: upper.length,
                        ),
                      );
                    }
                    setState(() {
                      if (_error != null) _error = null;
                    });
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: 280.w,
                child: PrimaryButton(
                  label: 'Join',
                  onPressed: _joinRoom,
                  disabled: !_isValidCode,
                  loading: _joining,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
