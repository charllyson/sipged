// lib/_blocs/system/tenant/tenant_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'tenant_data.dart';

class TenantItemsResult {
  final List<TenantItemData> units;
  final List<TenantItemData> roads;
  final List<TenantItemData> regions;
  final List<TenantItemData> fundingSources;
  final List<TenantItemData> programs;
  final List<TenantItemData> expenseNatures;
  final List<TenantItemData> companyBodies;

  const TenantItemsResult({
    required this.units,
    required this.roads,
    required this.regions,
    required this.fundingSources,
    required this.programs,
    required this.expenseNatures,
    required this.companyBodies,
  });
}

class TenantRepository {
  /// Tenant fixo temporário para testes.
  static const String testTenantId = 'SZQmefRUqdtLB14ahcuh';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  final String tenantId;

  TenantRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    String? tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance,
        tenantId = (tenantId == null || tenantId.trim().isEmpty)
            ? testTenantId
            : tenantId.trim();

  String get companyDocId => tenantId;

  String? get _currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    return _firestore.collection(TenantData.collectionName).doc(tenantId);
  }

  String get _tenantPath => 'tenants/$tenantId';

  String get _partnersPath => '$_tenantPath/partners';

  String get _unitsPath => '$_tenantPath/administrative/catalog/units';

  String get _regionsPath => '$_tenantPath/administrative/catalog/regions';

  String get _roadsPath => '$_tenantPath/assets/roads/acronym';

  String get _fundingSourcesPath {
    return '$_tenantPath/financial/catalog/funding_sources';
  }

  String get _programsPath {
    return '$_tenantPath/financial/catalog/programs';
  }

  String get _expenseNaturesPath {
    return '$_tenantPath/financial/catalog/expense_natures';
  }

  CollectionReference<Map<String, dynamic>> _collectionByPath(String path) {
    return _firestore.collection(path);
  }

  CollectionReference<Map<String, dynamic>> get _partnersRef {
    return _collectionByPath(_partnersPath);
  }

  CollectionReference<Map<String, dynamic>> get _unitsRef {
    return _collectionByPath(_unitsPath);
  }

  CollectionReference<Map<String, dynamic>> get _regionsRef {
    return _collectionByPath(_regionsPath);
  }

  CollectionReference<Map<String, dynamic>> get _roadsRef {
    return _collectionByPath(_roadsPath);
  }

  CollectionReference<Map<String, dynamic>> get _fundingSourcesRef {
    return _collectionByPath(_fundingSourcesPath);
  }

  CollectionReference<Map<String, dynamic>> get _programsRef {
    return _collectionByPath(_programsPath);
  }

  CollectionReference<Map<String, dynamic>> get _expenseNaturesRef {
    return _collectionByPath(_expenseNaturesPath);
  }

  CollectionReference<Map<String, dynamic>> _itemsRef(String key) {
    switch (key) {
      case 'units':
        return _unitsRef;

      case 'roads':
      case 'acronym':
        return _roadsRef;

      case 'regions':
        return _regionsRef;

      case 'funding_sources':
        return _fundingSourcesRef;

      case 'programs':
        return _programsRef;

      case 'expense_natures':
        return _expenseNaturesRef;

      case 'partners':
      case 'company_bodies':
      case 'companiesBodies':
        return _partnersRef;

      default:
        return _tenantRef.collection(key);
    }
  }

  Query<Map<String, dynamic>> _itemsQuery(String key) {
    return _itemsRef(key).orderBy('label');
  }

  Future<TenantData?> loadCompanyProfile() async {
    final snap = await _tenantRef.get();

    if (!snap.exists || snap.data() == null) {
      return null;
    }

    return TenantData.fromDoc(snap);
  }

  Future<TenantData?> loadTenantProfile() {
    return loadCompanyProfile();
  }

  Future<TenantItemsResult> loadTenantItems() async {
    final result = await Future.wait<List<TenantItemData>>([
      _loadItems('units'),
      _loadItems('roads'),
      _loadItems('regions'),
      _loadItems('funding_sources'),
      _loadItems('programs'),
      _loadItems('expense_natures'),
      _loadItems('partners'),
    ]);

    return TenantItemsResult(
      units: result[0],
      roads: result[1],
      regions: result[2],
      fundingSources: result[3],
      programs: result[4],
      expenseNatures: result[5],
      companyBodies: result[6],
    );
  }

  Future<List<TenantItemData>> _loadItems(String key) async {
    final snap = await _itemsQuery(key).get();

    return snap.docs
        .map(
          (doc) => TenantItemData.fromDoc(
        doc,
        forcedTenantId: tenantId,
      ),
    )
        .toList();
  }

  Future<Map<String, String>?> uploadCompanyLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final safeFileName = fileName.trim().isEmpty
        ? 'logo_${DateTime.now().millisecondsSinceEpoch}.png'
        : fileName.trim();

    final path = 'tenants/$tenantId/company/logo/$safeFileName';
    final ref = _storage.ref(path);

    final metadata = SettableMetadata(
      contentType: contentType ?? 'image/png',
      customMetadata: {
        'tenantId': tenantId,
        'companyId': tenantId,
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
      // Ignora arquivo inexistente.
    }
  }

  Future<TenantData> saveCompanyProfile({
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

    if (trimmedLabel.isEmpty) {
      throw ArgumentError('O nome da empresa não pode ser vazio.');
    }

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

    final exists = (await _tenantRef.get()).exists;

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'id': tenantId,
      'label': trimmedLabel,
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

    data.removeWhere((_, value) => value == null);

    await _tenantRef.set(data, SetOptions(merge: true));

    final snap = await _tenantRef.get();

    return TenantData.fromDoc(snap);
  }

  Future<TenantData> saveTenantProfile({
    required String label,
    required String fantasyName,
    String? cnpj,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
    bool removeLogo = false,
    String? oldLogoPath,
  }) {
    return saveCompanyProfile(
      label: label,
      fantasyName: fantasyName,
      cnpj: cnpj,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      logoContentType: logoContentType,
      removeLogo: removeLogo,
      oldLogoPath: oldLogoPath,
    );
  }

  Future<TenantData> updateCompanyName(
      String newLabel, {
        String? fantasyName,
      }) async {
    final cleanLabel = newLabel.trim();

    if (cleanLabel.isEmpty) {
      throw ArgumentError('O nome da empresa não pode ser vazio.');
    }

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'id': tenantId,
      'label': cleanLabel,
      'companyName': cleanLabel,
      if (fantasyName != null) 'fantasyName': fantasyName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    data.removeWhere((_, value) => value == null);

    await _tenantRef.set(data, SetOptions(merge: true));

    final snap = await _tenantRef.get();

    return TenantData.fromDoc(snap);
  }

  Future<TenantData> updateTenantName(
      String newLabel, {
        String? fantasyName,
      }) {
    return updateCompanyName(
      newLabel,
      fantasyName: fantasyName,
    );
  }

  Future<TenantData> updateCompanyLogo({
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

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'logoUrl': upload?['logoUrl'],
      'logoPath': upload?['logoPath'],
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    data.removeWhere((_, value) => value == null);

    await _tenantRef.set(data, SetOptions(merge: true));

    final snap = await _tenantRef.get();

    return TenantData.fromDoc(snap);
  }

  Future<TenantData> updateTenantLogo({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
    String? oldLogoPath,
  }) {
    return updateCompanyLogo(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      oldLogoPath: oldLogoPath,
    );
  }

  Future<void> deleteCompanyProfile() async {
    final snap = await _tenantRef.get();
    final data = snap.data();
    final oldLogoPath = data?['logoPath']?.toString();

    await deleteFileByPath(oldLogoPath);

    await _tenantRef.set(
      {
        'companyName': FieldValue.delete(),
        'fantasyName': FieldValue.delete(),
        'cnpj': FieldValue.delete(),
        'logoUrl': FieldValue.delete(),
        'logoPath': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserId,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteTenantProfile() {
    return deleteCompanyProfile();
  }

  Future<TenantItemData> _createItem(
      String key,
      String label, {
        Map<String, dynamic> extra = const <String, dynamic>{},
      }) async {
    final cleanLabel = label.trim();

    if (cleanLabel.isEmpty) {
      throw ArgumentError('O nome não pode ser vazio.');
    }

    final ref = _itemsRef(key).doc();
    final id = ref.id;

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'parentId': tenantId,
      'id': id,
      'label': cleanLabel,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _currentUserId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
      ...extra,
    };

    data.removeWhere((_, value) => value == null);

    await ref.set(data);

    final snap = await ref.get();

    return TenantItemData.fromDoc(
      snap,
      forcedTenantId: tenantId,
    );
  }

  Future<TenantItemData> _updateItemName(
      String key,
      String id,
      String label, {
        Map<String, dynamic> extra = const <String, dynamic>{},
      }) async {
    final cleanId = id.trim();
    final cleanLabel = label.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('ID inválido.');
    }

    if (cleanLabel.isEmpty) {
      throw ArgumentError('O nome não pode ser vazio.');
    }

    final ref = _itemsRef(key).doc(cleanId);

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'parentId': tenantId,
      'label': cleanLabel,
      ...extra,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    data.removeWhere((_, value) => value == null);

    await ref.set(data, SetOptions(merge: true));

    final snap = await ref.get();

    return TenantItemData.fromDoc(
      snap,
      forcedTenantId: tenantId,
    );
  }

  Future<TenantItemData> _updateItemExtra(
      String key,
      String id,
      Map<String, dynamic> extra,
      ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('ID inválido.');
    }

    final ref = _itemsRef(key).doc(cleanId);

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'parentId': tenantId,
      ...extra,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId,
    };

    data.removeWhere((_, value) => value == null);

    await ref.set(
      data,
      SetOptions(merge: true),
    );

    final snap = await ref.get();

    return TenantItemData.fromDoc(
      snap,
      forcedTenantId: tenantId,
    );
  }

  Future<void> _deleteItem(String key, String id) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw ArgumentError('ID inválido.');
    }

    await _itemsRef(key).doc(cleanId).delete();
  }

  Future<TenantItemData> createUnit(String label) {
    return _createItem(
      'units',
      label,
      extra: {
        'unitName': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateUnitName(String id, String label) {
    return _updateItemName(
      'units',
      id,
      label,
      extra: {
        'unitName': label.trim(),
      },
    );
  }

  Future<void> deleteUnit(String id) {
    return _deleteItem('units', id);
  }

  Future<TenantItemData> createRoad(String label) {
    return _createItem(
      'roads',
      label,
      extra: {
        'name': label.trim(),
        'acronym': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateRoadName(String id, String label) {
    return _updateItemName(
      'roads',
      id,
      label,
      extra: {
        'name': label.trim(),
        'acronym': label.trim(),
      },
    );
  }

  Future<void> deleteRoad(String id) {
    return _deleteItem('roads', id);
  }

  Future<TenantItemData> createRegion(
      String label, {
        List<String> municipios = const <String>[],
      }) {
    final cleanMunicipios = municipios
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _createItem(
      'regions',
      label,
      extra: {
        'regionName': label.trim(),
        'municipios': cleanMunicipios,
      },
    );
  }

  Future<TenantItemData> updateRegionName(String id, String label) {
    return _updateItemName(
      'regions',
      id,
      label,
      extra: {
        'regionName': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateRegionMunicipios(
      String id,
      List<String> municipios,
      ) {
    final cleanMunicipios = municipios
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _updateItemExtra(
      'regions',
      id,
      {
        'municipios': cleanMunicipios,
      },
    );
  }

  Future<void> deleteRegion(String id) {
    return _deleteItem('regions', id);
  }

  Future<TenantItemData> createFundingSource(String label) {
    return _createItem(
      'funding_sources',
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateFundingSourceName(String id, String label) {
    return _updateItemName(
      'funding_sources',
      id,
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<void> deleteFundingSource(String id) {
    return _deleteItem('funding_sources', id);
  }

  Future<TenantItemData> createProgram(String label) {
    return _createItem(
      'programs',
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateProgramName(String id, String label) {
    return _updateItemName(
      'programs',
      id,
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<void> deleteProgram(String id) {
    return _deleteItem('programs', id);
  }

  Future<TenantItemData> createExpenseNature(String label) {
    return _createItem(
      'expense_natures',
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateExpenseNatureName(String id, String label) {
    return _updateItemName(
      'expense_natures',
      id,
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<void> deleteExpenseNature(String id) {
    return _deleteItem('expense_natures', id);
  }

  Future<TenantItemData> createCompanyBody(
      String label, {
        String? cnpj,
      }) {
    final cleanCnpj = cnpj?.trim();

    return _createItem(
      'partners',
      label,
      extra: {
        'partnerId': null,
        'name': label.trim(),
        if (cleanCnpj != null && cleanCnpj.isNotEmpty) 'cnpj': cleanCnpj,
      },
    );
  }

  Future<TenantItemData> updateCompanyBodyName(String id, String label) {
    return _updateItemName(
      'partners',
      id,
      label,
      extra: {
        'name': label.trim(),
      },
    );
  }

  Future<TenantItemData> updateCompanyBodyData(
      String id, {
        String? label,
        String? cnpj,
      }) {
    final data = <String, dynamic>{};

    if (label != null && label.trim().isNotEmpty) {
      data['label'] = label.trim();
      data['name'] = label.trim();
    }

    if (cnpj != null && cnpj.trim().isNotEmpty) {
      data['cnpj'] = cnpj.trim();
    }

    return _updateItemExtra(
      'partners',
      id,
      data,
    );
  }

  Future<void> deleteCompanyBody(String id) {
    return _deleteItem('partners', id);
  }
}