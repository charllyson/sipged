part of 'cotacao_bloc.dart';

abstract class CotacaoEvent {}

class CotacaoLoadRequested extends CotacaoEvent {
  final String contractId;
  CotacaoLoadRequested(this.contractId);
}

class CotacaoSaveRequested extends CotacaoEvent {
  final String contractId;
  final SectionsMap sectionsData;
  CotacaoSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

class CotacaoSaveOneSectionRequested extends CotacaoEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;

  CotacaoSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Opcional: limpar o flag de sucesso após Snackbar/Toast
class CotacaoClearSuccessRequested extends CotacaoEvent {}
