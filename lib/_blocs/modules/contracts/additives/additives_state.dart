import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

enum AdditivesStatus { initial, loading, loaded, error }

class AdditivesState extends Equatable {
  final AdditivesStatus status;
  final List<AdditivesData> additives;
  final AdditivesData? selected;
  final bool isSaving;
  final bool isEditable;
  final bool editingMode;
  final bool formValid;
  final int? selectedIndex;
  final List<Attachment> sideAttachments;
  final int nextAvailableOrder;
  final Set<int> existingOrders;
  final String? errorMessage;

  final bool sideLoading;
  final double? uploadProgress;

  /// Mapa de alertas por ordem do aditivo.
  ///
  /// Exemplo:
  /// {
  ///   2: 'A data do 2º aditivo não pode ser menor que a data do 1º aditivo.'
  /// }
  final Map<int, String> dateOrderWarnings;

  bool get canAddFile => isEditable && selected?.id != null;

  bool get hasDateOrderWarnings => dateOrderWarnings.isNotEmpty;

  String? get selectedDateOrderWarning {
    final order = selected?.additiveOrder;

    if (order == null || order <= 0) return null;

    return dateOrderWarnings[order];
  }

  List<String> get orderOptions {
    if (existingOrders.isEmpty) return const <String>['1'];

    final max = existingOrders.reduce((a, b) => a > b ? a : b);
    final maxPlusOne = max + 1;

    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems {
    return existingOrders.map((e) => e.toString()).toSet();
  }

  const AdditivesState({
    required this.status,
    required this.additives,
    required this.selected,
    required this.isSaving,
    required this.isEditable,
    required this.editingMode,
    required this.formValid,
    required this.selectedIndex,
    required this.sideAttachments,
    required this.nextAvailableOrder,
    required this.existingOrders,
    required this.errorMessage,
    required this.sideLoading,
    required this.uploadProgress,
    required this.dateOrderWarnings,
  });

  factory AdditivesState.initial() {
    return const AdditivesState(
      status: AdditivesStatus.initial,
      additives: <AdditivesData>[],
      selected: null,
      isSaving: false,
      isEditable: true,
      editingMode: false,
      formValid: false,
      selectedIndex: null,
      sideAttachments: <Attachment>[],
      nextAvailableOrder: 1,
      existingOrders: <int>{},
      errorMessage: null,
      sideLoading: false,
      uploadProgress: null,
      dateOrderWarnings: <int, String>{},
    );
  }

  AdditivesState copyWith({
    AdditivesStatus? status,
    List<AdditivesData>? additives,
    AdditivesData? selected,
    bool? isSaving,
    bool? isEditable,
    bool? editingMode,
    bool? formValid,
    int? selectedIndex,
    List<Attachment>? sideAttachments,
    int? nextAvailableOrder,
    Set<int>? existingOrders,
    String? errorMessage,
    bool? sideLoading,
    double? uploadProgress,
    Map<int, String>? dateOrderWarnings,
    bool clearSelected = false,
    bool clearError = false,
    bool clearSelectedIndex = false,
    bool clearUploadProgress = false,
    bool clearDateOrderWarnings = false,
  }) {
    return AdditivesState(
      status: status ?? this.status,
      additives: additives ?? this.additives,
      selected: clearSelected ? null : (selected ?? this.selected),
      isSaving: isSaving ?? this.isSaving,
      isEditable: isEditable ?? this.isEditable,
      editingMode: editingMode ?? this.editingMode,
      formValid: formValid ?? this.formValid,
      selectedIndex: clearSelectedIndex ? null : (selectedIndex ?? this.selectedIndex),
      sideAttachments: sideAttachments ?? this.sideAttachments,
      nextAvailableOrder: nextAvailableOrder ?? this.nextAvailableOrder,
      existingOrders: existingOrders ?? this.existingOrders,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sideLoading: sideLoading ?? this.sideLoading,
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      dateOrderWarnings: clearDateOrderWarnings
          ? const <int, String>{}
          : (dateOrderWarnings ?? this.dateOrderWarnings),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    additives,
    selected,
    isSaving,
    isEditable,
    editingMode,
    formValid,
    selectedIndex,
    sideAttachments,
    nextAvailableOrder,
    existingOrders,
    errorMessage,
    sideLoading,
    uploadProgress,
    dateOrderWarnings,
  ];
}