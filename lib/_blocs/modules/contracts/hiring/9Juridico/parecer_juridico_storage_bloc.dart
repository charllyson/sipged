// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_storage_bloc.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class ParecerJuridicoStorageBloc {
  ParecerJuridicoStorageBloc({FirebaseStorage? firebaseStorage})
      : storage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage storage;

  String _filesPath({
    required String contractId,
    required String parecerId,
    required String docId,
  }) {
    return 'contracts/$contractId/parecer/$parecerId/documentos/$docId/files';
  }

  String _extractExt(String nameOrUrl) {
    final clean = nameOrUrl.trim();
    final queryFree = clean.split('?').first.split('#').first;
    final index = queryFree.lastIndexOf('.');

    if (index <= 0 || index == queryFree.length - 1) return '';

    return queryFree.substring(index + 1).toLowerCase();
  }

  String _contentTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<Attachment>> list({
    required String contractId,
    required String parecerId,
    required String docId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = parecerId.trim();
    final cleanDocId = docId.trim();

    if (cleanContractId.isEmpty || cleanParecerId.isEmpty || cleanDocId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = storage.ref(
      _filesPath(
        contractId: cleanContractId,
        parecerId: cleanParecerId,
        docId: cleanDocId,
      ),
    );

    final res = await ref.listAll();

    final attachments = await Future.wait(
      res.items.map((item) async {
        final url = await item.getDownloadURL();

        return Attachment(
          label: item.name,
          url: url,
        );
      }),
    );

    attachments.sort((a, b) => a.label.compareTo(b.label));

    return attachments;
  }

  Future<Attachment> upload({
    required String contractId,
    required String parecerId,
    required String docId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'docx',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = parecerId.trim();
    final cleanDocId = docId.trim();

    if (cleanContractId.isEmpty || cleanParecerId.isEmpty || cleanDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do parecer jurídico.');
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      throw Exception('Nenhum arquivo selecionado.');
    }

    final file = picked.files.single;
    final Uint8List? bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Falha ao ler os bytes do arquivo.');
    }

    final fileName = file.name.trim();

    if (fileName.isEmpty) {
      throw Exception('Nome do arquivo inválido.');
    }

    final ext = _extractExt(fileName);

    final ref = storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        parecerId: cleanParecerId,
        docId: cleanDocId,
      )}/$fileName',
    );

    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: <String, String>{
          'originalName': fileName,
          'contractId': cleanContractId,
          'parecerId': cleanParecerId,
          'docId': cleanDocId,
        },
      ),
    );

    task.snapshotEvents.listen((event) {
      final total = event.totalBytes == 0 ? 1 : event.totalBytes;
      onProgress(event.bytesTransferred / total);
    });

    final snap = await task;
    final url = await snap.ref.getDownloadURL();

    return Attachment(
      label: fileName,
      url: url,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    required String parecerId,
    required String docId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = parecerId.trim();
    final cleanDocId = docId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocId.isEmpty ||
        cleanFileName.isEmpty) {
      throw Exception('Caminho inválido para upload do parecer jurídico.');
    }

    if (bytes.isEmpty) {
      throw Exception('Bytes do arquivo vazios.');
    }

    final ext = _extractExt(cleanFileName);

    final ref = storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        parecerId: cleanParecerId,
        docId: cleanDocId,
      )}/$cleanFileName',
    );

    final task = ref.putData(
      bytes,
      metadata ??
          SettableMetadata(
            contentType: _contentTypeForExt(ext),
            customMetadata: <String, String>{
              'originalName': cleanFileName,
              'contractId': cleanContractId,
              'parecerId': cleanParecerId,
              'docId': cleanDocId,
            },
          ),
    );

    task.snapshotEvents.listen((event) {
      final total = event.totalBytes == 0 ? 1 : event.totalBytes;
      onProgress(event.bytesTransferred / total);
    });

    final snap = await task;
    final url = await snap.ref.getDownloadURL();

    return Attachment(
      label: cleanFileName,
      url: url,
    );
  }

  Future<bool> delete({
    required String contractId,
    required String parecerId,
    required String docId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = parecerId.trim();
    final cleanDocId = docId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          parecerId: cleanParecerId,
          docId: cleanDocId,
        )}/$cleanFileName',
      );

      await ref.delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) return false;

    try {
      await storage.ref(cleanPath).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}