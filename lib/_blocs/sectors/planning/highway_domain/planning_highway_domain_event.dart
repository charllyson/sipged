import 'package:equatable/equatable.dart';

abstract class PlanningHighwayDomainEvent extends Equatable {
  const PlanningHighwayDomainEvent();
  @override
  List<Object?> get props => [];
}

/// Recarrega as linhas do domínio para um contrato
class PlanningHighwayDomainRefreshRequested extends PlanningHighwayDomainEvent {
  final String contractId;
  const PlanningHighwayDomainRefreshRequested(this.contractId);
  @override
  List<Object?> get props => [contractId];
}

/// Importa em lote (linhas + geometrias) para um contrato
class PlanningHighwayDomainImportBatchRequested extends PlanningHighwayDomainEvent {
  final String contractId;
  final List<Map<String, dynamic>> linhasPrincipais;
  final List<Map<String, dynamic>> geometrias;
  const PlanningHighwayDomainImportBatchRequested({
    required this.contractId,
    required this.linhasPrincipais,
    required this.geometrias,
  });
  @override
  List<Object?> get props => [contractId, linhasPrincipais, geometrias];
}

/// Remove todas as linhas do domínio de um contrato
class PlanningHighwayDomainDeleteAllRequested extends PlanningHighwayDomainEvent {
  final String contractId;
  const PlanningHighwayDomainDeleteAllRequested(this.contractId);
  @override
  List<Object?> get props => [contractId];
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
