import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

import 'publicacao_extrato_data.dart';
import 'publicacao_extrato_repository.dart';
import 'publicacao_extrato_state.dart';

class PublicacaoExtratoCubit extends Cubit<PublicacaoExtratoState> {
  PublicacaoExtratoCubit({
    required String tenantId,
    PublicacaoExtratoRepository? repository,
  })  : _tenantId = _requireTenantId(tenantId),
        repo = repository ??
            PublicacaoExtratoRepository(
              tenantId: _requireTenantId(tenantId),
            ),
        super(PublicacaoExtratoState.initial());

  final String _tenantId;
  final PublicacaoExtratoRepository repo;

  int _loadSeq = 0;
  int _saveSeq = 0;

  bool get _alive => !isClosed;

  static String _requireTenantId(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId é obrigatório em PublicacaoExtratoCubit.');
    }

    return cleanTenantId;
  }

  String get tenantId => _tenantId;

  Future<PublicacaoExtratoData?> getDataForContract(String contractId) {
    final cleanContractId = contractId.trim();

    if (cleanContractId.isEmpty) {
      return Future<PublicacaoExtratoData?>.value(null);
    }

    return repo.readDataForContract(cleanContractId);
  }

  Future<Map<String, PublicacaoExtratoData?>> getSummaryForContracts(
      Iterable<String> contractIds, {
        bool debug = false,
      }) async {
    final ids = contractIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final initial = <String, PublicacaoExtratoData?>{
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
          '[PublicacaoExtratoCubit] getSummaryForContracts '
              'tenantId=$tenantId contratos=${ids.length} '
              'em ${sw.elapsedMilliseconds}ms',
        );
      }

      return <String, PublicacaoExtratoData?>{
        ...initial,
        ...result,
      };
    } catch (error, stack) {
      sw.stop();

      debugPrint(
        '[PublicacaoExtratoCubit] Erro getSummaryForContracts '
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
          clearPubId: true,
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
        pubId: ids.pubId,
        sectionIds: ids.sectionIds,
      );

      if (!_alive || reqId != _loadSeq) return;

      emit(
        state.copyWith(
          loading: false,
          saving: false,
          saveSuccess: false,
          contractId: cleanContractId,
          pubId: ids.pubId,
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
        pubId: ids.pubId,
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
          pubId: ids.pubId,
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
            pubId: ids.pubId,
            sectionIds: ids.sectionIds,
            error: 'Seção inválida: $cleanSectionKey',
          ),
        );
        return;
      }

      if (!_alive || reqId != _saveSeq) return;

      await repo.saveSection(
        contractId: cleanContractId,
        pubId: ids.pubId,
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
          pubId: ids.pubId,
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
    String? pubId,
    String? veiculoDocId,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = (pubId ?? state.pubId ?? '').trim();
    final cleanVeiculoDocId =
    (veiculoDocId ??
        state.sectionIds[PublicacaoExtratoData.sectionVeiculo] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty) {
      return const <Attachment>[];
    }

    return repo.listFiles(
      contractId: cleanContractId,
      pubId: cleanPubId,
      veiculoDocId: cleanVeiculoDocId,
    );
  }

  Future<List<Attachment>> listVeiculoFiles({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
  }) {
    return listFiles(
      contractId: contractId,
      pubId: pubId,
      veiculoDocId: veiculoDocId,
    );
  }

  Future<Attachment> uploadFile({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
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
    final cleanPubId = (pubId ?? state.pubId ?? '').trim();
    final cleanVeiculoDocId =
    (veiculoDocId ??
        state.sectionIds[PublicacaoExtratoData.sectionVeiculo] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty) {
      throw Exception('Caminho inválido para upload da publicação.');
    }

    return repo.uploadFile(
      contractId: cleanContractId,
      pubId: cleanPubId,
      veiculoDocId: cleanVeiculoDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadVeiculoFile({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
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
      pubId: pubId,
      veiculoDocId: veiculoDocId,
      onProgress: onProgress,
      allowedExtensions: allowedExtensions,
    );
  }

  Future<Attachment> uploadBytes({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
    required Uint8List bytes,
    required String fileName,
    required void Function(double progress) onProgress,
    SettableMetadata? metadata,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = (pubId ?? state.pubId ?? '').trim();
    final cleanVeiculoDocId =
    (veiculoDocId ??
        state.sectionIds[PublicacaoExtratoData.sectionVeiculo] ??
        '')
        .trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty) {
      throw Exception('Caminho inválido para upload da publicação.');
    }

    return repo.uploadBytes(
      contractId: cleanContractId,
      pubId: cleanPubId,
      veiculoDocId: cleanVeiculoDocId,
      bytes: bytes,
      fileName: fileName,
      onProgress: onProgress,
      metadata: metadata,
    );
  }

  Future<bool> deleteFile({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
    required String fileName,
  }) async {
    final cleanContractId = contractId.trim();
    final cleanPubId = (pubId ?? state.pubId ?? '').trim();
    final cleanVeiculoDocId =
    (veiculoDocId ??
        state.sectionIds[PublicacaoExtratoData.sectionVeiculo] ??
        '')
        .trim();
    final cleanFileName = fileName.trim();

    if (cleanContractId.isEmpty ||
        cleanPubId.isEmpty ||
        cleanVeiculoDocId.isEmpty ||
        cleanFileName.isEmpty) {
      return false;
    }

    return repo.deleteFile(
      contractId: cleanContractId,
      pubId: cleanPubId,
      veiculoDocId: cleanVeiculoDocId,
      fileName: cleanFileName,
    );
  }

  Future<bool> deleteVeiculoFile({
    required String contractId,
    String? pubId,
    String? veiculoDocId,
    required String fileName,
  }) {
    return deleteFile(
      contractId: contractId,
      pubId: pubId,
      veiculoDocId: veiculoDocId,
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