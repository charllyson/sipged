// lib/_blocs/sectors/transit/accidents/accidents_state.dart
import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsState extends Equatable {
  final bool initialized;
  final bool loading;
  final bool saving;

  // Filtros atuais
  final int? year;
  final int? month;
  final String? city;

  // Universo imutável (para o seletor de anos/meses)
  final List<AccidentsData> universe;

  // Coleções derivadas
  final List<AccidentsData> all;       // lista filtrada por (year/month/city)
  final List<AccidentsData> view;      // mesma all, mas já ordenada/ajustada para a tela
  final List<AccidentsData> pageItems; // fatia paginada

  // Paginação
  final int currentPage;
  final int totalPages;
  final int limitPerPage;

  // Agregações
  final Map<String, double> totalsByCity;
  final Map<String, double> totalsByType;
  final Map<String, double> resumeByType; // mesmo shape do controller antigo (cards)

  // Mensagens
  final String? error;
  final String? success;

  const AccidentsState({
    this.initialized = false,
    this.loading = false,
    this.saving = false,
    this.year,
    this.month,
    this.city,
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
  });

  AccidentsState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,
    int? year,
    int? month,
    String? city,
    List<AccidentsData>? universe,
    List<AccidentsData>? all,
    List<AccidentsData>? view,
    List<AccidentsData>? pageItems,
    int? currentPage,
    int? totalPages,
    int? limitPerPage,
    Map<String, double>? totalsByCity,
    Map<String, double>? totalsByType,
    Map<String, double>? resumeByType,
    String? error,
    String? success,
  }) {
    return AccidentsState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      year: year != null ? year : this.year,
      month: month != null ? month : this.month,
      city: city != null ? city : this.city,
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
  ];
}
