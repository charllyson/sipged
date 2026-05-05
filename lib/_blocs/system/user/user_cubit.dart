import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repo;

  StreamSubscription<List<UserData>>? _usersSub;
  StreamSubscription<UserData?>? _meSub;

  UserCubit(this.repo) : super(const UserState());

  @override
  Future<void> close() async {
    await _usersSub?.cancel();
    await _meSub?.cancel();
    return super.close();
  }

  Future<void> warmup({
    bool listenRealtime = false,
    bool bindCurrentUser = true,
  }) async {
    emit(state.copyWith(
      isLoadingUsers: true,
      loadUsersError: null,
    ));

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
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

      if (listenRealtime) {
        await setRealtimeEnabled(true);
      }

      if (bindCurrentUser) {
        await setCurrentUserBindEnabled(true);
      }
    } catch (err) {
      if (isClosed) return;

      emit(state.copyWith(
        isLoadingUsers: false,
        loadUsersError: '$err',
      ));
    }
  }

  Future<void> ensureLoaded({
    bool listenRealtime = false,
  }) async {
    if (state.all.isNotEmpty) {
      if (listenRealtime && _usersSub == null) {
        await setRealtimeEnabled(true);
      }

      return;
    }

    await refreshUsers();

    if (listenRealtime) {
      await setRealtimeEnabled(true);
    }
  }

  Future<void> refreshUsers() async {
    emit(state.copyWith(
      isLoadingUsers: true,
      loadUsersError: null,
    ));

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
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
      if (isClosed) return;

      emit(state.copyWith(
        isLoadingUsers: false,
        loadUsersError: '$err',
      ));
    }
  }

  Future<void> setRealtimeEnabled(bool enable) async {
    if (enable) {
      if (_usersSub == null) {
        _attachUsersStream();
      }

      emit(state.copyWith(
        realtimeEnabled: true,
      ));
    } else {
      await _usersSub?.cancel();
      _usersSub = null;

      emit(state.copyWith(
        realtimeEnabled: false,
      ));
    }
  }

  Future<void> setCurrentUserBindEnabled(bool enable) async {
    if (enable) {
      if (_meSub == null) {
        _attachMeStream();
      }

      emit(state.copyWith(
        currentBindEnabled: true,
      ));
    } else {
      await _meSub?.cancel();
      _meSub = null;

      emit(state.copyWith(
        currentBindEnabled: false,
      ));
    }
  }

  Future<UserData?> fetchById(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return null;

    final cached = state.byId[id];
    if (cached != null) return cached;

    try {
      final user = await repo.getById(id);

      if (user == null) return null;

      final all = [...state.all];
      final idx = all.indexWhere((x) => x.uid == user.uid);

      if (idx == -1) {
        all.add(user);
      } else {
        all[idx] = user;
      }

      final byId = Map<String, UserData>.from(state.byId);

      if ((user.uid ?? '').isNotEmpty) {
        byId[user.uid!] = user;
      }

      emit(state.copyWith(
        all: all,
        byId: byId,
      ));

      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserData user) async {
    try {
      await repo.save(user);

      final all = [...state.all];
      final id = (user.uid ?? '').trim();

      if (id.isNotEmpty) {
        final idx = all.indexWhere((x) => x.uid == id);

        if (idx == -1) {
          all.add(user);
        } else {
          all[idx] = user;
        }
      }

      final byId = Map<String, UserData>.from(state.byId);

      if (id.isNotEmpty) {
        byId[id] = user;
      }

      final current = state.current?.uid == id ? user : state.current;

      emit(state.copyWith(
        all: all,
        byId: byId,
        current: current,
      ));
    } catch (_) {
      // Opcional: expor saveError no UserState.
    }
  }

  Future<void> deactivateUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.deactivateUser(id);
    await refreshUsers();
  }

  Future<void> reactivateUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.reactivateUser(id);
    await refreshUsers();
  }

  Future<void> blockUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.blockUser(id);
    await refreshUsers();
  }

  Future<void> softDeleteUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.softDeleteUser(id);
    await refreshUsers();
  }

  Future<void> hardDeleteUserDocument(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.hardDeleteUserDocument(id);

    final all = [...state.all]..removeWhere((u) => u.uid == id);
    final byId = Map<String, UserData>.from(state.byId)..remove(id);

    final isCurrentDeleted = state.current?.uid == id;

    emit(state.copyWith(
      all: all,
      byId: byId,
      setCurrentNull: isCurrentDeleted,
    ));
  }

  Future<void> markNotificationSeen({
    required String uid,
    required String notificationId,
  }) async {
    try {
      await repo.markNotificationSeen(uid, notificationId);
    } catch (_) {
      // Silencioso.
    }
  }

  void setCurrentUser(UserData? user) {
    if (user == null) {
      emit(state.copyWith(
        setCurrentNull: true,
      ));
      return;
    }

    emit(state.copyWith(
      current: user,
    ));
  }

  void clearCurrentUser() {
    emit(state.copyWith(
      setCurrentNull: true,
    ));
  }

  void _attachUsersStream() {
    _usersSub?.cancel();

    _usersSub = repo.usersStream().listen(
          (list) {
        if (isClosed) return;

        final byId = <String, UserData>{
          for (final u in list)
            if ((u.uid ?? '').isNotEmpty) u.uid!: u,
        };

        emit(state.copyWith(
          all: list,
          byId: byId,
          initialized: true,
          loadUsersError: '',
        ));
      },
      onError: (err, [st]) {
        if (isClosed) return;

        emit(state.copyWith(
          loadUsersError: err.toString(),
        ));
      },
    );
  }

  void _attachMeStream() {
    _meSub?.cancel();

    _meSub = repo.currentUserStream().listen(
          (user) {
        if (isClosed) return;

        if (user == null) {
          emit(state.copyWith(
            setCurrentNull: true,
          ));
          return;
        }

        emit(state.copyWith(
          current: user,
        ));
      },
      onError: (err, [st]) {
        if (isClosed) return;

        emit(state.copyWith(
          setCurrentNull: true,
        ));
      },
    );
  }
}