import 'dart:developer';
import 'package:hyper_local/config/api_routes.dart';
import 'package:hyper_local/config/api_base_helper.dart';
import 'package:hyper_local/config/constant.dart';
import 'package:hyper_local/model/notification_model/notification_model.dart';

class NotificationRepository {
  // Use AppConstant.apiBaseHelper which includes auth headers
  ApiBaseHelper get _api => AppConstant.apiBaseHelper;

  Future<List<NotificationModel>> getNotifications({int page = 1, int perPage = 20}) async {
    try {
      final response = await _api.getAPICall(
        '${ApiRoutes.notificationsApi}?page=$page&per_page=$perPage',
        {},
      );
      if (response['success'] == true && response['data'] != null) {
        final notifications = response['data']['notifications'] as List<dynamic>? ?? [];
        return notifications.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _api.getAPICall(
        ApiRoutes.unreadNotificationCountApi,
        {},
      );
      if (response['success'] == true && response['data'] != null) {
        return response['data']['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _api.postAPICall(
        ApiRoutes.markNotificationReadApi(notificationId),
        {},
      );
      return response['success'] == true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _api.postAPICall(
        ApiRoutes.markAllNotificationsReadApi,
        {},
      );
      return response['success'] == true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> saveFcmToken(String token) async {
    try {
      log('Saving FCM token: ${token.substring(0, 20)}...');
      final response = await _api.postAPICall(
        ApiRoutes.fcmTokenApi,
        {'fcm_token': token},
      );
      log('FCM token save response: $response');
      return response['success'] == true;
    } catch (e) {
      log('Error saving FCM token: $e');
      return false;
    }
  }
}
