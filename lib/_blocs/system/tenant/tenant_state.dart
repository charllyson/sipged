// lib/_blocs/system/tenant/tenant_state.dart

import 'package:equatable/equatable.dart';

import 'tenant_data.dart';

class TenantState extends Equatable {
  final bool isLoading;
  final bool hasLoadedTenant;
  final bool hasLoadedTenantItems;
  final bool hasLoadedAvailableTenants;
  final String? error;

  final String? selectedTenantId;
  final List<TenantData> availableTenants;
  final TenantData? tenantProfile;

  final List<String> units;
  final List<String> roads;
  final List<String> regions;
  final List<String> fundingSources;
  final List<String> programs;
  final List<String> expenseNatures;
  final List<String> companyBodies;

  const TenantState({
    required this.isLoading,
    required this.hasLoadedTenant,
    required this.hasLoadedTenantItems,
    required this.hasLoadedAvailableTenants,
    required this.error,
    required this.selectedTenantId,
    required this.availableTenants,
    required this.tenantProfile,
    required this.units,
    required this.roads,
    required this.regions,
    required this.fundingSources,
    required this.programs,
    required this.expenseNatures,
    required this.companyBodies,
  });

  factory TenantState.initial() {
    return const TenantState(
      isLoading: false,
      hasLoadedTenant: false,
      hasLoadedTenantItems: false,
      hasLoadedAvailableTenants: false,
      error: null,
      selectedTenantId: null,
      availableTenants: [],
      tenantProfile: null,
      units: [],
      roads: [],
      regions: [],
      fundingSources: [],
      programs: [],
      expenseNatures: [],
      companyBodies: [],
    );
  }

  bool get hasTenantProfile => tenantProfile != null;

  bool get hasCompanyProfile => tenantProfile != null;

  TenantData? get companyProfile => tenantProfile;

  List<String> get partners => companyBodies;

  TenantData? get selectedTenant {
    final id = selectedTenantId?.trim();

    if (id == null || id.isEmpty) {
      return tenantProfile;
    }

    for (final tenant in availableTenants) {
      if (tenant.id == id) {
        return tenant;
      }
    }

    return tenantProfile;
  }

  TenantState copyWith({
    bool? isLoading,
    bool? hasLoadedTenant,
    bool? hasLoadedTenantItems,
    bool? hasLoadedAvailableTenants,
    String? error,
    bool clearError = false,
    String? selectedTenantId,
    bool clearSelectedTenantId = false,
    List<TenantData>? availableTenants,
    TenantData? tenantProfile,
    bool clearTenantProfile = false,
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
  }) {
    return TenantState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedTenant: hasLoadedTenant ?? this.hasLoadedTenant,
      hasLoadedTenantItems:
      hasLoadedTenantItems ?? this.hasLoadedTenantItems,
      hasLoadedAvailableTenants:
      hasLoadedAvailableTenants ?? this.hasLoadedAvailableTenants,
      error: clearError ? null : error ?? this.error,
      selectedTenantId: clearSelectedTenantId
          ? null
          : selectedTenantId ?? this.selectedTenantId,
      availableTenants: availableTenants ?? this.availableTenants,
      tenantProfile:
      clearTenantProfile ? null : tenantProfile ?? this.tenantProfile,
      units: units ?? this.units,
      roads: roads ?? this.roads,
      regions: regions ?? this.regions,
      fundingSources: fundingSources ?? this.fundingSources,
      programs: programs ?? this.programs,
      expenseNatures: expenseNatures ?? this.expenseNatures,
      companyBodies: companyBodies ?? this.companyBodies,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasLoadedTenant,
    hasLoadedTenantItems,
    hasLoadedAvailableTenants,
    error,
    selectedTenantId,
    availableTenants,
    tenantProfile,
    units,
    roads,
    regions,
    fundingSources,
    programs,
    expenseNatures,
    companyBodies,
  ];
}