// lib/_blocs/modules/contracts/hiring/7Dotacao/dotacao_cubit.dart

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'dotacao_data.dart';
import 'dotacao_repository.dart';
import 'dotacao_state.dart';

class DotacaoCubit extends Cubit<DotacaoState> {
  DotacaoCubit({
    required String tenantId,
    DotacaoRepository? repository,
  })  : repo = repository ?? DotacaoRepository(tenantId: tenantId),
        super(DotacaoState.initial());

  final DotacaoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<DotacaoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<DotacaoData?>.value(null);
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
          clearDotacaoId: true,
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
        dotacaoId: ids.dotacaoId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          dotacaoId: ids.dotacaoId,
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
        dotacaoId: ids.dotacaoId,
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
          dotacaoId: ids.dotacaoId,
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
            dotacaoId: ids.dotacaoId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        dotacaoId: ids.dotacaoId,
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
          dotacaoId: ids.dotacaoId,
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
    String? dotacaoId,
    String? documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = (dotacaoId ?? state.dotacaoId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DotacaoData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      dotacaoId: cleanDotacaoId,
      documentosId: cleanDocumentosId,
    );
  }

  Future<List<Attachment>> listDocumentosFiles({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
  }) {
    return listFiles(
      contractId: contractId,
      dotacaoId: dotacaoId,
      documentosId: documentosId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
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
    final cleanDotacaoId = (dotacaoId ?? state.dotacaoId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DotacaoData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload da dotação.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      dotacaoId: cleanDotacaoId,
      documentosId: cleanDocumentosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadDocumentosFile({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
    ],
  }) {
    return uploadFile(
      contractId: contractId,
      dotacaoId: dotacaoId,
      documentosId: documentosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = (dotacaoId ?? state.dotacaoId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DotacaoData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload da dotação.');
    }

    return repo.uploadBytes(
      contractId: cleanContractId,
      dotacaoId: cleanDotacaoId,
      documentosId: cleanDocumentosId,
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
      metadata: metadata,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDotacaoId = (dotacaoId ?? state.dotacaoId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DotacaoData.sectionDocumentos] ?? '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanDotacaoId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      dotacaoId: cleanDotacaoId,
      documentosId: cleanDocumentosId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteDocumentosFile({
    required String contractId,
    String? dotacaoId,
    String? documentosId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      dotacaoId: dotacaoId,
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