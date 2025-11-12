part of 'parecer_juridico_bloc.dart';

abstract class ParecerEvent {}

class ParecerLoadRequested extends ParecerEvent {
  final String contractId;
  ParecerLoadRequested(this.contractId);
}

class ParecerSaveRequested extends ParecerEvent {
  final String contractId;
  final SectionsMap sectionsData;
  ParecerSaveRequested({required this.contractId, required this.sectionsData});
}

class ParecerSaveOneSectionRequested extends ParecerEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  ParecerSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// limpar o flag de sucesso após mostrar Snackbar/toast
class ParecerClearSuccessRequested extends ParecerEvent {}
