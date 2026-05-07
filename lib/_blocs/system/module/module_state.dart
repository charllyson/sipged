// lib/_blocs/system/module/module_state.dart

import 'package:equatable/equatable.dart';

import 'module_data.dart';

class ModuleState extends Equatable {
  final ModuleEnum? selectedItem;

  final List<ModuleGroupData> visibleHomeGroups;
  final List<ModuleGroupData> visibleDrawerMainGroups;
  final List<ModuleGroupData> visibleDrawerActiveGroups;

  final String? deniedMessage;

  const ModuleState({
    required this.selectedItem,
    required this.visibleHomeGroups,
    required this.visibleDrawerMainGroups,
    required this.visibleDrawerActiveGroups,
    required this.deniedMessage,
  });

  factory ModuleState.initial() {
    return const ModuleState(
      selectedItem: null,
      visibleHomeGroups: <ModuleGroupData>[],
      visibleDrawerMainGroups: <ModuleGroupData>[],
      visibleDrawerActiveGroups: <ModuleGroupData>[],
      deniedMessage: null,
    );
  }

  bool get isHome => selectedItem == null;

  bool get hasVisibleHomeGroups => visibleHomeGroups.isNotEmpty;

  bool get hasVisibleDrawerMainGroups => visibleDrawerMainGroups.isNotEmpty;

  bool get hasVisibleDrawerActiveGroups => visibleDrawerActiveGroups.isNotEmpty;

  ModuleState copyWith({
    ModuleEnum? selectedItem,
    bool clearSelectedItem = false,
    List<ModuleGroupData>? visibleHomeGroups,
    List<ModuleGroupData>? visibleDrawerMainGroups,
    List<ModuleGroupData>? visibleDrawerActiveGroups,
    String? deniedMessage,
    bool clearDeniedMessage = false,
  }) {
    return ModuleState(
      selectedItem: clearSelectedItem ? null : selectedItem ?? this.selectedItem,
      visibleHomeGroups: visibleHomeGroups ?? this.visibleHomeGroups,
      visibleDrawerMainGroups:
      visibleDrawerMainGroups ?? this.visibleDrawerMainGroups,
      visibleDrawerActiveGroups:
      visibleDrawerActiveGroups ?? this.visibleDrawerActiveGroups,
      deniedMessage:
      clearDeniedMessage ? null : deniedMessage ?? this.deniedMessage,
    );
  }

  @override
  List<Object?> get props => [
    selectedItem,
    visibleHomeGroups,
    visibleDrawerMainGroups,
    visibleDrawerActiveGroups,
    deniedMessage,
  ];
}