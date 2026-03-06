// lib/_blocs/modules/transit/accidents/accidents_state.dart
import 'package:equatable/equatable.dart';

import 'accidents_data.dart';
import 'accidents_repository.dart'; // AddressSuggestion

class AccidentsState extends Equatable {
  final bool initialized;
  final bool loading;
  final bool saving;

  // Filtros
  final int? year;
  final int? month;
  final String? city;
  final String? type;
  final String? severity;

  // Universo / visões
  final List<AccidentsData> universe;
  final List<AccidentsData> all;
  final List<AccidentsData> view;
  final List<AccidentsData> pageItems;

  // Paginação
  final int currentPage;
  final int totalPages;
  final int limitPerPage;

  // Agregações
  final Map<String, double> totalsByCity;
  final Map<String, double> totalsByType;
  final Map<String, double> resumeByType;

  // Mensagens
  final String? error;
  final String? success;

  // ✅ Link público (último gerado)
  final String? lastPublicReportUrl;

  // Localização
  final bool gettingLocation;
  final AddressSuggestion? locationSuggestion;
  final String? locationError;

  const AccidentsState({
    this.initialized = false,
    this.loading = false,
    this.saving = false,
    this.year,
    this.month,
    this.city,
    this.type,
    this.severity,
    this.universe = const [],
    this.all = const [],
    this.view = const [],
    this.pageItems = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.limitPerPage = 15,
    this.totalsByCity = const {},
    this.totalsByType = const {},
    this.resumeByType = const {},
    this.error,
    this.success,
    this.lastPublicReportUrl,
    this.gettingLocation = false,
    this.locationSuggestion,
    this.locationError,
  });

  factory AccidentsState.initial() => const AccidentsState();

  AccidentsState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,

    // Filtros
    bool setYearNull = false,
    int? year,
    bool setMonthNull = false,
    int? month,
    bool setCityNull = false,
    String? city,
    bool setTypeNull = false,
    String? type,
    bool setSeverityNull = false,
    String? severity,

    // Listas
    List<AccidentsData>? universe,
    List<AccidentsData>? all,
    List<AccidentsData>? view,
    List<AccidentsData>? pageItems,

    // Paginação
    int? currentPage,
    int? totalPages,
    int? limitPerPage,

    // Agregações
    Map<String, double>? totalsByCity,
    Map<String, double>? totalsByType,
    Map<String, double>? resumeByType,

    // Mensagens
    String? error,
    String? success,

    // ✅ Link público
    String? lastPublicReportUrl,
    bool clearLastPublicReportUrl = false,

    // Localização
    bool? gettingLocation,
    AddressSuggestion? locationSuggestion,
    bool clearLocationSuggestion = false,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return AccidentsState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,

      year: setYearNull ? null : (year ?? this.year),
      month: setMonthNull ? null : (month ?? this.month),
      city: setCityNull ? null : (city ?? this.city),
      type: setTypeNull ? null : (type ?? this.type),
      severity: setSeverityNull ? null : (severity ?? this.severity),

      universe: universe ?? this.universe,
      all: all ?? this.all,
      view: view ?? this.view,
      pageItems: pageItems ?? this.pageItems,

      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limitPerPage: limitPerPage ?? this.limitPerPage,

      totalsByCity: totalsByCity ?? this.totalsByCity,
      totalsByType: totalsByType ?? this.totalsByType,
      resumeByType: resumeByType ?? this.resumeByType,

      error: error,
      success: success,

      lastPublicReportUrl: clearLastPublicReportUrl
          ? null
          : (lastPublicReportUrl ?? this.lastPublicReportUrl),

      gettingLocation: gettingLocation ?? this.gettingLocation,
      locationSuggestion: clearLocationSuggestion
          ? null
          : (locationSuggestion ?? this.locationSuggestion),
      locationError:
      clearLocationError ? null : (locationError ?? this.locationError),
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    loading,
    saving,
    year,
    month,
    city,
    type,
    severity,
    universe,
    all,
    view,
    pageItems,
    currentPage,
    totalPages,
    limitPerPage,
    totalsByCity,
    totalsByType,
    resumeByType,
    error,
    success,
    lastPublicReportUrl,
    gettingLocation,
    locationSuggestion,
    locationError,
  ];
}