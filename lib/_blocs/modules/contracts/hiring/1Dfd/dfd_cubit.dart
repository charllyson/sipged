// lib/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'dfd_data.dart';
import 'dfd_repository.dart';
import 'dfd_state.dart';

class DfdCubit extends Cubit<DfdState> {
  DfdCubit({
    required String tenantId,
    DfdRepository? repository,
  })  : _tenantId = _validateTenantId(tenantId),
        repo = repository ??
            DfdRepository(
              tenantId: _validateTenantId(tenantId),
            ),
        super(
        DfdState.initial(
          tenantId: _validateTenantId(tenantId),
        ),
      );

  final String _tenantId;
  final DfdRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  String get tenantId => _tenantId;

  static String _validateTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório para DfdCubit.');
    }

    return cleanTenantId;
  }

  Future<DfdData?> getDataForContract(String contractId) {
    final id = contractId.trim();

    if (id.isEmpty) return Future<DfdData?>.value(null);

    return repo.readDataForContract(id);
  }

  /// Carregamento resumido em lote para telas de listagem/dashboard.
  ///
  /// Usado pela ListDemandPage para evitar 1 leitura completa por contrato.
  /// Depende do método:
  ///
  /// DfdRepository.readDataForContractsSummary(...)
  Future<Map<String, DfdData?>> getSummaryForContracts(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final ids = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (ids.isEmpty) {
      return const <String, DfdData?>{};
    }

    final sw = Stopwatch()..start();

    try {
      final result = await repo.readDataForContractsSummary(
        ids,
        debug: debug,
      );

      sw.stop();

      if (debug) {
        debugPrint(
          '[DfdCubit] getSummaryForContracts | '
              'tenantId=$tenantId | '
              'contratos=${ids.length} | '
              'retorno=${result.length} | '
              'tempo=${sw.elapsedMilliseconds}ms',
        );
      }

      return result;
    } catch (error, stack) {
      sw.stop();

      debugPrint(
        '[DfdCubit] Erro em getSummaryForContracts | '
            'tenantId=$tenantId | '
            'contratos=${ids.length} | '
            'tempo=${sw.elapsedMilliseconds}ms | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      return <String, DfdData?>{
        for (final id in ids) id: null,
      };
    }
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
          clearDfdId: true,
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
        tenantId: _tenantId,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _loadSeq) return;

      final data = await repo.loadAllSections(
        contractId: cleanContractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          tenantId: _tenantId,
          contractId: cleanContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      if (!_alive || reqId != _loadSeq) return;

      debugPrint(
        '[DfdCubit] Erro em load | '
            'tenantId=$tenantId | '
            'contractId=$cleanContractId | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

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
        tenantId: _tenantId,
        contractId: cleanContractId,
        clearError: true,
      ),
    );

    try {
      final ids = await repo.ensureStructure(cleanContractId);

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSectionsBatch(
        contractId: cleanContractId,
        dfdId: ids.dfdId,
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
          tenantId: _tenantId,
          contractId: cleanContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      if (!_alive || reqId != _saveSeq) return;

      debugPrint(
        '[DfdCubit] Erro em saveAll | '
            'tenantId=$tenantId | '
            'contractId=$cleanContractId | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<String?> saveAllWithAutoContract({
    String? contractId,
    required DfdData data,
  }) async {
    final reqId = ++_saveSeq;

    emit(
      state.copyWith(
        saving: true,
        loading: false,
        saveSuccess: false,
        tenantId: _tenantId,
        clearError: true,
      ),
    );

    try {
      final baseContractId = contractId?.trim().isNotEmpty == true
          ? contractId!.trim()
          : state.contractId;

      final finalContractId = await repo.ensureContractAndSaveDfd(
        contractId: baseContractId,
        data: data,
      );

      if (!_alive || reqId != _saveSeq) return finalContractId;

      final ids = await repo.ensureStructure(finalContractId);

      if (!_alive || reqId != _saveSeq) return finalContractId;

      emit(
        state.copyWith(
          saving: false,
          loading: false,
          saveSuccess: true,
          tenantId: _tenantId,
          contractId: finalContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: data.toSectionsMap(),
          clearError: true,
        ),
      );

      return finalContractId;
    } catch (error, stack) {
      if (!_alive || reqId != _saveSeq) return null;

      debugPrint(
        '[DfdCubit] Erro em saveAllWithAutoContract | '
            'tenantId=$tenantId | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );

      return null;
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
        tenantId: _tenantId,
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
            tenantId: _tenantId,
            error: 'Seção inválida: $cleanSectionKey',
            dfdId: ids.dfdId,
            sectionIds: ids.sectionIds,
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        dfdId: ids.dfdId,
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
          tenantId: _tenantId,
          contractId: cleanContractId,
          dfdId: ids.dfdId,
          sectionIds: ids.sectionIds,
          sectionsData: merged,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      if (!_alive || reqId != _saveSeq) return;

      debugPrint(
        '[DfdCubit] Erro em saveOneSection | '
            'tenantId=$tenantId | '
            'contractId=$cleanContractId | '
            'sectionKey=$cleanSectionKey | '
            'erro=$error',
      );
      debugPrintStack(stackTrace: stack);

      emit(
        state.copyWith(
          saving: false,
          saveSuccess: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<List<Attachment>> listarDocsDfd({
    required String contractId,
    String? dfdId,
    String? documentosId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = (dfdId ?? state.dfdId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DfdData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listarDocsDfd(
      contractId: cleanContractId,
      dfdId: cleanDfdId,
      documentosId: cleanDocumentosId,
    );
  }

  Future<Attachment> uploadDocDfd({
    required String contractId,
    String? dfdId,
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
    final cleanDfdId = (dfdId ?? state.dfdId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DfdData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty) {
      throw Exception('Caminho inválido para upload do DFD.');
    }

    return repo.uploadDocDfd(
      contractId: cleanContractId,
      dfdId: cleanDfdId,
      documentosId: cleanDocumentosId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<bool> deleteDocDfd({
    required String contractId,
    String? dfdId,
    String? documentosId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanDfdId = (dfdId ?? state.dfdId ?? '').trim();
    final cleanDocumentosId =
    (documentosId ?? state.sectionIds[DfdData.sectionDocumentos] ?? '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanDfdId.isEmpty ||
        cleanDocumentosId.isEmpty ||
        fileName.trim().isEmpty) {
      return false;
    }

    return repo.deleteDocDfd(
      contractId: cleanContractId,
      dfdId: cleanDfdId,
      documentosId: cleanDocumentosId,
      fileName: fileName,
    );
  }

  Future<bool> deleteDocDfdByPath(String path) {
    return repo.deleteDocDfdByPath(path);
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