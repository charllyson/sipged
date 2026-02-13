// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_storage_bloc.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

/// contracts/{contractId}/parecer/{parecerId}/documentos/{docId}/files/{file}
class ParecerJuridicoStorageBloc {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String _filesPath({
    required String contractId,
    required String parecerId,
    required String docId,
  }) => 'contracts/$contractId/parecer/$parecerId/documentos/$docId/files';

  Future<List<Attachment>> list({
    required String contractId,
    required String parecerId,
    required String docId,
  }) async {
    final ref = storage.ref(_filesPath(
      contractId: contractId, parecerId: parecerId, docId: docId,
    ));
    final res = await ref.listAll();
    final out = <Attachment>[];
    for (final item in res.items) {
      final url = await item.getDownloadURL();
      out.add(Attachment(label: item.name, url: url));
    }
    return out;
  }

  Future<Attachment> upload({
    required String contractId,
    required String parecerId,
    required String docId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true, // necessário para Web
      allowedExtensions: allowedExtensions,
    );
    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado');
    }

    final fileName = picked.files.single.name;
    final ref = storage.ref('${_filesPath(
      contractId: contractId, parecerId: parecerId, docId: docId,
    )}/$fileName');

    UploadTask task;
    if (kIsWeb) {
      final bytes = picked.files.single.bytes;
      if (bytes == null) throw Exception('Falha ao ler bytes do arquivo');
      task = ref.putData(bytes);
    } else {
      final path = picked.files.single.path;
      if (path == null) throw Exception('Arquivo inválido');
      task = ref.putFile(File(path));
    }

    task.snapshotEvents.listen((e) {
      final total = e.totalBytes == 0 ? 1 : e.totalBytes;
      onProgress(e.bytesTransferred / total);
    });

    final snap = await task;
    final url = await snap.ref.getDownloadURL();
    return Attachment(label: fileName, url: url);
  }

  Future<bool> delete({
    required String contractId,
    required String parecerId,
    required String docId,
    required String fileName,
  }) async {
    try {
      final ref = storage.ref('${_filesPath(
        contractId: contractId, parecerId: parecerId, docId: docId,
      )}/$fileName');
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
