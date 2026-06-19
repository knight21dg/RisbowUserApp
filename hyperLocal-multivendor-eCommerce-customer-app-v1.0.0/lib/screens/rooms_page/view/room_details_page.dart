import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/connectivity_service.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';
import 'package:share_plus/share_plus.dart';

class RoomDetailsPage extends StatefulWidget {
  final String roomCode;

  const RoomDetailsPage({super.key, required this.roomCode});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  final RoomRepository _repository = RoomRepository();
  final ConnectivityService _connectivity = ConnectivityService.instance;

  GroupBuyRoom? _room;
  bool _loading = true;
  bool _offline = false;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _savings;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int get _currentUserId => int.tryParse(Global.userData?.userId ?? '') ?? 1;

  bool get _isMember =>
      _room?.members.any((member) => member.id == _currentUserId) ?? false;
  bool get _isOwner => (_room?.owner.id ?? -1) == _currentUserId;

  double get _totalAmount {
    final val = _summary?['total_price'];
    if (val == null) return _room?.cartTotal ?? 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return 0.0;
  }
  int get _totalItems => _summary?['total_items'] ?? _room?.cartItems.length ?? 0;
  int get _totalQuantity => _summary?['total_quantity'] ?? 
      (_room?.cartItems.fold<int>(0, (sum, i) => sum + i.quantity) ?? 0);
  int get _membersCount => _stats?['members_count'] ?? _room?.members.length ?? 0;
  double get _savingsAmount {
    final val = _savings?['savings_amount'];
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return 0.0;
  }
  double get _discountPercent {
    final val = _savings?['savings_percentage'];
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return 0.0;
  }

  Future<void> _loadRoom() async {
    setState(() => _loading = true);
    final isOnline = await _connectivity.refreshStatus();
    final room = await _repository.getRoomDetails(widget.roomCode);
    
    Map<String, dynamic>? summary;
    Map<String, dynamic>? stats;
    Map<String, dynamic>? savings;
    
    if (room != null && isOnline) {
      try {
        final results = await Future.wait([
          _repository.getRoomSummary(widget.roomCode),
          _repository.getRoomStats(widget.roomCode),
          _repository.getRoomSavings(widget.roomCode),
        ]);
        summary = results[0];
        stats = results[1];
        savings = results[2];
      } catch (_) {}
    }
    
    if (!mounted) return;
    setState(() {
      _offline = !isOnline;
      _room = room;
      _summary = summary;
      _stats = stats;
      _savings = savings;
      _loading = false;
    });
  }

  Future<void> _joinRoom() async {
    if (_room == null) return;
    final joined = await _repository.joinRoom(_room!.code);
    if (!mounted) return;
    if (joined == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cannot join this room')));
      return;
    }
    Global.setActiveRoomCode(joined.code);
    setState(() => _room = joined);
  }

  Future<void> _editQuantity(GroupBuyCartItem item) async {
    if (_room == null) return;
    final nextQty = await ModalDialog.showQuantityEditor(
      context,
      productName: item.name,
      initialQty: item.quantity,
    );
    if (nextQty == null || !_isMember) return;
    final updated = await _repository.updateItemQuantity(
      room: _room!,
      item: item,
      quantity: nextQty,
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _room = updated);
    }
  }

  Future<void> _endRoom() async {
    if (_room == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End Room?'),
          content: const Text('This closes the room for all members.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End Room'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final updated = await _repository.endRoom(_room!);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _room = updated);
    }
  }

  void _shareRoom() {
    if (_room == null) return;
    Share.share('Join my room on Risbow! https://risbow.com/room/${_room!.code}');
  }

  Future<void> _editRoom() async {
    if (_room == null) return;
    
    final nameController = TextEditingController(text: _room!.name);
    int maxMembers = _room!.maxMembers;
    if (maxMembers > 10) maxMembers = 10;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Room Name',
                      hintText: 'Enter room name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Members (Max 10)'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: maxMembers > 2 ? () => setDialogState(() => maxMembers--) : null,
                          ),
                          Text('$maxMembers', style: const TextStyle(fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: maxMembers < 10 ? () => setDialogState(() => maxMembers++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'max_members': maxMembers,
                  }),
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      }
    );
    
    if (result != null) {
      final updatedName = result['name'] as String;
      final updatedMaxMembers = result['max_members'] as int;
      if (updatedName.isNotEmpty && (updatedName != _room!.name || updatedMaxMembers != _room!.maxMembers)) {
        final updated = await _repository.updateRoom(_room!.code, {
          'name': updatedName,
          'max_members': updatedMaxMembers,
        });
        if (updated != null && mounted) {
          setState(() => _room = updated);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room updated!')));
        }
      }
    }
  }

  Future<void> _leaveRoom() async {
    if (_room == null) return;
    final updated = await _repository.leaveRoom(_room!);
    if (!mounted) return;
    if (updated != null) {
      setState(() => _room = updated);
      context.go('/rooms');
    }
  }

  void _addProduct() {
    if (_room == null) return;
    if (_room!.isClosed || _room!.isFull) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Room closed')));
      return;
    }
    if (_offline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No connection')));
      return;
    }
    context
        .push('/rooms/products', extra: _room!.code)
        .then((_) => _loadRoom());
  }

  void _checkout() {
    if (_room == null) return;
    context
        .push('/rooms/checkout', extra: _room!.code)
        .then((_) => _loadRoom());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CustomCircularProgressIndicator()));
    }
    if (_room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: Center(
          child: Text(
            'Room not found.',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final room = _room!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          room.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.headingColor,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isMember && !room.isClosed && !room.isFull)
            TextButton.icon(
              onPressed: _addProduct,
              icon: Icon(TablerIcons.plus, size: 18.sp, color: AppColors.primary),
              label: Text(
                'Add Items',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'share') {
                _shareRoom();
              } else if (value == 'edit') {
                _editRoom();
              } else if (value == 'end') {
                _endRoom();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(TablerIcons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share Room'),
                  ],
                ),
              ),
              if (_isOwner)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(TablerIcons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Room'),
                    ],
                  ),
                ),
              if (_isOwner)
                const PopupMenuItem(
                  value: 'end',
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('End Room', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoom,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 110.h),
          children: [
            if (_offline)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'You are offline. Some actions are disabled.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            _buildHeaderCard(room),
            SizedBox(height: 12.h),
            _buildMembersCard(room),
            SizedBox(height: 12.h),
            _buildAnalyticsCard(room),
            SizedBox(height: 12.h),
            _buildSharedCartCard(room),
            if (room.activities.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _buildActivityCard(room),
            ],
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(room),
      floatingActionButton: null,
    );
  }

  Widget _buildAnalyticsCard(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.chart_bar, size: 18, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                'Room Analytics',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.headingColor),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(child: _statItem('Items', _totalItems.toString(), TablerIcons.package)),
                Expanded(child: _statItem('Qty', _totalQuantity.toString(), TablerIcons.box)),
                Expanded(child: _statItem('Members', _membersCount.toString(), TablerIcons.users)),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statItem(
                    'Total',
                    '${AppConstant.currency}${_totalAmount.toStringAsFixed(0)}',
                    TablerIcons.currency_dollar,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    'Saved',
                    '${AppConstant.currency}${_savingsAmount.toStringAsFixed(0)}',
                    TablerIcons.discount_check,
                    valueColor: _savingsAmount > 0 ? const Color(0xFF10B981) : null,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    'Off',
                    '${_discountPercent.toStringAsFixed(0)}%',
                    TablerIcons.percentage,
                    valueColor: _discountPercent > 0 ? const Color(0xFF10B981) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.headingColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppColors.subtitleColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  room.code,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              if (!room.isPublic) ...[
                SizedBox(width: 8.w),
                Icon(TablerIcons.lock, size: 16, color: AppColors.subtitleColor),
              ],
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: room.status.toLowerCase() == 'open'
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  room.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: room.status.toLowerCase() == 'open' 
                        ? const Color(0xFF10B981) 
                        : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            room.name,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AppColors.headingColor),
          ),
          SizedBox(height: 12.h),
          GroupBuyProgressBar(
            progress: room.memberProgress,
            label: '${room.membersJoined}/${room.maxMembers} members joined',
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(TablerIcons.clock, size: 14, color: AppColors.subtitleColor),
              SizedBox(width: 4.w),
              Text(
                room.expiresAt == null
                    ? 'No expiry'
                    : 'Expires ${room.expiresAt!.toLocal()}'.split('.').first,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.subtitleColor,
                ),
              ),
              const Spacer(),
              if (room.isFull)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'ROOM FULL',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B)),
                  ),
                ),
              if (room.isExpired)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'EXPIRED',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.users, size: 14, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Text(
                      'Members',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${room.membersJoined}/${room.maxMembers}',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (room.members.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Column(
                  children: [
                    Icon(TablerIcons.users, size: 40, color: Colors.grey.shade300),
                    SizedBox(height: 8.h),
                    Text(
                      'Waiting for others to join...',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.subtitleColor),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: room.members.map((member) {
                final isCurrentUser = member.id == _currentUserId;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color: isCurrentUser ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12.r,
                        backgroundColor: isCurrentUser ? AppColors.primary : Colors.grey.shade400,
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCurrentUser ? 'You' : member.name,
                            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isCurrentUser ? AppColors.primary : Colors.black87),
                          ),
                          if (member.isOwner)
                            Text(
                              'Owner',
                              style: TextStyle(fontSize: 9.sp, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedCartCard(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.shopping_cart, size: 14, color: Colors.orange.shade700),
                    SizedBox(width: 4.w),
                    Text(
                      'Shared Cart',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isMember && !room.isClosed && !room.isFull)
                GestureDetector(
                  onTap: _addProduct,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(TablerIcons.plus, size: 14.sp, color: AppColors.primary),
                        SizedBox(width: 4.w),
                        Text(
                          'Add Items',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (room.cartItems.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '${room.cartItems.length} items',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          if (room.cartItems.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Column(
                  children: [
                    Icon(TablerIcons.shopping_cart, size: 40, color: Colors.grey.shade300),
                    SizedBox(height: 8.h),
                    Text(
                      'Cart is empty',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.subtitleColor),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Add products to start shopping together',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...room.cartItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: index < room.cartItems.length - 1 ? 10.h : 0),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey)),
                            )
                          : Icon(TablerIcons.package, size: 20, color: Colors.grey.shade400),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Qty: ${item.quantity} • ${item.addedByName}',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${AppConstant.currency}${item.totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        Text(
                          '${AppConstant.currency}${item.unitPrice.toStringAsFixed(0)} each',
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          if (room.cartItems.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(TablerIcons.currency_dollar, size: 18, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Cart Total',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  const Spacer(),
                  Text(
                    '${AppConstant.currency}${room.cartTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TablerIcons.activity, size: 14, color: Colors.blue.shade700),
                    SizedBox(width: 4.w),
                    Text(
                      'Activity',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...room.activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: index < room.activities.length - 1 ? 8.h : 0),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(TablerIcons.bolt, size: 14, color: Colors.blue.shade700),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.message,
                          style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatTime(activity.timestamp),
                          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }

  Widget _buildBottomBar(GroupBuyRoom room) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_isMember && room.cartItems.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.subtitleColor),
                    ),
                    Text(
                      '${AppConstant.currency}${room.cartTotal.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            if (_isMember) SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: !_isMember
                  ? Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: room.isClosed || room.isFull
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: room.isClosed || room.isFull
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _joinRoom,
                          borderRadius: BorderRadius.circular(14.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  room.isClosed || room.isFull ? Icons.block : TablerIcons.login_2,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  room.isClosed
                                      ? 'Room Closed'
                                      : room.isFull
                                      ? 'Room Full'
                                      : 'Join Room',
                                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: (room.cartItems.isEmpty && room.status != 'awaiting_payment') || room.isClosed
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: (room.cartItems.isEmpty && room.status != 'awaiting_payment') || room.isClosed
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (room.cartItems.isEmpty && room.status != 'awaiting_payment') || room.isClosed ? null : _checkout,
                          borderRadius: BorderRadius.circular(14.r),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  room.status == 'awaiting_payment'
                                      ? Icons.account_balance_wallet
                                      : TablerIcons.shopping_cart,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  room.status == 'awaiting_payment'
                                      ? 'Pay Split Share'
                                      : 'Checkout',
                                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isMember) ...[
              SizedBox(width: 10.w),
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _leaveRoom,
                    borderRadius: BorderRadius.circular(14.r),
                    child: Center(
                      child: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
