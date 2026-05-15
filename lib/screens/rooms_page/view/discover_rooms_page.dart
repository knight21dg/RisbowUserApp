import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/connectivity_service.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/rooms_page/model/group_buy_models.dart';
import 'package:hyper_local/screens/rooms_page/repo/room_repository.dart';
import 'package:hyper_local/screens/rooms_page/widgets/group_buy_components.dart';

class DiscoverRoomsPage extends StatefulWidget {
  const DiscoverRoomsPage({super.key});

  @override
  State<DiscoverRoomsPage> createState() => _DiscoverRoomsPageState();
}

class _DiscoverRoomsPageState extends State<DiscoverRoomsPage> {
  final RoomRepository _repository = RoomRepository();
  final ConnectivityService _connectivity = ConnectivityService();
  final TextEditingController _searchController = TextEditingController();

  List<GroupBuyRoom> _rooms = const <GroupBuyRoom>[];
  bool _loading = true;
  bool _offline = false;
  String _search = '';
  String _sort = 'popular';

  @override
  void initState() {
    super.initState();
    _loadDiscoverRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoverRooms() async {
    setState(() => _loading = true);
    final isOnline = await _connectivity.refreshStatus();
    final rooms = await _repository.discoverRooms(query: _search);
    if (!mounted) return;
    setState(() {
      _offline = !isOnline;
      _rooms = _sortRooms(rooms, _sort);
      _loading = false;
    });
  }

  List<GroupBuyRoom> _sortRooms(List<GroupBuyRoom> rooms, String sort) {
    final copy = List<GroupBuyRoom>.from(rooms);
    if (sort == 'latest') {
      copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      copy.sort((a, b) => b.membersJoined.compareTo(a.membersJoined));
    }
    return copy;
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort by',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                RadioListTile<String>(
                  value: 'popular',
                  groupValue: _sort,
                  title: const Text('Most popular'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    Navigator.pop(context);
                    _loadDiscoverRooms();
                  },
                ),
                RadioListTile<String>(
                  value: 'latest',
                  groupValue: _sort,
                  title: const Text('Latest'),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sort = value);
                    Navigator.pop(context);
                    _loadDiscoverRooms();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _sortRooms(_rooms, _sort);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Discover Rooms'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_offline)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              color: Colors.orange.shade100,
              child: Text(
                'Unable to refresh public rooms. Check connection.',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _search = value);
                _loadDiscoverRooms();
              },
              decoration: InputDecoration(
                hintText: 'Search rooms...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : rooms.isEmpty
                ? Center(
                    child: Text(
                      'No public rooms found.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 720
                          ? 2
                          : 1;
                      return GridView.builder(
                        padding: EdgeInsets.only(bottom: 16.h),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: crossAxisCount == 1 ? 1.85 : 1.45,
                        ),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return RoomCard(
                            room: room,
                            actionLabel: 'Join',
                            onPressed: () =>
                                context.push('/rooms/${room.code}'),
                            disabled: room.isExpired || room.isFull,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/rooms/join'),
        icon: const Icon(Icons.login_rounded),
        label: const Text('Join by code'),
      ),
    );
  }
}
