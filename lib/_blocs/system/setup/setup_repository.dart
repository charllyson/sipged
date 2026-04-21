import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'setup_data.dart';

class SetupRepository {
  static const String systemCollection = 'system';
  static const String companyDocId = 'company';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  SetupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _companyRef =>
      _firestore.collection(systemCollection).doc(companyDocId);

  CollectionReference<Map<String, dynamic>> _childCollection(String name) =>
      _companyRef.collection(name);

  Future<SetupData?> loadCompanyProfile() async {
    final snap = await _companyRef.get();
    if (!snap.exists || snap.data() == null) return null;
    return SetupData.fromDoc(snap);
  }

  Future<Map<String, String>?> uploadCompanyLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final safeFileName = fileName.trim().isEmpty
        ? 'logo_${DateTime.now().millisecondsSinceEpoch}.png'
        : fileName.trim();

    final path = 'system/company/logo/$safeFileName';
    final ref = _storage.ref(path);

    final metadata = SettableMetadata(
      contentType: contentType ?? 'image/png',
      customMetadata: {
        'docId': companyDocId,
        'uploadedBy': _currentUserId ?? '',
      },
    );

    await ref.putData(bytes, metadata);
    final url = await ref.getDownloadURL();

    return {
      'logoUrl': url,
      'logoPath': path,
    };
  }

  Future<void> deleteFileByPath(String? path) async {
    final clean = path?.trim() ?? '';
    if (clean.isEmpty) return;

    try {
      await _storage.ref(clean).delete();
    } catch (_) {
      // ignora se não existir
    }
  }

  Future<SetupData> saveCompanyProfile({
    required String label,
    required String fantasyName,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
  }) async {
    final trimmedLabel = label.trim();
    final trimmedFantasyName = fantasyName.trim();
    final trimmedCnpj = cnpj?.trim();

    String? logoUrl;
    String? logoPath;

    if (removeLogo && oldLogoPath != null && oldLogoPath.trim().isNotEmpty) {
      await deleteFileByPath(oldLogoPath);
    }

    if (logoBytes != null) {
      if (oldLogoPath != null && oldLogoPath.trim().isNotEmpty) {
        await deleteFileByPath(oldLogoPath);
      }

      final upload = await uploadCompanyLogo(
        bytes: logoBytes,
        fileName: logoFileName ?? 'logo.png',
        contentType: logoContentType,
      );

      logoUrl = upload?['logoUrl'];
      logoPath = upload?['logoPath'];
    }

    final exists = (await _companyRef.get()).exists;

    final data = <String, dynamic>{
      'companyId': companyDocId,
      'companyName': trimmedLabel,
      'fantasyName': trimmedFantasyName,
      'cnpj': (trimmedCnpj == null || trimmedCnpj.isEmpty) ? null : trimmedCnpj,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
      if (!exists) 'createdAt': FieldValue.serverTimestamp(),
      if (!exists) 'createdBy': _currentUserId,
    };

    if (removeLogo) {
      data['logoUrl'] = FieldValue.delete();
      data['logoPath'] = FieldValue.delete();
    }

    if (logoBytes != null) {
      data['logoUrl'] = logoUrl;
      data['logoPath'] = logoPath;
    }

    await _companyRef.set(data, SetOptions(merge: true));

    final snap = await _companyRef.get();
    return SetupData.fromDoc(snap);
  }

  Future<SetupData> updateCompanyName(
      String newLabel, {
        String? fantasyName,
      }) async {
    await _companyRef.set({
      'companyId': companyDocId,
      'companyName': newLabel.trim(),
      if (fantasyName != null) 'fantasyName': fantasyName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    }, SetOptions(merge: true));

    final snap = await _companyRef.get();
    return SetupData.fromDoc(snap);
  }

  Future<SetupData> updateCompanyLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String? oldLogoPath,
  }) async {
    if (oldLogoPath != null && oldLogoPath.trim().isNotEmpty) {
      await deleteFileByPath(oldLogoPath);
    }

    final upload = await uploadCompanyLogo(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );

    await _companyRef.set({
      'companyId': companyDocId,
      'logoUrl': upload?['logoUrl'],
      'logoPath': upload?['logoPath'],
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    }, SetOptions(merge: true));

    final snap = await _companyRef.get();
    return SetupData.fromDoc(snap);
  }

  Future<void> deleteCompanyProfile() async {
    final snap = await _companyRef.get();
    final data = snap.data();
    final oldLogoPath = data?['logoPath']?.toString();

    await deleteFileByPath(oldLogoPath);
    await _companyRef.delete();
  }

  Future<List<SetupData>> loadCompanyBodies() async {
    final snap = await _childCollection('companiesBodies').orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createCompanyBody(
      String label, {
        String? cnpj,
      }) async {
    final col = _childCollection('companiesBodies');
    final ref = col.doc();
    final id = ref.id;

    final trimmedCnpj = cnpj?.trim();

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      if (trimmedCnpj != null && trimmedCnpj.isNotEmpty) 'cnpj': trimmedCnpj,
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateCompanyBodyName(
      String bodyId,
      String newLabel,
      ) async {
    final ref = _childCollection('companiesBodies').doc(bodyId);

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteCompanyBody(String bodyId) async {
    await _childCollection('companiesBodies').doc(bodyId).delete();
  }

  Future<List<SetupData>> loadUnits() async {
    final snap = await _childCollection('units').orderBy('unitName').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createUnit(String label) async {
    final col = _childCollection('units');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'unitId': id,
      'unitName': label.trim(),
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateUnitName(
      String unitId,
      String newLabel,
      ) async {
    final ref = _childCollection('units').doc(unitId);

    await ref.update({
      'unitName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteUnit(String unitId) async {
    await _childCollection('units').doc(unitId).delete();
  }

  Future<List<SetupData>> loadRoads() async {
    final snap = await _childCollection('roads').orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createRoad(String label) async {
    final col = _childCollection('roads');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateRoadName(
      String roadId,
      String newLabel,
      ) async {
    final ref = _childCollection('roads').doc(roadId);

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteRoad(String roadId) async {
    await _childCollection('roads').doc(roadId).delete();
  }

  Future<List<SetupData>> loadRegions() async {
    final snap = await _childCollection('regions').orderBy('regionName').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createRegion(
      String label, {
        List<String>? municipios,
      }) async {
    final col = _childCollection('regions');
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
      'companyId': companyDocId,
      if (muniClean.isNotEmpty) 'municipios': muniClean,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateRegionMunicipios(
      String regionId,
      List<String> municipios,
      ) async {
    final ref = _childCollection('regions').doc(regionId);

    final muniClean =
    municipios.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    await ref.update({
      'municipios': muniClean,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<SetupData> updateRegionName(
      String regionId,
      String newLabel,
      ) async {
    final ref = _childCollection('regions').doc(regionId);

    await ref.update({
      'regionName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteRegion(String regionId) async {
    await _childCollection('regions').doc(regionId).delete();
  }

  Future<List<SetupData>> loadFundingSources() async {
    final snap = await _childCollection('funding_sources').orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createFundingSource(String label) async {
    final col = _childCollection('funding_sources');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateFundingSourceName(
      String sourceId,
      String newLabel,
      ) async {
    final ref = _childCollection('funding_sources').doc(sourceId);

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteFundingSource(String sourceId) async {
    await _childCollection('funding_sources').doc(sourceId).delete();
  }

  Future<List<SetupData>> loadPrograms() async {
    final snap = await _childCollection('programs').orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createProgram(String label) async {
    final col = _childCollection('programs');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateProgramName(
      String programId,
      String newLabel,
      ) async {
    final ref = _childCollection('programs').doc(programId);

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteProgram(String programId) async {
    await _childCollection('programs').doc(programId).delete();
  }

  Future<List<SetupData>> loadExpenseNatures() async {
    final snap = await _childCollection('expense_natures').orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyDocId))
        .toList();
  }

  Future<SetupData> createExpenseNature(String label) async {
    final col = _childCollection('expense_natures');
    final ref = col.doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'id': id,
      'name': label.trim(),
      'companyId': companyDocId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    return SetupData.fromMap(
      id: id,
      map: data,
      forcedParentId: companyDocId,
    );
  }

  Future<SetupData> updateExpenseNatureName(
      String natureId,
      String newLabel,
      ) async {
    final ref = _childCollection('expense_natures').doc(natureId);

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyDocId);
  }

  Future<void> deleteExpenseNature(String natureId) async {
    await _childCollection('expense_natures').doc(natureId).delete();
  }
}