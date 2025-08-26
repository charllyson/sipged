import 'package:equatable/equatable.dart';
import 'package:sisged/_blocs/actives/oaes/active_oaes_data.dart';

abstract class ActiveOaesEvent extends Equatable {
  const ActiveOaesEvent();
  @override
  List<Object?> get props => [];
}

class ActiveOaesWarmupRequested extends ActiveOaesEvent {
  const ActiveOaesWarmupRequested();
}

class ActiveOaesRefreshRequested extends ActiveOaesEvent {
  const ActiveOaesRefreshRequested();
}

class ActiveOaesSelectByIndex extends ActiveOaesEvent {
  final int index;
  const ActiveOaesSelectByIndex(this.index);
  @override
  List<Object?> get props => [index];
}

class ActiveOaesClearSelection extends ActiveOaesEvent {
  const ActiveOaesClearSelection();
}

class ActiveOaesFormPatched extends ActiveOaesEvent {
  final ActiveOaesData data;
  const ActiveOaesFormPatched(this.data);
  @override
  List<Object?> get props => [data];
}

class ActiveOaesUpsertRequested extends ActiveOaesEvent {
  final ActiveOaesData data;
  const ActiveOaesUpsertRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ActiveOaesDeleteRequested extends ActiveOaesEvent {
  final String id;
  const ActiveOaesDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// >>> NOVOS EVENTOS DE FILTRO <<<
/// pieIndex: índice da fatia (0..5) ou null para limpar
class ActiveOaesPieFilterChanged extends ActiveOaesEvent {
  final int? pieIndex;
  const ActiveOaesPieFilterChanged(this.pieIndex);
  @override
  List<Object?> get props => [pieIndex];
}

/// region: rótulo da região (ex: "SERTÃO") ou null para limpar
class ActiveOaesRegionFilterChanged extends ActiveOaesEvent {
  final String? region;
  const ActiveOaesRegionFilterChanged(this.region);
  @override
  List<Object?> get props => [region];
}
