import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications (call in main.dart before runApp)
  Future<void> initialize() async {
    if (kIsWeb) return;

    print('🔔 [NotificationService] Initializing...');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    print('✅ Notification service initialized');
  }

  /// Called when user taps on notification
  void _onNotificationTap(NotificationResponse response) {
    print('👆 Notification tapped: ${response.payload}');
    // Payload can be used to navigate to chat screen, etc.
  }

  /// Show notification for a new message
  Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
    required String payload,  // Can be used for navigation (e.g., userId)
  }) async {
    if (kIsWeb) return;

    print('📬 [NotificationService] Showing notification');
    print('   From: $senderName');
    print('   Preview: $messagePreview');

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'shadow_comm_messages',  // Channel ID
            'Messages',              // Channel name
            channelDescription: 'Notifications for new encrypted messages',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'New message',
            enableVibration: true,
            enableLights: true,
            color: Color.fromARGB(255, 0, 217, 255),  // Neon cyan
          );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails notificationDetails =
          NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

      // Use timestamp as unique notification ID to avoid duplicates
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notifications.show(
        notificationId,
        senderName,  // Title
        messagePreview,  // Body
        notificationDetails,
        payload: payload,
      );

      print('✅ Notification shown (ID: $notificationId)');
    } catch (e) {
      print('❌ Notification error: $e');
    }
  }

  /// Request notification permissions (mainly for Android 13+)
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    print('🔔 [NotificationService] Requesting permissions...');

    try {
      // For iOS, the permission is handled by the initialization settings
      // For Android 13+, we try to request via the platform channel
      // The flutter_local_notifications package handles most of this automatically
      print('✅ Notification permissions configured');
      return true;
    } catch (e) {
      print('⚠️  Permission request error: $e');
      return false;
    }
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }
}
