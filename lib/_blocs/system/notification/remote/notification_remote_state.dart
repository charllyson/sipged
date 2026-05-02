import 'package:equatable/equatable.dart';

import '../notification_data.dart';

class NotificationRemoteState extends Equatable {
  const NotificationRemoteState({
    this.history = const <NotificationData>[],
    this.systemNotifications = const <NotificationData>[],
    this.unreadUserNotifications = const <NotificationData>[],
    this.loading = false,
    this.sending = false,
    this.error,
  });

  final List<NotificationData> history;
  final List<NotificationData> systemNotifications;
  final List<NotificationData> unreadUserNotifications;

  final bool loading;
  final bool sending;
  final String? error;

  int get unreadHistoryCount => history.where((item) => !item.seen).length;

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

  NotificationRemoteState copyWith({
    List<NotificationData>? history,
    List<NotificationData>? systemNotifications,
    List<NotificationData>? unreadUserNotifications,
    bool? loading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return NotificationRemoteState(
      history: history ?? this.history,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      unreadUserNotifications:
      unreadUserNotifications ?? this.unreadUserNotifications,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    history,
    systemNotifications,
    unreadUserNotifications,
    loading,
    sending,
    error,
  ];
}