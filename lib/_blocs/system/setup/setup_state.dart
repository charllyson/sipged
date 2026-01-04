// lib/_blocs/system/info/setup_state.dart
import 'package:equatable/equatable.dart';
import 'setup_data.dart';

class SetupState extends Equatable {
  final bool isLoading;
  final String? error;

  final List<SetupData> companies;
  final List<SetupData> companyBodies; // empresas contratadas / licitantes
  final List<SetupData> units;
  final List<SetupData> roads;
  final List<SetupData> regions;
  final List<SetupData> fundingSources;
  final List<SetupData> programs;
  final List<SetupData> expenseNatures;

  final String? selectedCompanyId;

  const SetupState({
    required this.isLoading,
    required this.error,
    required this.companies,
    required this.companyBodies,
    required this.units,
    required this.roads,
    required this.regions,
    required this.fundingSources,
    required this.programs,
    required this.expenseNatures,
    required this.selectedCompanyId,
  });

  factory SetupState.initial() => const SetupState(
    isLoading: false,
    error: null,
    companies: [],
    companyBodies: [],
    units: [],
    roads: [],
    regions: [],
    fundingSources: [],
    programs: [],
    expenseNatures: [],
    selectedCompanyId: null,
  );

  SetupState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<SetupData>? companies,
    List<SetupData>? companyBodies,
    List<SetupData>? units,
    List<SetupData>? roads,
    List<SetupData>? regions,
    List<SetupData>? fundingSources,
    List<SetupData>? programs,
    List<SetupData>? expenseNatures,
    String? selectedCompanyId,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      companies: companies ?? this.companies,
      companyBodies: companyBodies ?? this.companyBodies,
      units: units ?? this.units,
      roads: roads ?? this.roads,
      regions: regions ?? this.regions,
      fundingSources: fundingSources ?? this.fundingSources,
      programs: programs ?? this.programs,
      expenseNatures: expenseNatures ?? this.expenseNatures,
      selectedCompanyId: selectedCompanyId ?? this.selectedCompanyId,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    companies,
    companyBodies,
    units,
    roads,
    regions,
    fundingSources,
    programs,
    expenseNatures,
    selectedCompanyId,
  ];
}
