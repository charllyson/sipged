// lib/_blocs/modules/operation/schedule/horizontal/schedule_linear_cubit.dart

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_repository.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_state.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

class ScheduleLinearApplyTarget {
  const ScheduleLinearApplyTarget({
    required this.estaca,
    required this.faixaIndex,
    this.finalPhotoUrls = const <String>[],
  });

  final int estaca;
  final int faixaIndex;
  final List<String> finalPhotoUrls;
}

class ScheduleLinearCubit extends Cubit<ScheduleLinearState> {
  ScheduleLinearCubit({
    required String tenantId,
    ScheduleLinearRepository? repository,
  })  : _repo = repository ?? ScheduleLinearRepository(tenantId: tenantId),
        super(const ScheduleLinearState());

  final ScheduleLinearRepository _repo;

  bool _warmingUp = false;
  String? _warmingUpContractId;

  String _cleanContractId(String? value) {
    return (value ?? '').trim();
  }

  String _cleanServiceKey(String? value) {
    final clean = (value ?? '').trim();

    if (clean.isEmpty) {
      return ScheduleLinearServicesData.geralKey;
    }

    return clean;
  }

  String? _resolveContractId([String? contractId]) {
    final fromArg = _cleanContractId(contractId);

    if (fromArg.isNotEmpty) {
      return fromArg;
    }

    final fromState = _cleanContractId(state.contractId);

    if (fromState.isNotEmpty) {
      return fromState;
    }

    return null;
  }

  int _totalEstacasFromDfdExtension(double? extensaoDfdMetros) {
    final extensao = extensaoDfdMetros ?? 0.0;

    if (extensao <= 0) {
      return 0;
    }

    return (extensao / ScheduleLinearCellData.metersPerStake).ceil();
  }

  List<String> _serviceKeysForGeral(List<ScheduleLinearServicesData> services) {
    return services
        .where((service) => !service.isGeral)
        .map((service) => service.key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
  }

  String _resolveSelectedServiceKey({
    required String requestedServiceKey,
    required List<ScheduleLinearServicesData> services,
  }) {
    final cleanRequested = _cleanServiceKey(requestedServiceKey);

    if (cleanRequested == ScheduleLinearServicesData.geralKey) {
      return ScheduleLinearServicesData.geralKey;
    }

    final exists = services.any((service) => service.key == cleanRequested);

    if (exists) {
      return cleanRequested;
    }

    return ScheduleLinearServicesData.geralKey;
  }

  ({DateTime? minDate, DateTime? maxDate}) _dateRangeFromCells(
      List<ScheduleLinearCellData> cells,
      ) {
    DateTime? minDate;
    DateTime? maxDate;

    for (final cell in cells) {
      final date = cell.primaryDate;

      if (date == null) continue;

      if (minDate == null || date.isBefore(minDate)) {
        minDate = date;
      }

      if (maxDate == null || date.isAfter(maxDate)) {
        maxDate = date;
      }
    }

    return (minDate: minDate, maxDate: maxDate);
  }

  Future<Map<String, dynamic>?> _pickGeoJsonMap() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>[
        'geojson',
        'json',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Arquivo GeoJSON vazio ou inválido.');
    }

    final content = utf8.decode(bytes);
    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('O arquivo selecionado não é um GeoJSON válido.');
    }

    return decoded;
  }

  Future<void> warmup({
    required String contractId,
    required double? extensaoDfdMetros,
    String? summarySubjectContract,
    String initialServiceKey = ScheduleLinearServicesData.geralKey,
  }) async {
    final cleanContractId = _cleanContractId(contractId);

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          initialized: true,
          error: 'contractId inválido para carregar cronograma.',
        ),
      );
      return;
    }

    if (_warmingUp && _warmingUpContractId == cleanContractId) {
      return;
    }

    _warmingUp = true;
    _warmingUpContractId = cleanContractId;

    try {
      await load(
        contractId: cleanContractId,
        extensaoDfdMetros: extensaoDfdMetros,
        summarySubjectContract: summarySubjectContract,
        selectedServiceKey: initialServiceKey,
      );
    } finally {
      _warmingUp = false;
      _warmingUpContractId = null;
    }
  }

  Future<void> load({
    required String contractId,
    required double? extensaoDfdMetros,
    String? summarySubjectContract,
    String selectedServiceKey = ScheduleLinearServicesData.geralKey,
  }) async {
    final cleanContractId = _cleanContractId(contractId);

    if (cleanContractId.isEmpty) {
      emit(
        state.copyWith(
          initialized: true,
          error: 'contractId inválido para carregar cronograma.',
        ),
      );
      return;
    }

    final sw = Stopwatch()..start();
    final requestedServiceKey = _cleanServiceKey(selectedServiceKey);

    emit(
      state.copyWith(
        initialized: false,
        contractId: cleanContractId,
        summarySubjectContract: summarySubjectContract,
        currentServiceKey: requestedServiceKey,
        loadingServices: true,
        loadingLanes: true,
        loadingExecucoes: true,
        savingOrImporting: false,
        busyReason: 'Carregando cronograma...',
        error: null,
      ),
    );

    try {
      final totalEstacasDfd = _totalEstacasFromDfdExtension(extensaoDfdMetros);

      final geometry = await _repo.fetchProjectGeometry(cleanContractId);

      final services = await _repo.loadAvailableServicesFromBudget(
        cleanContractId,
      );

      final lanes = await _repo.loadFaixas(cleanContractId);

      final cleanServiceKey = _resolveSelectedServiceKey(
        requestedServiceKey: requestedServiceKey,
        services: services,
      );

      final serviceTotals = await _repo.fetchBudgetServiceTotals(
        cleanContractId,
      );

      final physfin = await _repo.loadPhysFinGrid(cleanContractId);

      final serviceKeysForGeral = _serviceKeysForGeral(services);

      final execucoes = await _repo.fetchExecucoes(
        contractId: cleanContractId,
        selectedServiceKey: cleanServiceKey,
        serviceKeysForGeral: serviceKeysForGeral,
      );

      final range = _dateRangeFromCells(execucoes);

      final multiLine = geometry?.multiLine;
      final points = geometry?.points;

      final axis = ScheduleLinearState.axisFrom(
        multiLine: multiLine,
        points: points,
      );

      emit(
        state.copyWith(
          initialized: true,
          contractId: cleanContractId,
          summarySubjectContract:
          summarySubjectContract ?? state.summarySubjectContract,
          totalEstacas: totalEstacasDfd,
          currentServiceKey: cleanServiceKey,
          services: services,
          lanes: lanes,
          execucoes: execucoes,
          execIndex: ScheduleLinearState.buildExecIndex(execucoes),
          minDate: range.minDate,
          maxDate: range.maxDate,
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          error: null,
          geometryType: geometry?.geometryType,
          multiLine: multiLine,
          points: points,
          axis: axis,
          serviceTotals: serviceTotals,
          physfinPeriods: List<int>.from(physfin.periods),
          physfinGrid: Map<String, List<double>>.from(physfin.grid),
          busyReason: null,
        ),
      );

      sw.stop();
    } catch (e) {
      emit(
        state.copyWith(
          initialized: true,
          loadingServices: false,
          loadingLanes: false,
          loadingExecucoes: false,
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao carregar cronograma: $e',
        ),
      );
    }
  }

  Future<void> refresh({
    String? contractId,
    required double? extensaoDfdMetros,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para atualizar cronograma.',
        ),
      );
      return;
    }

    _repo.clearContractCache(cleanContractId);

    await load(
      contractId: cleanContractId,
      extensaoDfdMetros: extensaoDfdMetros,
      summarySubjectContract: state.summarySubjectContract,
      selectedServiceKey: state.currentServiceKey,
    );
  }

  Future<void> reloadExecucoes({
    String? contractId,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para recarregar execuções.',
        ),
      );
      return;
    }

    final sw = Stopwatch()..start();

    emit(
      state.copyWith(
        loadingExecucoes: true,
        busyReason: 'Recarregando execuções...',
        error: null,
      ),
    );

    try {
      final services = state.services.isNotEmpty
          ? state.services
          : await _repo.loadAvailableServicesFromBudget(cleanContractId);

      final cleanServiceKey = _resolveSelectedServiceKey(
        requestedServiceKey: state.currentServiceKey,
        services: services,
      );

      final serviceKeysForGeral = _serviceKeysForGeral(services);

      final execucoes = await _repo.fetchExecucoes(
        contractId: cleanContractId,
        selectedServiceKey: cleanServiceKey,
        serviceKeysForGeral: serviceKeysForGeral,
      );

      final range = _dateRangeFromCells(execucoes);

      emit(
        state.copyWith(
          currentServiceKey: cleanServiceKey,
          execucoes: execucoes,
          execIndex: ScheduleLinearState.buildExecIndex(execucoes),
          minDate: range.minDate,
          maxDate: range.maxDate,
          loadingExecucoes: false,
          busyReason: null,
          error: null,
        ),
      );

      sw.stop();
    } catch (e) {
      emit(
        state.copyWith(
          loadingExecucoes: false,
          busyReason: null,
          error: 'Erro ao recarregar execuções: $e',
        ),
      );
    }
  }

  Future<void> changeService(String serviceKey) async {
    final requestedServiceKey = _cleanServiceKey(serviceKey);

    final cleanContractId = _resolveContractId();

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          currentServiceKey: requestedServiceKey,
          error: 'Contrato inválido para trocar serviço.',
        ),
      );
      return;
    }

    final services = state.services.isNotEmpty
        ? state.services
        : await _repo.loadAvailableServicesFromBudget(cleanContractId);

    final cleanServiceKey = _resolveSelectedServiceKey(
      requestedServiceKey: requestedServiceKey,
      services: services,
    );

    if (cleanServiceKey == state.currentServiceKey) {
      return;
    }

    emit(
      state.copyWith(
        currentServiceKey: cleanServiceKey,
        loadingExecucoes: true,
        selectedPolylineId: null,
        busyReason: 'Carregando serviço...',
        error: null,
      ),
    );

    try {
      final serviceKeysForGeral = _serviceKeysForGeral(services);

      final execucoes = await _repo.fetchExecucoes(
        contractId: cleanContractId,
        selectedServiceKey: cleanServiceKey,
        serviceKeysForGeral: serviceKeysForGeral,
      );

      final range = _dateRangeFromCells(execucoes);

      emit(
        state.copyWith(
          currentServiceKey: cleanServiceKey,
          execucoes: execucoes,
          execIndex: ScheduleLinearState.buildExecIndex(execucoes),
          minDate: range.minDate,
          maxDate: range.maxDate,
          loadingExecucoes: false,
          busyReason: null,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingExecucoes: false,
          busyReason: null,
          error: 'Erro ao trocar serviço: $e',
        ),
      );
    }
  }

  void setSelectedPolyline(String? polylineId) {
    emit(
      state.copyWith(
        selectedPolylineId: polylineId,
      ),
    );
  }

  void setMapZoom(double zoom) {
    if ((state.mapZoom - zoom).abs() < 0.01) return;

    emit(
      state.copyWith(
        mapZoom: zoom,
      ),
    );
  }

  Future<void> saveLanesAndServices({
    String? contractId,
    required List<ScheduleLinearLaneData> lanes,
    required List<ScheduleLinearServicesData> services,
  }) async {
    await saveScheduleConfiguration(
      contractId: contractId,
      lanes: lanes,
      services: services,
    );
  }

  Future<void> saveScheduleConfiguration({
    String? contractId,
    required List<ScheduleLinearLaneData> lanes,
    required List<ScheduleLinearServicesData> services,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar configuração do cronograma.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'Salvando faixas e serviços...',
        error: null,
      ),
    );

    try {
      await _repo.saveScheduleConfiguration(
        contractId: cleanContractId,
        lanes: lanes,
        services: services,
      );

      _repo.clearContractCache(cleanContractId);

      final updatedServices = await _repo.loadAvailableServicesFromBudget(
        cleanContractId,
      );

      final updatedLanes = await _repo.loadFaixas(cleanContractId);

      final serviceKeysForGeral = _serviceKeysForGeral(updatedServices);

      final nextServiceKey = _resolveSelectedServiceKey(
        requestedServiceKey: state.currentServiceKey,
        services: updatedServices,
      );

      final updatedExecucoes = await _repo.fetchExecucoes(
        contractId: cleanContractId,
        selectedServiceKey: nextServiceKey,
        serviceKeysForGeral: serviceKeysForGeral,
      );

      final range = _dateRangeFromCells(updatedExecucoes);

      final serviceTotals = await _repo.fetchBudgetServiceTotals(
        cleanContractId,
      );

      final physfin = await _repo.loadPhysFinGrid(cleanContractId);

      emit(
        state.copyWith(
          initialized: true,
          contractId: cleanContractId,
          currentServiceKey: nextServiceKey,
          services: updatedServices,
          lanes: updatedLanes,
          execucoes: updatedExecucoes,
          execIndex: ScheduleLinearState.buildExecIndex(updatedExecucoes),
          minDate: range.minDate,
          maxDate: range.maxDate,
          serviceTotals: serviceTotals,
          physfinPeriods: List<int>.from(physfin.periods),
          physfinGrid: Map<String, List<double>>.from(physfin.grid),
          servicesRevision: state.servicesRevision + 1,
          lanesRevision: state.lanesRevision + 1,
          savingOrImporting: false,
          busyReason: null,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao salvar faixas e serviços: $e',
        ),
      );
    }
  }

  Future<ScheduleLinearData?> importGeoJson({
    String? contractId,
    Map<String, dynamic>? geojson,
    String? summarySubjectContract,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para importar geometria.',
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'Importando geometria...',
        error: null,
      ),
    );

    try {
      final geojsonMap = geojson ?? await _pickGeoJsonMap();

      if (geojsonMap == null) {
        emit(
          state.copyWith(
            savingOrImporting: false,
            busyReason: null,
            error: null,
          ),
        );

        return null;
      }

      final imported = await _repo.importGeoJson(
        contractId: cleanContractId,
        geojson: geojsonMap,
        summarySubjectContract:
        summarySubjectContract ?? state.summarySubjectContract,
      );

      _repo.clearContractCache(cleanContractId);

      final geometry = await _repo.fetchProjectGeometry(cleanContractId);

      final multiLine = geometry?.multiLine;
      final points = geometry?.points;

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          geometryType: geometry?.geometryType,
          multiLine: multiLine,
          points: points,
          axis: ScheduleLinearState.axisFrom(
            multiLine: multiLine,
            points: points,
          ),
          geometryRevision: state.geometryRevision + 1,
          error: null,
        ),
      );

      return imported;
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao importar geometria: $e',
        ),
      );

      return null;
    }
  }

  Future<void> deleteProjectGeometry({
    String? contractId,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para excluir geometria.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'Excluindo geometria...',
        error: null,
      ),
    );

    try {
      await _repo.deleteProjectGeometry(cleanContractId);

      _repo.clearContractCache(cleanContractId);

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          geometryType: null,
          multiLine: null,
          points: null,
          axis: const <LatLng>[],
          geometryRevision: state.geometryRevision + 1,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao excluir geometria: $e',
        ),
      );
    }
  }

  Future<List<String>> applySquareChanges({
    String? contractId,
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
    required ScheduleLinearCellStatus status,
    String? comentario,
    DateTime? takenAtForNew,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
    bool reloadAfter = true,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar execução.',
        ),
      );
      return const <String>[];
    }

    final cleanServiceKey = _cleanServiceKey(serviceKey);

    if (cleanServiceKey == ScheduleLinearServicesData.geralKey) {
      emit(
        state.copyWith(
          error:
          'A visão GERAL é apenas consolidada. Selecione um serviço específico para editar.',
        ),
      );
      return const <String>[];
    }

    final sw = Stopwatch()..start();

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'Salvando execução...',
        error: null,
      ),
    );

    try {
      final uploadedUrls = await _repo.applySquareChanges(
        contractId: cleanContractId,
        serviceKey: cleanServiceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
        status: status,
        comentario: comentario,
        takenAtForNew: takenAtForNew,
        finalPhotoUrls: finalPhotoUrls,
        newFilesBytes: newFilesBytes,
        newFileNames: newFileNames,
        newPhotoMetas: newPhotoMetas,
        currentUserId: currentUserId,
        clearCacheAfter: true,
      );

      if (reloadAfter) {
        await reloadExecucoes(contractId: cleanContractId);
      }

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          execRevision: state.execRevision + 1,
          error: null,
        ),
      );

      sw.stop();

      return uploadedUrls;
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao salvar execução: $e',
        ),
      );

      return const <String>[];
    }
  }

  Future<void> applySquareChangesBatch({
    String? contractId,
    required String serviceKey,
    required List<ScheduleLinearApplyTarget> targets,
    required ScheduleLinearCellStatus status,
    String? comentario,
    DateTime? takenAtForNew,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar execuções.',
        ),
      );
      return;
    }

    final cleanServiceKey = _cleanServiceKey(serviceKey);

    if (cleanServiceKey == ScheduleLinearServicesData.geralKey) {
      emit(
        state.copyWith(
          error:
          'A visão GERAL é apenas consolidada. Selecione um serviço específico para editar.',
        ),
      );
      return;
    }

    if (targets.isEmpty) {
      emit(
        state.copyWith(
          error: 'Nenhuma célula selecionada para salvar.',
        ),
      );
      return;
    }

    final swTotal = Stopwatch()..start();

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: targets.length == 1
            ? 'Salvando execução...'
            : 'Salvando ${targets.length} execuções...',
        error: null,
      ),
    );

    try {
      for (int i = 0; i < targets.length; i++) {
        final swItem = Stopwatch()..start();
        final target = targets[i];

        await _repo.applySquareChanges(
          contractId: cleanContractId,
          serviceKey: cleanServiceKey,
          estaca: target.estaca,
          faixaIndex: target.faixaIndex,
          status: status,
          comentario: comentario,
          takenAtForNew: takenAtForNew,
          finalPhotoUrls: target.finalPhotoUrls,
          newFilesBytes: targets.length > 1 ? const <Uint8List>[] : newFilesBytes,
          newFileNames: targets.length > 1 ? null : newFileNames,
          newPhotoMetas:
          targets.length > 1 ? const <pm.CarouselMetadata>[] : newPhotoMetas,
          currentUserId: currentUserId,
          clearCacheAfter: false,
        );

        swItem.stop();
      }

      _repo.clearExecCache(cleanContractId);

      final swReload = Stopwatch()..start();

      await reloadExecucoes(contractId: cleanContractId);

      swReload.stop();

      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          execRevision: state.execRevision + 1,
          error: null,
        ),
      );

      swTotal.stop();
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao salvar execuções em lote: $e',
        ),
      );
    }
  }

  Future<void> applySquareToCell({
    String? contractId,
    required int estaca,
    required int faixaIndex,
    required String tipoLabel,
    required ScheduleLinearCellStatus status,
    String? comentario,
    DateTime? takenAt,
    required List<String> finalPhotoUrls,
    required List<Uint8List> newFilesBytes,
    List<String>? newFileNames,
    List<pm.CarouselMetadata> newPhotoMetas = const [],
    required String currentUserId,
    bool reloadAfter = true,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar execução.',
        ),
      );
      return;
    }

    final serviceKey = _cleanServiceKey(state.currentServiceKey);

    if (serviceKey == ScheduleLinearServicesData.geralKey) {
      emit(
        state.copyWith(
          error:
          'A visão GERAL é apenas consolidada. Selecione um serviço específico para editar.',
        ),
      );
      return;
    }

    await applySquareChanges(
      contractId: cleanContractId,
      serviceKey: serviceKey,
      estaca: estaca,
      faixaIndex: faixaIndex,
      status: status,
      comentario: comentario,
      takenAtForNew: takenAt,
      finalPhotoUrls: finalPhotoUrls,
      newFilesBytes: newFilesBytes,
      newFileNames: newFileNames,
      newPhotoMetas: newPhotoMetas,
      currentUserId: currentUserId,
      reloadAfter: reloadAfter,
    );
  }

  Future<void> updatePhysFinGrid({
    required List<int> periods,
    required Map<String, List<double>> grid,
  }) async {
    await savePhysFinGrid(
      periods: periods,
      grid: grid,
    );
  }

  Future<void> savePhysFinGrid({
    String? contractId,
    required List<int> periods,
    required Map<String, List<double>> grid,
    String? updatedBy,
  }) async {
    final cleanContractId = _resolveContractId(contractId);

    if (cleanContractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar físico-financeiro.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savingOrImporting: true,
        busyReason: 'Salvando físico-financeiro...',
        error: null,
      ),
    );

    try {
      final normalizedGrid = <String, List<double>>{};

      for (final entry in grid.entries) {
        final key = entry.key.trim();

        if (key.isEmpty || key == ScheduleLinearServicesData.geralKey) {
          continue;
        }

        normalizedGrid[key] = List<double>.from(entry.value);
      }

      await _repo.savePhysFinGrid(
        contractId: cleanContractId,
        periods: List<int>.from(periods),
        grid: normalizedGrid,
        updatedBy: updatedBy,
      );

      final physfin = await _repo.loadPhysFinGrid(cleanContractId);

      emit(
        state.copyWith(
          physfinPeriods: List<int>.from(physfin.periods),
          physfinGrid: Map<String, List<double>>.from(physfin.grid),
          physfinRevision: state.physfinRevision + 1,
          savingOrImporting: false,
          busyReason: null,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          savingOrImporting: false,
          busyReason: null,
          error: 'Erro ao salvar físico-financeiro: $e',
        ),
      );
    }
  }

  bool _isDoneOrInProgressCell(ScheduleLinearCellData cell) {
    return cell.isConcluido || cell.isEmAndamento;
  }

  void setDateFilter({
    required List<ScheduleLinearCellData> cells,
    String? label,
  }) {
    final keys = cells
        .where(_isDoneOrInProgressCell)
        .map((cell) => cell.cellKey)
        .toSet();

    emit(
      state.copyWith(
        dateFilterActive: true,
        dateFilterCellKeys: keys,
        dateFilterLabel: label,
      ),
    );
  }

  void clearDateFilter() {
    if (!state.dateFilterActive &&
        state.dateFilterCellKeys.isEmpty &&
        state.dateFilterLabel == null) {
      return;
    }

    emit(
      state.copyWith(
        dateFilterActive: false,
        dateFilterCellKeys: const <String>{},
        dateFilterLabel: null,
      ),
    );
  }

  void clear() {
    _warmingUp = false;
    _warmingUpContractId = null;

    final cleanContractId = _cleanContractId(state.contractId);

    if (cleanContractId.isNotEmpty) {
      _repo.clearContractCache(cleanContractId);
    }

    emit(const ScheduleLinearState());
  }
}