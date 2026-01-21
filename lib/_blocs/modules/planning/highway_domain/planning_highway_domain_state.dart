// lib/_blocs/planning/highway_domain/planning_highway_domain_state.dart
import 'package:equatable/equatable.dart';
import 'planning_highway_domain_data.dart';

class PlanningHighwayDomainState extends Equatable {
  final bool initialized;
  final bool loading;
  final bool saving;
  final String? error;

  final bool visible; // camada ligada/desligada no mapa
  final String? selectedId;

  final List<PlanningHighwayDomainData> items;

  const PlanningHighwayDomainState({
    this.initialized = false,
    this.loading = false,
    this.saving = false,
    this.error,
    this.visible = true,
    this.selectedId,
    this.items = const [],
  });

  PlanningHighwayDomainState copyWith({
    bool? initialized,
    bool? loading,
    bool? saving,
    String? error,
    bool? visible,
    Object? selectedId,
    List<PlanningHighwayDomainData>? items,
  }) {
    return PlanningHighwayDomainState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: error,
      visible: visible ?? this.visible,
      selectedId: selectedId is Unset ? this.selectedId : selectedId as String?,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [initialized, loading, saving, error, visible, selectedId, items];
}

class Unset {
  const Unset();
}
