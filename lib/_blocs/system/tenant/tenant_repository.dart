// lib/_blocs/system/tenant/tenant_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'tenant_data.dart';

class TenantItemsResult {
  final List<String> units;
  final List<String> roads;
  final List<String> regions;
  final List<String> fundingSources;
  final List<String> programs;
  final List<String> expenseNatures;
  final List<String> companyBodies;

  const TenantItemsResult({
    required this.units,
    required this.roads,
    required this.regions,
    required this.fundingSources,
    required this.programs,
    required this.expenseNatures,
    required this.companyBodies,
  });

  factory TenantItemsResult.empty() {
    return const TenantItemsResult(
      units: <String>[],
      roads: <String>[],
      regions: <String>[],
      fundingSources: <String>[],
      programs: <String>[],
      expenseNatures: <String>[],
      companyBodies: <String>[],
    );
  }
}

class TenantRepository {
  static String? _activeTenantId;

  TenantRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    String? tenantId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance {
    final cleanTenantId = tenantId?.trim();

    if (cleanTenantId != null && cleanTenantId.isNotEmpty) {
      _activeTenantId = cleanTenantId;
    }
  }

  static const String collectionName = 'tenants';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String get tenantId {
    final id = _activeTenantId?.trim();

    if (id == null || id.isEmpty) {
      throw StateError(
        'Nenhuma empresa selecionada. Selecione uma empresa antes de carregar os dados.',
      );
    }

    return id;
  }

  String? get activeTenantId {
    final id = _activeTenantId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool get hasActiveTenant {
    final id = _activeTenantId?.trim();
    return id != null && id.isNotEmpty;
  }

  String get companyDocId => tenantId;

  String? get _currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _tenantsRef {
    return _firestore.collection(collectionName);
  }

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection('users');
  }

  DocumentReference<Map<String, dynamic>> get _tenantRef {
    return _tenantsRef.doc(tenantId);
  }

  DocumentReference<Map<String, dynamic>> _tenantRefById(String tenantId) {
    return _tenantsRef.doc(tenantId.trim());
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _usersRef.doc(uid.trim());
  }

  String get _tenantPath => '$collectionName/$tenantId';

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

  void setActiveTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não pode ser vazio.');
    }

    _activeTenantId = cleanTenantId;
  }

  void clearActiveTenantId() {
    _activeTenantId = null;
  }

  Future<void> clearPersistedTenantForCurrentUser() async {
    final uid = _currentUserId?.trim();

    if (uid == null || uid.isEmpty) return;

    await _userRef(uid).set(
      {
        'currentTenantId': FieldValue.delete(),
        'selectedTenantId': FieldValue.delete(),
        'activeTenantId': FieldValue.delete(),
        'lastTenantId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
      case 'companyBodies':
        return _partnersRef;

      default:
        return _tenantRef.collection(key);
    }
  }

  Future<Map<String, dynamic>?> _loadCurrentUserRaw() async {
    final uid = _currentUserId?.trim();

    if (uid == null || uid.isEmpty) return null;

    final snap = await _userRef(uid).get();

    return snap.data();
  }

  bool _isSuperUserMap(Map<String, dynamic>? data) {
    if (data == null) return false;

    bool isSuper(dynamic value) {
      final raw = value?.toString().trim();

      if (raw == null || raw.isEmpty) return false;

      final normalized = raw
          .toUpperCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_')
          .replaceAll('__', '_')
          .trim();

      const superValues = <String>{
        'ADMINISTRADOR',
        'ADMINISTRATOR',
        'ADMIN',
        'ADM',
        'DESENVOLVEDOR',
        'DEVELOPER',
        'DEV',
        'SUPERADMIN',
        'SUPER_ADMIN',
        'SUPERUSER',
        'SUPER_USER',
        'ROOT',
        'OWNER',
        'ADMINISTRADOR_GERAL',
        'ADMIN_GERAL',
      };

      return superValues.contains(normalized);
    }

    return isSuper(data['baseRole']) ||
        isSuper(data['baseProfile']) ||
        isSuper(data['globalRole']) ||
        isSuper(data['role']);
  }

  String? _cleanNullableString(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }

  List<String> _listFromDynamic(dynamic value) {
    if (value == null) return const <String>[];

    if (value is List) {
      return _cleanStringList(
        value
            .map((item) => item?.toString() ?? '')
            .where((item) => item.trim().isNotEmpty),
      );
    }

    if (value is String) {
      return _cleanStringList(
        value
            .split(RegExp(r'[\n,;]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    return const <String>[];
  }

  List<String> _mapKeysFromDynamic(dynamic value) {
    if (value is! Map) return const <String>[];

    final keys = <String>[];

    for (final entry in value.entries) {
      final key = entry.key?.toString().trim() ?? '';

      if (key.isEmpty) continue;

      final rawValue = entry.value;

      if (rawValue is Map) {
        final enabled = rawValue['enabled'];
        final active = rawValue['active'];
        final allowed = rawValue['allowed'];
        final disabled = rawValue['disabled'];

        if (enabled == false ||
            active == false ||
            allowed == false ||
            disabled == true) {
          continue;
        }
      }

      keys.add(key);
    }

    return _cleanStringList(keys);
  }

  List<String> _tenantIdsFromCurrentUserMap(Map<String, dynamic>? data) {
    if (data == null) return const <String>[];

    final ids = <String>[
      ..._listFromDynamic(data['tenantIds']),
      ..._listFromDynamic(data['allowedTenantIds']),
      ..._listFromDynamic(data['accessibleTenantIds']),
      ..._listFromDynamic(data['companyIds']),
      ..._listFromDynamic(data['allowedCompanyIds']),
      ..._listFromDynamic(data['accessibleCompanyIds']),
      ..._mapKeysFromDynamic(data['tenantAccess']),
      ..._mapKeysFromDynamic(data['tenantsAccess']),
      ..._mapKeysFromDynamic(data['companyAccess']),
      ..._mapKeysFromDynamic(data['companiesAccess']),
      ..._mapKeysFromDynamic(data['tenantRoles']),
      ..._mapKeysFromDynamic(data['tenantModuleOverrides']),
    ];

    return _cleanStringList(ids);
  }

  Future<List<String>> loadAllowedTenantIdsForCurrentUser() async {
    final data = await _loadCurrentUserRaw();

    if (_isSuperUserMap(data)) {
      final snap = await _tenantsRef.get();

      return _cleanStringList(snap.docs.map((doc) => doc.id));
    }

    return _tenantIdsFromCurrentUserMap(data);
  }

  Future<bool> currentUserCanAccessTenant(String tenantId) async {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) return false;

    final data = await _loadCurrentUserRaw();

    if (_isSuperUserMap(data)) return true;

    final allowed = _tenantIdsFromCurrentUserMap(data);

    return allowed.contains(cleanTenantId);
  }

  Future<String?> loadPreferredTenantIdForCurrentUser() async {
    final data = await _loadCurrentUserRaw();

    final currentTenantId = _cleanNullableString(
      data?['currentTenantId'] ??
          data?['selectedTenantId'] ??
          data?['activeTenantId'] ??
          data?['lastTenantId'],
    );

    if (currentTenantId == null) return null;

    if (await currentUserCanAccessTenant(currentTenantId)) {
      return currentTenantId;
    }

    return null;
  }

  Future<void> persistActiveTenantForCurrentUser(String tenantId) async {
    final uid = _currentUserId?.trim();
    final cleanTenantId = tenantId.trim();

    if (uid == null || uid.isEmpty || cleanTenantId.isEmpty) return;

    final canAccess = await currentUserCanAccessTenant(cleanTenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para acessar esta empresa.');
    }

    await _userRef(uid).set(
      {
        'currentTenantId': cleanTenantId,
        'selectedTenantId': cleanTenantId,
        'activeTenantId': cleanTenantId,
        'lastTenantId': cleanTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  List<String> _cleanStringList(Iterable<String> values) {
    final list = values
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  List<String> _mergeStringLists(
      List<String> first,
      List<String> second,
      ) {
    return _cleanStringList([
      ...first,
      ...second,
    ]);
  }

  List<String> _replaceOrAppendString(
      List<String> list,
      String value,
      ) {
    final clean = value.trim();

    if (clean.isEmpty) return _cleanStringList(list);

    final updated = [...list];

    final index = updated.indexWhere(
          (e) => e.trim().toLowerCase() == clean.toLowerCase(),
    );

    if (index < 0) {
      updated.add(clean);
    } else {
      updated[index] = clean;
    }

    return _cleanStringList(updated);
  }

  List<String> _renameStringItem({
    required List<String> list,
    required String oldValue,
    required String newValue,
  }) {
    final oldClean = oldValue.trim();
    final newClean = newValue.trim();

    if (oldClean.isEmpty) {
      throw ArgumentError('Item original inválido.');
    }

    if (newClean.isEmpty) {
      throw ArgumentError('O novo nome não pode ser vazio.');
    }

    final updated = [...list];

    final index = updated.indexWhere(
          (e) => e.trim().toLowerCase() == oldClean.toLowerCase(),
    );

    if (index < 0) {
      updated.add(newClean);
    } else {
      updated[index] = newClean;
    }

    return _cleanStringList(updated);
  }

  List<String> _deleteStringItem({
    required List<String> list,
    required String value,
  }) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('Item inválido.');
    }

    return _cleanStringList(
      list.where((e) => e.trim().toLowerCase() != clean.toLowerCase()),
    );
  }

  String _labelFromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final value = data['label'] ??
        data['name'] ??
        data['unitName'] ??
        data['roadName'] ??
        data['regionName'] ??
        data['companyName'] ??
        data['fantasyName'] ??
        data['acronym'] ??
        data['sigla'] ??
        id;

    return value.toString().trim();
  }

  Future<List<String>> _loadItemsFromSubcollection(String key) async {
    final snap = await _itemsRef(key).get();

    final values = snap.docs
        .map(
          (doc) => _labelFromMap(
        id: doc.id,
        data: doc.data(),
      ),
    )
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return _cleanStringList(values);
  }

  Future<void> _updateTenantArrayField({
    required String field,
    required List<String> values,
  }) async {
    await _tenantRef.set(
      {
        field: _cleanStringList(values),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _currentUserId,
      },
      SetOptions(merge: true),
    );
  }

  Future<List<TenantData>> loadAvailableTenants() async {
    final userData = await _loadCurrentUserRaw();
    final isSuper = _isSuperUserMap(userData);
    final allowedTenantIds = _tenantIdsFromCurrentUserMap(userData);

    debugPrint(
      '[TenantRepository] loadAvailableTenants | '
          'isSuper=$isSuper | '
          'allowedTenantIds=$allowedTenantIds | '
          'collection=$collectionName',
    );

    if (isSuper) {
      final snap = await _tenantsRef.get();

      debugPrint(
        '[TenantRepository] tenants encontrados=${snap.docs.length}',
      );

      final tenants = snap.docs
          .where((doc) => doc.id.trim().isNotEmpty)
          .map(TenantData.fromDoc)
          .where((tenant) => tenant.id.trim().isNotEmpty)
          .toList();

      tenants.sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );

      return tenants;
    }

    if (allowedTenantIds.isEmpty) {
      debugPrint(
        '[TenantRepository] Usuário comum sem vínculos com tenants.',
      );

      return const <TenantData>[];
    }

    final tenants = <TenantData>[];

    for (final tenantId in allowedTenantIds) {
      final cleanTenantId = tenantId.trim();

      if (cleanTenantId.isEmpty) continue;

      final snap = await _tenantRefById(cleanTenantId).get();

      if (!snap.exists || snap.data() == null) {
        debugPrint(
          '[TenantRepository] Tenant vinculado não encontrado: $cleanTenantId',
        );
        continue;
      }

      tenants.add(TenantData.fromDoc(snap));
    }

    tenants.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );

    debugPrint(
      '[TenantRepository] tenants liberados para usuário comum=${tenants.length}',
    );

    return tenants;
  }

  Future<TenantData> createTenantForCurrentUser({
    required String label,
    String? fantasyName,
    String? cnpj,
  }) async {
    final uid = _currentUserId?.trim();

    if (uid == null || uid.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }

    final cleanLabel = label.trim();
    final cleanFantasyName = fantasyName?.trim() ?? '';
    final cleanCnpj = cnpj?.trim() ?? '';

    if (cleanLabel.isEmpty) {
      throw ArgumentError('O nome da empresa não pode ser vazio.');
    }

    final docRef = _tenantsRef.doc();
    final newTenantId = docRef.id;

    final batch = _firestore.batch();

    final tenantData = <String, dynamic>{
      'id': newTenantId,
      'tenantId': newTenantId,
      'companyId': newTenantId,
      'label': cleanLabel,
      'companyName': cleanLabel,
      'fantasyName': cleanFantasyName,
      if (cleanCnpj.isNotEmpty) 'cnpj': cleanCnpj,
      'units': const <String>[],
      'roads': const <String>[],
      'regions': const <String>[],
      'fundingSources': const <String>[],
      'programs': const <String>[],
      'expenseNatures': const <String>[],
      'companyBodies': const <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    };

    batch.set(
      docRef,
      tenantData,
      SetOptions(merge: true),
    );

    batch.set(
      _userRef(uid),
      {
        'tenantIds': FieldValue.arrayUnion([newTenantId]),
        'allowedTenantIds': FieldValue.arrayUnion([newTenantId]),
        'accessibleTenantIds': FieldValue.arrayUnion([newTenantId]),
        'tenantAccess.$newTenantId': {
          'enabled': true,
          'allowed': true,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'tenantRoles.$newTenantId': 'admin',
        'currentTenantId': newTenantId,
        'selectedTenantId': newTenantId,
        'activeTenantId': newTenantId,
        'lastTenantId': newTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    setActiveTenantId(newTenantId);

    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) {
      throw StateError('A empresa foi criada, mas não pôde ser carregada.');
    }

    return TenantData.fromDoc(snap);
  }

  Future<TenantData?> loadCompanyProfile() async {
    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para acessar esta empresa.');
    }

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
    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para acessar esta empresa.');
    }

    final profile = await loadTenantProfile();

    final arrays = profile == null
        ? TenantItemsResult.empty()
        : TenantItemsResult(
      units: profile.units,
      roads: profile.roads,
      regions: profile.regions,
      fundingSources: profile.fundingSources,
      programs: profile.programs,
      expenseNatures: profile.expenseNatures,
      companyBodies: profile.companyBodies,
    );

    final result = await Future.wait<List<String>>([
      _loadItemsFromSubcollection('units'),
      _loadItemsFromSubcollection('roads'),
      _loadItemsFromSubcollection('regions'),
      _loadItemsFromSubcollection('funding_sources'),
      _loadItemsFromSubcollection('programs'),
      _loadItemsFromSubcollection('expense_natures'),
      _loadItemsFromSubcollection('partners'),
    ]);

    return TenantItemsResult(
      units: _mergeStringLists(arrays.units, result[0]),
      roads: _mergeStringLists(arrays.roads, result[1]),
      regions: _mergeStringLists(arrays.regions, result[2]),
      fundingSources: _mergeStringLists(arrays.fundingSources, result[3]),
      programs: _mergeStringLists(arrays.programs, result[4]),
      expenseNatures: _mergeStringLists(arrays.expenseNatures, result[5]),
      companyBodies: _mergeStringLists(arrays.companyBodies, result[6]),
    );
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
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
  }) async {
    final trimmedLabel = label.trim();
    final trimmedFantasyName = fantasyName.trim();
    final trimmedCnpj = cnpj?.trim();

    if (trimmedLabel.isEmpty) {
      throw ArgumentError('O nome da empresa não pode ser vazio.');
    }

    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para editar esta empresa.');
    }

    final currentSnap = await _tenantRef.get();
    final exists = currentSnap.exists;

    final currentProfile = currentSnap.exists && currentSnap.data() != null
        ? TenantData.fromDoc(currentSnap)
        : null;

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

    final data = <String, dynamic>{
      'tenantId': tenantId,
      'companyId': tenantId,
      'id': tenantId,
      'label': trimmedLabel,
      'companyName': trimmedLabel,
      'fantasyName': trimmedFantasyName,
      'cnpj': (trimmedCnpj == null || trimmedCnpj.isEmpty) ? null : trimmedCnpj,
      'units': _cleanStringList(units ?? currentProfile?.units ?? const []),
      'roads': _cleanStringList(roads ?? currentProfile?.roads ?? const []),
      'regions': _cleanStringList(regions ?? currentProfile?.regions ?? const []),
      'fundingSources': _cleanStringList(
        fundingSources ?? currentProfile?.fundingSources ?? const [],
      ),
      'programs': _cleanStringList(
        programs ?? currentProfile?.programs ?? const [],
      ),
      'expenseNatures': _cleanStringList(
        expenseNatures ?? currentProfile?.expenseNatures ?? const [],
      ),
      'companyBodies': _cleanStringList(
        companyBodies ?? currentProfile?.companyBodies ?? const [],
      ),
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
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
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
      units: units,
      roads: roads,
      regions: regions,
      fundingSources: fundingSources,
      programs: programs,
      expenseNatures: expenseNatures,
      companyBodies: companyBodies,
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

    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para editar esta empresa.');
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
    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para editar esta empresa.');
    }

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
    final canAccess = await currentUserCanAccessTenant(tenantId);

    if (!canAccess) {
      throw StateError('Usuário sem permissão para editar esta empresa.');
    }

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

  Future<String> createUnit(String label) async {
    final profile = await loadTenantProfile();
    final updated = _replaceOrAppendString(profile?.units ?? const [], label);

    await _updateTenantArrayField(
      field: 'units',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateUnitName(String oldLabel, String newLabel) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.units ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'units',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<void> deleteUnit(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.units ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'units',
      values: updated,
    );
  }

  Future<String> createRoad(String label) async {
    final profile = await loadTenantProfile();
    final updated = _replaceOrAppendString(profile?.roads ?? const [], label);

    await _updateTenantArrayField(
      field: 'roads',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateRoadName(String oldLabel, String newLabel) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.roads ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'roads',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<void> deleteRoad(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.roads ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'roads',
      values: updated,
    );
  }

  Future<String> createRegion(
      String label, {
        List<String> municipios = const <String>[],
      }) async {
    final profile = await loadTenantProfile();
    final updated = _replaceOrAppendString(profile?.regions ?? const [], label);

    await _updateTenantArrayField(
      field: 'regions',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateRegionName(String oldLabel, String newLabel) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.regions ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'regions',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<String> updateRegionMunicipios(
      String label,
      List<String> municipios,
      ) async {
    return label.trim();
  }

  Future<void> deleteRegion(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.regions ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'regions',
      values: updated,
    );
  }

  Future<String> createFundingSource(String label) async {
    final profile = await loadTenantProfile();

    final updated = _replaceOrAppendString(
      profile?.fundingSources ?? const [],
      label,
    );

    await _updateTenantArrayField(
      field: 'fundingSources',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateFundingSourceName(
      String oldLabel,
      String newLabel,
      ) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.fundingSources ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'fundingSources',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<void> deleteFundingSource(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.fundingSources ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'fundingSources',
      values: updated,
    );
  }

  Future<String> createProgram(String label) async {
    final profile = await loadTenantProfile();

    final updated = _replaceOrAppendString(
      profile?.programs ?? const [],
      label,
    );

    await _updateTenantArrayField(
      field: 'programs',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateProgramName(
      String oldLabel,
      String newLabel,
      ) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.programs ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'programs',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<void> deleteProgram(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.programs ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'programs',
      values: updated,
    );
  }

  Future<String> createExpenseNature(String label) async {
    final profile = await loadTenantProfile();

    final updated = _replaceOrAppendString(
      profile?.expenseNatures ?? const [],
      label,
    );

    await _updateTenantArrayField(
      field: 'expenseNatures',
      values: updated,
    );

    return label.trim();
  }

  Future<String> updateExpenseNatureName(
      String oldLabel,
      String newLabel,
      ) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.expenseNatures ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'expenseNatures',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<void> deleteExpenseNature(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.expenseNatures ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'expenseNatures',
      values: updated,
    );
  }

  Future<String> createCompanyBody(
      String label, {
        String? cnpj,
      }) async {
    final profile = await loadTenantProfile();

    final updated = _replaceOrAppendString(
      profile?.companyBodies ?? const [],
      label,
    );

    await _updateTenantArrayField(
      field: 'companyBodies',
      values: updated,
    );

    return label.trim();
  }

  Future<String> createPartner(
      String label, {
        String? cnpj,
      }) {
    return createCompanyBody(
      label,
      cnpj: cnpj,
    );
  }

  Future<String> updateCompanyBodyName(
      String oldLabel,
      String newLabel,
      ) async {
    final profile = await loadTenantProfile();

    final updated = _renameStringItem(
      list: profile?.companyBodies ?? const [],
      oldValue: oldLabel,
      newValue: newLabel,
    );

    await _updateTenantArrayField(
      field: 'companyBodies',
      values: updated,
    );

    return newLabel.trim();
  }

  Future<String> updatePartnerName(
      String oldLabel,
      String newLabel,
      ) {
    return updateCompanyBodyName(oldLabel, newLabel);
  }

  Future<String> updateCompanyBodyData(
      String oldLabel, {
        String? label,
        String? cnpj,
      }) {
    final newLabel = label?.trim();

    if (newLabel == null || newLabel.isEmpty) {
      return Future.value(oldLabel.trim());
    }

    return updateCompanyBodyName(oldLabel, newLabel);
  }

  Future<String> updatePartnerData(
      String oldLabel, {
        String? label,
        String? cnpj,
      }) {
    return updateCompanyBodyData(
      oldLabel,
      label: label,
      cnpj: cnpj,
    );
  }

  Future<void> deleteCompanyBody(String label) async {
    final profile = await loadTenantProfile();

    final updated = _deleteStringItem(
      list: profile?.companyBodies ?? const [],
      value: label,
    );

    await _updateTenantArrayField(
      field: 'companyBodies',
      values: updated,
    );
  }

  Future<void> deletePartner(String label) {
    return deleteCompanyBody(label);
  }
}