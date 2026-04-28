import 'package:equatable/equatable.dart';

import 'notification_data.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.visible = const <NotificationData>[],
    this.pending = const <NotificationData>[],
    this.history = const <NotificationData>[],
    this.systemNotifications = const <NotificationData>[],
    this.unreadUserNotifications = const <NotificationData>[],
    this.loading = false,
    this.error,
    this.maxVisible = 4,
  });

  final List<NotificationData> visible;
  final List<NotificationData> pending;

  /// Histórico geral do usuário.
  final List<NotificationData> history;

  /// Notificações globais do sistema.
  final List<NotificationData> systemNotifications;

  /// Notificações ainda não vistas pelo usuário.
  final List<NotificationData> unreadUserNotifications;

  final bool loading;
  final String? error;
  final int maxVisible;

  bool get hasVisible => visible.isNotEmpty;
  bool get hasPending => pending.isNotEmpty;

  int get unreadHistoryCount => history.where((e) => !e.seen).length;

  int get unreadUserCount => unreadUserNotifications.length;

  List<NotificationData> get bellNotifications {
    final merged = <NotificationData>[
      ...unreadUserNotifications,
      ...systemNotifications,
    ];

    merged.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return merged;
  }

  NotificationState copyWith({
    List<NotificationData>? visible,
    List<NotificationData>? pending,
    List<NotificationData>? history,
    List<NotificationData>? systemNotifications,
    List<NotificationData>? unreadUserNotifications,
    bool? loading,
    String? error,
    int? maxVisible,
    bool clearError = false,
  }) {
    return NotificationState(
      visible: visible ?? this.visible,
      pending: pending ?? this.pending,
      history: history ?? this.history,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      unreadUserNotifications:
      unreadUserNotifications ?? this.unreadUserNotifications,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      maxVisible: maxVisible ?? this.maxVisible,
    );
  }

  @override
  List<Object?> get props => [
    visible,
    pending,
    history,
    systemNotifications,
    unreadUserNotifications,
    loading,
    error,
    maxVisible,
  ];
}