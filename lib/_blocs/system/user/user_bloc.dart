import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/system/user/user_repository.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repo;

  StreamSubscription<List<UserData>>? _usersSub;
  StreamSubscription<UserData?>? _meSub;

  UserBloc(this.repo) : super(const UserState()) {
    on<UserWarmupRequested>(_onWarmup);
    on<UsersEnsureLoadedRequested>(_onEnsureLoaded);
    on<UsersRefreshRequested>(_onRefresh);
    on<UsersRealtimeToggleRequested>(_onRealtimeToggle);
    on<CurrentUserBindToggleRequested>(_onCurrentBindToggle);
    on<UserFetchByIdRequested>(_onFetchById);
    on<UserSaveRequested>(_onSave);
    on<UserMarkNotificationSeenRequested>(_onMarkSeen);

    // Handlers para eventos vindos das streams
    on<UsersStreamUpdated>(_onUsersStreamUpdated);
    on<UsersStreamError>(_onUsersStreamError);
    on<CurrentUserStreamUpdated>(_onCurrentUserStreamUpdated);
  }

  @override
  Future<void> close() {
    _usersSub?.cancel();
    _meSub?.cancel();
    return super.close();
  }

  // ---------------- Handlers ----------------

  Future<void> _onWarmup(
      UserWarmupRequested e,
      Emitter<UserState> emit,
      ) async {
    emit(state.copyWith(isLoadingUsers: true, loadUsersError: null));
    try {
      final users = await repo.getAll();
      final byId = {
        for (final u in users)
          if ((u.uid ?? '').isNotEmpty) u.uid!: u,
      };

      emit(state.copyWith(
        initialized: true,
        all: users,
        byId: byId,
        isLoadingUsers: false,
        loadUsersError: '',
      ));

      if (e.listenRealtime) {
        _attachUsersStream(); // << não passa emit
        emit(state.copyWith(realtimeEnabled: true));
      }
      if (e.bindCurrentUser) {
        _attachMeStream(); // << não passa emit
        emit(state.copyWith(currentBindEnabled: true));
      }
    } catch (err) {
      emit(state.copyWith(isLoadingUsers: false, loadUsersError: '$err'));
    }
  }

  Future<void> _onEnsureLoaded(
      UsersEnsureLoadedRequested e,
      Emitter<UserState> emit,
      ) async {
    if (state.all.isNotEmpty) {
      if (e.listenRealtime && _usersSub == null) {
        _attachUsersStream();
        emit(state.copyWith(realtimeEnabled: true));
      }
      return;
    }
    add(const UsersRefreshRequested());
    if (e.listenRealtime) add(const UsersRealtimeToggleRequested(true));
  }

  Future<void> _onRefresh(
      UsersRefreshRequested e,
      Emitter<UserState> emit,
      ) async {
    emit(state.copyWith(isLoadingUsers: true, loadUsersError: null));
    try {
      final users = await repo.getAll();
      final byId = {
        for (final u in users)
          if ((u.uid ?? '').isNotEmpty) u.uid!: u,
      };
      emit(state.copyWith(
        initialized: true,
        all: users,
        byId: byId,
        isLoadingUsers: false,
        loadUsersError: '',
      ));
    } catch (err) {
      emit(state.copyWith(isLoadingUsers: false, loadUsersError: '$err'));
    }
  }

  Future<void> _onRealtimeToggle(
      UsersRealtimeToggleRequested e,
      Emitter<UserState> emit,
      ) async {
    if (e.enable) {
      if (_usersSub == null) _attachUsersStream();
      emit(state.copyWith(realtimeEnabled: true));
    } else {
      await _usersSub?.cancel();
      _usersSub = null;
      emit(state.copyWith(realtimeEnabled: false));
    }
  }

  Future<void> _onCurrentBindToggle(
      CurrentUserBindToggleRequested e,
      Emitter<UserState> emit,
      ) async {
    if (e.enable) {
      if (_meSub == null) _attachMeStream();
      emit(state.copyWith(currentBindEnabled: true));
    } else {
      await _meSub?.cancel();
      _meSub = null;
      emit(state.copyWith(currentBindEnabled: false));
    }
  }

  Future<void> _onFetchById(
      UserFetchByIdRequested e,
      Emitter<UserState> emit,
      ) async {
    final cached = state.byId[e.uid];
    if (cached != null) return; // já temos

    try {
      final u = await repo.getById(e.uid);
      if (u == null) return;

      final all = [...state.all];
      final idx = all.indexWhere((x) => x.uid == u.uid);
      if (idx == -1) {
        all.add(u);
      } else {
        all[idx] = u;
      }

      final byId = Map<String, UserData>.from(state.byId);
      if ((u.uid ?? '').isNotEmpty) byId[u.uid!] = u;

      emit(state.copyWith(all: all, byId: byId));
    } catch (err) {
      // silencioso
    }
  }

  Future<void> _onSave(
      UserSaveRequested e,
      Emitter<UserState> emit,
      ) async {
    try {
      await repo.save(e.user);

      // atualiza cache local
      final all = [...state.all];
      final id = (e.user.uid ?? '').trim();
      if (id.isNotEmpty) {
        final idx = all.indexWhere((x) => x.uid == id);
        if (idx == -1) {
          all.add(e.user);
        } else {
          all[idx] = e.user;
        }
      }

      final byId = Map<String, UserData>.from(state.byId);
      if (id.isNotEmpty) byId[id] = e.user;

      final current = (state.current?.uid == id) ? e.user : state.current;

      emit(state.copyWith(all: all, byId: byId, current: current));
    } catch (err) {
      // opção: expor um erro específico de save no estado
    }
  }

  Future<void> _onMarkSeen(
      UserMarkNotificationSeenRequested e,
      Emitter<UserState> emit,
      ) async {
    try {
      await repo.markNotificationSeen(e.uid, e.notificationId);
    } catch (err) {
    }
  }

  // ---- Handlers dos eventos disparados pelas streams ----

  void _onUsersStreamUpdated(
      UsersStreamUpdated e,
      Emitter<UserState> emit,
      ) {
    final byId = {
      for (final u in e.list)
        if ((u.uid ?? '').isNotEmpty) u.uid!: u,
    };
    emit(state.copyWith(all: e.list, byId: byId, loadUsersError: ''));
  }

  void _onUsersStreamError(
      UsersStreamError e,
      Emitter<UserState> emit,
      ) {
    emit(state.copyWith(loadUsersError: e.message));
  }

  void _onCurrentUserStreamUpdated(
      CurrentUserStreamUpdated e,
      Emitter<UserState> emit,
      ) {
    emit(state.copyWith(current: e.current));
  }

  // ---------------- Helpers de stream ----------------

  void _attachUsersStream() {
    _usersSub?.cancel();
    _usersSub = repo.usersStream().listen(
          (list) => add(UsersStreamUpdated(list)),
      onError: (err, [st]) => add(UsersStreamError(err.toString())),
    );
  }

  void _attachMeStream() {
    _meSub?.cancel();
    _meSub = repo.currentUserStream().listen(
          (u) => add(CurrentUserStreamUpdated(u)),
      onError: (err, [st]) {
        // opcional: logar
      },
    );
  }
}
