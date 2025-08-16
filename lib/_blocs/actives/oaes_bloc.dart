import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../_datas/actives/oaes/oaesData.dart';

class OaesBloc extends BlocBase {
  OaesBloc();

  final _ref = FirebaseFirestore.instance.collection('actives_oaes');

  /// Salvar ou atualizar OAE
  Future<void> saveOrUpdateOAE(OaesData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    data.id ??= docRef.id;

    final json = data.toMap()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    final snapshot = await docRef.get();
    final isNewDocument = !snapshot.exists || snapshot.data()?['createdAt'] == null;

    if (isNewDocument) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));
  }

  /// Deletar OAE
  Future<void> deletarOAE(String id) async {
    await _ref.doc(id).delete();
  }

  /// Buscar página de OAEs com paginação
  Future<List<OaesData>> getOAEsPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _ref.orderBy('order').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => OaesData.fromDocument(doc)).toList();
  }

  /// Buscar todos os OAEs (sem paginação, se necessário)
  Future<List<OaesData>> getAllOAEs() async {
    final snapshot = await _ref.orderBy('order').get();
    return snapshot.docs.map((doc) => OaesData.fromDocument(doc)).toList();
  }
}
