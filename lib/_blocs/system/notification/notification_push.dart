// lib/_blocs/system/notification/notification_push.dart

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

  final Set<String> _recentForegroundKeys = <String>{};
  final Map<String, Timer> _recentForegroundTimers = <String, Timer>{};

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

    final token = await _getTokenByPlatform();

    if (token == null || token.trim().isEmpty) {
      return;
    }

    await remoteCubit.registerPushToken(
      userId: cleanUserId,
      token: token,
      platform: _platformName(),
    );
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
      onDidReceiveNotificationResponse: (response) {},
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
    });
  }

  void _listenForegroundMessages(
      NotificationLocalCubit localCubit,
      ) {
    _foregroundSub?.cancel();

    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      if (_shouldSuppressForegroundToast(message)) {
        return;
      }

      final notification = _notificationFromRemoteMessage(message);
      final key = _foregroundDedupKey(message, notification);

      if (_wasRecentlyShown(key)) {
        return;
      }

      _markRecentlyShown(key);

      localCubit.show(notification);

      if (!kIsWeb) {
        await _showLocalNotification(message);
      }
    });
  }

  bool _shouldSuppressForegroundToast(RemoteMessage message) {
    final currentUserId = _currentUserId?.trim();

    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }

    final data = message.data;

    final actorId = _clean(data['actorId']?.toString());
    final createdBy = _clean(data['createdBy']?.toString());
    final senderId = _clean(data['senderId']?.toString());

    if (actorId == currentUserId) return true;
    if (createdBy == currentUserId) return true;
    if (senderId == currentUserId) return true;

    return false;
  }

  bool _wasRecentlyShown(String key) {
    final cleanKey = key.trim();

    if (cleanKey.isEmpty) return false;

    return _recentForegroundKeys.contains(cleanKey);
  }

  void _markRecentlyShown(String key) {
    final cleanKey = key.trim();

    if (cleanKey.isEmpty) return;

    _recentForegroundKeys.add(cleanKey);

    _recentForegroundTimers[cleanKey]?.cancel();
    _recentForegroundTimers[cleanKey] = Timer(
      const Duration(seconds: 12),
          () {
        _recentForegroundKeys.remove(cleanKey);
        _recentForegroundTimers.remove(cleanKey);
      },
    );
  }

  String _foregroundDedupKey(
      RemoteMessage message,
      NotificationData notification,
      ) {
    final data = message.data;

    final messageId = message.messageId?.trim();

    if (messageId != null && messageId.isNotEmpty) {
      return 'message|$messageId';
    }

    final action = _clean(data['action']?.toString());
    final measurementId = _clean(data['measurementId']?.toString());
    final contractId = _clean(data['contractId']?.toString());
    final measurementOrder = _clean(data['measurementOrder']?.toString());
    final source = _clean(
      (data['notificationSource'] ??
          data['sourceKey'] ??
          data['subSource'] ??
          data['source'])
          ?.toString(),
    );

    if (source.isNotEmpty && action.isNotEmpty && measurementId.isNotEmpty) {
      return '$source|$action|$measurementId';
    }

    if (source.isNotEmpty &&
        action.isNotEmpty &&
        contractId.isNotEmpty &&
        measurementOrder.isNotEmpty) {
      return '$source|$action|$contractId|$measurementOrder';
    }

    final createdAt = notification.createdAt?.millisecondsSinceEpoch ?? 0;

    return 'fallback|${notification.title}|${notification.subtitle}|$createdAt';
  }

  void _listenOpenedMessages(
      void Function(RemoteMessage message)? onMessageOpened,
      ) {
    _openedSub?.cancel();

    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
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

  String _clean(String? value) {
    return (value ?? '').trim();
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();

    for (final timer in _recentForegroundTimers.values) {
      timer.cancel();
    }

    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
    _currentUserId = null;

    _recentForegroundKeys.clear();
    _recentForegroundTimers.clear();
  }
}