part of 'dfd_bloc.dart';

sealed class DfdEvent {}

class DfdLoadRequested extends DfdEvent {
  final String contractId;
  DfdLoadRequested(this.contractId);
}

class DfdSaveRequested extends DfdEvent {
  final String contractId;
  final SectionsMap sectionsData; // {secao: map}
  DfdSaveRequested({required this.contractId, required this.sectionsData});
}

class DfdSaveOneSectionRequested extends DfdEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  DfdSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

class DfdClearSuccessRequested extends DfdEvent {}

/// 🔹 Leitura leve: status + tipoObra + extensaoKm
class DfdReadLightFieldsRequested extends DfdEvent {
  final String contractId;
  DfdReadLightFieldsRequested(this.contractId);
}

/// (retrocompat opcional)
class DfdReadWorkTypeAndExtRequested extends DfdEvent {
  final String contractId;
  DfdReadWorkTypeAndExtRequested(this.contractId);
}
