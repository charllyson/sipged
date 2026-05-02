// lib/_blocs/system/notification/remote/notification_remote_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../notification_channel.dart';
import '../notification_data.dart';
import '../notification_source.dart';

class NotificationRemoteRepository {
  NotificationRemoteRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userNotificationsRef(
      String userId,
      ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  CollectionReference<Map<String, dynamic>> _userPushTokensRef(
      String userId,
      ) {
    return _firestore.collection('users').doc(userId).collection('pushTokens');
  }

  CollectionReference<Map<String, dynamic>> _userNotificationPreferencesRef(
      String userId,
      ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationPreferences');
  }

  CollectionReference<Map<String, dynamic>> _globalNotificationsRef() {
    return _firestore.collection('notifications');
  }

  // ---------------------------------------------------------------------------
  // PUSH TOKENS
  // ---------------------------------------------------------------------------

  Future<void> savePushToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final cleanUserId = userId.trim();
    final cleanToken = token.trim();
    final cleanPlatform = platform.trim().isEmpty ? 'unknown' : platform.trim();

    if (cleanUserId.isEmpty || cleanToken.isEmpty) return;

    await _userPushTokensRef(cleanUserId).doc(cleanToken).set({
      'token': cleanToken,
      'platform': cleanPlatform,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> disablePushToken({
    required String userId,
    required String token,
    String reason = 'disabled-by-client',
  }) async {
    final cleanUserId = userId.trim();
    final cleanToken = token.trim();

    if (cleanUserId.isEmpty || cleanToken.isEmpty) return;

    await _userPushTokensRef(cleanUserId).doc(cleanToken).set({
      'enabled': false,
      'disabledAt': FieldValue.serverTimestamp(),
      'disabledReason': reason,
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // PREFERÊNCIAS DE NOTIFICAÇÃO
  // ---------------------------------------------------------------------------

  Map<String, bool> defaultChannelsMap({
    bool local = true,
    bool bell = true,
    bool push = true,
    bool email = false,
    bool sms = false,
  }) {
    return <String, bool>{
      NotificationChannel.local.key: local,
      NotificationChannel.bell.key: bell,
      NotificationChannel.push.key: push,
      NotificationChannel.email.key: email,
      NotificationChannel.sms.key: sms,
    };
  }

  Map<String, bool> _normalizeChannelsMap(
      Map<String, dynamic>? raw, {
        Map<String, bool>? fallback,
      }) {
    final base = fallback ?? defaultChannelsMap();

    if (raw == null) {
      return Map<String, bool>.from(base);
    }

    return <String, bool>{
      NotificationChannel.local.key:
      raw[NotificationChannel.local.key] is bool
          ? raw[NotificationChannel.local.key] as bool
          : base[NotificationChannel.local.key] ?? true,
      NotificationChannel.bell.key: raw[NotificationChannel.bell.key] is bool
          ? raw[NotificationChannel.bell.key] as bool
          : base[NotificationChannel.bell.key] ?? true,
      NotificationChannel.push.key: raw[NotificationChannel.push.key] is bool
          ? raw[NotificationChannel.push.key] as bool
          : base[NotificationChannel.push.key] ?? true,
      NotificationChannel.email.key: raw[NotificationChannel.email.key] is bool
          ? raw[NotificationChannel.email.key] as bool
          : base[NotificationChannel.email.key] ?? false,
      NotificationChannel.sms.key: raw[NotificationChannel.sms.key] is bool
          ? raw[NotificationChannel.sms.key] as bool
          : base[NotificationChannel.sms.key] ?? false,
    };
  }

  Future<void> ensureDefaultNotificationPreferences({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final batch = _firestore.batch();
    int count = 0;

    for (final subSource in NotificationSourceRegistry.allSubSources) {
      final ref = _userNotificationPreferencesRef(cleanUserId).doc(
        subSource.key,
      );

      batch.set(ref, {
        'source': subSource.source.key,
        'subSource': subSource.key,
        'channels': defaultChannelsMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      count++;

      if (count >= 450) {
        await batch.commit();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  Future<Map<String, Map<String, bool>>> getNotificationPreferences({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return <String, Map<String, bool>>{};
    }

    final snapshot =
    await _userNotificationPreferencesRef(cleanUserId).get();

    final result = <String, Map<String, bool>>{};

    for (final subSource in NotificationSourceRegistry.allSubSources) {
      result[subSource.key] = defaultChannelsMap();
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final subSourceKey = (data['subSource'] ?? doc.id).toString().trim();

      if (subSourceKey.isEmpty) continue;

      final channelsRaw = data['channels'];

      result[subSourceKey] = _normalizeChannelsMap(
        channelsRaw is Map<String, dynamic> ? channelsRaw : null,
        fallback: result[subSourceKey],
      );
    }

    return result;
  }

  Stream<Map<String, Map<String, bool>>> watchNotificationPreferences({
    required String userId,
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const Stream<Map<String, Map<String, bool>>>.empty();
    }

    return _userNotificationPreferencesRef(cleanUserId).snapshots().map((
        snapshot,
        ) {
      final result = <String, Map<String, bool>>{};

      for (final subSource in NotificationSourceRegistry.allSubSources) {
        result[subSource.key] = defaultChannelsMap();
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final subSourceKey = (data['subSource'] ?? doc.id).toString().trim();

        if (subSourceKey.isEmpty) continue;

        final channelsRaw = data['channels'];

        result[subSourceKey] = _normalizeChannelsMap(
          channelsRaw is Map<String, dynamic> ? channelsRaw : null,
          fallback: result[subSourceKey],
        );
      }

      return result;
    });
  }

  Future<Map<String, bool>> getPreferenceForSubSource({
    required String userId,
    required String subSourceKey,
  }) async {
    final cleanUserId = userId.trim();
    final cleanSubSourceKey = subSourceKey.trim();

    if (cleanUserId.isEmpty || cleanSubSourceKey.isEmpty) {
      return defaultChannelsMap();
    }

    final doc = await _userNotificationPreferencesRef(cleanUserId)
        .doc(cleanSubSourceKey)
        .get();

    if (!doc.exists) {
      return defaultChannelsMap();
    }

    final data = doc.data();
    final channelsRaw = data?['channels'];

    return _normalizeChannelsMap(
      channelsRaw is Map<String, dynamic> ? channelsRaw : null,
    );
  }

  Future<bool> isChannelEnabled({
    required String userId,
    required String subSourceKey,
    required NotificationChannel channel,
  }) async {
    final preference = await getPreferenceForSubSource(
      userId: userId,
      subSourceKey: subSourceKey,
    );

    return preference[channel.key] ?? false;
  }

  Future<void> setNotificationPreferenceChannel({
    required String userId,
    required NotificationSubSource subSource,
    required NotificationChannel channel,
    required bool enabled,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    await _userNotificationPreferencesRef(cleanUserId)
        .doc(subSource.key)
        .set({
      'source': subSource.source.key,
      'subSource': subSource.key,
      'channels.${channel.key}': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setNotificationPreferenceChannels({
    required String userId,
    required NotificationSubSource subSource,
    required Map<NotificationChannel, bool> channels,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final map = <String, dynamic>{
      'source': subSource.source.key,
      'subSource': subSource.key,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    for (final entry in channels.entries) {
      map['channels.${entry.key.key}'] = entry.value;
    }

    await _userNotificationPreferencesRef(cleanUserId)
        .doc(subSource.key)
        .set(map, SetOptions(merge: true));
  }

  Future<void> resetNotificationPreferences({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final batch = _firestore.batch();
    int count = 0;

    for (final subSource in NotificationSourceRegistry.allSubSources) {
      final ref = _userNotificationPreferencesRef(cleanUserId).doc(
        subSource.key,
      );

      batch.set(ref, {
        'source': subSource.source.key,
        'subSource': subSource.key,
        'channels': defaultChannelsMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      count++;

      if (count >= 450) {
        await batch.commit();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // CRIAÇÃO DE NOTIFICAÇÕES
  // ---------------------------------------------------------------------------

  Future<String> createUserNotification({
    required String userId,
    required NotificationData data,
    bool sendPush = false,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw Exception('ID do usuário não informado para criar notificação.');
    }

    final notification = data.copyWith(
      sendPush: sendPush || data.sendPush,
      persistInFirebase: true,
      recipientUserId: cleanUserId,
      createdAt: data.createdAt ?? DateTime.now(),
    );

    final doc = await _userNotificationsRef(cleanUserId).add(
      notification.toMap(),
    );

    await doc.update({
      'id': doc.id,
    });

    return doc.id;
  }

  Future<List<String>> createUserNotifications({
    required Iterable<String> userIds,
    required NotificationData data,
    bool sendPush = false,
  }) async {
    final cleanUserIds = userIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (cleanUserIds.isEmpty) {
      return <String>[];
    }

    final createdIds = <String>[];

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final userId in cleanUserIds) {
      final ref = _userNotificationsRef(userId).doc();

      final notification = data.copyWith(
        id: ref.id,
        sendPush: sendPush || data.sendPush,
        persistInFirebase: true,
        recipientUserId: userId,
        createdAt: data.createdAt ?? DateTime.now(),
      );

      batch.set(ref, notification.toMap());

      createdIds.add(ref.id);
      count++;

      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    return createdIds;
  }

  Future<List<String>> createUserNotificationsRespectingPreferences({
    required Iterable<String> userIds,
    required NotificationData data,
    required String subSourceKey,
  }) async {
    final cleanUserIds = userIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (cleanUserIds.isEmpty) {
      return <String>[];
    }

    final createdIds = <String>[];

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final userId in cleanUserIds) {
      final preferences = await getPreferenceForSubSource(
        userId: userId,
        subSourceKey: subSourceKey,
      );

      final bellEnabled = preferences[NotificationChannel.bell.key] ?? true;
      final pushEnabled = preferences[NotificationChannel.push.key] ?? true;
      final emailEnabled = preferences[NotificationChannel.email.key] ?? false;
      final smsEnabled = preferences[NotificationChannel.sms.key] ?? false;

      if (!bellEnabled && !pushEnabled && !emailEnabled && !smsEnabled) {
        continue;
      }

      final ref = _userNotificationsRef(userId).doc();

      final notification = data.copyWith(
        id: ref.id,
        sendPush: data.sendPush && pushEnabled,
        sendEmail: data.sendEmail && emailEnabled,
        sendSms: data.sendSms && smsEnabled,
        persistInFirebase: bellEnabled,
        recipientUserId: userId,
        createdAt: data.createdAt ?? DateTime.now(),
      );

      if (bellEnabled) {
        batch.set(ref, notification.toMap());
        createdIds.add(ref.id);
        count++;
      }

      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    return createdIds;
  }

  Future<String> createGlobalNotification({
    required NotificationData data,
    bool sendPush = false,
  }) async {
    final notification = data.copyWith(
      sendPush: sendPush || data.sendPush,
      persistInFirebase: true,
      createdAt: data.createdAt ?? DateTime.now(),
    );

    final doc = await _globalNotificationsRef().add(
      notification.toMap(),
    );

    await doc.update({
      'id': doc.id,
    });

    return doc.id;
  }

  // ---------------------------------------------------------------------------
  // LEITURA / STREAMS
  // ---------------------------------------------------------------------------

  Stream<List<NotificationData>> watchSystemNotifications({
    int limit = 30,
  }) {
    return _globalNotificationsRef()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationData.fromDoc(doc)).toList();
    });
  }

  Stream<List<NotificationData>> watchUserNotifications({
    required String userId,
    int limit = 50,
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const Stream<List<NotificationData>>.empty();
    }

    return _userNotificationsRef(cleanUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NotificationData.fromDoc(doc)).toList();
    });
  }

  Stream<List<NotificationData>> watchUnreadUserNotifications({
    required String userId,
    int limit = 30,
  }) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const Stream<List<NotificationData>>.empty();
    }

    return _userNotificationsRef(cleanUserId)
        .where('seen', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final items =
      snapshot.docs.map((doc) => NotificationData.fromDoc(doc)).toList();

      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return items;
    });
  }

  Future<List<NotificationData>> getUserNotifications({
    required String userId,
    int limit = 50,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return <NotificationData>[];
    }

    final snapshot = await _userNotificationsRef(cleanUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => NotificationData.fromDoc(doc)).toList();
  }

  // ---------------------------------------------------------------------------
  // AÇÕES DO SINO
  // ---------------------------------------------------------------------------

  Future<void> markAsSeen({
    required String userId,
    required String notificationId,
  }) async {
    final cleanUserId = userId.trim();
    final cleanNotificationId = notificationId.trim();

    if (cleanUserId.isEmpty || cleanNotificationId.isEmpty) return;

    await _userNotificationsRef(cleanUserId).doc(cleanNotificationId).update({
      'seen': true,
      'seenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsSeen({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final snapshot = await _userNotificationsRef(cleanUserId)
        .where('seen', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'seen': true,
        'seenAt': FieldValue.serverTimestamp(),
      });

      count++;

      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  Future<void> deleteUserNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanUserId = userId.trim();
    final cleanNotificationId = notificationId.trim();

    if (cleanUserId.isEmpty || cleanNotificationId.isEmpty) return;

    await _userNotificationsRef(cleanUserId).doc(cleanNotificationId).delete();
  }

  Future<void> clearUserNotifications({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    final snapshot = await _userNotificationsRef(cleanUserId).get();

    if (snapshot.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);

      count++;

      if (count >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }
}