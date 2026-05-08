// lib/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_cubit.dart

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'parecer_juridico_data.dart';
import 'parecer_juridico_repository.dart';
import 'parecer_juridico_state.dart';

class ParecerJuridicoCubit extends Cubit<ParecerState> {
  ParecerJuridicoCubit([ParecerJuridicoRepository? repository])
      : repo = repository ?? ParecerJuridicoRepository(),
        super(ParecerState.initial());

  final ParecerJuridicoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<ParecerJuridicoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<ParecerJuridicoData?>.value(null);
    }

    return repo.readDataForContract(cleanContractId);
  }

  Future<void> load(String contractId) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
          clearContractId: true,
          clearParecerId: true,
          sectionIds: const <String, String>{},
          sectionsData: const <String, Map<String, dynamic>>{},
        ),
      );
      return;
    }

    final reqId = ++_loadSeq;

    emit(
      state.copyWith(
        loading: true,
        saving: false,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _loadSeq) return;

      final data = await repo.loadAllSections(
        contractId: cleanContractId,
        parecerId: ids.parecerId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          parecerId: ids.parecerId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> saveAll({
    required String contractId,
    required Map<String, Map<String, dynamic>> sectionsData,
  }) async {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
        ),
      );
      return;
    }

    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        loading: false,
        saving: true,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSectionsBatch(
        contractId: cleanContractId,
        parecerId: ids.parecerId,
        sectionIds: ids.sectionIds,
        sectionsData: sectionsData,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{
        ...state.sectionsData,
      };

      sectionsData.forEach((key, value) {
        merged[key] = <String, dynamic>{
          ...(merged[key] ?? const <String, dynamic>{}),
          ...value,
        };
      });

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: cleanContractId,
          parecerId: ids.parecerId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> saveOneSection({
    required String contractId,
    required String sectionKey,
    required Map<String, dynamic> data,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanSectionKey = sectionKey.trim();

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Contrato não informado.',
        ),
      );
      return;
    }

    if (cleanSectionKey.isEmpty) {
      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: 'Seção não informada.',
        ),
      );
      return;
    }

    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        loading: false,
        saving: true,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);
      final sectionDocId = ids.sectionIds[cleanSectionKey];

      if (sectionDocId == null || sectionDocId.trim().isEmpty) {
        if (!_alive || reqId != _saveSeq) return;

        emit(
          state.copyWith(
            saving: false,
            saveSuccess: false,
            parecerId: ids.parecerId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        parecerId: ids.parecerId,
        sectionKey: cleanSectionKey,
        sectionDocId: sectionDocId,
        data: data,
      );

      if (!_alive || reqId != _saveSeq) return;

      final merged = <String, Map<String, dynamic>>{
        ...state.sectionsData,
      };

      merged[cleanSectionKey] = <String, dynamic>{
        ...(merged[cleanSectionKey] ?? const <String, dynamic>{}),
        ...data,
      };

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: true,
          contractId: cleanContractId,
          parecerId: ids.parecerId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!_alive || reqId != _saveSeq) return;

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<List<Attachment>> listFiles({
    required String contractId,
    String? parecerId,
    String? documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = (parecerId ?? state.parecerId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ??
        state.sectionIds[ParecerJuridicoData.sectionDocumentos] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      parecerId: cleanParecerId,
      documentosId: cleanDocumentosId,
    );
  }

  Future<List<Attachment>> listDocumentosFiles({
    required String contractId,
    String? parecerId,
    String? documentosId,
  }) {
    return listFiles(
      contractId: contractId,
      parecerId: parecerId,
      documentosId: documentosId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? parecerId,
    String? documentosId,
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
    final cleanParecerId = (parecerId ?? state.parecerId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ??
        state.sectionIds[ParecerJuridicoData.sectionDocumentos] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload do parecer jurídico.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      parecerId: cleanParecerId,
      documentosId: cleanDocumentosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadDocumentosFile({
    required String contractId,
    String? parecerId,
    String? documentosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'docx',
    ],
  }) {
    return uploadFile(
      contractId: contractId,
      parecerId: parecerId,
      documentosId: documentosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    String? parecerId,
    String? documentosId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = (parecerId ?? state.parecerId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ??
        state.sectionIds[ParecerJuridicoData.sectionDocumentos] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload do parecer jurídico.');
    }

    return repo.uploadBytes(
      contractId: cleanContractId,
      parecerId: cleanParecerId,
      documentosId: cleanDocumentosId,
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
      metadata: metadata,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? parecerId,
    String? documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanParecerId = (parecerId ?? state.parecerId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ??
        state.sectionIds[ParecerJuridicoData.sectionDocumentos] ??
        '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanParecerId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      parecerId: cleanParecerId,
      documentosId: cleanDocumentosId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteDocumentosFile({
    required String contractId,
    String? parecerId,
    String? documentosId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      parecerId: parecerId,
      documentosId: documentosId,
      fileName: fileName,
    );
  }

  Future<bool> deleteByPath(String path) {
    return repo.deleteByPath(path);
  }

  void clearSuccessFlag() {
    if (state.saveSuccess) {
      emit(state.copyWith(saveSuccess: false));
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}