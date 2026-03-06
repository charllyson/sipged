// lib/_blocs/modules/transit/accidents/accidents_cubit.dart
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

  Map<String, double> _resumeMapByType(List<AccidentsData> view) {
    final Map<String, double> out = {};
    for (final a in view) {
      final key = AccidentsData.canonicalType(a.typeOfAccident);
      out[key] = (out[key] ?? 0) + 1.0;
    }
    return out;
  }

  String _severityOf(AccidentsData a) {
    final deaths = (a.death ?? 0);
    if (deaths > 0) return 'GRAVE';

    final score = (a.scoresVictims ?? 0);
    if (score >= 3) return 'GRAVE';
    if (score == 2) return 'MODERADO';
    return 'LEVE';
  }

  List<AccidentsData> _applyLocalFilter(
      List<AccidentsData> universe, {
        int? year,
        int? month,
        String? city,
        String? type,
        String? severity,
      }) {
    final normalizedCity =
    (city?.trim().isNotEmpty == true) ? city!.trim().toUpperCase() : null;

    final normalizedType =
    (type?.trim().isNotEmpty == true) ? type!.trim().toUpperCase() : null;

    final normalizedSeverity = (severity?.trim().isNotEmpty == true)
        ? severity!.trim().toUpperCase()
        : null;

    return universe.where((a) {
      final date = a.date;
      if (date == null) return false;

      final okYear = year == null || date.year == year;
      final okMonth = month == null || date.month == month;

      final cityCandidate = (a.city ?? a.locality ?? '').trim().toUpperCase();
      final okCity = normalizedCity == null || cityCandidate == normalizedCity;

      final canonical =
      AccidentsData.canonicalType(a.typeOfAccident).toUpperCase();
      final okType = normalizedType == null || canonical == normalizedType;

      final sev = _severityOf(a).toUpperCase();
      final okSeverity =
          normalizedSeverity == null || sev == normalizedSeverity;

      return okYear && okMonth && okCity && okType && okSeverity;
    }).toList();
  }

  Future<void> _recomputeAndEmit({
    int? page,
    List<AccidentsData>? allOverride,
    int? year,
    int? month,
    String? city,
    String? type,
    String? severity,
    bool setYearNull = false,
    bool setMonthNull = false,
    bool setCityNull = false,
    bool setTypeNull = false,
    bool setSeverityNull = false,
  }) async {
    final all = allOverride ?? state.all;

    final view = _sortDescByDate(all);

    final totalPages = _calcTotalPages(view.length, state.limitPerPage);

    final requestedPage = page ?? state.currentPage;
    final curPage = requestedPage.clamp(1, totalPages);
    final pageItems = _slice(view, curPage, state.limitPerPage);

    final totalsByCity = await repo.getValoresPorCidade(view);
    final totalsByType = await repo.getTotaisPorTipoAcidente(view);
    final resumeByType = _resumeMapByType(view);

    emit(
      state.copyWith(
        loading: false,
        year: year,
        setYearNull: setYearNull,
        month: month,
        setMonthNull: setMonthNull,
        city: city,
        setCityNull: setCityNull,
        type: type,
        setTypeNull: setTypeNull,
        severity: severity,
        setSeverityNull: setSeverityNull,
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
  //                 API PÚBLICA (base)
  // ============================================================

  Future<void> warmup({
    int? initialYear,
    int? initialMonth,
    String? initialCity,
    String? initialType,
    String? initialSeverity,
  }) async {
    final normalizedCity =
    (initialCity?.trim().isNotEmpty == true) ? initialCity!.trim() : null;

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
        type: initialType,
        setTypeNull: initialType == null,
        severity: initialSeverity,
        setSeverityNull: initialSeverity == null,
        error: null,
        success: null,
        clearLocationSuggestion: true,
        clearLocationError: true,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      final universe = await repo.getAllAccidents();
      emit(state.copyWith(universe: universe));

      final filtered = _applyLocalFilter(
        universe,
        year: initialYear,
        month: initialMonth,
        city: normalizedCity,
        type: initialType,
        severity: initialSeverity,
      );

      await _recomputeAndEmit(
        page: 1,
        allOverride: filtered,
        year: initialYear,
        month: initialMonth,
        city: normalizedCity,
        type: initialType,
        severity: initialSeverity,
        setYearNull: initialYear == null,
        setMonthNull: initialMonth == null,
        setCityNull: normalizedCity == null,
        setTypeNull: initialType == null,
        setSeverityNull: initialSeverity == null,
      );

      emit(state.copyWith(initialized: true));
    } catch (err) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  Future<void> changeFilter({
    int? year,
    int? month,
    String? city,
    String? type,
    String? severity,
  }) async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        success: null,
        clearLocationSuggestion: true,
        clearLocationError: true,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      final normalizedCity =
      (city?.trim().isNotEmpty == true) ? city!.trim() : null;
      final normalizedType =
      (type?.trim().isNotEmpty == true) ? type!.trim() : null;
      final normalizedSeverity =
      (severity?.trim().isNotEmpty == true) ? severity!.trim() : null;

      final filtered = _applyLocalFilter(
        state.universe,
        year: year,
        month: month,
        city: normalizedCity,
        type: normalizedType,
        severity: normalizedSeverity,
      );

      await _recomputeAndEmit(
        page: 1,
        allOverride: filtered,
        year: year,
        month: month,
        city: normalizedCity,
        type: normalizedType,
        severity: normalizedSeverity,
        setYearNull: year == null,
        setMonthNull: month == null,
        setCityNull: normalizedCity == null,
        setTypeNull: normalizedType == null,
        setSeverityNull: normalizedSeverity == null,
      );
    } catch (err) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  Future<void> changePage(int page) async {
    await _recomputeAndEmit(page: page);
  }

  Future<void> saveAccident(AccidentsData data) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        clearLocationError: true,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      await repo.saveOrUpdateAccident(data);

      final universe = await repo.getAllAccidents();
      emit(state.copyWith(universe: universe));

      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
      );

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
        setTypeNull: state.type == null,
        setSeverityNull: state.severity == null,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Acidente salvo com sucesso!',
          clearLocationSuggestion: true,
        ),
      );
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

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
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      final y = yearHint ?? state.year ?? DateTime.now().year;
      await repo.deleteAccident(id: id, year: y);

      final universe = await repo.getAllAccidents();
      emit(state.copyWith(universe: universe));

      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
      );

      final shouldGoBackOnePage = state.currentPage > 1 &&
          _slice(_sortDescByDate(filtered), state.currentPage, state.limitPerPage)
              .isEmpty;

      final nextPage =
      shouldGoBackOnePage ? state.currentPage - 1 : state.currentPage;

      await _recomputeAndEmit(
        page: nextPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
        setTypeNull: state.type == null,
        setSeverityNull: state.severity == null,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Acidente apagado com sucesso.',
          clearLocationSuggestion: true,
        ),
      );
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        loading: true,
        error: null,
        success: null,
        clearLocationError: true,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      final filtered = _applyLocalFilter(
        state.universe,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
      );

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
        setTypeNull: state.type == null,
        setSeverityNull: state.severity == null,
      );
    } catch (err) {
      emit(state.copyWith(loading: false, error: '$err'));
    }
  }

  // ============================================================
  // ✅ LINK PÚBLICO (QR)
  // ============================================================

  Future<String> generatePublicReportLink(
      AccidentsData accident, {
        Duration expiresIn = const Duration(days: 30),
      }) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      final url = await repo.ensurePublicReportLink(
        accident: accident,
        expiresIn: expiresIn,
      );

      // Recarrega universo pra refletir o token no item
      final universe = await repo.getAllAccidents();
      emit(state.copyWith(universe: universe));

      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
      );

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
        setTypeNull: state.type == null,
        setSeverityNull: state.severity == null,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Link público gerado!',
          lastPublicReportUrl: url,
        ),
      );

      return url;
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
      rethrow;
    }
  }

  Future<void> revokePublicReportLink(AccidentsData accident) async {
    emit(
      state.copyWith(
        saving: true,
        error: null,
        success: null,
        clearLastPublicReportUrl: true,
      ),
    );

    try {
      await repo.revokePublicReportLink(accident: accident);

      final universe = await repo.getAllAccidents();
      emit(state.copyWith(universe: universe));

      final filtered = _applyLocalFilter(
        universe,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
      );

      await _recomputeAndEmit(
        page: state.currentPage,
        allOverride: filtered,
        year: state.year,
        month: state.month,
        city: state.city,
        type: state.type,
        severity: state.severity,
        setYearNull: state.year == null,
        setMonthNull: state.month == null,
        setCityNull: state.city == null,
        setTypeNull: state.type == null,
        setSeverityNull: state.severity == null,
      );

      emit(
        state.copyWith(
          saving: false,
          success: 'Link público revogado.',
        ),
      );
    } catch (err) {
      emit(state.copyWith(saving: false, error: '$err'));
    }
  }

  // ============================================================
  // ✅ TOGGLES (INTERAÇÃO)
  // ============================================================

  bool _equalsNorm(String? a, String? b) =>
      (a ?? '').trim().toUpperCase() == (b ?? '').trim().toUpperCase();

  Future<void> toggleCity(String? city) async {
    final incoming = (city?.trim().isNotEmpty == true) ? city!.trim() : null;
    final shouldClear = _equalsNorm(state.city, incoming);
    await changeFilter(
      year: state.year,
      month: state.month,
      city: shouldClear ? null : incoming,
      type: state.type,
      severity: state.severity,
    );
  }

  Future<void> toggleType(String? type) async {
    final incoming = (type?.trim().isNotEmpty == true) ? type!.trim() : null;
    final shouldClear = _equalsNorm(state.type, incoming);
    await changeFilter(
      year: state.year,
      month: state.month,
      city: state.city,
      type: shouldClear ? null : incoming,
      severity: state.severity,
    );
  }

  Future<void> toggleSeverity(String? severity) async {
    final incoming =
    (severity?.trim().isNotEmpty == true) ? severity!.trim() : null;
    final shouldClear = _equalsNorm(state.severity, incoming);
    await changeFilter(
      year: state.year,
      month: state.month,
      city: state.city,
      type: state.type,
      severity: shouldClear ? null : incoming,
    );
  }

  Future<void> toggleMonth(int? month) async {
    final shouldClear = (state.month != null && state.month == month);
    await changeFilter(
      year: state.year,
      month: shouldClear ? null : month,
      city: state.city,
      type: state.type,
      severity: state.severity,
    );
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
    } catch (err) {
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
    } catch (err) {
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
    } catch (err) {
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