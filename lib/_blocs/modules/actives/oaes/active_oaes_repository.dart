// lib/_blocs/modules/actives/oaes/active_oaes_repository.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'active_oaes_data.dart';

class ActiveOaesRepository {
  ActiveOaesRepository({
    String? tenantId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _tenantId = _cleanTenantId(tenantId),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String? _tenantId;

  static String? _cleanTenantId(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  String? get currentTenantId => _cleanTenantId(_tenantId);

  bool get hasTenant => currentTenantId != null;

  String get effectiveTenantId {
    final clean = currentTenantId;

    if (clean == null || clean.isEmpty) {
      throw StateError(
        'tenantId não definido em ActiveOaesRepository. '
            'Selecione uma empresa antes de acessar OAEs.',
      );
    }

    return clean;
  }

  void setActiveTenantId(String? value) {
    final next = _cleanTenantId(value);

    if (_tenantId == next) return;

    _tenantId = next;
  }

  String get collectionPath {
    return 'tenants/$effectiveTenantId/assets/oaes/items';
  }

  String get storageBasePath {
    return 'tenants/$effectiveTenantId/assets/oaes';
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _firestore.collection(collectionPath);
  }

  String _uid() {
    return _auth.currentUser?.uid ?? '';
  }

  // ---------------------------------------------------------------------------
  // OAE DATA
  // ---------------------------------------------------------------------------

  Future<List<ActiveOaesData>> fetchAll() async {
    if (!hasTenant) return const <ActiveOaesData>[];

    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _ref.orderBy('order').get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition' || e.code == 'not-found') {
        snapshot = await _ref.get();
      } else {
        rethrow;
      }
    }

    final list = snapshot.docs.map(ActiveOaesData.fromDocument).toList();

    list.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return list;
  }

  Future<List<ActiveOaesData>> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (!hasTenant) return const <ActiveOaesData>[];

    Query<Map<String, dynamic>> query = _ref.orderBy('order').limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs.map(ActiveOaesData.fromDocument).toList();
  }

  Future<ActiveOaesData> upsert(ActiveOaesData data) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar OAE.');
    }

    final docRef = data.id == null || data.id!.trim().isEmpty
        ? _ref.doc()
        : _ref.doc(data.id!.trim());

    final id = docRef.id;
    final existing = await docRef.get();

    final json = data.copyWith(id: id).toMap()
      ..addAll({
        'id': id,
        'tenantId': effectiveTenantId,
        'companyId': effectiveTenantId,
        'recordPath': docRef.path,
        'sourceCollectionModel': 'tenant_assets_oaes_items',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      });

    final isNew = !existing.exists || existing.data()?['createdAt'] == null;

    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = _uid();
    } else {
      json.remove('createdAt');
      json.remove('createdBy');
    }

    await docRef.set(json, SetOptions(merge: true));

    final snap = await docRef.get();
    return ActiveOaesData.fromDocument(snap);
  }

  Future<void> deleteById(String id) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para excluir OAE.');
    }

    final cleanId = id.trim();

    if (cleanId.isEmpty) return;

    await _ref.doc(cleanId).delete();
  }

  Future<ActiveOaesData?> getById(String id) async {
    if (!hasTenant) return null;

    final cleanId = id.trim();

    if (cleanId.isEmpty) return null;

    final snap = await _ref.doc(cleanId).get();

    if (!snap.exists) return null;

    return ActiveOaesData.fromDocument(snap);
  }

  Future<void> setAttachments({
    required String oaeId,
    required List<Attachment> attachments,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar anexos da OAE.');
    }

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) {
      throw Exception('oaeId é obrigatório para salvar anexos.');
    }

    final docRef = _ref.doc(cleanId);

    await docRef.set(
      {
        'attachments': attachments.isEmpty
            ? FieldValue.delete()
            : attachments.map((item) => item.toMap()).toList(),
        'tenantId': effectiveTenantId,
        'companyId': effectiveTenantId,
        'recordPath': docRef.path,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers Storage
  // ---------------------------------------------------------------------------

  String _sanitize(String s) {
    return s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');
  }

  String _baseName(String name) {
    var s = name.trim();

    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);

    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);

    s = s.split('/').last;

    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  String _extWithDot(String name) {
    final m = RegExp(
      r'\.([a-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(name.trim());

    return m == null ? '' : '.${m.group(1)!.toLowerCase()}';
  }

  String _extNoDot(String name) {
    final e = _extWithDot(name);
    return e.isEmpty ? '' : e.substring(1);
  }

  String storedFileName(String originalName) {
    final base = _sanitize(_baseName(originalName));

    final rnd = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');

    final ex = _extWithDot(originalName);

    return '$base-$rnd${ex.isEmpty ? ".bin" : ex}';
  }

  String _contentTypeForExt(String extNoDot) {
    final e = extNoDot.toLowerCase();

    switch (e) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'json':
        return 'application/json';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      case 'xml':
        return 'application/xml';
      case 'zip':
        return 'application/zip';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'doc':
        return 'application/msword';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }

  // ---------------------------------------------------------------------------
  // Upload genérico
  // ---------------------------------------------------------------------------

  Future<Attachment> uploadBytes({
    required String baseDir,
    required Uint8List bytes,
    required String originalName,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para enviar arquivo de OAE.');
    }

    final dir = baseDir.endsWith('/')
        ? baseDir.substring(0, baseDir.length - 1)
        : baseDir;

    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final ext = _extNoDot(originalName);
    final label = forcedLabel ?? _baseName(originalName);
    final uid = _uid();

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: {
          'tenantId': effectiveTenantId,
          'companyId': effectiveTenantId,
          'originalName': originalName,
        },
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress.clamp(0.0, 1.0));
        }
      });
    }

    await task;

    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();
    final now = DateTime.now();

    return Attachment(
      id: ref.name,
      label: label.isEmpty ? 'Arquivo' : label,
      url: url,
      path: ref.fullPath,
      ext: ext.isEmpty ? 'bin' : ext,
      size: meta.size?.toInt(),
      createdAt: now,
      createdBy: uid,
      updatedAt: now,
      updatedBy: uid,
    );
  }

  Future<Attachment?> pickAndUploadSingle({
    required String baseDir,
    List<String>? allowedExtensions,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para anexar arquivo de OAE.');
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return null;

    final f = result.files.single;

    return uploadBytes(
      baseDir: baseDir,
      bytes: f.bytes!,
      originalName: f.name,
      onProgress: onProgress,
      forcedLabel: forcedLabel,
    );
  }

  // ---------------------------------------------------------------------------
  // Storage utilitários
  // ---------------------------------------------------------------------------

  Future<bool> deleteByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return false;

    try {
      await _storage.ref(cleanPath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getDownloadUrlByPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return null;

    try {
      return await _storage.ref(cleanPath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<bool> existsPath(String storagePath) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) return false;

    try {
      await _storage.ref(cleanPath).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PHOTOS da OAE
  // ---------------------------------------------------------------------------

  Future<List<Attachment>> loadPhotos(String oaeId) async {
    if (!hasTenant) return const <Attachment>[];

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) return const <Attachment>[];

    final snap = await _ref.doc(cleanId).get();
    final data = snap.data() ?? <String, dynamic>{};
    final raw = data['photos'] as List? ?? const [];

    final list = raw.map<Attachment>((e) {
      if (e is Attachment) return e;
      return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
    }).toList(growable: true);

    list.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    return list;
  }

  Future<void> savePhotos(String oaeId, List<Attachment> photos) async {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para salvar fotos da OAE.');
    }

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) return;

    await _ref.doc(cleanId).set(
      {
        'photos': photos.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _uid(),
        'tenantId': effectiveTenantId,
        'companyId': effectiveTenantId,
      },
      SetOptions(merge: true),
    );
  }

  Future<Attachment> uploadPhotoBytes({
    required String oaeId,
    required Uint8List bytes,
    required String originalName,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) {
    if (!hasTenant) {
      throw Exception('tenantId é obrigatório para enviar foto da OAE.');
    }

    final cleanId = oaeId.trim();

    if (cleanId.isEmpty) {
      throw Exception('oaeId é obrigatório para enviar foto.');
    }

    final baseDir = '$storageBasePath/$cleanId/photos';

    return uploadBytes(
      baseDir: baseDir,
      bytes: bytes,
      originalName: originalName,
      onProgress: onProgress,
      forcedLabel: forcedLabel,
    );
  }
}