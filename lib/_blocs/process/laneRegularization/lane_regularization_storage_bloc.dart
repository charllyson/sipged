// lib/_blocs/sectors/planning/laneRegularization/lane_regularization_storage_bloc.dart
import 'dart:typed_data';
import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class LaneRegularizationStorageBloc extends BlocBase {
  final FirebaseStorage _storage;
  LaneRegularizationStorageBloc({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  String _sanitize(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '-');

  String _baseFolder(String contractId, String propertyId) =>
      'contracts/$contractId/planning_highway_domain/properties/$propertyId/';

  String _geoFolder(String cId, String pId) => '${_baseFolder(cId, pId)}geo/';
  String _docsFolder(String cId, String pId) => '${_baseFolder(cId, pId)}docs/';

  bool _isGeoName(String n) {
    final s = n.toLowerCase();
    return s.endsWith('.kml') || s.endsWith('.kmz') || s.endsWith('.geojson') || s.endsWith('.json');
  }

  // -------- LISTAGEM (com path) --------

  Future<List<({String name, String url, String path})>> listarGeo({
    required String contractId,
    required String propertyId,
  }) async {
    final ref = _storage.ref(_geoFolder(contractId, propertyId));
    final res = await ref.listAll();
    final out = <({String name, String url, String path})>[];
    for (final item in res.items) {
      try {
        out.add((name: item.name, url: await item.getDownloadURL(), path: item.fullPath));
      } catch (_) {}
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  Future<List<({String name, String url, String path})>> listarDocs({
    required String contractId,
    required String propertyId,
  }) async {
    final ref = _storage.ref(_docsFolder(contractId, propertyId));
    final res = await ref.listAll();
    final out = <({String name, String url, String path})>[];
    for (final item in res.items) {
      try {
        out.add((name: item.name, url: await item.getDownloadURL(), path: item.fullPath));
      } catch (_) {}
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  // -------- UPLOAD (detalhado) --------

  String _guessGeoContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.kml')) return 'application/vnd.google-earth.kml+xml';
    if (lower.endsWith('.kmz')) return 'application/vnd.google-earth.kmz';
    if (lower.endsWith('.geojson') || lower.endsWith('.json')) return 'application/geo+json';
    return 'application/octet-stream';
  }

  Future<({String name, String url, String path})> _uploadBytesTo(
      String fullPath, {
        required Uint8List bytes,
        String? contentType,
        void Function(double progress)? onProgress,
      }) async {
    final ref = _storage.ref(fullPath);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    if (onProgress != null) {
      task.snapshotEvents.listen((e) {
        if (e.totalBytes > 0) onProgress(e.bytesTransferred / e.totalBytes);
      });
    }
    await task;
    final url = await ref.getDownloadURL();
    return (name: ref.name, url: url, path: ref.fullPath);
  }

  Future<({String name, String url, String path})> uploadGeoWithPickerDetailed({
    required String contractId,
    required String propertyId,
    required void Function(double progress) onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kml', 'kmz', 'geojson', 'json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum arquivo georreferenciado selecionado.');
    }
    final original = result.files.single.name;
    final safe = _sanitize(original.split('/').last);
    final lower = safe.toLowerCase();

    String ext = '';
    if (lower.endsWith('.kml')) ext = '.kml';
    else if (lower.endsWith('.kmz')) ext = '.kmz';
    else if (lower.endsWith('.geojson') || lower.endsWith('.json')) ext = '.geojson';

    final baseName = ext.isEmpty ? safe : safe.substring(0, safe.length - ext.length);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${_geoFolder(contractId, propertyId)}${baseName}_$ts$ext';

    return _uploadBytesTo(
      path,
      bytes: result.files.single.bytes!,
      contentType: _guessGeoContentType(safe),
      onProgress: onProgress,
    );
  }

  Future<({String name, String url, String path})> uploadDocWithPickerDetailed({
    required String contractId,
    required String propertyId,
    required void Function(double progress) onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      throw Exception('Nenhum PDF selecionado.');
    }
    final original = result.files.single.name;
    final safe = _sanitize(original.split('/').last);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${_docsFolder(contractId, propertyId)}${safe}_$ts.pdf';

    return _uploadBytesTo(
      path,
      bytes: result.files.single.bytes!,
      contentType: 'application/pdf',
      onProgress: onProgress,
    );
  }

  // -------- Exclusão --------

  Future<void> deleteByUrl(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }

  Future<void> deleteByPath(String fullPath) async {
    try {
      await _storage.ref(fullPath).delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }
}
