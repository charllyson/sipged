import 'package:cloud_firestore/cloud_firestore.dart';

import 'expropriation_data.dart';

class ExpropriationRepository {
  ExpropriationRepository({
    FirebaseFirestore? firestore,
    required String tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _tenantId = _validateRequiredId(
          tenantId,
          fieldName: 'tenantId',
        );

  final FirebaseFirestore _firestore;
  final String _tenantId;

  String get tenantId => _tenantId;

  static String _validateRequiredId(
      String value, {
        required String fieldName,
      }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('$fieldName é obrigatório.');
    }

    return trimmed;
  }

  String _cleanRequiredId(
      String value, {
        required String fieldName,
      }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('$fieldName é obrigatório.');
    }

    return trimmed;
  }

  DocumentReference<Map<String, dynamic>> _contractDoc(String contractId) {
    final cleanContractId = _cleanRequiredId(
      contractId,
      fieldName: 'contractId',
    );

    return _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('contracts')
        .doc(cleanContractId);
  }

  CollectionReference<Map<String, dynamic>> _collection(String contractId) {
    return _contractDoc(contractId)
        .collection('land')
        .doc('main')
        .collection('imovel');
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String propertyId,
  }) {
    final cleanPropertyId = _cleanRequiredId(
      propertyId,
      fieldName: 'propertyId',
    );

    return _collection(contractId).doc(cleanPropertyId);
  }

  Future<List<ExpropriationData>> fetchAll(String contractId) async {
    final cleanContractId = _cleanRequiredId(
      contractId,
      fieldName: 'contractId',
    );

    final snapshot = await _collection(cleanContractId).get();

    final list = snapshot.docs
        .map(
          (doc) => ExpropriationData.fromMap(
        doc.data(),
        id: doc.id,
        contractId: cleanContractId,
      ),
    )
        .toList(growable: false);

    return list;
  }

  Future<ExpropriationData?> fetchById({
    required String contractId,
    required String propertyId,
  }) async {
    final cleanContractId = _cleanRequiredId(
      contractId,
      fieldName: 'contractId',
    );

    final cleanPropertyId = propertyId.trim();
    if (cleanPropertyId.isEmpty) return null;

    final snapshot = await _doc(
      contractId: cleanContractId,
      propertyId: cleanPropertyId,
    ).get();

    final map = snapshot.data();

    if (!snapshot.exists || map == null) return null;

    return ExpropriationData.fromMap(
      map,
      id: snapshot.id,
      contractId: cleanContractId,
    );
  }

  Future<ExpropriationData> save(ExpropriationData data) async {
    final cleanContractId = _cleanRequiredId(
      data.contractId,
      fieldName: 'contractId',
    );

    final now = DateTime.now();
    final propertyId = data.id?.trim();

    if (propertyId == null || propertyId.isEmpty) {
      final ref = _collection(cleanContractId).doc();

      final saved = data.copyWith(
        id: ref.id,
        contractId: cleanContractId,
        createdAt: data.createdAt ?? now,
        updatedAt: now,
      );

      await ref.set(saved.toMap());

      return saved;
    }

    final saved = data.copyWith(
      id: propertyId,
      contractId: cleanContractId,
      createdAt: data.createdAt ?? now,
      updatedAt: now,
    );

    await _doc(
      contractId: cleanContractId,
      propertyId: propertyId,
    ).set(
      saved.toMap(),
      SetOptions(merge: true),
    );

    return saved;
  }

  Future<void> delete({
    required String contractId,
    required String propertyId,
  }) async {
    final cleanContractId = _cleanRequiredId(
      contractId,
      fieldName: 'contractId',
    );

    final cleanPropertyId = propertyId.trim();
    if (cleanPropertyId.isEmpty) return;

    await _doc(
      contractId: cleanContractId,
      propertyId: cleanPropertyId,
    ).delete();
  }
}