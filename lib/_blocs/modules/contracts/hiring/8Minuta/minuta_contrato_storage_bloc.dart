import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

/// contracts/{contractId}/minuta/{minutaId}/gestao_refs/{gestaoId}/files/{file}
class MinutaContratoStorageBloc {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String _filesPath({
    required String contractId,
    required String minutaId,
    required String gestaoId,
  }) =>
      'contracts/$contractId/minuta/$minutaId/gestao_refs/$gestaoId/files';

  Future<List<Attachment>> list({
    required String contractId,
    required String minutaId,
    required String gestaoId,
  }) async {
    final ref = storage.ref(
      _filesPath(contractId: contractId, minutaId: minutaId, gestaoId: gestaoId),
    );
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
    required String minutaId,
    required String gestaoId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );
    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado');
    }

    final fileName = picked.files.single.name;
    final ref = storage.ref(
      '${_filesPath(contractId: contractId, minutaId: minutaId, gestaoId: gestaoId)}/$fileName',
    );

    UploadTask task;
    if (kIsWeb) {
      final Uint8List? bytes = picked.files.single.bytes;
      if (bytes == null) throw Exception('Falha ao ler arquivo (bytes nulos).');
      task = ref.putData(bytes);
    } else {
      final String? path = picked.files.single.path;
      if (path == null) throw Exception('Arquivo inválido (sem caminho).');
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

  Future<Attachment> uploadBytes({
    required String contractId,
    required String minutaId,
    required String gestaoId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final ref = storage.ref(
      '${_filesPath(contractId: contractId, minutaId: minutaId, gestaoId: gestaoId)}/$fileName',
    );
    final task = ref.putData(bytes, metadata);
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
    required String minutaId,
    required String gestaoId,
    required String fileName,
  }) async {
    try {
      final ref = storage.ref(
        '${_filesPath(contractId: contractId, minutaId: minutaId, gestaoId: gestaoId)}/$fileName',
      );
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
