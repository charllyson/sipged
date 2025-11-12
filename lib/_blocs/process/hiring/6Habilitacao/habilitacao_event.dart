part of 'habilitacao_bloc.dart';

abstract class HabilitacaoEvent {}

class HabilitacaoLoadRequested extends HabilitacaoEvent {
  final String contractId;
  HabilitacaoLoadRequested(this.contractId);
}

class HabilitacaoSaveRequested extends HabilitacaoEvent {
  final String contractId;
  final SectionsMap sectionsData;
  HabilitacaoSaveRequested({required this.contractId, required this.sectionsData});
}

class HabilitacaoSaveOneSectionRequested extends HabilitacaoEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  HabilitacaoSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Para limpar o flag de sucesso após feedback visual
class HabilitacaoClearSuccessRequested extends HabilitacaoEvent {}
