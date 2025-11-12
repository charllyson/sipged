part of 'etp_bloc.dart';

abstract class EtpEvent {}

class EtpLoadRequested extends EtpEvent {
  final String contractId;
  EtpLoadRequested(this.contractId);
}

class EtpSaveRequested extends EtpEvent {
  final String contractId;
  final SectionsMap sectionsData;
  EtpSaveRequested({required this.contractId, required this.sectionsData});
}

class EtpSaveOneSectionRequested extends EtpEvent {
  final String contractId;
  final String sectionKey;
  final Map<String, dynamic> data;
  EtpSaveOneSectionRequested({
    required this.contractId,
    required this.sectionKey,
    required this.data,
  });
}

/// Opcional: para limpar o flag de sucesso depois de um Snackbar/Toast
class EtpClearSuccessRequested extends EtpEvent {}
