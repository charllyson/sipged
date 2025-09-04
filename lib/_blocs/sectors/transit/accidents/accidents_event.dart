// lib/_blocs/sectors/transit/accidents/accidents_event.dart
import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';

abstract class AccidentsEvent extends Equatable {
  const AccidentsEvent();
  @override
  List<Object?> get props => [];
}

/// Inicializa: carrega universo completo e aplica filtro inicial (opcional)
class AccidentsWarmupRequested extends AccidentsEvent {
  final int? initialYear;
  final int? initialMonth;
  final String? initialCity;
  const AccidentsWarmupRequested({this.initialYear, this.initialMonth, this.initialCity});
}

/// Altera filtros de ano/mês/cidade
class AccidentsFilterChanged extends AccidentsEvent {
  final int? year;
  final int? month;
  final String? city;
  const AccidentsFilterChanged({this.year, this.month, this.city});
  @override
  List<Object?> get props => [year, month, city];
}

/// Paginação (1-based)
class AccidentsPageRequested extends AccidentsEvent {
  final int page;
  const AccidentsPageRequested(this.page);
  @override
  List<Object?> get props => [page];
}

/// Salvar/criar acidente
class AccidentsSaveRequested extends AccidentsEvent {
  final AccidentsData data;
  const AccidentsSaveRequested(this.data);
  @override
  List<Object?> get props => [data];
}

/// Apagar acidente (yearHint ajuda a localizar o doc)
class AccidentsDeleteRequested extends AccidentsEvent {
  final String id;
  final int? yearHint;
  const AccidentsDeleteRequested({required this.id, this.yearHint});
  @override
  List<Object?> get props => [id, yearHint];
}

/// Recarregar mantendo filtros atuais
class AccidentsRefreshRequested extends AccidentsEvent {
  const AccidentsRefreshRequested();
}
