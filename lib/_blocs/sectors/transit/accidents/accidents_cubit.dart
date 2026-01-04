// lib/_blocs/sectors/transit/accidents/accidents_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'accidents_data.dart';
import 'accidents_repository.dart';
import 'accidents_state.dart';

class AccidentsCubit extends Cubit<AccidentsState> {
  final AccidentsRepository repo;

  AccidentsCubit({AccidentsRepository? repository})
      : repo = repository ?? AccidentsRepository(),
        super(AccidentsState.initial());

  // ============================================================
  //                      HELPERS INTERNOS
  // ============================================================

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
    final Map<String, double> out = {};
    for (final a in view) {
      final key = AccidentsData.canonicalType(a.typeOfAccident);
      out[key] = (out[key] ?? 0) + 1.0;
    }
    return out;
  }

  // 🔥 FILTRO EM MEMÓRIA
  List<AccidentsData> _applyLocalFilter(
      List<AccidentsData> universe, {
        int? year,
        int? month,
        String? city,
      }) {
    final normalizedCity = (city?.trim().isNotEmpty == true)
        ? city!.trim().toUpperCase()
        : null;

    return universe.where((a) {
      final date = a.date;
      if (date == null) return false;

      final okYear = year == null || date.year == year;
      final okMonth = month == null || date.month == month;

      final cityCandidate =
      (a.city ?? a.locality ?? '').trim().toUpperCase();

      final okCity = normalizedCity == null || cityCandidate == normalizedCity;

      return okYear && okMonth && okCity;
    }).toList();
  }

  // 🔥 RECOMPILA TUDO E EMITE O ESTADO
  Future<void> _recomputeAndEmit({
    int? page,
    List<AccidentsData>? allOverride,
    int? year,
    int? month,
    String? city,
    bool setYearNull = false,
    bool setMonthNull = false,
    bool setCityNull = false,
  }) async {
    final all = allOverride ?? state.all;

    final view = _sortDescByDate(all);
    final totalPages = _calcTotalPages(view.length, state.limitPerPage);

    final requestedPage = page ?? state.currentPage;
    final curPage = requestedPage.clamp(1, totalPages);
    final pageItems = _slice(view, curPage, state.limitPerPage);

    final totalsByCity = await repo.getValoresPorCidade(view);
    final totalsByType = await repo.getTotaisPorTipoAcidente(view);
    final resumeByType = _resumeMap(view);

    emit(
      state.copyWith(
        loading: false,
        year: year,
        setYearNull: setYearNull,
        month: month,
        setMonthNull: setMonthNull,
        city: city,
        setCityNull: setCityNull,
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
      ),
    );
  }

  // ============================================================
  //                 API PÚBLICA (CORRIGIDA)
  // ============================================================

  /// 1️⃣ Carrega o UNIVERSO completo
  Future<void> warmup({
    int? initialYear,
    int? initialMonth,
    String? initialCity,
  }) async {
    final normalizedCity = (initialCity?.trim().isNotEmpty == true)
        ? initialCity!.trim()
        : null;

    emit(
      state.copyWith(
        loading: true,
        initialized: false,
        year: initialYear,
        setYearNull: initialYear == null,
        month: initialMonth,
        setMonthNull: initialMonth == null,
        city: normalizedCity,
        setCityNull: normalizedCity == null,
        error: null,
        success: null,
        clearLocationSuggestion: true,
        clearLocationError: true,
      ),
    );

    try {
      final universe = await repo.getAllAccidents(
        year: initialYear,
        month: initialMonth,
        city: normalizedCity,
      );

      emit(state.copyWith(universe: universe));

      await _recomputeAndEmit(
        page: 1,
        allOverride: universe,
        year: initialYear,
        month: initialMonth,
        city: normalizedCity,
        setYearNull: initialYear == null,
        setMonthNull: initialMonth == null,
        setCityNull: normalizedCity == null,
      );

      emit(state.copyWith(initialized: true));
    } catch (err, st) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  /// 2️⃣ Filtro em memória (corrigido)
  Future<void> changeFilter({
    int? year,
    int? month,
    String? city,
  }) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        success: null,
        clearLocationSuggestion: true,
        clearLocationError: true,
      ),
    );

    try {
      final normalizedCity =
      (city?.trim().isNotEmpty == true) ? city!.trim() : null;

      // 🔥 filtro local, sem acessar Firestore
      final filtered = _applyLocalFilter(
        state.universe,
        year: year,
        month: month,
        city: normalizedCity,
      );

      await _recomputeAndEmit(
        page: 1,
        allOverride: filtered,
        year: year,
        month: month,
        city: normalizedCity,
        setYearNull: year == null,
        setMonthNull: month == null,
        setCityNull: normalizedCity == null,
      );
    } catch (err, st) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  /// 3️⃣ Paginação (mantida)
  Future<void> changePage(int page) async {
    await _recomputeAndEmit(page: page);
  }

  /// 4️⃣ Salvar → recarrega universe + aplica filtro atual
  Future<void> saveAccident(AccidentsData data) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        clearLocationError: true,
      ),
    );

    try {
      await repo.saveOrUpdateAccident(data);

      final universe = await repo.getAllAccidents();
      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
      );

      emit(state.copyWith(universe: universe));

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Acidente salvo com sucesso!',
          clearLocationSuggestion: true,
        ),
      );
    } catch (err, st) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  /// 5️⃣ Delete → recarrega universe + refiltra
  Future<void> deleteAccident({
    required String id,
    int? yearHint,
  }) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        clearLocationError: true,
      ),
    );

    try {
      final y = yearHint ?? state.year ?? DateTime.now().year;
      await repo.deleteAccident(id: id, year: y);

      final universe = await repo.getAllAccidents();
      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
      );

      emit(state.copyWith(universe: universe));

      final shouldGoBackOnePage = state.currentPage > 1 &&
          _slice(filtered, state.currentPage, state.limitPerPage).isEmpty;

      final nextPage =
      shouldGoBackOnePage ? state.currentPage - 1 : state.currentPage;

      await _recomputeAndEmit(
        page: nextPage,
        allOverride: filtered,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Acidente apagado com sucesso.',
          clearLocationSuggestion: true,
        ),
      );
    } catch (err, st) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  /// 6️⃣ Refresh → sem Firestore, só reprocessa view
  Future<void> refresh() async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        success: null,
        clearLocationError: true,
      ),
    );

    try {
      final filtered = _applyLocalFilter(
        state.universe,
        year: state.year,
        month: state.month,
        city: state.city,
      );

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
      );
    } catch (err, st) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  // =============================
  //         LOCALIZAÇÃO
  // =============================

  Future<void> getCurrentLocation() async {
    emit(
      state.copyWith(
        gettingLocation: true,
        clearLocationSuggestion: true,
        clearLocationError: true,
      ),
    );

    try {
      final suggestion = await repo.resolveCurrentLocation();
      emit(
        state.copyWith(
          gettingLocation: false,
          locationSuggestion: suggestion,
        ),
      );
    } catch (err, st) {
      emit(
        state.copyWith(
          gettingLocation: false,
          locationError: '$err',
          clearLocationSuggestion: true,
        ),
      );
    }
  }

  Future<void> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    emit(
      state.copyWith(
        gettingLocation: true,
        clearLocationSuggestion: true,
        clearLocationError: true,
      ),
    );

    try {
      final suggestion =
      await repo.reverseGeocode(lat: latitude, lon: longitude);

      emit(
        state.copyWith(
          gettingLocation: false,
          locationSuggestion: suggestion,
        ),
      );
    } catch (err, st) {
      emit(
        state.copyWith(
          gettingLocation: false,
          locationError: '$err',
          clearLocationSuggestion: true,
        ),
      );
    }
  }

  Future<void> geocodeCep(String cep) async {
    emit(
      state.copyWith(
        gettingLocation: true,
        clearLocationSuggestion: true,
        clearLocationError: true,
      ),
    );

    try {
      final suggestion = await repo.geocodeCep(cep);

      emit(
        state.copyWith(
          gettingLocation: false,
          locationSuggestion: suggestion,
        ),
      );
    } catch (err, st) {
      emit(
        state.copyWith(
          gettingLocation: false,
          locationError: '$err',
          clearLocationSuggestion: true,
        ),
      );
    }
  }
}
