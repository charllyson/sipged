import 'package:meta/meta.dart';

@immutable
abstract class ProgressEvent {}

class ProgressBindRequested extends ProgressEvent {
  final String contractId;
  final String collectionName; // ex: 'dfd'
  final String stageId;        // ex: primeiro doc da coleção
  ProgressBindRequested({
    required this.contractId,
    required this.collectionName,
    required this.stageId,
  });
}

class ProgressSnapshotChanged extends ProgressEvent {
  final bool approved;
  final bool completed;
  ProgressSnapshotChanged({
    required this.approved,
    required this.completed,
  });
}

class ProgressErrorOccurred extends ProgressEvent {
  final String message;
  ProgressErrorOccurred(this.message);
}
