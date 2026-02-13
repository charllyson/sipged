import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

/// Padrão de armazenamento:
/// contracts/{contractId}/edital/{editalId}/{sectionKey}/{sectionDocId}/files/{fileName}
class EditalStorageBloc {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String _filesPath({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
  }) =>
      'contracts/$contractId/edital/$editalId/$sectionKey/$sectionDocId/files';

  Future<List<Attachment>> listFiles({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
  }) async {
    final ref = storage.ref(_filesPath(
      contractId: contractId,
      editalId: editalId,
      sectionKey: sectionKey,
      sectionDocId: sectionDocId,
    ));
    final result = await ref.listAll();

    final List<Attachment> list = [];
    for (final item in result.items) {
      final url = await item.getDownloadURL();
      list.add(Attachment(label: item.name, url: url));
    }
    return list;
  }

  Future<Attachment> uploadFile({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
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
    if (filePath == null) throw Exception('Arquivo inválido');

    final file = File(filePath);
    final name = picked.files.single.name;

    final ref = storage.ref('${_filesPath(
      contractId: contractId,
      editalId: editalId,
      sectionKey: sectionKey,
      sectionDocId: sectionDocId,
    )}/$name');

    final upload = ref.putFile(file);
    upload.snapshotEvents.listen((e) {
      final total = e.totalBytes == 0 ? 1 : e.totalBytes;
      onProgress(e.bytesTransferred / total);
    });

    final snap = await upload;
    final url = await snap.ref.getDownloadURL();
    return Attachment(label: name, url: url);
  }

  Future<bool> deleteFile({
    required String contractId,
    required String editalId,
    required String sectionKey,
    required String sectionDocId,
    required String fileName,
  }) async {
    try {
      final ref = storage.ref('${_filesPath(
        contractId: contractId,
        editalId: editalId,
        sectionKey: sectionKey,
        sectionDocId: sectionDocId,
      )}/$fileName');
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
