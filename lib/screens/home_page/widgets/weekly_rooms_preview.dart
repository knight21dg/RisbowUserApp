import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/router/app_routes.dart';

class WeeklyRoomsPreview extends StatefulWidget {
  final List<RoomPreview> rooms;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const WeeklyRoomsPreview({
    super.key,
    required this.rooms,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  State<WeeklyRoomsPreview> createState() => _WeeklyRoomsPreviewState();
}

class _WeeklyRoomsPreviewState extends State<WeeklyRoomsPreview> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        SizedBox(height: 12.h),
        SizedBox(
          height: 160.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: widget.rooms.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: _RoomPreviewCard(
                  room: widget.rooms[index],
                  onTap: () {
                    context.push('/rooms/${widget.rooms[index].code}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 14.w,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Weekly Rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.onViewAll != null)
            TextButton(
              onPressed: widget.onViewAll,
              child: Text(
                'View All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            width: 100.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 160.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Container(
                  width: 160.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomPreviewCard extends StatelessWidget {
  final RoomPreview room;
  final VoidCallback? onTap;

  const _RoomPreviewCard({
    required this.room,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                  child: room.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: room.bannerUrl!,
                          height: 70.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.group,
                              color: Colors.grey[400],
                              size: 30.w,
                            ),
                          ),
                        )
                      : Container(
                          height: 70.h,
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30.w,
                          ),
                        ),
                ),
                Positioned(
                  top: 6.h,
                  right: 6.w,
                  child: _buildStatusBadge(context),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  _buildProgressBar(context),
                  SizedBox(height: 4.h),
                  Text(
                    '${room.membersJoined}/${room.maxMembers} joined',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color badgeColor;
    String statusText;

    switch (room.status.toLowerCase()) {
      case 'active':
        badgeColor = Colors.green;
        statusText = 'Active';
        break;
      case 'unlocked':
        badgeColor = Colors.orange;
        statusText = 'Unlocked';
        break;
      case 'teasing':
        badgeColor = Colors.blue;
        statusText = 'Coming';
        break;
      default:
        badgeColor = Colors.grey;
        statusText = room.status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = room.maxMembers > 0 ? room.membersJoined / room.maxMembers : 0.0;
    
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
            minHeight: 4.h,
          ),
        ),
      ],
    );
  }
}

class RoomPreview {
  final int id;
  final String code;
  final String name;
  final String? bannerUrl;
  final int maxMembers;
  final int membersJoined;
  final String status;
  final String? ownerName;
  final double? discount;

  const RoomPreview({
    required this.id,
    required this.code,
    required this.name,
    this.bannerUrl,
    required this.maxMembers,
    required this.membersJoined,
    required this.status,
    this.ownerName,
    this.discount,
  });

  factory RoomPreview.fromJson(Map<String, dynamic> json) {
    return RoomPreview(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? 'Group Deal',
      bannerUrl: json['banner'],
      maxMembers: json['max_members'] ?? json['required_members'] ?? 50,
      membersJoined: json['members_joined'] ?? json['joined_members'] ?? 0,
      status: json['status'] ?? 'teasing',
      ownerName: json['owner_name'],
      discount: json['discount']?.toDouble(),
    );
  }
}