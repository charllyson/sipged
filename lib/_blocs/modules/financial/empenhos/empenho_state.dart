import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'empenho_data.dart';

enum EmpenhoStatus { initial, loading, success, failure }

class EmpenhoState extends Equatable {
  final EmpenhoStatus status;
  final List<EmpenhoData> items;
  final EmpenhoData? selected;
  final String? contractId;
  final String? error;

  final bool loadingDfds;
  final List<DfdData> dfds;

  final String numero;

  final String? demandContractId;
  final String demandLabel;

  final String credor;

  final String? companyId;
  final String companyLabel;

  final String? fundingSourceId;
  final String fundingSourceLabel;

  final String totalText;
  final DateTime? date;

  final List<String> sliceLabels;
  final List<String> sliceAmounts;

  final List<Attachment> attachments;
  final int? selectedSideIndex;

  const EmpenhoState({
    this.status = EmpenhoStatus.initial,
    this.items = const [],
    this.selected,
    this.contractId,
    this.error,
    this.loadingDfds = false,
    this.dfds = const [],
    this.numero = '',
    this.demandContractId,
    this.demandLabel = '',
    this.credor = '',
    this.companyId,
    this.companyLabel = '',
    this.fundingSourceId,
    this.fundingSourceLabel = '',
    this.totalText = '',
    this.date,
    this.sliceLabels = const [],
    this.sliceAmounts = const [],
    this.attachments = const [],
    this.selectedSideIndex,
  });

  factory EmpenhoState.initial() {
    return const EmpenhoState(status: EmpenhoStatus.initial);
  }

  EmpenhoState copyWith({
    EmpenhoStatus? status,
    List<EmpenhoData>? items,
    EmpenhoData? selected,
    bool clearSelected = false,
    String? contractId,
    bool clearContractId = false,
    String? error,
    bool clearError = false,
    bool? loadingDfds,
    List<DfdData>? dfds,
    String? numero,
    String? demandContractId,
    String? demandLabel,
    bool clearDemand = false,
    String? credor,
    String? companyId,
    bool clearCompanyId = false,
    String? companyLabel,
    String? fundingSourceId,
    bool clearFundingSourceId = false,
    String? fundingSourceLabel,
    String? totalText,
    DateTime? date,
    bool clearDate = false,
    List<String>? sliceLabels,
    List<String>? sliceAmounts,
    List<Attachment>? attachments,
    int? selectedSideIndex,
    bool clearSelectedSideIndex = false,
  }) {
    final nextDemandLabel = clearDemand ? '' : (demandLabel ?? this.demandLabel);

    return EmpenhoState(
      status: status ?? this.status,
      items: items ?? this.items,
      selected: clearSelected ? null : (selected ?? this.selected),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      error: clearError ? null : (error ?? this.error),
      loadingDfds: loadingDfds ?? this.loadingDfds,
      dfds: dfds ?? this.dfds,
      numero: numero ?? this.numero,
      demandContractId:
      clearDemand ? null : (demandContractId ?? this.demandContractId),
      demandLabel: nextDemandLabel,
      credor: credor ?? nextDemandLabel,
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      companyLabel: companyLabel ?? this.companyLabel,
      fundingSourceId: clearFundingSourceId
          ? null
          : (fundingSourceId ?? this.fundingSourceId),
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
      totalText: totalText ?? this.totalText,
      date: clearDate ? null : (date ?? this.date),
      sliceLabels: sliceLabels ?? this.sliceLabels,
      sliceAmounts: sliceAmounts ?? this.sliceAmounts,
      attachments: attachments ?? this.attachments,
      selectedSideIndex: clearSelectedSideIndex
          ? null
          : (selectedSideIndex ?? this.selectedSideIndex),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    selected,
    contractId,
    error,
    loadingDfds,
    dfds,
    numero,
    demandContractId,
    demandLabel,
    credor,
    companyId,
    companyLabel,
    fundingSourceId,
    fundingSourceLabel,
    totalText,
    date,
    sliceLabels,
    sliceAmounts,
    attachments,
    selectedSideIndex,
  ];
}