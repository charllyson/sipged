// lib/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_cubit.dart

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'minuta_contrato_data.dart';
import 'minuta_contrato_repository.dart';
import 'minuta_contrato_state.dart';

class MinutaContratoCubit extends Cubit<MinutaState> {
  MinutaContratoCubit({
    required String tenantId,
    MinutaContratoRepository? repository,
  })  : repo = repository ?? MinutaContratoRepository(tenantId: tenantId),
        super(MinutaState.initial());

  final MinutaContratoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<MinutaContratoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<MinutaContratoData?>.value(null);
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
          clearMinutaId: true,
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
        minutaId: ids.minutaId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          minutaId: ids.minutaId,
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
        minutaId: ids.minutaId,
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
          minutaId: ids.minutaId,
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
            minutaId: ids.minutaId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        minutaId: ids.minutaId,
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
          minutaId: ids.minutaId,
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
    String? minutaId,
    String? gestaoId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = (minutaId ?? state.minutaId ?? '').trim();
    final cleanGestaoId =
    (gestaoId ?? state.sectionIds[MinutaContratoData.sectionGestaoRefs] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      minutaId: cleanMinutaId,
      gestaoId: cleanGestaoId,
    );
  }

  Future<List<Attachment>> listGestaoFiles({
    required String contractId,
    String? minutaId,
    String? gestaoId,
  }) {
    return listFiles(
      contractId: contractId,
      minutaId: minutaId,
      gestaoId: gestaoId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? minutaId,
    String? gestaoId,
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
    final cleanMinutaId = (minutaId ?? state.minutaId ?? '').trim();
    final cleanGestaoId =
    (gestaoId ?? state.sectionIds[MinutaContratoData.sectionGestaoRefs] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty) {
      throw Exception('Caminho inválido para upload da minuta.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      minutaId: cleanMinutaId,
      gestaoId: cleanGestaoId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadGestaoFile({
    required String contractId,
    String? minutaId,
    String? gestaoId,
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
      minutaId: minutaId,
      gestaoId: gestaoId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    String? minutaId,
    String? gestaoId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = (minutaId ?? state.minutaId ?? '').trim();
    final cleanGestaoId =
    (gestaoId ?? state.sectionIds[MinutaContratoData.sectionGestaoRefs] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty) {
      throw Exception('Caminho inválido para upload da minuta.');
    }

    return repo.uploadBytes(
      contractId: cleanContractId,
      minutaId: cleanMinutaId,
      gestaoId: cleanGestaoId,
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
      metadata: metadata,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? minutaId,
    String? gestaoId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanMinutaId = (minutaId ?? state.minutaId ?? '').trim();
    final cleanGestaoId =
    (gestaoId ?? state.sectionIds[MinutaContratoData.sectionGestaoRefs] ?? '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanMinutaId.isEmpty ||
        cleanGestaoId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      minutaId: cleanMinutaId,
      gestaoId: cleanGestaoId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteGestaoFile({
    required String contractId,
    String? minutaId,
    String? gestaoId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      minutaId: minutaId,
      gestaoId: gestaoId,
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