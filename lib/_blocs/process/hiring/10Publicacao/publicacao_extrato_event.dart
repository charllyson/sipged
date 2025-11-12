part of 'publicacao_extrato_bloc.dart';

sealed class PublicacaoExtratoEvent {}

class PublicacaoExtratoLoadRequested extends PublicacaoExtratoEvent {
  final String contractId;
  PublicacaoExtratoLoadRequested(this.contractId);
}

class PublicacaoExtratoSaveRequested extends PublicacaoExtratoEvent {
  final String contractId;
  final SectionsMap sectionsData;
  PublicacaoExtratoSaveRequested({
    required this.contractId,
    required this.sectionsData,
  });
}

class PublicacaoExtratoSaveOneSectionRequested extends PublicacaoExtratoEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  PublicacaoExtratoSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// limpar o flag de sucesso após mostrar Snackbar/toast
class PublicacaoExtratoClearSuccessRequested extends PublicacaoExtratoEvent {}
