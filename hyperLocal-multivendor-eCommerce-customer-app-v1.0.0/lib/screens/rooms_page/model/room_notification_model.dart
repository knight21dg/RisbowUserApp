import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constant.dart';
import '../../../model/notification_model/notification_model.dart';

enum RoomNotificationType {
  room,
  roomUnlocked,
  memberJoined,
  roomExpired,
  roomApproved,
  roomRejected,
}

class RoomNotification extends NotificationModel {
  final String? roomCode;
  final String? roomName;
  final int? memberCount;
  final RoomNotificationType? roomNotificationType;

  RoomNotification({
    required super.id,
    required super.title,
    required super.message,
    super.image,
    super.video,
    required super.type,
    required super.isRead,
    required super.createdAt,
    super.metadata,
    this.roomCode,
    this.roomName,
    this.memberCount,
    this.roomNotificationType,
  });

  factory RoomNotification.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? '';
    final metadata = json['metadata'] as Map<String, dynamic>?;

    RoomNotificationType? roomType;
    if (type == 'room_unlocked' || type == 'roomUnlocked') {
      roomType = RoomNotificationType.roomUnlocked;
    } else if (type == 'room_member_joined' || type == 'roomMemberJoined') {
      roomType = RoomNotificationType.memberJoined;
    } else if (type == 'room_expired' || type == 'roomExpired') {
      roomType = RoomNotificationType.roomExpired;
    } else if (type == 'room_approved' || type == 'roomApproved') {
      roomType = RoomNotificationType.roomApproved;
    } else if (type == 'room_rejected' || type == 'roomRejected') {
      roomType = RoomNotificationType.roomRejected;
    } else if (type == 'room' || type.contains('room')) {
      roomType = RoomNotificationType.room;
    }

    return RoomNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      image: json['image'],
      video: json['video'],
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      metadata: metadata,
      roomCode: metadata?['room_code'] ?? json['room_code'],
      roomName: metadata?['room_name'] ?? json['room_name'],
      memberCount: metadata?['member_count'] ?? json['member_count'],
      roomNotificationType: roomType,
    );
  }

  bool get isRoomUnlocked => type == 'room_unlocked' || roomNotificationType == RoomNotificationType.roomUnlocked;
  bool get isMemberJoined => type == 'room_member_joined' || roomNotificationType == RoomNotificationType.memberJoined;
  bool get isRoomExpired => type == 'room_expired' || roomNotificationType == RoomNotificationType.roomExpired;
  bool get isRoomApproved => type == 'room_approved' || roomNotificationType == RoomNotificationType.roomApproved;
  bool get isRoomRejected => type == 'room_rejected' || roomNotificationType == RoomNotificationType.roomRejected;

  String get roomEventEmoji {
    if (isRoomUnlocked) return '🎊';
    if (isMemberJoined) return '🎉';
    if (isRoomExpired) return '⏰';
    if (isRoomApproved) return '✅';
    if (isRoomRejected) return '❌';
    return '📢';
  }
}

class RoomNotificationService {
  static RoomNotificationService? _instance;
  static RoomNotificationService get instance => _instance ??= RoomNotificationService._();
  RoomNotificationService._();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<List<RoomNotification>> getRoomNotifications({int perPage = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstant.baseUrl}notifications/rooms?per_page=$perPage'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> notifications = data['data']['data'] ?? [];
          return notifications.map((n) => RoomNotification.fromJson(n)).toList();
        }
      }
      throw Exception('Failed to fetch room notifications');
    } catch (e) {
      throw Exception('Failed to fetch room notifications: $e');
    }
  }
}