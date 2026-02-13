import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_data.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_data.dart';

// ✅ novos
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_data.dart';

enum FinancialDashboardStatus { initial, loading, success, failure }

class FinancialDashboardState extends Equatable {
  final FinancialDashboardStatus status;
  final String? error;

  final List<BudgetData> budgets;
  final List<EmpenhoData> empenhos;

  // ✅ carregados uma vez (para reuso)
  final List<AdditivesData> allAdditives;
  final List<ApostillesData> allApostilles;

  /// ✅ DEMANDA -> (DFD + aditivos + apostilas)
  final Map<String, double> demandTotals;

  // drilldown
  final String? selectedEmpenhoId;

  // filtros (dropdowns)
  final String statusDfdLabel;
  final String fundingSourceLabel;
  final String extraLabel;

  const FinancialDashboardState({
    this.status = FinancialDashboardStatus.initial,
    this.error,
    this.budgets = const <BudgetData>[],
    this.empenhos = const <EmpenhoData>[],
    this.allAdditives = const <AdditivesData>[],
    this.allApostilles = const <ApostillesData>[],
    this.demandTotals = const <String, double>{},
    this.selectedEmpenhoId,
    this.statusDfdLabel = '',
    this.fundingSourceLabel = '',
    this.extraLabel = '',
  });

  factory FinancialDashboardState.initial() => const FinancialDashboardState();

  FinancialDashboardState copyWith({
    FinancialDashboardStatus? status,
    String? error,
    bool clearError = false,

    List<BudgetData>? budgets,
    List<EmpenhoData>? empenhos,

    List<AdditivesData>? allAdditives,
    List<ApostillesData>? allApostilles,
    Map<String, double>? demandTotals,

    String? selectedEmpenhoId,
    bool clearSelectedEmpenho = false,

    String? statusDfdLabel,
    String? fundingSourceLabel,
    String? extraLabel,
  }) {
    return FinancialDashboardState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      budgets: budgets ?? this.budgets,
      empenhos: empenhos ?? this.empenhos,
      allAdditives: allAdditives ?? this.allAdditives,
      allApostilles: allApostilles ?? this.allApostilles,
      demandTotals: demandTotals ?? this.demandTotals,
      selectedEmpenhoId: clearSelectedEmpenho
          ? null
          : (selectedEmpenhoId ?? this.selectedEmpenhoId),
      statusDfdLabel: statusDfdLabel ?? this.statusDfdLabel,
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
      extraLabel: extraLabel ?? this.extraLabel,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    budgets,
    empenhos,
    allAdditives,
    allApostilles,
    demandTotals,
    selectedEmpenhoId,
    statusDfdLabel,
    fundingSourceLabel,
    extraLabel,
  ];
}
