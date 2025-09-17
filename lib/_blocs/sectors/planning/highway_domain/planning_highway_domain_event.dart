// lib/_blocs/planning/highway_domain/planning_highway_domain_event.dart
import 'package:equatable/equatable.dart';

abstract class PlanningHighwayDomainEvent extends Equatable {
  const PlanningHighwayDomainEvent();
  @override
  List<Object?> get props => [];
}

class PlanningHighwayDomainRefreshRequested extends PlanningHighwayDomainEvent {
  const PlanningHighwayDomainRefreshRequested();
}

class PlanningHighwayDomainImportBatchRequested extends PlanningHighwayDomainEvent {
  final List<Map<String, dynamic>> linhasPrincipais;
  final List<Map<String, dynamic>> geometrias;
  const PlanningHighwayDomainImportBatchRequested({
    required this.linhasPrincipais,
    required this.geometrias,
  });
  @override
  List<Object?> get props => [linhasPrincipais, geometrias];
}

class PlanningHighwayDomainDeleteAllRequested extends PlanningHighwayDomainEvent {
  const PlanningHighwayDomainDeleteAllRequested();
}

class PlanningHighwayDomainVisibilityToggled extends PlanningHighwayDomainEvent {
  final bool? visible; // se null, inverte
  const PlanningHighwayDomainVisibilityToggled([this.visible]);
  @override
  List<Object?> get props => [visible];
}

class PlanningHighwayDomainFeatureSelected extends PlanningHighwayDomainEvent {
  final String? id; // null = limpa seleção
  const PlanningHighwayDomainFeatureSelected(this.id);
  @override
  List<Object?> get props => [id];
}
