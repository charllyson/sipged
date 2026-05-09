import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/system/tenant/tenant_repository.dart';

import 'setup_data.dart';

class SetupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TenantRepository _tenantRepository;

  SetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TenantRepository? tenantRepository,
    String? tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantRepository = tenantRepository ??
            TenantRepository(
              tenantId: tenantId,
            );

  String get tenantId => _tenantRepository.tenantId;

  String? get _currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    return _firestore.collection(TenantRepository.collectionName).doc(tenantId);
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

    final cleanType = type?.trim();

    final ref = _itemsCollection(group).doc(cleanKey);

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'parentId': tenantId,
      'id': cleanKey,
      'key': cleanKey,
      'label': cleanLabel,
      'type': cleanType != null && cleanType.isNotEmpty
          ? cleanType
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

    await ref.set(data, SetOptions(merge: true));

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

    final cleanKey = key?.trim();
    final cleanLabel = label?.trim();
    final cleanDescription = description?.trim();
    final cleanType = type?.trim();

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'parentId': tenantId,
      if (cleanKey != null && cleanKey.isNotEmpty) 'key': cleanKey,
      if (cleanLabel != null && cleanLabel.isNotEmpty) 'label': cleanLabel,
      if (description != null) 'description': cleanDescription,
      if (cleanType != null && cleanType.isNotEmpty) 'type': cleanType,
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