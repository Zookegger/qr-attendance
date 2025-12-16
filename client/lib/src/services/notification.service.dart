import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // --- CHANNELS CONFIGURATION ---
  static const String _channelHighId = 'high_importance_channel_v2';
  static const String _channelHighName = 'Urgent Alerts';
  static const String _channelHighDesc =
      'Notifications that require immediate attention.';

  static const String _channelDefaultId = 'default_channel';
  static const String _channelDefaultName = 'General Updates';
  static const String _channelDefaultDesc = 'Standard reminders and updates.';

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint("User declined or has not accepted permissions");
      return;
    }

    // 2. Setup Local Notifications (Common Settings)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // 3. Create MULTIPLE Channels (Android 8.0+)
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Create High Importance Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelHighId,
          _channelHighName,
          description: _channelHighDesc,
          importance: Importance.max,
          playSound: true,
        ),
      );

      // Create Default Channel (Lower importance, no popup)
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelDefaultId,
          _channelDefaultName,
          description: _channelDefaultDesc,
          importance: Importance.defaultImportance, // No heads-up display
          playSound: true,
        ),
      );
    }

    // 4. Handle Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 6. Get the Token
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint("============================================");
    debugPrint("YOUR FCM TOKEN: $fcmToken");
    debugPrint("============================================");
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // LOGIC: Check the payload 'type' to decide priority
    // Default to 'default' if no type is provided
    final String type = message.data['type'] ?? 'normal';

    AndroidNotificationDetails androidDetails;

    if (type == 'urgent') {
      // Use High Importance Channel
      androidDetails = AndroidNotificationDetails(
        _channelHighId,
        _channelHighName,
        channelDescription: _channelHighDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Urgent Alert',
      );
    } else {
      // Use Default Channel
      androidDetails = const AndroidNotificationDetails(
        _channelDefaultId,
        _channelDefaultName,
        channelDescription: _channelDefaultDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
    }

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }
}
