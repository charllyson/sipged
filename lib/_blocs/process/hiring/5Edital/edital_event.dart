part of 'edital_bloc.dart';

abstract class EditalEvent {}

class EditalLoadRequested extends EditalEvent {
  final String contractId;
  EditalLoadRequested(this.contractId);
}

class EditalSaveRequested extends EditalEvent {
  final String contractId;
  final SectionsMap sectionsData;
  EditalSaveRequested({required this.contractId, required this.sectionsData});
}

class EditalSaveOneSectionRequested extends EditalEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  EditalSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Opcional: limpar o flag de sucesso (após Snackbar/Toast)
class EditalClearSuccessRequested extends EditalEvent {}
