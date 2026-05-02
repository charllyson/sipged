// lib/_blocs/system/notification/preferences/notification_preferences_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'package:sipged/_blocs/system/notification/notification_source.dart';
import 'notification_preference_data.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationPreferences');
  }

  DocumentReference<Map<String, dynamic>> _sourceRef({
    required String userId,
    required String sourceKey,
  }) {
    return _ref(userId).doc(sourceKey);
  }

  Future<void> ensureDefaults(String userId) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final subSource in NotificationSourceRegistry.allSubSources) {
      final docRef = _sourceRef(
        userId: cleanUserId,
        sourceKey: subSource.key,
      );

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        batch.set(
          docRef,
          NotificationPreferenceData.defaultForSubSource(subSource).toMap(),
          SetOptions(merge: true),
        );

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
  }

  Stream<List<NotificationPreferenceData>> watchPreferences(String userId) {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return const Stream<List<NotificationPreferenceData>>.empty();
    }

    return _ref(cleanUserId).snapshots().map((snapshot) {
      final remoteItems = snapshot.docs.map((doc) {
        return NotificationPreferenceData.fromMap(
          doc.data(),
          sourceKey: doc.id,
        );
      }).toList();

      final byKey = <String, NotificationPreferenceData>{
        for (final item in remoteItems) item.sourceKey: item,
      };

      return NotificationSourceRegistry.allSubSources.map((subSource) {
        return byKey[subSource.key] ??
            NotificationPreferenceData.defaultForSubSource(subSource);
      }).toList();
    });
  }

  Future<List<NotificationPreferenceData>> getPreferences(String userId) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return NotificationSourceRegistry.allSubSources
          .map(NotificationPreferenceData.defaultForSubSource)
          .toList();
    }

    final snapshot = await _ref(cleanUserId).get();

    final remoteItems = snapshot.docs.map((doc) {
      return NotificationPreferenceData.fromMap(
        doc.data(),
        sourceKey: doc.id,
      );
    }).toList();

    final byKey = <String, NotificationPreferenceData>{
      for (final item in remoteItems) item.sourceKey: item,
    };

    return NotificationSourceRegistry.allSubSources.map((subSource) {
      return byKey[subSource.key] ??
          NotificationPreferenceData.defaultForSubSource(subSource);
    }).toList();
  }

  Future<NotificationPreferenceData> getPreference({
    required String userId,
    required String sourceKey,
  }) async {
    final cleanUserId = userId.trim();
    final cleanSourceKey = _normalizeSourceKey(sourceKey);

    final fallback = _fallbackPreference(cleanSourceKey);

    if (cleanUserId.isEmpty) return fallback;

    final snapshot = await _sourceRef(
      userId: cleanUserId,
      sourceKey: cleanSourceKey,
    ).get();

    if (!snapshot.exists) return fallback;

    return NotificationPreferenceData.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
      sourceKey: cleanSourceKey,
    );
  }

  Future<void> savePreference({
    required String userId,
    required NotificationPreferenceData preference,
  }) async {
    final cleanUserId = userId.trim();
    final cleanSourceKey = _normalizeSourceKey(preference.sourceKey);

    if (cleanUserId.isEmpty || cleanSourceKey.isEmpty) return;

    await _sourceRef(
      userId: cleanUserId,
      sourceKey: cleanSourceKey,
    ).set(
      preference.copyWith(sourceKey: cleanSourceKey).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> setSourceEnabled({
    required String userId,
    required String sourceKey,
    required bool enabled,
  }) async {
    final current = await getPreference(
      userId: userId,
      sourceKey: sourceKey,
    );

    await savePreference(
      userId: userId,
      preference: current.copyWith(enabled: enabled),
    );
  }

  Future<void> setChannelEnabled({
    required String userId,
    required String sourceKey,
    required NotificationChannel channel,
    required bool enabled,
  }) async {
    final current = await getPreference(
      userId: userId,
      sourceKey: sourceKey,
    );

    await savePreference(
      userId: userId,
      preference: current.toggleChannel(
        channel: channel,
        value: enabled,
      ),
    );
  }

  Future<void> resetDefaults(String userId) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final subSource in NotificationSourceRegistry.allSubSources) {
      final docRef = _sourceRef(
        userId: cleanUserId,
        sourceKey: subSource.key,
      );

      batch.set(
        docRef,
        NotificationPreferenceData.defaultForSubSource(subSource).toMap(),
        SetOptions(merge: true),
      );

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

  String _normalizeSourceKey(String value) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) {
      return NotificationSubSource.generalSystem.key;
    }

    final subSource = NotificationSourceRegistry.tryResolveSubSource(clean);

    if (subSource != null) {
      return subSource.key;
    }

    final source = NotificationSourceRegistry.resolveSource(clean);
    final subSources = source.subSources;

    if (subSources.isNotEmpty) {
      return subSources.first.key;
    }

    return NotificationSubSource.generalSystem.key;
  }

  NotificationPreferenceData _fallbackPreference(String sourceKey) {
    final subSource = NotificationSourceRegistry.tryResolveSubSource(sourceKey);

    if (subSource != null) {
      return NotificationPreferenceData.defaultForSubSource(subSource);
    }

    final source = NotificationSourceRegistry.resolveSource(sourceKey);

    return NotificationPreferenceData.defaultForSource(source);
  }
}