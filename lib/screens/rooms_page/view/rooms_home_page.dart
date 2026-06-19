import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local/screens/rooms_page/bloc/weekly_rooms_bloc.dart';
import 'package:hyper_local/screens/rooms_page/repo/weekly_rooms_repo.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_join_bottom_sheet.dart';
import 'package:hyper_local/screens/rooms_page/view/private_room_details_page.dart';

class RoomsHomePage extends StatefulWidget {
  const RoomsHomePage({super.key});

  @override
  State<RoomsHomePage> createState() => _RoomsHomePageState();
}

class _RoomsHomePageState extends State<RoomsHomePage> {
  final RoomRepository _repository = RoomRepository();
  final ConnectivityService _connectivity = ConnectivityService.instance;
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
                              child: CustomCircularProgressIndicator(
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GroupBuyBloc()..add(const LoadMyRooms())),
        BlocProvider(create: (_) => WeeklyRoomsBloc(WeeklyRoomsRepo())..add(FetchActiveRooms())),
      ],
      child: BlocListener<WeeklyRoomsBloc, WeeklyRoomsState>(
        listener: (context, state) {
          if (state is GroupJoinSuccess) {
            // Navigate to the private room details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateRoomDetailsPage(
                  roomData: state.data['data'],
                ),
              ),
            );
          } else if (state is WeeklyRoomsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
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
                _buildWeeklyRoomsSection(),
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
                      ? const Center(child: CustomCircularProgressIndicator())
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
    ),
  );
  }

  Widget _buildWeeklyRoomsSection() {
    return BlocBuilder<WeeklyRoomsBloc, WeeklyRoomsState>(
      builder: (context, state) {
        if (state is WeeklyRoomsLoading) {
          return const SizedBox.shrink();
        }
        if (state is ActiveRoomsLoaded && state.rooms.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Exclusive Rooms',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'New every week!',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 180.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    return _buildWeeklyRoomCard(context, room);
                  },
                ),
              ),
              const Divider(height: 32),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWeeklyRoomCard(BuildContext context, dynamic room) {
    final bannerUrl = room['banner'] ?? '';
    return GestureDetector(
      onTap: () => _showWeeklyRoomJoinSheet(context, room),
      child: Container(
        width: 280.w,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              bannerUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: bannerUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(color: Colors.blue[100]),
                    )
                  : Container(color: Colors.blue[100]),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'] ?? 'Weekly Room',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, color: Colors.white, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          '${room['max_instances']} slots available',
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'EXCLUSIVE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWeeklyRoomJoinSheet(BuildContext context, dynamic room) {
    GroupJoinBottomSheet.show(
      context,
      onJoinCodeEntered: (code) {
        context.read<WeeklyRoomsBloc>().add(JoinPrivateGroup(code));
      },
      onStartNewGroup: () {
        context.read<WeeklyRoomsBloc>().add(StartNewPrivateGroup(room['id']));
      },
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
