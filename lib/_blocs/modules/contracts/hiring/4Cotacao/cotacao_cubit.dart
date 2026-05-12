// lib/_blocs/modules/contracts/hiring/4Cotacao/cotacao_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'cotacao_data.dart';
import 'cotacao_repository.dart';
import 'cotacao_state.dart';

class CotacaoCubit extends Cubit<CotacaoState> {
  CotacaoCubit({
    required String tenantId,
    CotacaoRepository? repository,
  })  : repo = repository ?? CotacaoRepository(tenantId: tenantId),
        super(CotacaoState.initial());

  final CotacaoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  Future<CotacaoData?> getDataForContract(String contractId) {
    final id = contractId.trim();
    if (id.isEmpty) return Future<CotacaoData?>.value(null);

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
          clearCotacaoId: true,
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
        cotacaoId: ids.cotacaoId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          cotacaoId: ids.cotacaoId,
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
        cotacaoId: ids.cotacaoId,
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
          cotacaoId: ids.cotacaoId,
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
            cotacaoId: ids.cotacaoId,
            sectionIds: ids.sectionIds,
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        cotacaoId: ids.cotacaoId,
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
          cotacaoId: ids.cotacaoId,
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

  Future<List<Attachment>> listAttachments({
    required String contractId,
    String? cotacaoId,
    String? anexosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = (cotacaoId ?? state.cotacaoId ?? '').trim();
    final cleanAnexosId = (anexosId ?? state.currentDocsId ?? '').trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listAttachments(
      contractId: cleanContractId,
      cotacaoId: cleanCotacaoId,
      anexosId: cleanAnexosId,
    );
  }

  Future<Attachment> uploadAttachment({
    required String contractId,
    String? cotacaoId,
    String? anexosId,
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
    final cleanCotacaoId = (cotacaoId ?? state.cotacaoId ?? '').trim();
    final cleanAnexosId = (anexosId ?? state.currentDocsId ?? '').trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty) {
      throw Exception('Caminho inválido para upload da cotação.');
    }

    return repo.uploadAttachment(
      contractId: cleanContractId,
      cotacaoId: cleanCotacaoId,
      anexosId: cleanAnexosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<bool> deleteAttachment({
    required String contractId,
    String? cotacaoId,
    String? anexosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanCotacaoId = (cotacaoId ?? state.cotacaoId ?? '').trim();
    final cleanAnexosId = (anexosId ?? state.currentDocsId ?? '').trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanCotacaoId.isEmpty ||
        cleanAnexosId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteAttachment(
      contractId: cleanContractId,
      cotacaoId: cleanCotacaoId,
      anexosId: cleanAnexosId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteAttachmentByPath(String path) {
    return repo.deleteAttachmentByPath(path);
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