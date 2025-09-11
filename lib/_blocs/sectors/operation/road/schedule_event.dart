import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:siged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  @override
  List<Object?> get props => [];
}

/// Inicializa estado com contrato e serviço inicial
class ScheduleWarmupRequested extends ScheduleEvent {
  final String contractId;
  final int totalEstacas;
  final String initialServiceKey;
  const ScheduleWarmupRequested({
    required this.contractId,
    required this.totalEstacas,
    this.initialServiceKey = 'geral',
  });
  @override
  List<Object?> get props => [contractId, totalEstacas, initialServiceKey];
}

/// Recarrega tudo (serviços, faixas, execuções)
class ScheduleRefreshRequested extends ScheduleEvent {
  const ScheduleRefreshRequested();
}

/// Seleciona um serviço
class ScheduleServiceSelected extends ScheduleEvent {
  final String serviceKey;
  const ScheduleServiceSelected(this.serviceKey);
  @override
  List<Object?> get props => [serviceKey];
}

/// Salvar faixas (e recarregar)
class ScheduleLanesSaveRequested extends ScheduleEvent {
  final List<ScheduleLaneClass> lanes;
  const ScheduleLanesSaveRequested(this.lanes);
  @override
  List<Object?> get props => [lanes];
}

/// Recarrega execuções da serviceKey atual
class ScheduleExecucoesReloadRequested extends ScheduleEvent {
  const ScheduleExecucoesReloadRequested();
}

/// ---------------------------------------------------------------------------
/// AÇÃO ÚNICA: Aplicar (status/comentário/data + novos uploads + exclusões + ordenação)
/// ---------------------------------------------------------------------------
class ScheduleSquareApplyRequested extends ScheduleEvent {
  final int estaca;
  final int faixaIndex;

  // Metadados de célula
  final String tipoLabel;
  final String status;        // 'concluido' | 'em_andamento' | 'a_iniciar'
  final String? comentario;   // null = limpar
  final DateTime? takenAt;    // data do modal (fallback p/ novas fotos)

  // Fotos (UI já traz as que restaram depois de clicar no "X" e reordenar)
  final List<String> finalPhotoUrls;                // ordem final sem as novas
  final List<Uint8List> newFilesBytes;              // novas fotos (0..n)
  final List<String>? newFileNames;                 // nomes das novas (opcional)
  final List<pm.CarouselMetadata> newPhotoMetas;    // metas alinhadas às novas (opcional)

  // Usuário
  final String currentUserId;

  const ScheduleSquareApplyRequested({
    required this.estaca,
    required this.faixaIndex,
    required this.tipoLabel,
    required this.status,
    this.comentario,
    this.takenAt,
    required this.finalPhotoUrls,
    required this.newFilesBytes,
    this.newFileNames,
    this.newPhotoMetas = const [],
    required this.currentUserId,
  });

  @override
  List<Object?> get props => [
    estaca, faixaIndex, tipoLabel, status, comentario, takenAt,
    finalPhotoUrls, newFilesBytes, newFileNames, newPhotoMetas, currentUserId
  ];
}
