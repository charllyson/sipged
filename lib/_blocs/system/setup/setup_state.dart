import 'package:equatable/equatable.dart';
import 'setup_data.dart';

class SetupState extends Equatable {
  final bool isLoading;
  final bool hasLoadedSystem;
  final String? error;

  final SetupData? companyProfile;
  final List<SetupData> companyBodies;
  final List<SetupData> units;
  final List<SetupData> roads;
  final List<SetupData> regions;
  final List<SetupData> fundingSources;
  final List<SetupData> programs;
  final List<SetupData> expenseNatures;

  const SetupState({
    required this.isLoading,
    required this.hasLoadedSystem,
    required this.error,
    required this.companyProfile,
    required this.companyBodies,
    required this.units,
    required this.roads,
    required this.regions,
    required this.fundingSources,
    required this.programs,
    required this.expenseNatures,
  });

  factory SetupState.initial() => const SetupState(
    isLoading: false,
    hasLoadedSystem: false,
    error: null,
    companyProfile: null,
    companyBodies: [],
    units: [],
    roads: [],
    regions: [],
    fundingSources: [],
    programs: [],
    expenseNatures: [],
  );

  SetupState copyWith({
    bool? isLoading,
    bool? hasLoadedSystem,
    String? error,
    bool clearError = false,
    SetupData? companyProfile,
    bool clearCompanyProfile = false,
    List<SetupData>? companyBodies,
    List<SetupData>? units,
    List<SetupData>? roads,
    List<SetupData>? regions,
    List<SetupData>? fundingSources,
    List<SetupData>? programs,
    List<SetupData>? expenseNatures,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedSystem: hasLoadedSystem ?? this.hasLoadedSystem,
      error: clearError ? null : (error ?? this.error),
      companyProfile:
      clearCompanyProfile ? null : (companyProfile ?? this.companyProfile),
      companyBodies: companyBodies ?? this.companyBodies,
      units: units ?? this.units,
      roads: roads ?? this.roads,
      regions: regions ?? this.regions,
      fundingSources: fundingSources ?? this.fundingSources,
      programs: programs ?? this.programs,
      expenseNatures: expenseNatures ?? this.expenseNatures,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasLoadedSystem,
    error,
    companyProfile,
    companyBodies,
    units,
    roads,
    regions,
    fundingSources,
    programs,
    expenseNatures,
  ];
}