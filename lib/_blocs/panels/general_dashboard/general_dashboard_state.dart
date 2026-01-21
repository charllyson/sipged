import 'package:equatable/equatable.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:siged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_data.dart';

class GeneralDashboardState extends Equatable {
  final bool initialized;

  /// Loading global (inicialização / tela inteira)
  final bool isLoading;

  /// ✅ Loading específico para manter shimmer nos gráficos durante recalculo
  final bool isRecalculatingCharts;

  final List<ProcessData> allContracts;
  final List<ProcessData> filteredContracts;

  final List<ReportMeasurementData> allMeasurements;
  final List<AdjustmentMeasurementData> allAdjustments;
  final List<RevisionMeasurementData> allRevisions;

  final List<AdditivesData> allAdditives;
  final List<ApostillesData> allApostilles;

  final List<String> uniqueCompanies;

  // Filtros / seleção
  final List<String> selectedRegions;
  final String? selectedRegion;
  final int? selectedRegionIndex;

  final String? selectedCompany;
  final int? selectedCompanyIndex;

  final String? selectedStatus;
  final String? selectedRoad;

  final String? selectedMunicipio;

  final int? selectedYear;
  final int? selectedMonth;

  final String tipoDeValorSelecionado;

  // ===== STATUS (FILTRADO) =====
  final Map<String, double> totaisStatusIniciais;
  final Map<String, double> totaisStatusAditivos;
  final Map<String, double> totaisStatusApostilas;

  // ===== STATUS (FULL) =====
  final Map<String, double> totaisStatusIniciaisFull;
  final Map<String, double> totaisStatusAditivosFull;
  final Map<String, double> totaisStatusApostilasFull;

  // ===== REGIÃO (FILTRADO) =====
  final Map<String, double> totaisRegiaoIniciais;
  final Map<String, double> totaisRegiaoAditivos;
  final Map<String, double> totaisRegiaoApostilas;

  // ===== REGIÃO (FULL) =====
  final Map<String, double> totaisRegiaoIniciaisFull;
  final Map<String, double> totaisRegiaoAditivosFull;
  final Map<String, double> totaisRegiaoApostilasFull;

  // ===== EMPRESA (FILTRADO) =====
  final Map<String, double> totaisEmpresaIniciais;
  final Map<String, double> totaisEmpresaAditivos;
  final Map<String, double> totaisEmpresaApostilas;

  // ===== EMPRESA (FULL) =====
  final Map<String, double> totaisEmpresaIniciaisFull;
  final Map<String, double> totaisEmpresaAditivosFull;
  final Map<String, double> totaisEmpresaApostilasFull;

  // ===== RODOVIA (Treemap) =====
  final Map<String, double> totaisRodoviaFull;
  final Map<String, double> totaisRodoviaFiltrado;

  final double? totalMedicoes;
  final double? totalReajustes;
  final double? totalRevisoes;

  const GeneralDashboardState({
    this.initialized = false,
    this.isLoading = false,
    this.isRecalculatingCharts = false,
    this.allContracts = const [],
    this.filteredContracts = const [],
    this.allMeasurements = const [],
    this.allAdjustments = const [],
    this.allRevisions = const [],
    this.allAdditives = const [],
    this.allApostilles = const [],
    this.uniqueCompanies = const [],
    this.selectedRegions = const [],
    this.selectedRegion,
    this.selectedRegionIndex,
    this.selectedCompany,
    this.selectedCompanyIndex,
    this.selectedStatus,
    this.selectedRoad,
    this.selectedMunicipio,
    this.selectedYear,
    this.selectedMonth,
    this.tipoDeValorSelecionado = 'Somatório total',
    this.totaisStatusIniciais = const {},
    this.totaisStatusAditivos = const {},
    this.totaisStatusApostilas = const {},
    this.totaisStatusIniciaisFull = const {},
    this.totaisStatusAditivosFull = const {},
    this.totaisStatusApostilasFull = const {},
    this.totaisRegiaoIniciais = const {},
    this.totaisRegiaoAditivos = const {},
    this.totaisRegiaoApostilas = const {},
    this.totaisRegiaoIniciaisFull = const {},
    this.totaisRegiaoAditivosFull = const {},
    this.totaisRegiaoApostilasFull = const {},
    this.totaisEmpresaIniciais = const {},
    this.totaisEmpresaAditivos = const {},
    this.totaisEmpresaApostilas = const {},
    this.totaisEmpresaIniciaisFull = const {},
    this.totaisEmpresaAditivosFull = const {},
    this.totaisEmpresaApostilasFull = const {},
    this.totaisRodoviaFull = const {},
    this.totaisRodoviaFiltrado = const {},
    this.totalMedicoes,
    this.totalReajustes,
    this.totalRevisoes,
  });

  static const Object _unset = Object();

  GeneralDashboardState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isRecalculatingCharts,
    List<ProcessData>? allContracts,
    List<ProcessData>? filteredContracts,
    List<ReportMeasurementData>? allMeasurements,
    List<AdjustmentMeasurementData>? allAdjustments,
    List<RevisionMeasurementData>? allRevisions,
    List<AdditivesData>? allAdditives,
    List<ApostillesData>? allApostilles,
    List<String>? uniqueCompanies,
    List<String>? selectedRegions,
    Object? selectedRegion = _unset,
    Object? selectedRegionIndex = _unset,
    Object? selectedCompany = _unset,
    Object? selectedCompanyIndex = _unset,
    Object? selectedStatus = _unset,
    Object? selectedRoad = _unset,
    Object? selectedMunicipio = _unset,
    Object? selectedYear = _unset,
    Object? selectedMonth = _unset,
    String? tipoDeValorSelecionado,
    Map<String, double>? totaisStatusIniciais,
    Map<String, double>? totaisStatusAditivos,
    Map<String, double>? totaisStatusApostilas,
    Map<String, double>? totaisStatusIniciaisFull,
    Map<String, double>? totaisStatusAditivosFull,
    Map<String, double>? totaisStatusApostilasFull,
    Map<String, double>? totaisRegiaoIniciais,
    Map<String, double>? totaisRegiaoAditivos,
    Map<String, double>? totaisRegiaoApostilas,
    Map<String, double>? totaisRegiaoIniciaisFull,
    Map<String, double>? totaisRegiaoAditivosFull,
    Map<String, double>? totaisRegiaoApostilasFull,
    Map<String, double>? totaisEmpresaIniciais,
    Map<String, double>? totaisEmpresaAditivos,
    Map<String, double>? totaisEmpresaApostilas,
    Map<String, double>? totaisEmpresaIniciaisFull,
    Map<String, double>? totaisEmpresaAditivosFull,
    Map<String, double>? totaisEmpresaApostilasFull,
    Map<String, double>? totaisRodoviaFull,
    Map<String, double>? totaisRodoviaFiltrado,
    double? totalMedicoes,
    double? totalReajustes,
    double? totalRevisoes,
  }) {
    return GeneralDashboardState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isRecalculatingCharts: isRecalculatingCharts ?? this.isRecalculatingCharts,
      allContracts: allContracts ?? this.allContracts,
      filteredContracts: filteredContracts ?? this.filteredContracts,
      allMeasurements: allMeasurements ?? this.allMeasurements,
      allAdjustments: allAdjustments ?? this.allAdjustments,
      allRevisions: allRevisions ?? this.allRevisions,
      allAdditives: allAdditives ?? this.allAdditives,
      allApostilles: allApostilles ?? this.allApostilles,
      uniqueCompanies: uniqueCompanies ?? this.uniqueCompanies,
      selectedRegions: selectedRegions ?? this.selectedRegions,
      selectedRegion: identical(selectedRegion, _unset)
          ? this.selectedRegion
          : selectedRegion as String?,
      selectedRegionIndex: identical(selectedRegionIndex, _unset)
          ? this.selectedRegionIndex
          : selectedRegionIndex as int?,
      selectedCompany: identical(selectedCompany, _unset)
          ? this.selectedCompany
          : selectedCompany as String?,
      selectedCompanyIndex: identical(selectedCompanyIndex, _unset)
          ? this.selectedCompanyIndex
          : selectedCompanyIndex as int?,
      selectedStatus: identical(selectedStatus, _unset)
          ? this.selectedStatus
          : selectedStatus as String?,
      selectedRoad: identical(selectedRoad, _unset)
          ? this.selectedRoad
          : selectedRoad as String?,
      selectedMunicipio: identical(selectedMunicipio, _unset)
          ? this.selectedMunicipio
          : selectedMunicipio as String?,
      selectedYear: identical(selectedYear, _unset)
          ? this.selectedYear
          : selectedYear as int?,
      selectedMonth: identical(selectedMonth, _unset)
          ? this.selectedMonth
          : selectedMonth as int?,
      tipoDeValorSelecionado:
      tipoDeValorSelecionado ?? this.tipoDeValorSelecionado,
      totaisStatusIniciais: totaisStatusIniciais ?? this.totaisStatusIniciais,
      totaisStatusAditivos: totaisStatusAditivos ?? this.totaisStatusAditivos,
      totaisStatusApostilas: totaisStatusApostilas ?? this.totaisStatusApostilas,
      totaisStatusIniciaisFull:
      totaisStatusIniciaisFull ?? this.totaisStatusIniciaisFull,
      totaisStatusAditivosFull:
      totaisStatusAditivosFull ?? this.totaisStatusAditivosFull,
      totaisStatusApostilasFull:
      totaisStatusApostilasFull ?? this.totaisStatusApostilasFull,
      totaisRegiaoIniciais: totaisRegiaoIniciais ?? this.totaisRegiaoIniciais,
      totaisRegiaoAditivos: totaisRegiaoAditivos ?? this.totaisRegiaoAditivos,
      totaisRegiaoApostilas: totaisRegiaoApostilas ?? this.totaisRegiaoApostilas,
      totaisRegiaoIniciaisFull:
      totaisRegiaoIniciaisFull ?? this.totaisRegiaoIniciaisFull,
      totaisRegiaoAditivosFull:
      totaisRegiaoAditivosFull ?? this.totaisRegiaoAditivosFull,
      totaisRegiaoApostilasFull:
      totaisRegiaoApostilasFull ?? this.totaisRegiaoApostilasFull,
      totaisEmpresaIniciais:
      totaisEmpresaIniciais ?? this.totaisEmpresaIniciais,
      totaisEmpresaAditivos:
      totaisEmpresaAditivos ?? this.totaisEmpresaAditivos,
      totaisEmpresaApostilas:
      totaisEmpresaApostilas ?? this.totaisEmpresaApostilas,
      totaisEmpresaIniciaisFull:
      totaisEmpresaIniciaisFull ?? this.totaisEmpresaIniciaisFull,
      totaisEmpresaAditivosFull:
      totaisEmpresaAditivosFull ?? this.totaisEmpresaAditivosFull,
      totaisEmpresaApostilasFull:
      totaisEmpresaApostilasFull ?? this.totaisEmpresaApostilasFull,
      totaisRodoviaFull: totaisRodoviaFull ?? this.totaisRodoviaFull,
      totaisRodoviaFiltrado:
      totaisRodoviaFiltrado ?? this.totaisRodoviaFiltrado,
      totalMedicoes: totalMedicoes ?? this.totalMedicoes,
      totalReajustes: totalReajustes ?? this.totalReajustes,
      totalRevisoes: totalRevisoes ?? this.totalRevisoes,
    );
  }

  @override
  List<Object?> get props => [
    initialized,
    isLoading,
    isRecalculatingCharts,
    allContracts,
    filteredContracts,
    allMeasurements,
    allAdjustments,
    allRevisions,
    allAdditives,
    allApostilles,
    uniqueCompanies,
    selectedRegions,
    selectedRegion,
    selectedRegionIndex,
    selectedCompany,
    selectedCompanyIndex,
    selectedStatus,
    selectedRoad,
    selectedMunicipio,
    selectedYear,
    selectedMonth,
    tipoDeValorSelecionado,
    totaisStatusIniciais,
    totaisStatusAditivos,
    totaisStatusApostilas,
    totaisStatusIniciaisFull,
    totaisStatusAditivosFull,
    totaisStatusApostilasFull,
    totaisRegiaoIniciais,
    totaisRegiaoAditivos,
    totaisRegiaoApostilas,
    totaisRegiaoIniciaisFull,
    totaisRegiaoAditivosFull,
    totaisRegiaoApostilasFull,
    totaisEmpresaIniciais,
    totaisEmpresaAditivos,
    totaisEmpresaApostilas,
    totaisEmpresaIniciaisFull,
    totaisEmpresaAditivosFull,
    totaisEmpresaApostilasFull,
    totaisRodoviaFull,
    totaisRodoviaFiltrado,
    totalMedicoes,
    totalReajustes,
    totalRevisoes,
  ];
}
