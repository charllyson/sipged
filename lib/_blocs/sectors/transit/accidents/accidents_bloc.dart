// lib/_blocs/sectors/transit/accidents/accidents_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_event.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_repository.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';

class AccidentsBloc extends Bloc<AccidentsEvent, AccidentsState> {
  final AccidentsRepository _repo;

  AccidentsBloc({AccidentsRepository? repository})
      : _repo = repository ?? AccidentsRepository(),
        super(const AccidentsState()) {
    on<AccidentsWarmupRequested>(_onWarmup);
    on<AccidentsFilterChanged>(_onFilterChanged);
    on<AccidentsPageRequested>(_onPageRequested);
    on<AccidentsSaveRequested>(_onSave);
    on<AccidentsDeleteRequested>(_onDelete);
    on<AccidentsRefreshRequested>(_onRefresh);
  }

  // ================= Helpers =================
  List<AccidentsData> _sortDescByDate(List<AccidentsData> list) {
    final cp = List<AccidentsData>.from(list);
    cp.sort((a, b) {
      final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return cp;
  }

  List<AccidentsData> _slice(List<AccidentsData> list, int page, int limit) {
    if (list.isEmpty) return const [];
    final start = (page - 1) * limit;
    if (start >= list.length) return const [];
    final end = (start + limit) > list.length ? list.length : (start + limit);
    return list.sublist(start, end);
  }

  int _calcTotalPages(int totalDocs, int limit) =>
      totalDocs == 0 ? 1 : ((totalDocs + limit - 1) ~/ limit);

  Map<String, double> _resumeMap(List<AccidentsData> view) {
    // mesmo shape esperado pelos cards do summary (tipo -> double)
    final Map<String, double> out = {};
    for (final a in view) {
      final t = (a.typeOfAccident ?? '').trim().toUpperCase();
      if (t.isEmpty) continue;
      final key = AccidentsData.getTitleByAccidentType(t).toUpperCase() == 'OUTROS'
          ? 'OUTROS'
          : t;
      out[key] = (out[key] ?? 0) + 1.0;
    }
    return out;
  }

  Future<void> _recomputeAndEmit({
    required Emitter<AccidentsState> emit,
    required int page,
    List<AccidentsData>? allOverride,
    int? year,
    int? month,
    String? city,
  }) async {
    final all = allOverride ?? state.all;
    final view = _sortDescByDate(all);
    final totalPages = _calcTotalPages(view.length, state.limitPerPage);
    final curPage = page.clamp(1, totalPages);
    final pageItems = _slice(view, curPage, state.limitPerPage);

    final totalsByCity = await _repo.getValoresPorCidade(view);
    final totalsByType = await _repo.getTotaisPorTipoAcidente(view);
    final resumeByType = _resumeMap(view);

    emit(state.copyWith(
      loading: false,
      year: year ?? state.year,
      month: month ?? state.month,
      city: city ?? state.city,
      all: all,
      view: view,
      pageItems: pageItems,
      currentPage: curPage,
      totalPages: totalPages,
      totalsByCity: totalsByCity,
      totalsByType: totalsByType,
      resumeByType: resumeByType,
      error: null,
      success: null,
    ));
  }

  // ================= Handlers =================

  Future<void> _onWarmup(
      AccidentsWarmupRequested e,
      Emitter<AccidentsState> emit,
      ) async {
    emit(state.copyWith(
      loading: true,
      initialized: false,
      year: e.initialYear ?? DateTime.now().year,
      month: e.initialMonth,
      city: (e.initialCity?.trim().isEmpty ?? true) ? null : e.initialCity!.trim(),
      error: null,
      success: null,
    ));

    try {
      // Universo SEM filtros (para o seletor) — fica guardado
      final universe = await _repo.getAllAccidents();

      // Lista filtrada conforme filtros iniciais
      final filtered = await _repo.getAllAccidents(
        year: state.year,
        month: state.month,
        city: state.city,
      );

      // Primeira emissão: universe + placeholder para não piscar
      emit(state.copyWith(universe: universe));

      await _recomputeAndEmit(
        emit: emit,
        page: 1,
        allOverride: filtered,
      );

      emit(state.copyWith(initialized: true));
    } catch (err, st) {
      debugPrint('Warmup error: $err\n$st');
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  Future<void> _onFilterChanged(
      AccidentsFilterChanged e,
      Emitter<AccidentsState> emit,
      ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final nextYear = e.year;
      final nextMonth = e.month;
      final nextCity = (e.city?.trim().isEmpty ?? true) ? null : e.city!.trim();

      // NUNCA mexe em state.universe aqui
      final filtered = await _repo.getAllAccidents(
        year: nextYear,
        month: nextMonth,
        city: nextCity,
      );

      await _recomputeAndEmit(
        emit: emit,
        page: 1,
        allOverride: filtered,
        year: nextYear,
        month: nextMonth,
        city: nextCity,
      );
    } catch (err, st) {
      debugPrint('Filter error: $err\n$st');
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  Future<void> _onPageRequested(
      AccidentsPageRequested e,
      Emitter<AccidentsState> emit,
      ) async {
    // paginação é local — sem hits na rede
    await _recomputeAndEmit(emit: emit, page: e.page);
  }

  Future<void> _onSave(
      AccidentsSaveRequested e,
      Emitter<AccidentsState> emit,
      ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      await _repo.saveOrUpdateAccident(e.data);

      // Recarrega universo (opcional) e filtrados (obrigatório)
      // Se o volume for grande e você quiser economizar, pode pular o universo
      final universe = await _repo.getAllAccidents();
      final filtered = await _repo.getAllAccidents(
        year: state.year,
        month: state.month,
        city: state.city,
      );

      emit(state.copyWith(universe: universe));
      await _recomputeAndEmit(emit: emit, page: state.currentPage, allOverride: filtered);

      emit(state.copyWith(saving: false, success: 'Acidente salvo com sucesso!'));
    } catch (err, st) {
      debugPrint('Save error: $err\n$st');
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  Future<void> _onDelete(
      AccidentsDeleteRequested e,
      Emitter<AccidentsState> emit,
      ) async {
    emit(state.copyWith(saving: true, error: null, success: null));
    try {
      final y = e.yearHint ?? state.year ?? DateTime.now().year;
      await _repo.deleteAccident(id: e.id, year: y);

      // Recarrega
      final universe = await _repo.getAllAccidents();
      final filtered = await _repo.getAllAccidents(
        year: state.year,
        month: state.month,
        city: state.city,
      );

      emit(state.copyWith(universe: universe));
      await _recomputeAndEmit(
        emit: emit,
        page: state.currentPage > 1 && _slice(filtered, state.currentPage, state.limitPerPage).isEmpty
            ? state.currentPage - 1
            : state.currentPage,
        allOverride: filtered,
      );

      emit(state.copyWith(saving: false, success: 'Acidente apagado com sucesso.'));
    } catch (err, st) {
      debugPrint('Delete error: $err\n$st');
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  Future<void> _onRefresh(
      AccidentsRefreshRequested e,
      Emitter<AccidentsState> emit,
      ) async {
    emit(state.copyWith(loading: true, error: null, success: null));
    try {
      final filtered = await _repo.getAllAccidents(
        year: state.year,
        month: state.month,
        city: state.city,
      );
      await _recomputeAndEmit(emit: emit, page: state.currentPage, allOverride: filtered);
    } catch (err, st) {
      debugPrint('Refresh error: $err\n$st');
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }
}
