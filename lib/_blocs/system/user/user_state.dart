// lib/_blocs/system/user/user_state.dart

import 'package:equatable/equatable.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

class UserState extends Equatable {
  const UserState({
    this.initialized = false,
    this.current,
    this.all = const <UserData>[],
    this.byId = const <String, UserData>{},
    this.isLoadingUsers = false,
    this.loadUsersError,
    this.realtimeEnabled = false,
    this.currentBindEnabled = false,
    this.isSavingUser = false,
    this.saveUserError,
  });

  final bool initialized;

  final UserData? current;
  final List<UserData> all;
  final Map<String, UserData> byId;

  final bool isLoadingUsers;
  final String? loadUsersError;

  final bool realtimeEnabled;
  final bool currentBindEnabled;

  final bool isSavingUser;
  final String? saveUserError;

  UserState copyWith({
    bool? initialized,
    UserData? current,
    bool setCurrentNull = false,
    List<UserData>? all,
    Map<String, UserData>? byId,
    bool? isLoadingUsers,
    String? loadUsersError,
    bool clearLoadUsersError = false,
    bool? realtimeEnabled,
    bool? currentBindEnabled,
    bool? isSavingUser,
    String? saveUserError,
    bool clearSaveUserError = false,
  }) {
    return UserState(
      initialized: initialized ?? this.initialized,
      current: setCurrentNull ? null : current ?? this.current,
      all: all ?? this.all,
      byId: byId ?? this.byId,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      loadUsersError:
      clearLoadUsersError ? null : loadUsersError ?? this.loadUsersError,
      realtimeEnabled: realtimeEnabled ?? this.realtimeEnabled,
      currentBindEnabled: currentBindEnabled ?? this.currentBindEnabled,
      isSavingUser: isSavingUser ?? this.isSavingUser,
      saveUserError:
      clearSaveUserError ? null : saveUserError ?? this.saveUserError,
    );
  }

  String labelFor(
      String? uid, {
        String fallback = '—',
      }) {
    if (uid == null || uid.trim().isEmpty) return fallback;

    final user = byId[uid.trim()];
    final name = (user?.name ?? '').trim();
    final surname = (user?.surname ?? '').trim();

    final full = [name, surname].where((s) => s.isNotEmpty).join(' ').trim();

    return full.isEmpty ? user?.uid ?? fallback : full;
  }

  @override
  List<Object?> get props => [
    initialized,
    current,
    all,
    byId,
    isLoadingUsers,
    loadUsersError,
    realtimeEnabled,
    currentBindEnabled,
    isSavingUser,
    saveUserError,
  ];
}