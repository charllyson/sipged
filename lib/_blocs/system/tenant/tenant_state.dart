// lib/_blocs/system/tenant/tenant_state.dart

import 'package:equatable/equatable.dart';

import 'tenant_data.dart';

class TenantState extends Equatable {
  final bool isLoading;
  final bool hasLoadedTenant;
  final bool hasLoadedTenantItems;
  final String? error;

  final TenantData? tenantProfile;

  final List<TenantItemData> units;
  final List<TenantItemData> roads;
  final List<TenantItemData> regions;
  final List<TenantItemData> fundingSources;
  final List<TenantItemData> programs;
  final List<TenantItemData> expenseNatures;
  final List<TenantItemData> companyBodies;

  const TenantState({
    required this.isLoading,
    required this.hasLoadedTenant,
    required this.hasLoadedTenantItems,
    required this.error,
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
      error: null,
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

  List<TenantItemData> get partners => companyBodies;

  TenantState copyWith({
    bool? isLoading,
    bool? hasLoadedTenant,
    bool? hasLoadedTenantItems,
    String? error,
    bool clearError = false,
    TenantData? tenantProfile,
    bool clearTenantProfile = false,
    List<TenantItemData>? units,
    List<TenantItemData>? roads,
    List<TenantItemData>? regions,
    List<TenantItemData>? fundingSources,
    List<TenantItemData>? programs,
    List<TenantItemData>? expenseNatures,
    List<TenantItemData>? companyBodies,
  }) {
    return TenantState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedTenant: hasLoadedTenant ?? this.hasLoadedTenant,
      hasLoadedTenantItems:
      hasLoadedTenantItems ?? this.hasLoadedTenantItems,
      error: clearError ? null : error ?? this.error,
      tenantProfile: clearTenantProfile
          ? null
          : tenantProfile ?? this.tenantProfile,
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
    error,
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