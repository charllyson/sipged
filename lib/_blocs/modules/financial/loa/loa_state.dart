import 'package:equatable/equatable.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'loa_data.dart';

enum LOAStatus { initial, loading, success, failure }

class LOAState extends Equatable {
  final LOAStatus status;
  final List<LOAData> items;
  final LOAData? selected;
  final String? contractId;
  final String? error;

  // ---------------- FORM ----------------
  final String? companyId;
  final String companyLabel;

  final String? fundingSourceId;
  final String fundingSourceLabel;

  final int year;
  final String budgetCode;
  final String description;
  final String amountText;

  final List<Attachment> attachments;
  final int? selectedSideIndex;

  const LOAState({
    this.status = LOAStatus.initial,
    this.items = const [],
    this.selected,
    this.contractId,
    this.error,
    this.companyId,
    this.companyLabel = '',
    this.fundingSourceId,
    this.fundingSourceLabel = '',
    this.year = 0,
    this.budgetCode = '',
    this.description = '',
    this.amountText = '',
    this.attachments = const [],
    this.selectedSideIndex,
  });

  factory LOAState.initial() =>
      LOAState(status: LOAStatus.initial, year: DateTime.now().year);

  LOAState copyWith({
    LOAStatus? status,
    List<LOAData>? items,
    LOAData? selected,
    String? contractId,
    String? error,
    bool clearSelected = false,
    bool clearError = false,

    String? companyId,
    String? companyLabel,
    bool clearCompanyId = false,

    String? fundingSourceId,
    String? fundingSourceLabel,
    bool clearFundingSourceId = false,

    int? year,
    String? budgetCode,
    String? description,
    String? amountText,

    List<Attachment>? attachments,
    int? selectedSideIndex,
    bool clearSelectedSideIndex = false,
  }) {
    return LOAState(
      status: status ?? this.status,
      items: items ?? this.items,
      selected: clearSelected ? null : (selected ?? this.selected),
      contractId: contractId ?? this.contractId,
      error: clearError ? null : (error ?? this.error),

      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      companyLabel: companyLabel ?? this.companyLabel,

      fundingSourceId: clearFundingSourceId
          ? null
          : (fundingSourceId ?? this.fundingSourceId),
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,

      year: year ?? this.year,
      budgetCode: budgetCode ?? this.budgetCode,
      description: description ?? this.description,
      amountText: amountText ?? this.amountText,

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
    companyId,
    companyLabel,
    fundingSourceId,
    fundingSourceLabel,
    year,
    budgetCode,
    description,
    amountText,
    attachments,
    selectedSideIndex,
  ];
}
