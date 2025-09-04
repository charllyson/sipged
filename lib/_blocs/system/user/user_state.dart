import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

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
    List<UserData>? all,
    Map<String, UserData>? byId,
    bool? isLoadingUsers,
    String? loadUsersError, // passe null para manter, '' para limpar
    bool? realtimeEnabled,
    bool? currentBindEnabled,
  }) {
    return UserState(
      initialized: initialized ?? this.initialized,
      current: current ?? this.current,
      all: all ?? this.all,
      byId: byId ?? this.byId,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      loadUsersError: loadUsersError,
      realtimeEnabled: realtimeEnabled ?? this.realtimeEnabled,
      currentBindEnabled: currentBindEnabled ?? this.currentBindEnabled,
    );
  }

  /// Helper de rótulo (Nome Sobrenome) com fallback
  String labelFor(String? uid, {String fallback = '—'}) {
    if (uid == null || uid.isEmpty) return fallback;
    final u = byId[uid];
    final name = (u?.name ?? '').trim();
    final surname = (u?.surname ?? '').trim();
    final full = [name, surname].where((s) => s.isNotEmpty).join(' ').trim();
    return full.isEmpty ? (u?.id ?? fallback) : full;
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
