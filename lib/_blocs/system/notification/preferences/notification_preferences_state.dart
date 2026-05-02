// lib/_blocs/system/notification/preferences/notification_preferences_state.dart

import 'package:equatable/equatable.dart';

import 'notification_preference_data.dart';

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.items = const <NotificationPreferenceData>[],
    this.loading = false,
    this.saving = false,
    this.error,
  });

  final List<NotificationPreferenceData> items;
  final bool loading;
  final bool saving;
  final String? error;

  NotificationPreferenceData? preferenceBySource(String sourceKey) {
    final clean = sourceKey.trim();

    for (final item in items) {
      if (item.sourceKey == clean) return item;
    }

    return null;
  }

  NotificationPreferencesState copyWith({
    List<NotificationPreferenceData>? items,
    bool? loading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return NotificationPreferencesState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    items,
    loading,
    saving,
    error,
  ];
}