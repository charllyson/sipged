// lib/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'habilitacao_data.dart';
import 'habilitacao_repository.dart';
import 'habilitacao_state.dart';

class HabilitacaoCubit extends Cubit<HabilitacaoState> {
  HabilitacaoCubit({
    required String tenantId,
    HabilitacaoRepository? repository,
  })  : repo = repository ?? HabilitacaoRepository(tenantId: tenantId),
        super(HabilitacaoState.initial());

  final HabilitacaoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<HabilitacaoData?> getDataForContract(String contractId) {
    final id = contractId.trim();
    if (id.isEmpty) return Future<HabilitacaoData?>.value(null);

    return repo.readDataForContract(id);
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
          clearHabId: true,
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
        habId: ids.habId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          habId: ids.habId,
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
        saving: true,
        loading: false,
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
        habId: ids.habId,
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
          habId: ids.habId,
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
        saving: true,
        loading: false,
        saveSuccess: false,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);
      final sectionId = ids.sectionIds[cleanSectionKey];

      if (sectionId == null || sectionId.trim().isEmpty) {
        if (!_alive || reqId != _saveSeq) return;

        emit(
          state.copyWith(
            saving: false,
            saveSuccess: false,
            error: 'Seção inválida: $cleanSectionKey',
            habId: ids.habId,
            sectionIds: ids.sectionIds,
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        habId: ids.habId,
        sectionKey: cleanSectionKey,
        sectionDocId: sectionId,
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
          habId: ids.habId,
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
    String? habId,
    String? licitacaoDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanHabId = (habId ?? state.habId ?? '').trim();
    final cleanLicitacaoDocId =
    (licitacaoDocId ??
        state.sectionIds[HabilitacaoData.sectionLicitacaoAdesao] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanHabId.isEmpty ||
        cleanLicitacaoDocId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      habId: cleanHabId,
      licitacaoDocId: cleanLicitacaoDocId,
    );
  }

  Future<List<Attachment>> listLicitacaoFiles({
    required String contractId,
    String? habId,
    String? licitacaoDocId,
  }) {
    return listFiles(
      contractId: contractId,
      habId: habId,
      licitacaoDocId: licitacaoDocId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? habId,
    String? licitacaoDocId,
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
    final cleanHabId = (habId ?? state.habId ?? '').trim();
    final cleanLicitacaoDocId =
    (licitacaoDocId ??
        state.sectionIds[HabilitacaoData.sectionLicitacaoAdesao] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanHabId.isEmpty ||
        cleanLicitacaoDocId.isEmpty) {
      throw Exception('Caminho inválido para upload da habilitação.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      habId: cleanHabId,
      licitacaoDocId: cleanLicitacaoDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadLicitacaoFile({
    required String contractId,
    String? habId,
    String? licitacaoDocId,
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
      habId: habId,
      licitacaoDocId: licitacaoDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? habId,
    String? licitacaoDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanHabId = (habId ?? state.habId ?? '').trim();
    final cleanLicitacaoDocId =
    (licitacaoDocId ??
        state.sectionIds[HabilitacaoData.sectionLicitacaoAdesao] ??
        '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanHabId.isEmpty ||
        cleanLicitacaoDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      habId: cleanHabId,
      licitacaoDocId: cleanLicitacaoDocId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteLicitacaoFile({
    required String contractId,
    String? habId,
    String? licitacaoDocId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      habId: habId,
      licitacaoDocId: licitacaoDocId,
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