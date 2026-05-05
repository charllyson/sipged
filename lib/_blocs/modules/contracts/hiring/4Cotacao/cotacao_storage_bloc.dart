// lib/_blocs/modules/contracts/hiring/4Cotacao/cotacao_storage_bloc.dart

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class CotacaoStorageBloc {
  CotacaoStorageBloc({FirebaseStorage? firebaseStorage})
      : storage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage storage;

  String _filesPath({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
  }) {
    return 'contracts/$contractId/cotacao/$cotacaoId/anexosEvidencias/$anexosId/files';
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
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<Attachment>> list({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      return const <Attachment>[];
    }

    final ref = storage.ref(
      _filesPath(
        contractId: cleanContractId,
        cotacaoId: cleanCotacaoId,
        anexosId: cleanAnexosId,
      ),
    );

    final result = await ref.listAll();

    final attachments = await Future.wait(
      result.items.map((item) async {
        final url = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        final ext = _extractExt(item.name);

        return Attachment(
          id: item.name,
          label: item.name,
          url: url,
          path: item.fullPath,
          ext: ext,
          size: metadata.size?.toInt(),
        );
      }),
    );

    attachments.sort((a, b) => a.label.compareTo(b.label));

    return attachments;
  }

  Future<Attachment> upload({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      throw Exception('Caminho inválido para upload da cotação.');
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
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Falha ao ler os bytes do arquivo.');
    }

    final name = file.name.trim();

    if (name.isEmpty) {
      throw Exception('Nome do arquivo inválido.');
    }

    final ext = _extractExt(name);

    final ref = storage.ref(
      '${_filesPath(
        contractId: cleanContractId,
        cotacaoId: cleanCotacaoId,
        anexosId: cleanAnexosId,
      )}/$name',
    );

    final upload = ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
        contentType: _contentTypeForExt(ext),
        customMetadata: <String, String>{
          'originalName': name,
          'contractId': cleanContractId,
          'cotacaoId': cleanCotacaoId,
          'anexosId': cleanAnexosId,
        },
      ),
    );

    upload.snapshotEvents.listen((event) {
      final total = event.totalBytes == 0 ? 1 : event.totalBytes;
      onProgress(event.bytesTransferred / total);
    });

    final snap = await upload;
    final url = await snap.ref.getDownloadURL();
    final metadata = await snap.ref.getMetadata();

    return Attachment(
      id: snap.ref.name,
      label: name,
      url: url,
      path: snap.ref.fullPath,
      ext: ext,
      size: metadata.size?.toInt(),
    );
  }

  Future<bool> delete({
    required String contractId,
    required String cotacaoId,
    required String anexosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = cotacaoId.trim();
    final cleanAnexosId = anexosId.trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    try {
      final ref = storage.ref(
        '${_filesPath(
          contractId: cleanContractId,
          cotacaoId: cleanCotacaoId,
          anexosId: cleanAnexosId,
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