import 'package:equatable/equatable.dart';

import 'setup_data.dart';

class SetupState extends Equatable {
  final bool isLoading;
  final bool hasLoadedSystem;
  final String? error;

  final List<SetupData> modules;
  final List<SetupData> profiles;
  final List<SetupData> permissions;
  final List<SetupData> parameters;
  final List<SetupData> integrations;
  final List<SetupData> featureFlags;

  const SetupState({
    required this.isLoading,
    required this.hasLoadedSystem,
    required this.error,
    required this.modules,
    required this.profiles,
    required this.permissions,
    required this.parameters,
    required this.integrations,
    required this.featureFlags,
  });

  factory SetupState.initial() {
    return const SetupState(
      isLoading: false,
      hasLoadedSystem: false,
      error: null,
      modules: <SetupData>[],
      profiles: <SetupData>[],
      permissions: <SetupData>[],
      parameters: <SetupData>[],
      integrations: <SetupData>[],
      featureFlags: <SetupData>[],
    );
  }

  List<SetupData> itemsByGroup(SetupGroup group) {
    switch (group) {
      case SetupGroup.modules:
        return modules;

      case SetupGroup.profiles:
        return profiles;

      case SetupGroup.permissions:
        return permissions;

      case SetupGroup.parameters:
        return parameters;

      case SetupGroup.integrations:
        return integrations;

      case SetupGroup.featureFlags:
        return featureFlags;
    }
  }

  SetupState copyWith({
    bool? isLoading,
    bool? hasLoadedSystem,
    String? error,
    bool clearError = false,
    List<SetupData>? modules,
    List<SetupData>? profiles,
    List<SetupData>? permissions,
    List<SetupData>? parameters,
    List<SetupData>? integrations,
    List<SetupData>? featureFlags,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      hasLoadedSystem: hasLoadedSystem ?? this.hasLoadedSystem,
      error: clearError ? null : error ?? this.error,
      modules: modules ?? this.modules,
      profiles: profiles ?? this.profiles,
      permissions: permissions ?? this.permissions,
      parameters: parameters ?? this.parameters,
      integrations: integrations ?? this.integrations,
      featureFlags: featureFlags ?? this.featureFlags,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasLoadedSystem,
    error,
    modules,
    profiles,
    permissions,
    parameters,
    integrations,
    featureFlags,
  ];
}