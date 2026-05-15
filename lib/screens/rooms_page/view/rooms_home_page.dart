import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/connectivity_service.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/bloc/group_buy_bloc.dart';
import 'package:hyper_local/screens/rooms_page/bloc/group_buy_event.dart';
import 'package:hyper_local/screens/rooms_page/bloc/group_buy_state.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class RoomsHomePage extends StatefulWidget {
  const RoomsHomePage({super.key});

  @override
  State<RoomsHomePage> createState() => _RoomsHomePageState();
}

class _RoomsHomePageState extends State<RoomsHomePage> {
  final RoomRepository _repository = RoomRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  final TextEditingController _searchController = TextEditingController();

  List<GroupBuyRoom> _rooms = const <GroupBuyRoom>[];
  bool _loading = true;
  bool _offline = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final isOnline = await _connectivity.refreshStatus();
    final rooms = await _repository.getMyRooms(query: _search);
    if (!mounted) return;
    setState(() {
      _offline = !isOnline;
      _rooms = rooms;
      _loading = false;
    });
  }

  List<GroupBuyRoom> get _filteredRooms {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return _rooms;
    return _rooms.where((room) {
      return room.name.toLowerCase().contains(query) ||
          room.code.toLowerCase().contains(query);
    }).toList();
  }

  void _showJoinRoomBottomSheet(BuildContext context) {
    final codeController = TextEditingController();
    bool joining = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Join Room',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter the room code to join',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.subtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter room code (e.g., GRP-XXXXXX)',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(TablerIcons.login_2),
                        errorText: error,
                      ),
                      onChanged: (value) {
                        if (error != null) {
                          setSheetState(() => error = null);
                        }
                      },
                    ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: joining
                          ? null
                          : () async {
                              final code = codeController.text.trim().toUpperCase();
                              if (code.isEmpty || code.length < 6) {
                                setSheetState(() => error = 'Enter a valid room code');
                                return;
                              }
                              setSheetState(() {
                                joining = true;
                                error = null;
                              });
                              final room = await RoomRepository().joinRoom(code);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              if (room != null && !room.isExpired && !room.isFull) {
                                Global.setActiveRoomCode(room.code);
                                context.push('/rooms/${room.code}');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot join this room')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: joining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Join Room',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupBuyBloc()..add(const LoadMyRooms()),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Group Buy Rooms'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Create Room',
              onPressed: () => context.push('/rooms/create'),
              icon: const Icon(TablerIcons.plus),
            ),
            IconButton(
              tooltip: 'Join Room',
              onPressed: _offline ? null : () => _showJoinRoomBottomSheet(context),
              icon: const Icon(TablerIcons.login_2),
            ),
            IconButton(
              tooltip: 'Discover Rooms',
              onPressed: () => context.push('/rooms/discover'),
              icon: const Icon(TablerIcons.compass),
            ),
            SizedBox(width: 4.w),
          ],
        ),
        body: BlocBuilder<GroupBuyBloc, GroupBuyState>(
          builder: (context, state) {
            return Column(
              children: [
                if (_offline)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    color: Colors.orange.shade100,
                    child: Text(
                      'Unable to load latest rooms. Check connection.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _search = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search rooms...',
                      prefixIcon: const Icon(TablerIcons.search),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(TablerIcons.x),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredRooms.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          child: ListView.builder(
                            itemCount: _filteredRooms.length,
                            itemBuilder: (context, index) {
                              final room = _filteredRooms[index];
                              return RoomCard(
                                room: room,
                                actionLabel: 'View',
                                onPressed: () => context.push('/rooms/${room.code}'),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              TablerIcons.users_group,
              size: 56.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No active rooms. Create or join a room.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.headingColor,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Create Room',
                    onPressed: () => context.push('/rooms/create'),
                    icon: TablerIcons.plus,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            SecondaryButton(
              label: 'Join with Code',
              onPressed: _offline ? null : () => context.push('/rooms/join'),
              icon: TablerIcons.login_2,
              disabled: _offline,
            ),
          ],
        ),
      ),
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoomsHomePage();
  }
}
