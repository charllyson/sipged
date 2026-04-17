import 'package:cloud_firestore/cloud_firestore.dart';
import 'land_property_data.dart';

class LandPropertyRepository {
  LandPropertyRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String contractId) {
    return _firestore.collection('land').doc(contractId).collection('imovel');
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String propertyId,
  }) {
    return _collection(contractId).doc(propertyId);
  }

  Future<List<LandPropertyData>> fetchAll(String contractId) async {
    final snapshot = await _collection(contractId).get();

    return snapshot.docs
        .map(
          (doc) => LandPropertyData.fromMap(
        doc.data(),
        id: doc.id,
        contractId: contractId,
      ),
    )
        .toList(growable: false);
  }

  Future<LandPropertyData?> fetchById({
    required String contractId,
    required String propertyId,
  }) async {
    final normalizedPropertyId = propertyId.trim();
    if (normalizedPropertyId.isEmpty) return null;

    final doc = await _doc(
      contractId: contractId,
      propertyId: normalizedPropertyId,
    ).get();

    final map = doc.data();
    if (!doc.exists || map == null) return null;

    return LandPropertyData.fromMap(
      map,
      id: doc.id,
      contractId: contractId,
    );
  }

  Future<LandPropertyData> save(LandPropertyData data) async {
    final now = DateTime.now();
    final normalizedContractId = data.contractId.trim();

    if (normalizedContractId.isEmpty) {
      throw Exception('contractId é obrigatório para salvar o imóvel.');
    }

    final propertyId = data.id?.trim();
    if (propertyId == null || propertyId.isEmpty) {
      final ref = _collection(normalizedContractId).doc();

      final saved = data.copyWith(
        id: ref.id,
        contractId: normalizedContractId,
        createdAt: data.createdAt ?? now,
        updatedAt: now,
      );

      await ref.set(saved.toMap());
      return saved;
    }

    final saved = data.copyWith(
      id: propertyId,
      contractId: normalizedContractId,
      createdAt: data.createdAt ?? now,
      updatedAt: now,
    );

    await _doc(
      contractId: normalizedContractId,
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
    final normalizedPropertyId = propertyId.trim();
    if (normalizedPropertyId.isEmpty) return;

    await _doc(
      contractId: contractId,
      propertyId: normalizedPropertyId,
    ).delete();
  }
}