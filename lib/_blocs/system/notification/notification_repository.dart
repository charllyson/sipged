import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_data.dart';

class NotificationRepository {
  NotificationRepository({
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

  CollectionReference<Map<String, dynamic>> _globalNotificationsRef() {
    return _firestore.collection('notifications');
  }

  Future<String> createUserNotification({
    required String userId,
    required NotificationData data,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw Exception('ID do usuário não informado para criar notificação.');
    }

    final doc = await _userNotificationsRef(cleanUserId).add(data.toMap());
    return doc.id;
  }

  Future<List<String>> createUserNotifications({
    required List<String> userIds,
    required NotificationData data,
  }) async {
    final cleanUserIds = userIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
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
      batch.set(ref, data.toMap());
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

  Future<String> createGlobalNotification({
    required NotificationData data,
  }) async {
    final doc = await _globalNotificationsRef().add(data.toMap());
    return doc.id;
  }

  Stream<List<NotificationData>> watchSystemNotifications({
    int limit = 30,
  }) {
    return _globalNotificationsRef()
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationData.fromDoc(doc))
          .toList();
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
      return snapshot.docs
          .map((doc) => NotificationData.fromDoc(doc))
          .toList();
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
      final items = snapshot.docs
          .map((doc) => NotificationData.fromDoc(doc))
          .toList();

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