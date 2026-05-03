import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_repository.dart';

import 'setup_data.dart';

class SetupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  final String tenantId;

  SetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        tenantId = (tenantId == null || tenantId.trim().isEmpty)
            ? TenantRepository.testTenantId
            : tenantId.trim();

  String? get _currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    return _firestore.collection(TenantData.collectionName).doc(tenantId);
  }

  CollectionReference<Map<String, dynamic>> _itemsCollection(SetupGroup group) {
    return _tenantRef
        .collection('setup')
        .doc(group.collectionName)
        .collection('items');
  }

  Future<List<SetupData>> loadGroup(SetupGroup group) async {
    final snap = await _itemsCollection(group).orderBy('order').get();

    return snap.docs
        .map(
          (doc) => SetupData.fromDoc(
        doc,
        group: group,
        forcedTenantId: tenantId,
      ),
    )
        .toList();
  }

  Future<Map<SetupGroup, List<SetupData>>> loadAll() async {
    final results = await Future.wait<List<SetupData>>(
      SetupGroup.values.map(loadGroup),
    );

    final data = <SetupGroup, List<SetupData>>{};

    for (int i = 0; i < SetupGroup.values.length; i++) {
      data[SetupGroup.values[i]] = results[i];
    }

    return data;
  }

  Future<SetupData> createItem({
    required SetupGroup group,
    required String key,
    required String label,
    String? description,
    String? type,
    dynamic value,
    bool enabled = true,
    int order = 0,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final cleanKey = key.trim();

    if (cleanKey.isEmpty) {
      throw ArgumentError('A chave técnica não pode estar vazia.');
    }

    final cleanLabel = label.trim();

    if (cleanLabel.isEmpty) {
      throw ArgumentError('O rótulo não pode estar vazio.');
    }

    final ref = _itemsCollection(group).doc(cleanKey);

    final nowData = <String, dynamic>{
      'tenantId': tenantId,
      'key': cleanKey,
      'label': cleanLabel,
      'type': type?.trim().isNotEmpty == true
          ? type!.trim()
          : _defaultTypeForGroup(group),
      'enabled': enabled,
      'order': order,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'value': ?value,
      if (metadata.isNotEmpty) 'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    await ref.set(nowData, SetOptions(merge: true));

    final snap = await ref.get();

    return SetupData.fromDoc(
      snap,
      group: group,
      forcedTenantId: tenantId,
    );
  }

  Future<SetupData> updateItem({
    required SetupGroup group,
    required String id,
    String? key,
    String? label,
    String? description,
    String? type,
    dynamic value,
    bool? enabled,
    int? order,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('O ID do item não pode estar vazio.');
    }

    final data = <String, dynamic>{
      'tenantId': tenantId,
      if (key != null && key.trim().isNotEmpty) 'key': key.trim(),
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      if (description != null) 'description': description.trim(),
      if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      'value': ?value,
      'enabled': ?enabled,
      'order': ?order,
      'metadata': ?metadata,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    final ref = _itemsCollection(group).doc(cleanId);

    await ref.set(data, SetOptions(merge: true));

    final snap = await ref.get();

    return SetupData.fromDoc(
      snap,
      group: group,
      forcedTenantId: tenantId,
    );
  }

  Future<SetupData> toggleItem({
    required SetupGroup group,
    required String id,
    required bool enabled,
  }) async {
    return updateItem(
      group: group,
      id: id,
      enabled: enabled,
    );
  }

  Future<void> deleteItem({
    required SetupGroup group,
    required String id,
  }) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('O ID do item não pode estar vazio.');
    }

    await _itemsCollection(group).doc(cleanId).delete();
  }

  String _defaultTypeForGroup(SetupGroup group) {
    switch (group) {
      case SetupGroup.modules:
        return 'module';

      case SetupGroup.profiles:
        return 'profile';

      case SetupGroup.permissions:
        return 'permission';

      case SetupGroup.parameters:
        return 'parameter';

      case SetupGroup.integrations:
        return 'integration';

      case SetupGroup.featureFlags:
        return 'feature_flag';
    }
  }
}