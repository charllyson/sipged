// lib/_blocs/process/additives/additives_state.dart
import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/process/additives/additives_data.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

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

  bool get canAddFile => isEditable && selected?.id != null;

  List<String> get orderOptions {
    if (existingOrders.isEmpty) return const <String>['1'];
    final max = existingOrders.reduce((a, b) => a > b ? a : b);
    final maxPlusOne = max + 1;
    return List<String>.generate(maxPlusOne, (i) => '${i + 1}');
  }

  Set<String> get greyOrderItems =>
      existingOrders.map((e) => e.toString()).toSet();

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
    bool clearSelected = false,
    bool clearError = false,
    bool clearSelectedIndex = false,
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
  ];
}
