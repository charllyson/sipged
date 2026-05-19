import 'package:equatable/equatable.dart';

import 'permission_data.dart';

class PermissionState extends Equatable {
  final bool isLoading;
  final bool hasLoaded;
  final bool realtimeEnabled;
  final String? error;

  final String? activeTenantId;
  final UserPermissionData? current;

  const PermissionState({
    required this.isLoading,
    required this.hasLoaded,
    required this.realtimeEnabled,
    required this.error,
    required this.activeTenantId,
    required this.current,
  });

  factory PermissionState.initial() {
    return const PermissionState(
      isLoading: false,
      hasLoaded: false,
      realtimeEnabled: false,
      error: null,
      activeTenantId: null,
      current: null,
    );
  }

  bool get hasPermissions {
    return current != null && current!.uid.trim().isNotEmpty;
  }

  bool get hasActiveTenant {
    final id = activeTenantId?.trim();

    return id != null && id.isNotEmpty;
  }

  PermissionUser get activeRole {
    final data = current;

    if (data == null) {
      return PermissionUser.leitor;
    }

    return data.roleForTenant(activeTenantId);
  }

  bool get isSuperUser {
    final data = current;

    if (data == null) {
      return false;
    }

    return data.isSuperUserForTenant(activeTenantId);
  }

  List<String> get enabledTenantIds {
    return current?.enabledTenantIds ?? const <String>[];
  }

  bool canAccessTenant(String? tenantId) {
    final id = tenantId?.trim();

    if (id == null || id.isEmpty) {
      return false;
    }

    return current?.canAccessTenant(id) == true;
  }

  PermissionState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    bool? realtimeEnabled,
    String? error,
    bool clearError = false,
    String? activeTenantId,
    bool clearActiveTenantId = false,
    UserPermissionData? current,
    bool clearCurrent = false,
  }) {
    return PermissionState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      realtimeEnabled: realtimeEnabled ?? this.realtimeEnabled,
      error: clearError ? null : error ?? this.error,
      activeTenantId:
      clearActiveTenantId ? null : activeTenantId ?? this.activeTenantId,
      current: clearCurrent ? null : current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasLoaded,
    realtimeEnabled,
    error,
    activeTenantId,
    current,
  ];
}