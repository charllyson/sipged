import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'edital_data.dart';
import 'edital_repository.dart';
import 'edital_state.dart';

class EditalCubit extends Cubit<EditalState> {
  EditalCubit({
    required String tenantId,
    EditalRepository? repository,
  })  : _tenantId = _requireTenantId(tenantId),
        repo = repository ??
            EditalRepository(
              tenantId: _requireTenantId(tenantId),
            ),
        super(EditalState.initial());

  final String _tenantId;
  final EditalRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  String get tenantId => _tenantId;

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em EditalCubit.');
    }

    return cleanTenantId;
  }

  Future<EditalData?> getDataForContract(String contractId) {
    final id = contractId.trim();

    if (id.isEmpty) {
      return Future<EditalData?>.value(null);
    }

    return repo.readDataForContract(id);
  }

  Future<Map<String, EditalData?>> getSummaryForContracts(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final ids = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final initial = <String, EditalData?>{
      for (final id in ids) id: null,
    };

    if (ids.isEmpty) {
      return initial;
    }

    final sw = Stopwatch()..start();

    try {
      final result = await repo.getSummaryForContracts(
        ids,
        debug: debug,
      );

      sw.stop();

      if (debug) {
        debugPrint(
          '[EditalCubit] getSummaryForContracts '
              'tenantId=$tenantId contratos=${ids.length} '
              'em ${sw.elapsedMilliseconds}ms',
        );
      }

      return <String, EditalData?>{
        ...initial,
        ...result,
      };
    } catch (error, stack) {
      sw.stop();

      debugPrint(
        '[EditalCubit] Erro getSummaryForContracts '
            'tenantId=$tenantId contratos=${ids.length} '
            'em ${sw.elapsedMilliseconds}ms: $error',
      );
      debugPrintStack(stackTrace: stack);

      return initial;
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
          clearEditalId: true,
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
      final ids = await repo.ensureEditalStructure(cleanContractId);

      if (!_alive || reqId != _loadSeq) return;

      final data = await repo.loadAllSections(
        contractId: cleanContractId,
        editalId: ids.editalId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          editalId: ids.editalId,
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
      final ids = await repo.ensureEditalStructure(cleanContractId);

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSectionsBatch(
        contractId: cleanContractId,
        editalId: ids.editalId,
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
          editalId: ids.editalId,
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
      final ids = await repo.ensureEditalStructure(cleanContractId);
      final sectionId = ids.sectionIds[cleanSectionKey];

      if (sectionId == null || sectionId.trim().isEmpty) {
        if (!_alive || reqId != _saveSeq) return;

        emit(
          state.copyWith(
            saving: false,
            saveSuccess: false,
            error: 'Seção inválida: $cleanSectionKey',
            editalId: ids.editalId,
            sectionIds: ids.sectionIds,
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        editalId: ids.editalId,
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
          editalId: ids.editalId,
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
    String? editalId,
    required String sectionKey,
    String? sectionDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = (editalId ?? state.editalId ?? '').trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId =
    (sectionDocId ?? state.sectionIds[cleanSectionKey] ?? '').trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      editalId: cleanEditalId,
      sectionKey: cleanSectionKey,
      sectionDocId: cleanSectionDocId,
    );
  }

  Future<List<Attachment>> listDocumentFiles({
    required String contractId,
    String? editalId,
    String? sectionDocId,
  }) {
    return listFiles(
      contractId: contractId,
      editalId: editalId,
      sectionKey: EditalData.sectionDocumentos,
      sectionDocId: sectionDocId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? editalId,
    required String sectionKey,
    String? sectionDocId,
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
    final cleanEditalId = (editalId ?? state.editalId ?? '').trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId =
    (sectionDocId ?? state.sectionIds[cleanSectionKey] ?? '').trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty) {
      throw Exception('Caminho inválido para upload do edital.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      editalId: cleanEditalId,
      sectionKey: cleanSectionKey,
      sectionDocId: cleanSectionDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadDocumentFile({
    required String contractId,
    String? editalId,
    String? sectionDocId,
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
      editalId: editalId,
      sectionKey: EditalData.sectionDocumentos,
      sectionDocId: sectionDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? editalId,
    required String sectionKey,
    String? sectionDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanEditalId = (editalId ?? state.editalId ?? '').trim();
    final cleanSectionKey = sectionKey.trim();
    final cleanSectionDocId =
    (sectionDocId ?? state.sectionIds[cleanSectionKey] ?? '').trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanEditalId.isEmpty ||
        cleanSectionKey.isEmpty ||
        cleanSectionDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      editalId: cleanEditalId,
      sectionKey: cleanSectionKey,
      sectionDocId: cleanSectionDocId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteDocumentFile({
    required String contractId,
    String? editalId,
    String? sectionDocId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      editalId: editalId,
      sectionKey: EditalData.sectionDocumentos,
      sectionDocId: sectionDocId,
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