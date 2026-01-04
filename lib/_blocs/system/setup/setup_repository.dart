import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'setup_data.dart';

class SetupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // =========================
  //      COMPANIES (órgãos contratantes)
  // =========================

  Future<List<SetupData>> loadCompanies() async {
    final snap = await _firestore
        .collection('companies')
        .orderBy('companyName')
        .get();

    return snap.docs.map((d) => SetupData.fromDoc(d)).toList();
  }

  // AGORA ACEITA cnpj OPCIONAL
  Future<SetupData> createCompany(String label, {String? cnpj}) async {
    final col = _firestore.collection('companies');
    final ref = col.doc(); // gera id
    final id = ref.id;

    final trimmedCnpj = cnpj?.trim();

    final data = <String, dynamic>{
      'companyId': id,
      'companyName': label.trim(),
      if (trimmedCnpj != null && trimmedCnpj.isNotEmpty) 'cnpj': trimmedCnpj,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    // A leitura real (com createdAt convertido) virá depois.
    return SetupData.fromMap(id: id, map: data);
  }

  /// 🔥 EDITAR nome da company
  Future<SetupData> updateCompanyName(
      String companyId,
      String newLabel,
      ) async {
    final ref = _firestore.collection('companies').doc(companyId);

    await ref.update({
      'companyName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap);
  }

  /// 🔥 DELETAR company
  Future<void> deleteCompany(String companyId) async {
    final ref = _firestore.collection('companies').doc(companyId);
    await ref.delete();
  }

  // =========================
  //    COMPANIES BODIES (empresas contratadas / licitantes)
  // =========================

  Future<List<SetupData>> loadCompanyBodies(String companyId) async {
    final col =
    _firestore.collection('companies/$companyId/companiesBodies');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createCompanyBody(
      String companyId,
      String label, {
        String? cnpj,
      }) async {
    final col =
    _firestore.collection('companies/$companyId/companiesBodies');
    final ref = col.doc();
    final id = ref.id;

    final trimmedCnpj = cnpj?.trim();

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      if (trimmedCnpj != null && trimmedCnpj.isNotEmpty) 'cnpj': trimmedCnpj,
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR nome da empresa contratada / licitante
  Future<SetupData> updateCompanyBodyName(
      String companyId,
      String bodyId,
      String newLabel,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/companiesBodies/$bodyId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR empresa contratada / licitante
  Future<void> deleteCompanyBody(
      String companyId,
      String bodyId,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/companiesBodies/$bodyId');
    await ref.delete();
  }

  // =========================
  //         UNITS
  // =========================

  Future<List<SetupData>> loadUnits(String companyId) async {
    final col = _firestore.collection('companies/$companyId/units');
    final snap = await col.orderBy('unitName').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createUnit(String companyId, String label) async {
    final col = _firestore.collection('companies/$companyId/units');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'unitId': id,
      'unitName': label.trim(),
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR nome da unidade
  Future<SetupData> updateUnitName(
      String companyId,
      String unitId,
      String newLabel,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/units/$unitId');

    await ref.update({
      'unitName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR unidade
  Future<void> deleteUnit(
      String companyId,
      String unitId,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/units/$unitId');
    await ref.delete();
  }

  // =========================
  //         ROADS
  // =========================

  Future<List<SetupData>> loadRoads(String companyId) async {
    final col = _firestore.collection('companies/$companyId/roads');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createRoad(String companyId, String label) async {
    final col = _firestore.collection('companies/$companyId/roads');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR nome da rodovia
  Future<SetupData> updateRoadName(
      String companyId,
      String roadId,
      String newLabel,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/roads/$roadId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR rodovia
  Future<void> deleteRoad(
      String companyId,
      String roadId,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/roads/$roadId');
    await ref.delete();
  }

  // =========================
  //         REGIONS
  // =========================

  Future<List<SetupData>> loadRegions(String companyId) async {
    final col = _firestore.collection('companies/$companyId/regions');
    final snap = await col.orderBy('regionName').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createRegion(
      String companyId,
      String label, {
        List<String>? municipios,
      }) async {
    final col = _firestore.collection('companies/$companyId/regions');
    final ref = col.doc();
    final id = ref.id;

    final muniClean = municipios
        ?.map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList() ??
        const <String>[];

    final data = <String, dynamic>{
      'regionId': id,
      'regionName': label.trim(),
      'companyId': companyId,
      if (muniClean.isNotEmpty) 'municipios': muniClean,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// Atualiza apenas a lista de municípios de uma região existente
  Future<SetupData> updateRegionMunicipios(
      String companyId,
      String regionId,
      List<String> municipios,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/regions/$regionId');

    final muniClean = municipios
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await ref.update({
      'municipios': muniClean,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();

    return SetupData.fromDoc(
      snap,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR nome da região
  Future<SetupData> updateRegionName(
      String companyId,
      String regionId,
      String newLabel,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/regions/$regionId');

    await ref.update({
      'regionName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR região
  Future<void> deleteRegion(
      String companyId,
      String regionId,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/regions/$regionId');
    await ref.delete();
  }

  // =========================
  //    FUNDING SOURCES
  // =========================

  Future<List<SetupData>> loadFundingSources(String companyId) async {
    final col =
    _firestore.collection('companies/$companyId/funding_sources');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createFundingSource(
      String companyId,
      String label,
      ) async {
    final col =
    _firestore.collection('companies/$companyId/funding_sources');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR fonte de recurso
  Future<SetupData> updateFundingSourceName(
      String companyId,
      String sourceId,
      String newLabel,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/funding_sources/$sourceId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR fonte de recurso
  Future<void> deleteFundingSource(
      String companyId,
      String sourceId,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/funding_sources/$sourceId');
    await ref.delete();
  }

  // =========================
  //        PROGRAMS
  // =========================

  Future<List<SetupData>> loadPrograms(String companyId) async {
    final col = _firestore.collection('companies/$companyId/programs');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createProgram(
      String companyId,
      String label,
      ) async {
    final col = _firestore.collection('companies/$companyId/programs');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR programa
  Future<SetupData> updateProgramName(
      String companyId,
      String programId,
      String newLabel,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/programs/$programId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR programa
  Future<void> deleteProgram(
      String companyId,
      String programId,
      ) async {
    final ref =
    _firestore.doc('companies/$companyId/programs/$programId');
    await ref.delete();
  }

  // =========================
  //    EXPENSE NATURES
  // =========================

  Future<List<SetupData>> loadExpenseNatures(
      String companyId,
      ) async {
    final col =
    _firestore.collection('companies/$companyId/expense_natures');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createExpenseNature(
      String companyId,
      String label,
      ) async {
    final col =
    _firestore.collection('companies/$companyId/expense_natures');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyId,
    );
  }

  /// 🔥 EDITAR natureza de despesa
  Future<SetupData> updateExpenseNatureName(
      String companyId,
      String natureId,
      String newLabel,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/expense_natures/$natureId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  /// 🔥 DELETAR natureza de despesa
  Future<void> deleteExpenseNature(
      String companyId,
      String natureId,
      ) async {
    final ref = _firestore
        .doc('companies/$companyId/expense_natures/$natureId');
    await ref.delete();
  }
}
