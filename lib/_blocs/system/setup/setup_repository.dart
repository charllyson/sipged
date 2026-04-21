import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'setup_data.dart';

class SetupRepository {
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

  Future<List<SetupData>> loadCompanies() async {
    final snap =
    await _firestore.collection('companies').orderBy('companyName').get();

    return snap.docs.map((d) => SetupData.fromDoc(d)).toList();
  }

  Future<Map<String, String>?> uploadCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final safeFileName = fileName.trim().isEmpty
        ? 'logo_${DateTime.now().millisecondsSinceEpoch}.png'
        : fileName.trim();

    final path = 'companies/$companyId/logo/$safeFileName';
    final ref = _storage.ref(path);

    final metadata = SettableMetadata(
      contentType: contentType ?? 'image/png',
      customMetadata: {
        'companyId': companyId,
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
    String? companyId,
    required String label,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
  }) async {
    final normalizedId = companyId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      return createCompany(
        label,
        cnpj: cnpj,
        logoBytes: logoBytes,
        logoFileName: logoFileName,
        logoContentType: logoContentType,
      );
    }

    final ref = _firestore.collection('companies').doc(normalizedId);
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
        companyId: normalizedId,
        bytes: logoBytes,
        fileName: logoFileName ?? 'logo.png',
        contentType: logoContentType,
      );

      logoUrl = upload?['logoUrl'];
      logoPath = upload?['logoPath'];
    }

    final update = <String, dynamic>{
      'companyName': label.trim(),
      'cnpj': trimmedCnpj,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    if (removeLogo) {
      update['logoUrl'] = FieldValue.delete();
      update['logoPath'] = FieldValue.delete();
    }

    if (logoBytes != null) {
      update['logoUrl'] = logoUrl;
      update['logoPath'] = logoPath;
    }

    await ref.set(update, SetOptions(merge: true));

    final snap = await ref.get();
    return SetupData.fromDoc(snap);
  }

  Future<SetupData> createCompany(
      String label, {
        String? cnpj,
        Uint8List? logoBytes,
        String? logoFileName,
        String? logoContentType,
      }) async {
    final col = _firestore.collection('companies');
    final ref = col.doc();
    final id = ref.id;

    final trimmedCnpj = cnpj?.trim();

    String? logoUrl;
    String? logoPath;

    if (logoBytes != null) {
      final upload = await uploadCompanyLogo(
        companyId: id,
        bytes: logoBytes,
        fileName: logoFileName ?? 'logo.png',
        contentType: logoContentType,
      );
      logoUrl = upload?['logoUrl'];
      logoPath = upload?['logoPath'];
    }

    final data = <String, dynamic>{
      'companyId': id,
      'companyName': label.trim(),
      if (trimmedCnpj != null && trimmedCnpj.isNotEmpty) 'cnpj': trimmedCnpj,
      if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
      if (logoPath != null && logoPath.isNotEmpty) 'logoPath': logoPath,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
    };

    await ref.set(data);

    final snap = await ref.get();
    return SetupData.fromDoc(snap);
  }

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

  Future<SetupData> updateCompanyLogo({
    required String companyId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String? oldLogoPath,
  }) async {
    final ref = _firestore.collection('companies').doc(companyId);

    if (oldLogoPath != null && oldLogoPath.trim().isNotEmpty) {
      await deleteFileByPath(oldLogoPath);
    }

    final upload = await uploadCompanyLogo(
      companyId: companyId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );

    await ref.update({
      'logoUrl': upload?['logoUrl'],
      'logoPath': upload?['logoPath'],
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap);
  }

  Future<void> deleteCompany(String companyId) async {
    final ref = _firestore.collection('companies').doc(companyId);

    final snap = await ref.get();
    final data = snap.data();
    final oldLogoPath = data?['logoPath']?.toString();

    await deleteFileByPath(oldLogoPath);
    await ref.delete();
  }

  Future<List<SetupData>> loadCompanyBodies(String companyId) async {
    final col = _firestore.collection('companies/$companyId/companiesBodies');
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
    final col = _firestore.collection('companies/$companyId/companiesBodies');
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

  Future<SetupData> updateCompanyBodyName(
      String companyId,
      String bodyId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/companiesBodies/$bodyId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteCompanyBody(String companyId, String bodyId) async {
    final ref = _firestore.doc('companies/$companyId/companiesBodies/$bodyId');
    await ref.delete();
  }

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

  Future<SetupData> updateUnitName(
      String companyId,
      String unitId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/units/$unitId');

    await ref.update({
      'unitName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteUnit(String companyId, String unitId) async {
    final ref = _firestore.doc('companies/$companyId/units/$unitId');
    await ref.delete();
  }

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

  Future<SetupData> updateRoadName(
      String companyId,
      String roadId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/roads/$roadId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteRoad(String companyId, String roadId) async {
    final ref = _firestore.doc('companies/$companyId/roads/$roadId');
    await ref.delete();
  }

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

  Future<SetupData> updateRegionMunicipios(
      String companyId,
      String regionId,
      List<String> municipios,
      ) async {
    final ref = _firestore.doc('companies/$companyId/regions/$regionId');

    final muniClean =
    municipios.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    await ref.update({
      'municipios': muniClean,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<SetupData> updateRegionName(
      String companyId,
      String regionId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/regions/$regionId');

    await ref.update({
      'regionName': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteRegion(String companyId, String regionId) async {
    final ref = _firestore.doc('companies/$companyId/regions/$regionId');
    await ref.delete();
  }

  Future<List<SetupData>> loadFundingSources(String companyId) async {
    final col = _firestore.collection('companies/$companyId/funding_sources');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createFundingSource(String companyId, String label) async {
    final col = _firestore.collection('companies/$companyId/funding_sources');
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

  Future<SetupData> updateFundingSourceName(
      String companyId,
      String sourceId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/funding_sources/$sourceId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteFundingSource(String companyId, String sourceId) async {
    final ref = _firestore.doc('companies/$companyId/funding_sources/$sourceId');
    await ref.delete();
  }

  Future<List<SetupData>> loadPrograms(String companyId) async {
    final col = _firestore.collection('companies/$companyId/programs');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createProgram(String companyId, String label) async {
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

  Future<SetupData> updateProgramName(
      String companyId,
      String programId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/programs/$programId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteProgram(String companyId, String programId) async {
    final ref = _firestore.doc('companies/$companyId/programs/$programId');
    await ref.delete();
  }

  Future<List<SetupData>> loadExpenseNatures(String companyId) async {
    final col = _firestore.collection('companies/$companyId/expense_natures');
    final snap = await col.orderBy('name').get();

    return snap.docs
        .map((d) => SetupData.fromDoc(d, forcedParentId: companyId))
        .toList();
  }

  Future<SetupData> createExpenseNature(String companyId, String label) async {
    final col = _firestore.collection('companies/$companyId/expense_natures');
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

  Future<SetupData> updateExpenseNatureName(
      String companyId,
      String natureId,
      String newLabel,
      ) async {
    final ref = _firestore.doc('companies/$companyId/expense_natures/$natureId');

    await ref.update({
      'name': newLabel.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    });

    final snap = await ref.get();
    return SetupData.fromDoc(snap, forcedParentId: companyId);
  }

  Future<void> deleteExpenseNature(String companyId, String natureId) async {
    final ref = _firestore.doc('companies/$companyId/expense_natures/$natureId');
    await ref.delete();
  }
}