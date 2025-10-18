import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

class AddressSuggestion extends Equatable {
  final double? latitude;
  final double? longitude;
  final String street;
  final String subLocality;
  final String administrativeArea;
  final String postalCode;
  final String country;
  final String isoCountryCode;
  final String city;

  const AddressSuggestion({
    this.latitude,
    this.longitude,
    this.street = '',
    this.subLocality = '',
    this.administrativeArea = '',
    this.postalCode = '',
    this.country = '',
    this.isoCountryCode = '',
    this.city = '',
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    street,
    subLocality,
    administrativeArea,
    postalCode,
    country,
    isoCountryCode,
    city,
  ];
}

class AccidentsState extends Equatable {
  final bool initialized;
  final bool loading;
  final bool saving;

  // Filtros
  final int? year;
  final int? month;
  final String? city;

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
    this.gettingLocation = false,
    this.locationSuggestion,
    this.locationError,
  });

  AccidentsState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,

    bool setYearNull = false,
    int? year,
    bool setMonthNull = false,
    int? month,
    bool setCityNull = false,
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

      gettingLocation: gettingLocation ?? this.gettingLocation,
      locationSuggestion: clearLocationSuggestion ? null : (locationSuggestion ?? this.locationSuggestion),
      locationError: clearLocationError ? null : (locationError ?? this.locationError),
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
    gettingLocation,
    locationSuggestion,
    locationError,
  ];
}
