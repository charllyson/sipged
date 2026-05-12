// lib/_blocs/modules/contracts/hiring/10Arquivamento/termo_arquivamento_cubit.dart

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'termo_arquivamento_data.dart';
import 'termo_arquivamento_repository.dart';
import 'termo_arquivamento_state.dart';

class TermoArquivamentoCubit extends Cubit<TermoArquivamentoState> {
  TermoArquivamentoCubit({
    required String tenantId,
    TermoArquivamentoRepository? repository,
  })  : _tenantId = _requireTenantId(tenantId),
        repo = repository ??
            TermoArquivamentoRepository(
              tenantId: tenantId,
            ),
        super(TermoArquivamentoState.initial());

  final String _tenantId;
  final TermoArquivamentoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em TermoArquivamentoCubit.');
    }

    return cleanTenantId;
  }

  String get tenantId => _tenantId;

  Future<TermoArquivamentoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<TermoArquivamentoData?>.value(null);
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
          clearTaId: true,
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
        taId: ids.taId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          taId: ids.taId,
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
        taId: ids.taId,
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
          taId: ids.taId,
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
            taId: ids.taId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        taId: ids.taId,
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
          taId: ids.taId,
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
    String? taId,
    String? pecasDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = (taId ?? state.taId ?? '').trim();
    final cleanPecasDocId =
    (pecasDocId ?? state.sectionIds[TermoArquivamentoData.sectionPecas] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      taId: cleanTaId,
      pecasDocId: cleanPecasDocId,
    );
  }

  Future<List<Attachment>> listPecasFiles({
    required String contractId,
    String? taId,
    String? pecasDocId,
  }) {
    return listFiles(
      contractId: contractId,
      taId: taId,
      pecasDocId: pecasDocId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? taId,
    String? pecasDocId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'doc',
      'docx',
    ],
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = (taId ?? state.taId ?? '').trim();
    final cleanPecasDocId =
    (pecasDocId ?? state.sectionIds[TermoArquivamentoData.sectionPecas] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do termo de arquivamento.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      taId: cleanTaId,
      pecasDocId: cleanPecasDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadPecasFile({
    required String contractId,
    String? taId,
    String? pecasDocId,
    required void Function(double progress) onProgress,
    List<String> allowedExtensions = const <String>[
      'pdf',
      'png',
      'jpg',
      'jpeg',
      'webp',
      'doc',
      'docx',
    ],
  }) {
    return uploadFile(
      contractId: contractId,
      taId: taId,
      pecasDocId: pecasDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    String? taId,
    String? pecasDocId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = (taId ?? state.taId ?? '').trim();
    final cleanPecasDocId =
    (pecasDocId ?? state.sectionIds[TermoArquivamentoData.sectionPecas] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do termo de arquivamento.');
    }

    return repo.uploadBytes(
      contractId: cleanContractId,
      taId: cleanTaId,
      pecasDocId: cleanPecasDocId,
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
      metadata: metadata,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? taId,
    String? pecasDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanTaId = (taId ?? state.taId ?? '').trim();
    final cleanPecasDocId =
    (pecasDocId ?? state.sectionIds[TermoArquivamentoData.sectionPecas] ?? '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanTaId.isEmpty ||
        cleanPecasDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      taId: cleanTaId,
      pecasDocId: cleanPecasDocId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deletePecasFile({
    required String contractId,
    String? taId,
    String? pecasDocId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      taId: taId,
      pecasDocId: pecasDocId,
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