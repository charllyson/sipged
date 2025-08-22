import 'dart:async';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sisged/_datas/actives/oaes/active_oaes_data.dart';

class ActiveOaesBloc extends BlocBase {
  ActiveOaesBloc();

  final _ref = FirebaseFirestore.instance.collection('actives_oaes');

  /// Salvar ou atualizar OAE
  Future<void> saveOrUpdateOAE(ActiveOaesData data) async {
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
  Future<List<ActiveOaesData>> getOAEsPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _ref.orderBy('order').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => ActiveOaesData.fromDocument(doc)).toList();
  }

  /// Buscar todos os OAEs (sem paginação, se necessário)
  Future<List<ActiveOaesData>> getAllOAEs() async {
    final snapshot = await _ref.orderBy('order').get();
    return snapshot.docs.map((doc) => ActiveOaesData.fromDocument(doc)).toList();
  }
}
