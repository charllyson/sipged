import 'package:cloud_firestore/cloud_firestore.dart';
import 'land_assessment_data.dart';

class LandAssessmentRepository {
  LandAssessmentRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String contractId) {
    return _firestore.collection('land').doc(contractId).collection('avaliacao');
  }

  DocumentReference<Map<String, dynamic>> _doc({
    required String contractId,
    required String propertyId,
  }) {
    return _collection(contractId).doc(propertyId);
  }

  Future<LandAssessmentData?> fetchById({
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

    return LandAssessmentData.fromMap(
      map,
      id: doc.id,
      contractId: contractId,
    );
  }

  Future<LandAssessmentData> save(LandAssessmentData data) async {
    final propertyId = data.id?.trim();
    if (propertyId == null || propertyId.isEmpty) {
      throw Exception('propertyId é obrigatório para salvar a avaliação.');
    }

    final now = DateTime.now();

    final normalized = data.copyWith(
      id: propertyId,
      contractId: data.contractId.trim(),
      createdAt: data.createdAt ?? now,
      updatedAt: now,
    );

    await _doc(
      contractId: normalized.contractId,
      propertyId: propertyId,
    ).set(
      normalized.toMap(),
      SetOptions(merge: true),
    );

    return normalized;
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