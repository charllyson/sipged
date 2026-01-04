import 'package:equatable/equatable.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'empenho_data.dart';

enum EmpenhoStatus { initial, loading, success, failure }

class EmpenhoState extends Equatable {
  final EmpenhoStatus status;
  final List<EmpenhoData> items;
  final EmpenhoData? selected;
  final String? contractId;
  final String? error;

  // ---------------- FORM ----------------
  final String numero;

  /// ✅ demanda (id + label)
  final String? demandContractId;
  final String demandLabel;

  /// compat (legado)
  final String credor;

  /// company
  final String? companyId;
  final String companyLabel;

  /// fonte de recurso
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

  factory EmpenhoState.initial() =>
      const EmpenhoState(status: EmpenhoStatus.initial);

  EmpenhoState copyWith({
    EmpenhoStatus? status,
    List<EmpenhoData>? items,
    EmpenhoData? selected,
    String? contractId,
    String? error,
    bool clearSelected = false,
    bool clearError = false,

    String? numero,

    String? demandContractId,
    String? demandLabel,
    bool clearDemand = false,

    // legado
    String? credor,

    String? companyId,
    String? companyLabel,
    bool clearCompanyId = false,

    String? fundingSourceId,
    String? fundingSourceLabel,
    bool clearFundingSourceId = false,

    String? totalText,
    DateTime? date,
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
      contractId: contractId ?? this.contractId,
      error: clearError ? null : (error ?? this.error),

      numero: numero ?? this.numero,

      demandContractId: clearDemand ? null : (demandContractId ?? this.demandContractId),
      demandLabel: nextDemandLabel,

      // legado espelhado (se não passar, usa demandLabel)
      credor: (credor ?? nextDemandLabel),

      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      companyLabel: companyLabel ?? this.companyLabel,

      fundingSourceId: clearFundingSourceId
          ? null
          : (fundingSourceId ?? this.fundingSourceId),
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,

      totalText: totalText ?? this.totalText,
      date: date ?? this.date,
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
