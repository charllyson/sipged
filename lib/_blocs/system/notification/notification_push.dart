import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_cubit.dart';
import 'package:sipged/firebase_options_flavors.dart';

@pragma('vm:entry-point')
Future<void> sipgedFirebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp();

  debugPrint('[Push Background] messageId=${message.messageId}');
  debugPrint('[Push Background] data=${message.data}');
}

class NotificationPush {
  NotificationPush._();

  static final NotificationPush instance = NotificationPush._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  String? _currentUserId;

  static const AndroidNotificationChannel _androidChannel =
  AndroidNotificationChannel(
    'sipged_high_importance',
    'Notificações SIPGED',
    description: 'Canal principal de notificações do SIPGED.',
    importance: Importance.high,
  );

  Future<void> initialize({
    required String userId,
    required NotificationLocalCubit localCubit,
    required NotificationRemoteCubit remoteCubit,
    void Function(RemoteMessage message)? onMessageOpened,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    _currentUserId = cleanUserId;

    await _requestPermission();
    await _configureLocalNotifications();
    await _configureForegroundPresentation();

    await registerCurrentToken(
      userId: cleanUserId,
      remoteCubit: remoteCubit,
    );

    _listenTokenRefresh(
      userId: cleanUserId,
      remoteCubit: remoteCubit,
    );

    _listenForegroundMessages(localCubit);
    _listenOpenedMessages(onMessageOpened);

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      onMessageOpened?.call(initialMessage);
    }
  }

  Future<void> registerCurrentToken({
    required String userId,
    required NotificationRemoteCubit remoteCubit,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      final token = await _getTokenByPlatform();

      if (token == null || token.trim().isEmpty) {
        debugPrint('[Push] Token FCM não disponível.');
        return;
      }

      debugPrint('================ FCM TOKEN ================');
      debugPrint(token);
      debugPrint('===========================================');

      await remoteCubit.registerPushToken(
        userId: cleanUserId,
        token: token,
        platform: _platformName(),
      );

      debugPrint('[Push] Token FCM registrado para userId=$cleanUserId');
    } catch (e) {
      debugPrint('[Push] Erro ao obter/registrar token FCM: $e');
    }
  }

  Future<String?> _getTokenByPlatform() async {
    if (kIsWeb) {
      final vapidKey = FirebaseOptionsFlavors.webPushVapidKey.trim();

      if (vapidKey.isEmpty) {
        debugPrint(
          '[Push] WEB_PUSH_VAPID_KEY não informado. '
              'Use --dart-define=WEB_PUSH_VAPID_KEY=SUA_CHAVE_PUBLICA',
        );
      }

      return _messaging.getToken(
        vapidKey: vapidKey.isEmpty ? null : vapidKey,
      );
    }

    return _messaging.getToken();
  }

  Future<void> removeCurrentToken({
    required NotificationRemoteCubit remoteCubit,
  }) async {
    final userId = _currentUserId?.trim();

    if (userId == null || userId.isEmpty) return;

    final token = await _getTokenByPlatform();

    if (token == null || token.trim().isEmpty) return;

    await remoteCubit.removeCurrentPushToken(
      userId: userId,
      token: token,
      reason: 'logout-or-disabled',
    );

    await _messaging.deleteToken();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('[Push] Permissão: ${settings.authorizationStatus}');
  }

  Future<void> _configureLocalNotifications() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[Push Local Click] payload=${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _listenTokenRefresh({
    required String userId,
    required NotificationRemoteCubit remoteCubit,
  }) {
    _tokenRefreshSub?.cancel();

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final cleanToken = token.trim();

      if (cleanToken.isEmpty) return;

      await remoteCubit.registerPushToken(
        userId: userId,
        token: cleanToken,
        platform: _platformName(),
      );

      debugPrint('[Push] Token FCM atualizado para userId=$userId');
    });
  }

  void _listenForegroundMessages(
      NotificationLocalCubit localCubit,
      ) {
    _foregroundSub?.cancel();

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('[Push Foreground] messageId=${message.messageId}');
      debugPrint('[Push Foreground] data=${message.data}');

      final notification = _notificationFromRemoteMessage(message);

      localCubit.show(notification);

      if (!kIsWeb) {
        await _showLocalNotification(message);
      }
    });
  }

  void _listenOpenedMessages(
      void Function(RemoteMessage message)? onMessageOpened,
      ) {
    _openedSub?.cancel();

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[Push Opened] messageId=${message.messageId}');
      debugPrint('[Push Opened] data=${message.data}');

      onMessageOpened?.call(message);
    });
  }

  NotificationData _notificationFromRemoteMessage(RemoteMessage message) {
    final data = message.data;

    final title =
        message.notification?.title ?? data['title']?.toString() ?? 'SIPGED';

    final body = message.notification?.body ??
        data['body']?.toString() ??
        data['subtitle']?.toString();

    final status = NotificationStatusExtension.fromString(
      data['status']?.toString() ?? data['type']?.toString(),
    );

    return NotificationData(
      title: title,
      subtitle: body,
      details: data['details']?.toString(),
      leadingLabel: data['leadingLabel']?.toString(),
      status: status,
      channels: const {
        NotificationChannel.local,
      },
      createdAt: DateTime.now(),
      persistInFirebase: false,
      sendPush: false,
      extra: Map<String, dynamic>.from(data),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'SIPGED';

    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['subtitle']?.toString() ??
        message.data['details']?.toString();

    const androidDetails = AndroidNotificationDetails(
      'sipged_high_importance',
      'Notificações SIPGED',
      channelDescription: 'Canal principal de notificações do SIPGED.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'SIPGED',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';

    return 'unknown';
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();

    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
    _currentUserId = null;
  }
}