import 'package:equatable/equatable.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

/// Inicializa (carrega lista) e opcionalmente liga realtime/bind do current
class UserWarmupRequested extends UserEvent {
  final bool listenRealtime;
  final bool bindCurrentUser;
  const UserWarmupRequested({
    this.listenRealtime = false,
    this.bindCurrentUser = true,
  });
  @override
  List<Object?> get props => [listenRealtime, bindCurrentUser];
}

/// Garante que os dados estejam carregados (não força reload se já houver cache)
class UsersEnsureLoadedRequested extends UserEvent {
  final bool listenRealtime;
  const UsersEnsureLoadedRequested({this.listenRealtime = false});
  @override
  List<Object?> get props => [listenRealtime];
}

/// Força recarregar a lista de usuários
class UsersRefreshRequested extends UserEvent {
  const UsersRefreshRequested();
}

/// Liga/desliga assinatura em tempo real da coleção `users`
class UsersRealtimeToggleRequested extends UserEvent {
  final bool enable;
  const UsersRealtimeToggleRequested(this.enable);
  @override
  List<Object?> get props => [enable];
}

/// Inicia/para o bind do usuário atual
class CurrentUserBindToggleRequested extends UserEvent {
  final bool enable;
  const CurrentUserBindToggleRequested(this.enable);
  @override
  List<Object?> get props => [enable];
}

/// Busca por UID com cache
class UserFetchByIdRequested extends UserEvent {
  final String uid;
  const UserFetchByIdRequested(this.uid);
  @override
  List<Object?> get props => [uid];
}

/// Salvar/atualizar usuário
class UserSaveRequested extends UserEvent {
  final UserData user;
  const UserSaveRequested(this.user);
  @override
  List<Object?> get props => [user];
}

/// Marcar notificação como vista
class UserMarkNotificationSeenRequested extends UserEvent {
  final String uid;
  final String notificationId;
  const UserMarkNotificationSeenRequested({
    required this.uid,
    required this.notificationId,
  });
  @override
  List<Object?> get props => [uid, notificationId];
}

/// --- Eventos internos disparados pelas streams ---

/// Atualização da lista completa de usuários (realtime)
class UsersStreamUpdated extends UserEvent {
  final List<UserData> list;
  const UsersStreamUpdated(this.list);
  @override
  List<Object?> get props => [list];
}

/// Erro no stream de usuários
class UsersStreamError extends UserEvent {
  final String message;
  const UsersStreamError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Atualização do usuário atual (realtime)
class CurrentUserStreamUpdated extends UserEvent {
  final UserData? current;
  const CurrentUserStreamUpdated(this.current);
  @override
  List<Object?> get props => [current];
}
