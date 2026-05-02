import 'package:equatable/equatable.dart';

import '../notification_data.dart';

class NotificationLocalState extends Equatable {
  const NotificationLocalState({
    this.visible = const <NotificationData>[],
    this.pending = const <NotificationData>[],
    this.error,
    this.maxVisible = 4,
  });

  final List<NotificationData> visible;
  final List<NotificationData> pending;
  final String? error;
  final int maxVisible;

  bool get hasVisible => visible.isNotEmpty;
  bool get hasPending => pending.isNotEmpty;

  NotificationLocalState copyWith({
    List<NotificationData>? visible,
    List<NotificationData>? pending,
    String? error,
    int? maxVisible,
    bool clearError = false,
  }) {
    return NotificationLocalState(
      visible: visible ?? this.visible,
      pending: pending ?? this.pending,
      error: clearError ? null : error ?? this.error,
      maxVisible: maxVisible ?? this.maxVisible,
    );
  }

  @override
  List<Object?> get props => [
    visible,
    pending,
    error,
    maxVisible,
  ];
}