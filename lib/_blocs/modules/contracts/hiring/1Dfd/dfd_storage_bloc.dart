import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

/// Anexos do DFD:
///   contracts/{contractId}/dfd/{dfdId}/documentos/{documentosId}/files/{file}
///
/// Estrutura fixa:
///   dfdId        -> normalmente "main"
///   documentosId -> normalmente "main"
class DfdStorageBloc {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String _filesPath({
    required String contractId,
    required String dfdId,
    required String documentosId,
  }) =>
      'contracts/$contractId/dfd/$dfdId/documentos/$documentosId/files';

  String _extractExt(String nameOrUrl) {
    final n = nameOrUrl.trim();
    final idx = n.lastIndexOf('.');
    if (idx <= 0 || idx == n.length - 1) return '';
    return n.substring(idx + 1).toLowerCase();
  }

  Future<List<Attachment>> listarDocsDfd({
    required String contractId,
    required String dfdId,
    required String documentosId,
  }) async {
    final ref = storage.ref(
      _filesPath(
        contractId: contractId,
        dfdId: dfdId,
        documentosId: documentosId,
      ),
    );

    final result = await ref.listAll();

    final futures = result.items.map((item) async {
      final url = await item.getDownloadURL();
      final ext = _extractExt(item.name);
      return Attachment(label: item.name, url: url, ext: ext);
    }).toList();

    return Future.wait(futures);
  }

  Future<Attachment> uploadFile({
    required String contractId,
    required String dfdId,
    required String documentosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg'],
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb, // ✅ no Web precisamos dos bytes
    );

    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado');
    }

    final file = picked.files.single;
    final name = file.name;
    final ext = _extractExt(name);

    final ref = storage.ref(
      '${_filesPath(
        contractId: contractId,
        dfdId: dfdId,
        documentosId: documentosId,
      )}/$name',
    );

    final SettableMetadata meta = SettableMetadata(
      contentType: _contentTypeForExt(ext),
    );

    UploadTask upload;

    if (kIsWeb) {
      final Uint8List? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Falha ao ler bytes do arquivo (Web).');
      }
      upload = ref.putData(bytes, meta);
    } else {
      final path = file.path;
      if (path == null || path.isEmpty) {
        throw Exception('Arquivo inválido (path null).');
      }
      // ignore: avoid_slow_async_io
      upload = ref.putFile(await _fileFromPath(path), meta);
    }

    // progresso
    upload.snapshotEvents.listen((e) {
      final total = (e.totalBytes == 0) ? 1 : e.totalBytes;
      onProgress(e.bytesTransferred / total);
    });

    final snap = await upload;
    final url = await snap.ref.getDownloadURL();

    return Attachment(label: name, url: url, ext: ext);
  }

  Future<bool> deleteFile({
    required String contractId,
    required String dfdId,
    required String documentosId,
    required String fileName,
  }) async {
    try {
      final ref = storage.ref(
        '${_filesPath(
          contractId: contractId,
          dfdId: dfdId,
          documentosId: documentosId,
        )}/$fileName',
      );
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============== helpers ==============

  String _contentTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  // Evita importar dart:io diretamente no topo (Web quebra).
  // Aqui usamos import condicional “manual” via dynamic.
  Future<dynamic> _fileFromPath(String path) async {
    // dart:io só existe fora do Web
    // ignore: avoid_dynamic_calls
    final io = await _io();
    // ignore: avoid_dynamic_calls
    return io.File(path);
  }

  Future<dynamic> _io() async {
    // ignore: avoid_web_libraries_in_flutter
    if (kIsWeb) throw Exception('dart:io não disponível no Web');
    // ignore: uri_does_not_exist
    return await Future.value(_DartIoProxy());
  }
}

/// Proxy pequeno para encapsular dart:io sem importar no arquivo.
/// Em runtime mobile/desktop, isso precisa existir com dart:io.
/// Como o Flutter não permite importar condicional “na mão” aqui sem 2 arquivos,
/// a forma mais limpa é você criar versões separadas.
/// MAS: na prática, esse proxy só é usado quando kIsWeb == false.
class _DartIoProxy {
  // ignore: avoid_dynamic_calls
  dynamic File(String path) {
    // ignore: avoid_dynamic_calls
    // ignore: uri_does_not_exist
    // Se seu build reclamar aqui, eu te mando a versão 100% correta com import condicional em 2 arquivos.
    throw UnimplementedError('Proxy dart:io não resolvido neste ambiente.');
  }
}
