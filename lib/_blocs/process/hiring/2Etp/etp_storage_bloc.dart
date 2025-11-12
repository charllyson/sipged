import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// Caminho:
/// contracts/{contractId}/etp/{etpId}/documentos/{documentosId}/files/{file}
class EtpStorageBloc {
  final FirebaseStorage storage = FirebaseStorage.instance;

  String _filesPath({
    required String contractId,
    required String etpId,
    required String documentosId,
  }) => 'contracts/$contractId/etp/$etpId/documentos/$documentosId/files';

  Future<List<Attachment>> list({
    required String contractId,
    required String etpId,
    required String documentosId,
  }) async {
    final ref = storage.ref(_filesPath(
      contractId: contractId, etpId: etpId, documentosId: documentosId,
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
    required String etpId,
    required String documentosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg'],
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: allowedExtensions,
    );
    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado');
    }
    final path = picked.files.single.path;
    if (path == null) throw Exception('Arquivo inválido');

    final name = picked.files.single.name;
    final ref = storage.ref('${_filesPath(
      contractId: contractId, etpId: etpId, documentosId: documentosId,
    )}/$name');

    final task = ref.putFile(File(path));
    task.snapshotEvents.listen((e) {
      final total = e.totalBytes == 0 ? 1 : e.totalBytes;
      onProgress(e.bytesTransferred / total);
    });

    final snap = await task;
    final url = await snap.ref.getDownloadURL();
    return Attachment(label: name, url: url);
  }

  Future<bool> delete({
    required String contractId,
    required String etpId,
    required String documentosId,
    required String fileName,
  }) async {
    try {
      final ref = storage.ref('${_filesPath(
        contractId: contractId, etpId: etpId, documentosId: documentosId,
      )}/$fileName');
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
