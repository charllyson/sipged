// lib/_blocs/modules/transit/infractions/infractions_state.dart

import 'package:equatable/equatable.dart';

import 'infractions_data.dart';

class InfractionsState extends Equatable {
  final bool initRan;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final bool loading;
  final bool isFiltering;
  final bool isPaging;

  final String? errorMessage;

  final String? currentInfractionId;
  final InfractionsData? selectedInfraction;

  final int? selectedYear;
  final int? selectedMonth;

  final int currentPage;
  final int totalPages;
  final int itemsPerPage;

  final List<InfractionsData> selectorUniverseAll;
  final List<InfractionsData> filtered;
  final List<InfractionsData> pageItems;

  const InfractionsState({
    this.initRan = false,
    this.isEditable = true,
    this.isSaving = false,
    this.formValidated = false,
    this.loading = false,
    this.isFiltering = false,
    this.isPaging = false,
    this.errorMessage,
    this.currentInfractionId,
    this.selectedInfraction,
    this.selectedYear,
    this.selectedMonth,
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 50,
    this.selectorUniverseAll = const <InfractionsData>[],
    this.filtered = const <InfractionsData>[],
    this.pageItems = const <InfractionsData>[],
  });

  factory InfractionsState.initial() {
    return const InfractionsState();
  }

  InfractionsState copyWith({
    bool? initRan,
    bool? isEditable,
    bool? isSaving,
    bool? formValidated,
    bool? loading,
    bool? isFiltering,
    bool? isPaging,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? currentInfractionId,
    bool clearCurrentInfractionId = false,
    InfractionsData? selectedInfraction,
    bool clearSelectedInfraction = false,
    int? selectedYear,
    bool clearSelectedYear = false,
    int? selectedMonth,
    bool clearSelectedMonth = false,
    int? currentPage,
    int? totalPages,
    int? itemsPerPage,
    List<InfractionsData>? selectorUniverseAll,
    List<InfractionsData>? filtered,
    List<InfractionsData>? pageItems,
  }) {
    return InfractionsState(
      initRan: initRan ?? this.initRan,
      isEditable: isEditable ?? this.isEditable,
      isSaving: isSaving ?? this.isSaving,
      formValidated: formValidated ?? this.formValidated,
      loading: loading ?? this.loading,
      isFiltering: isFiltering ?? this.isFiltering,
      isPaging: isPaging ?? this.isPaging,
      errorMessage:
      clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      currentInfractionId: clearCurrentInfractionId
          ? null
          : currentInfractionId ?? this.currentInfractionId,
      selectedInfraction: clearSelectedInfraction
          ? null
          : selectedInfraction ?? this.selectedInfraction,
      selectedYear: clearSelectedYear ? null : selectedYear ?? this.selectedYear,
      selectedMonth:
      clearSelectedMonth ? null : selectedMonth ?? this.selectedMonth,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      selectorUniverseAll:
      selectorUniverseAll ?? this.selectorUniverseAll,
      filtered: filtered ?? this.filtered,
      pageItems: pageItems ?? this.pageItems,
    );
  }

  @override
  List<Object?> get props {
    return [
      initRan,
      isEditable,
      isSaving,
      formValidated,
      loading,
      isFiltering,
      isPaging,
      errorMessage,
      currentInfractionId,
      selectedInfraction,
      selectedYear,
      selectedMonth,
      currentPage,
      totalPages,
      itemsPerPage,
      selectorUniverseAll,
      filtered,
      pageItems,
    ];
  }
}