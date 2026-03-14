// lib/_blocs/modules/actives/oacs/active_oacs_repository.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'active_oacs_data.dart';

class ActiveOacsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ActiveOacsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('actives_oacs');

  // ---------------------------------------------------------------------------
  // OAC DATA (Firestore)
  // ---------------------------------------------------------------------------

  Future<List<ActiveOacsData>> fetchAll() async {
    final snapshot = await _ref.orderBy('order').get();
    return snapshot.docs.map((doc) => ActiveOacsData.fromDocument(doc)).toList();
  }

  Future<List<ActiveOacsData>> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = _ref.orderBy('order').limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ActiveOacsData.fromDocument(doc)).toList();
  }

  Future<ActiveOacsData> upsert(ActiveOacsData data) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final docRef = data.id != null ? _ref.doc(data.id) : _ref.doc();
    data.id ??= docRef.id;

    // IMPORTANTE: usa toMap() para manter compatibilidade com seu padrão atual
    final json = data.toMap()
      ..addAll({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': firebaseUser?.uid ?? '',
      });

    final snapshot = await docRef.get();
    final isNew = !snapshot.exists || snapshot.data()?['createdAt'] == null;
    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = firebaseUser?.uid ?? '';
    }

    await docRef.set(json, SetOptions(merge: true));

    final snap = await docRef.get();
    return ActiveOacsData.fromDocument(snap);
  }

  Future<void> deleteById(String id) async {
    await _ref.doc(id).delete();
  }

  Future<ActiveOacsData?> getById(String id) async {
    final snap = await _ref.doc(id).get();
    if (!snap.exists) return null;
    return ActiveOacsData.fromDocument(snap);
  }

  // ---------------------------------------------------------------------------
  // Storage helpers (igual ao seu de OAEs)
  // ---------------------------------------------------------------------------

  String _sanitize(String s) =>
      s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

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
    final m = RegExp(r'\.([a-z0-9]+)$', caseSensitive: false).firstMatch(name.trim());
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
    final e = (extNoDot).toLowerCase();
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
      case 'pickers':
        return 'image/pickers+xml';
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
  // Upload genérico (bytes / FilePicker) para anexos
  // ---------------------------------------------------------------------------

  Future<Attachment> uploadBytes({
    required String baseDir,
    required Uint8List bytes,
    required String originalName,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) async {
    final dir =
    baseDir.endsWith('/') ? baseDir.substring(0, baseDir.length - 1) : baseDir;
    final name = storedFileName(originalName);
    final ref = _storage.ref('$dir/$name');

    final ext = _extNoDot(originalName);
    final label = forcedLabel ?? _baseName(originalName);

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: {'originalName': originalName},
      ),
    );

    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }

    await task;

    final url = await ref.getDownloadURL();
    final meta = await ref.getMetadata();
    final now = DateTime.now();
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
    try {
      await _storage.ref(storagePath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getDownloadUrlByPath(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<bool> existsPath(String storagePath) async {
    try {
      await _storage.ref(storagePath).getMetadata();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PHOTOS da OAC (campo "photos" no documento)
  // ---------------------------------------------------------------------------

  Future<List<Attachment>> loadPhotos(String oacId) async {
    final snap = await _ref.doc(oacId).get();
    final data = (snap.data() ?? <String, dynamic>{});
    final raw = (data['photos'] as List?) ?? const [];

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

  Future<void> savePhotos(String oacId, List<Attachment> photos) async {
    await _ref.doc(oacId).set({
      'photos': photos.map((a) => a.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Attachment> uploadPhotoBytes({
    required String oacId,
    required Uint8List bytes,
    required String originalName,
    void Function(double progress)? onProgress,
    String? forcedLabel,
  }) {
    final baseDir = 'actives_oacs/$oacId/photos';
    return uploadBytes(
      baseDir: baseDir,
      bytes: bytes,
      originalName: originalName,
      onProgress: onProgress,
      forcedLabel: forcedLabel,
    );
  }
}
