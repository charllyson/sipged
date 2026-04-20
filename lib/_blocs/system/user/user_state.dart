// lib/_blocs/system/user/user_state.dart
import 'package:equatable/equatable.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class UserState extends Equatable {
  final bool initialized;

  // Dados
  final UserData? current;
  final List<UserData> all;
  final Map<String, UserData> byId;

  // Flags de UI
  final bool isLoadingUsers;
  final String? loadUsersError;

  // Assinaturas ativas
  final bool realtimeEnabled;
  final bool currentBindEnabled;

  const UserState({
    this.initialized = false,
    this.current,
    this.all = const [],
    this.byId = const {},
    this.isLoadingUsers = false,
    this.loadUsersError,
    this.realtimeEnabled = false,
    this.currentBindEnabled = false,
  });

  UserState copyWith({
    bool? initialized,
    UserData? current,
    bool setCurrentNull = false,
    List<UserData>? all,
    Map<String, UserData>? byId,
    bool? isLoadingUsers,
    String? loadUsersError, // null = mantém | '' = limpa
    bool? realtimeEnabled,
    bool? currentBindEnabled,
  }) {
    return UserState(
      initialized: initialized ?? this.initialized,
      current: setCurrentNull ? null : (current ?? this.current),
      all: all ?? this.all,
      byId: byId ?? this.byId,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      loadUsersError: loadUsersError ?? this.loadUsersError,
      realtimeEnabled: realtimeEnabled ?? this.realtimeEnabled,
      currentBindEnabled: currentBindEnabled ?? this.currentBindEnabled,
    );
  }

  String labelFor(String? uid, {String fallback = '—'}) {
    if (uid == null || uid.isEmpty) return fallback;

    final user = byId[uid];
    final name = (user?.name ?? '').trim();
    final surname = (user?.surname ?? '').trim();

    final full = [name, surname]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    return full.isEmpty ? (user?.uid ?? fallback) : full;
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
  ];
}