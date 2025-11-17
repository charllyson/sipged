// lib/_blocs/process/hiring/1Dfd/dfd_storage_bloc.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

/// Anexos do DFD:
///   contracts/{contractId}/dfd/{dfdId}/documentos/{documentosId}/files/{file}
///
/// Com a nova metodologia:
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

    // Busca URLs em paralelo (melhor performance)
    final futures = result.items.map((item) async {
      final url = await item.getDownloadURL();
      return Attachment(label: item.name, url: url);
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
    );

    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado');
    }

    final filePath = picked.files.single.path;
    if (filePath == null) {
      throw Exception('Arquivo inválido');
    }

    final file = File(filePath);
    final name = picked.files.single.name;

    final ref = storage.ref(
      '${_filesPath(
        contractId: contractId,
        dfdId: dfdId,
        documentosId: documentosId,
      )}/$name',
    );

    final upload = ref.putFile(file);
    upload.snapshotEvents.listen((e) {
      final total = e.totalBytes == 0 ? 1 : e.totalBytes;
      final p = e.bytesTransferred / total;
      onProgress(p);
    });

    final snap = await upload;
    final url = await snap.ref.getDownloadURL();

    return Attachment(label: name, url: url);
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
}
