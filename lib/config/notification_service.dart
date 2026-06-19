import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'global_keys.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Skip notifications for SDUI schema updates in background
  if (message.data['type'] == 'sdui_schema_updated') {
    log('SDUI schema updated in background, skipping notification');
    return;
  }

  // Avoid double notifications: if FCM already contains notification payload,
  // Android will show it automatically in background.
  // Process message even if notification is present if we have image data to show
  // Process message if we have image data to show, even if notification is present
  final String? imgUrl = message.data['image'] ?? message.notification?.android?.imageUrl;
  if (message.notification != null && imgUrl == null) {
    return;
  }

  String? title = message.data['title'] ?? message.notification?.title ?? 'Risbow';
  String? body = message.data['body'] ?? message.notification?.body ?? '';
  String? imageUrl = imgUrl;

  BigPictureStyleInformation? bigPictureStyle;
  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/background_img_${message.messageId}';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(filePath),
        contentTitle: title,
        summaryText: body,
      );
    } catch (e) {
      log('Error downloading background image: $e');
    }
  }

const String channelId = 'risbow_premium_channel';
   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
     channelId,
     'Risbow Notifications',
     importance: Importance.max,
     priority: Priority.high,
     icon: 'notification',
     largeIcon: const DrawableResourceAndroidBitmap('notification'),
     fullScreenIntent: true,
     styleInformation: bigPictureStyle ?? BigPictureStyleInformation(
       const DrawableResourceAndroidBitmap('notification'),
       largeIcon: const DrawableResourceAndroidBitmap('notification'),
       contentTitle: title,
       summaryText: body,
     ),
   );

  DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    subtitle: 'Risbow',
    threadIdentifier: 'risbow_thread',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // Show default notification for background messages
  FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    message.data['title'] ?? message.notification?.title ?? 'Risbow',
    message.data['body'] ?? message.notification?.body ?? '',
    NotificationDetails(
        android: androidDetails,
        iOS: iosDetails
    ),
  );
}

class NotificationService {
  late BuildContext? context;
  NotificationService({this.context});

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Stream for SDUI schema update notifications (live reload)
  static final _sduiUpdateController = StreamController<void>.broadcast();
  static Stream<void> get sduiUpdateStream => _sduiUpdateController.stream;
  static void notifySduiUpdate() {
    if (!_sduiUpdateController.isClosed) {
      _sduiUpdateController.add(null);
    }
  }

  /// Subscribe to SDUI update FCM topic
  Future<void> _subscribeToSduiTopic() async {
    try {
      await _firebaseMessaging.subscribeToTopic('sdui_updates');
      log('Subscribed to sdui_updates FCM topic');
    } catch (e) {
      log('Failed to subscribe to sdui_updates topic: $e');
    }
  }

  Future<void> initFirebaseMessaging(BuildContext context) async {
    await Firebase.initializeApp();
    await _requestNotificationPermissions();
    await _subscribeToSduiTopic();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('notification');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
      },
    );

    // Create high importance channel for Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
      'risbow_premium_channel',
      'Risbow Smart Notifications',
      description: 'Updates about your orders, special offers and rewards',
      importance: Importance.max,
    ));

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        log('Foreground Title: ${message.notification?.title}');
        log('Foreground Body: ${message.notification?.body}');

        // Check for SDUI schema update
        if (message.data['type'] == 'sdui_schema_updated') {
          log('SDUI schema updated, notifying listeners');
          notifySduiUpdate();
          // Don't show a notification overlay for SDUI updates
          return;
        }

        _showForegroundNotification(message);
      },
      onError: (error) {
        log('FirebaseMessaging onMessage error: $error');
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        log('Message opened app: ${message.notification?.title}');
        _handleNavigation(message);
      },
      onError: (error) {
        log('FirebaseMessaging onMessageOpenedApp error: $error');
      },
    );

    _firebaseMessaging.onTokenRefresh.listen(
      (String newToken) {
        log('New FCM Token: $newToken');
      },
      onError: (error) {
        log('FirebaseMessaging onTokenRefresh error: $error');
      },
    );
  }

  Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  void _showForegroundNotification(RemoteMessage message) async {
    // 1. Show custom In-App notification overlay for better engagement
    _showInAppNotificationOverlay(message);

    // 2. Also show system notification for history/consistency
    String? imageUrl = message.data['image'] ?? message.notification?.android?.imageUrl;
    String? title = message.data['title'] ?? message.notification?.title ?? 'Risbow';
    String? body = message.data['body'] ?? message.notification?.body ?? '';
    bool isGif = message.data['is_gif'] == 'true';

    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null && imageUrl.isNotEmpty && !isGif) {
      final largeIcon = await _downloadAndSaveFile(imageUrl, 'largeIcon');
      final bigPicture = await _downloadAndSaveFile(imageUrl, 'bigPicture');
      if (bigPicture != null) {
        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicture),
          largeIcon: largeIcon != null ? FilePathAndroidBitmap(largeIcon) : null,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
      }
    }

final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
       'risbow_premium_channel',
       'Risbow Smart Notifications',
       channelDescription: 'Updates about your orders, special offers and rewards',
       importance: Importance.max,
       priority: Priority.high,
       icon: 'notification',
       largeIcon: const DrawableResourceAndroidBitmap('notification'),
      color: const Color(0xFF1565C0), // Risbow Primary (Modern Blue)
      enableLights: true,
      ledColor: const Color(0xFF1565C0),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: bigPictureStyle,
      groupKey: 'risbow_group',
    );

    // iOS attachments
    List<DarwinNotificationAttachment> attachments = [];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String? filePath = await _downloadAndSaveFile(imageUrl, 'notification_img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      if (filePath != null) {
        attachments.add(DarwinNotificationAttachment(filePath));
      }
    }

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      subtitle: 'Risbow',
      threadIdentifier: 'risbow_thread',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: attachments,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  void _showInAppNotificationOverlay(RemoteMessage message) {
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null) return;

    String title = message.data['title'] ?? message.notification?.title ?? 'Update';
    String body = message.data['body'] ?? message.notification?.body ?? '';
    String? imageUrl = message.data['image'] ?? message.notification?.android?.imageUrl;

    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) {
              overlayEntry.remove();
            },
            child: GestureDetector(
              onTap: () {
                overlayEntry.remove();
                _handleNavigation(message);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.notifications),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

Future<void> showBackgroundNotification(RemoteMessage message) async {
     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
       'risbow_channel_id',
       'Risbow Notifications',
       importance: Importance.max,
       priority: Priority.high,
       icon: 'notification',
       largeIcon: DrawableResourceAndroidBitmap('notification'),
     );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Risbow',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  void _handleNavigation(RemoteMessage message) {
    // Extract data from message
    final String? videoUrl = message.data['video_url'];
    final String? notificationId = message.data['notification_id'];
    final String? type = message.data['type'];
    final String? redirectType = message.data['redirect_type'];
    final String? redirectValue = message.data['redirect_value'];

    final navigatorContext = GlobalKeys.navigatorKey.currentContext;

    if (navigatorContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle redirect if configured
        if (redirectType != null && redirectType.isNotEmpty && redirectValue != null && redirectValue.isNotEmpty) {
          log('Redirect: type=$redirectType, value=$redirectValue');
          
          switch (redirectType) {
            case 'sdui':
              navigatorContext.pushNamed('sdui');
              return;
            case 'room':
              navigatorContext.pushNamed('room-detail', pathParameters: {
                'code': redirectValue,
              });
              return;
            case 'custom_page':
              navigatorContext.pushNamed('custom-sale-page', pathParameters: {
                'slug': redirectValue,
              });
              return;
            case 'product':
              navigatorContext.pushNamed('product-detail', queryParameters: {
                'slug': redirectValue,
              });
              return;
            case 'category':
              navigatorContext.pushNamed('product-listing', queryParameters: {
                'type': 'category',
                'identifier': redirectValue,
              });
              return;
            case 'url':
              // Handle external URL opening if needed, or a webview route
              log('URL redirect not implemented: $redirectValue');
              return;
          }
        }
        
        // If notification has video, open video player
        if (videoUrl != null && videoUrl.isNotEmpty) {
          log('Opening video from notification: $videoUrl');
          navigatorContext.pushNamed('videoPage', pathParameters: {
            'slug': videoUrl,
          });
        } else if (notificationId != null) {
          // Navigate to notification/notification details page
          log('Opening notification: $notificationId');
} else if (type != null) {
           // Navigate based on notification type
           log('Notification type: $type');

           switch (type) {
             case 'room_unlocked':
             case 'room_member_joined':
             case 'new_room':
               final roomCode = message.data['room_code'];
               if (roomCode != null && roomCode.isNotEmpty) {
                 log('Navigating to room: $roomCode');
                 navigatorContext.pushNamed('room-detail', pathParameters: {
                   'code': roomCode,
                 });
               }
               break;
           }
         }
      });
    }
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      log('Error downloading file: $e');
      return null;
    }
  }
}

Future<String?> getFCMToken() async {
  return await NotificationService().getFcmToken();
}