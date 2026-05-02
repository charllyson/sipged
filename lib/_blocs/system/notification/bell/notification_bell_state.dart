import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/system/notification/notification_data.dart';

class NotificationBellState extends Equatable {
  const NotificationBellState({
    this.systemNotifications = const <NotificationData>[],
    this.unreadUserNotifications = const <NotificationData>[],
    this.loading = false,
    this.error,
  });

  final List<NotificationData> systemNotifications;
  final List<NotificationData> unreadUserNotifications;

  final bool loading;
  final String? error;

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

  NotificationBellState copyWith({
    List<NotificationData>? systemNotifications,
    List<NotificationData>? unreadUserNotifications,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationBellState(
      systemNotifications: systemNotifications ?? this.systemNotifications,
      unreadUserNotifications:
      unreadUserNotifications ?? this.unreadUserNotifications,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    systemNotifications,
    unreadUserNotifications,
    loading,
    error,
  ];
}