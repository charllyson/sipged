import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/process/hiring/_shared/sections_types.dart';
import 'dfd_repository.dart';

part 'dfd_event.dart';
part 'dfd_state.dart';

class DfdBloc extends Bloc<DfdEvent, DfdState> {
  final DfdRepository repo;

  DfdBloc(this.repo) : super(DfdState.initial()) {
    on<DfdLoadRequested>(_onLoad);
    on<DfdSaveRequested>(_onSaveAll);
    on<DfdSaveOneSectionRequested>(_onSaveOne);

    on<DfdClearSuccessRequested>((e, emit) {
      if (state.saveSuccess) emit(state.copyWith(saveSuccess: false));
    });

    on<DfdReadLightFieldsRequested>(_onReadLightFields);
    on<DfdReadWorkTypeAndExtRequested>(_onReadWorkTypeAndExt); // retrocompat
  }

  Future<void> _onLoad(DfdLoadRequested e, Emitter<DfdState> emit) async {
    emit(state.copyWith(loading: true, error: null, saveSuccess: false));
    try {
      final ids = await repo.ensureDfdStructure(e.contractId);
      final data = await repo.loadAllSections(
        contractId: e.contractId,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
      );
      final leve = await repo.readLightFields(e.contractId);

      emit(state.copyWith(
        loading: false,
        dfdId: ids.dfdId,
        sectionIds: ids.sectionIds,
        sectionsData: data,
        workType: leve.tipoObra,
        extensaoKm: leve.extensaoKm,
        contractStatus: leve.status,
      ));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }

  Future<void> _onSaveAll(DfdSaveRequested e, Emitter<DfdState> emit) async {
    if (!state.hasValidPath) return;
    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSectionsBatch(
        contractId: e.contractId,
        dfdId: state.dfdId!,
        sectionIds: state.sectionIds,
        sectionsData: e.sectionsData,
      );

      final merged = {...state.sectionsData};
      e.sectionsData.forEach((k, v) {
        merged[k] = {...(merged[k] ?? const {}), ...v};
      });

      final novoWorkType = e.sectionsData['objeto']?['tipoObra'] as String?;
      final novoExt = e.sectionsData['localizacao']?['extensaoKm'];
      final novoStatus = e.sectionsData['identificacao']?['statusContrato'] as String?;

      emit(state.copyWith(
        saving: false,
        saveSuccess: true,
        sectionsData: merged,
        workType: novoWorkType ?? state.workType,
        extensaoKm: (novoExt is num)
            ? novoExt.toDouble()
            : (novoExt is String
            ? double.tryParse(
          novoExt.replaceAll('.', '').replaceAll(',', '.').trim(),
        ) ?? state.extensaoKm
            : state.extensaoKm),
        contractStatus: (novoStatus != null && novoStatus.trim().isNotEmpty)
            ? novoStatus.trim()
            : state.contractStatus,
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, saveSuccess: false, error: err.toString()));
    }
  }

  Future<void> _onSaveOne(
      DfdSaveOneSectionRequested e,
      Emitter<DfdState> emit,
      ) async {
    if (!state.hasValidPath) return;
    final sectionId = state.sectionIds[e.sectionKey];
    if (sectionId == null) {
      emit(state.copyWith(error: 'Seção inválida: ${e.sectionKey}'));
      return;
    }

    emit(state.copyWith(saving: true, saveSuccess: false, error: null));
    try {
      await repo.saveSection(
        contractId: e.contractId,
        dfdId: state.dfdId!,
        sectionKey: e.sectionKey,
        sectionDocId: sectionId,
        data: e.data,
      );

      final merged = {...state.sectionsData};
      merged[e.sectionKey] = {...(merged[e.sectionKey] ?? const {}), ...e.data};

      String? workType = state.workType;
      double? extKm = state.extensaoKm;
      String? status = state.contractStatus;

      if (e.sectionKey == 'objeto') {
        final v = (e.data['tipoObra'] ?? '').toString().trim();
        if (v.isNotEmpty) workType = v;
      } else if (e.sectionKey == 'localizacao') {
        final raw = e.data['extensaoKm'];
        if (raw is num) {
          extKm = raw.toDouble();
        } else if (raw is String) {
          final parsed = double.tryParse(raw.replaceAll('.', '').replaceAll(',', '.').trim());
          if (parsed != null) extKm = parsed;
        }
      } else if (e.sectionKey == 'identificacao') {
        final v = (e.data['statusContrato'] ?? '').toString().trim();
        if (v.isNotEmpty) status = v;
      }

      emit(state.copyWith(
        saving: false,
        saveSuccess: true,
        sectionsData: merged,
        workType: workType,
        extensaoKm: extKm,
        contractStatus: status,
      ));
    } catch (err) {
      emit(state.copyWith(saving: false, saveSuccess: false, error: err.toString()));
    }
  }

  Future<void> _onReadLightFields(
      DfdReadLightFieldsRequested e,
      Emitter<DfdState> emit,
      ) async {
    try {
      final res = await repo.readLightFields(e.contractId);
      emit(state.copyWith(
        workType: res.tipoObra,
        extensaoKm: res.extensaoKm,
        contractStatus: res.status,
      ));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }

  // Retrocompat
  Future<void> _onReadWorkTypeAndExt(
      DfdReadWorkTypeAndExtRequested e,
      Emitter<DfdState> emit,
      ) async {
    try {
      final res = await repo.readWorkTypeAndExtent(e.contractId);
      emit(state.copyWith(workType: res.tipoObra, extensaoKm: res.extensaoKm));
    } catch (err) {
      emit(state.copyWith(error: err.toString()));
    }
  }
}
