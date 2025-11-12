part of 'dotacao_bloc.dart';

abstract class DotacaoEvent {}

class DotacaoLoadRequested extends DotacaoEvent {
  final String contractId;
  DotacaoLoadRequested(this.contractId);
}

class DotacaoSaveRequested extends DotacaoEvent {
  final String contractId;
  final SectionsMap sectionsData;
  DotacaoSaveRequested({required this.contractId, required this.sectionsData});
}

class DotacaoSaveOneSectionRequested extends DotacaoEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  DotacaoSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// limpar o flag de sucesso após mostrar Snackbar/toast
class DotacaoClearSuccessRequested extends DotacaoEvent {}
