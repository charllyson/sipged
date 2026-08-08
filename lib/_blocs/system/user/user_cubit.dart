// lib/_blocs/system/user/user_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit(this.repo) : super(const UserState());

  final UserRepository repo;

  StreamSubscription<List<UserData>>? _usersSub;
  StreamSubscription<UserData?>? _meSub;

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
    emit(
      state.copyWith(
        isLoadingUsers: true,
        clearLoadUsersError: true,
      ),
    );

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
        for (final user in users)
          if ((user.uid ?? '').trim().isNotEmpty) user.uid!.trim(): user,
      };

      emit(
        state.copyWith(
          initialized: true,
          all: users,
          byId: byId,
          isLoadingUsers: false,
          loadUsersError: '',
        ),
      );

      if (listenRealtime) {
        await setRealtimeEnabled(true);
      }

      if (bindCurrentUser) {
        await setCurrentUserBindEnabled(true);
      }
    } catch (err) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoadingUsers: false,
          loadUsersError: '$err',
        ),
      );
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
    emit(
      state.copyWith(
        isLoadingUsers: true,
        clearLoadUsersError: true,
      ),
    );

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
        for (final user in users)
          if ((user.uid ?? '').trim().isNotEmpty) user.uid!.trim(): user,
      };

      emit(
        state.copyWith(
          initialized: true,
          all: users,
          byId: byId,
          isLoadingUsers: false,
          loadUsersError: '',
        ),
      );
    } catch (err) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isLoadingUsers: false,
          loadUsersError: '$err',
        ),
      );
    }
  }

  Future<void> setRealtimeEnabled(bool enable) async {
    if (enable) {
      if (_usersSub == null) {
        _attachUsersStream();
      }

      emit(
        state.copyWith(
          realtimeEnabled: true,
        ),
      );
    } else {
      await _usersSub?.cancel();
      _usersSub = null;

      emit(
        state.copyWith(
          realtimeEnabled: false,
        ),
      );
    }
  }

  Future<void> setCurrentUserBindEnabled(bool enable) async {
    if (enable) {
      if (_meSub == null) {
        _attachMeStream();
      }

      emit(
        state.copyWith(
          currentBindEnabled: true,
        ),
      );
    } else {
      await _meSub?.cancel();
      _meSub = null;

      emit(
        state.copyWith(
          currentBindEnabled: false,
        ),
      );
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

      _upsertUserInState(user);

      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserData user) async {
    emit(
      state.copyWith(
        isSavingUser: true,
        clearSaveUserError: true,
      ),
    );

    try {
      await repo.save(user);

      _upsertUserInState(user);

      emit(
        state.copyWith(
          isSavingUser: false,
          saveUserError: '',
        ),
      );
    } catch (err) {
      if (isClosed) return;

      emit(
        state.copyWith(
          isSavingUser: false,
          saveUserError: '$err',
        ),
      );

      rethrow;
    }
  }

  Future<void> deactivateUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.deactivateUser(id);
    await _refreshUserAfterDirectUpdate(id);
  }

  Future<void> reactivateUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.reactivateUser(id);
    await _refreshUserAfterDirectUpdate(id);
  }

  Future<void> blockUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.blockUser(id);
    await _refreshUserAfterDirectUpdate(id);
  }

  Future<void> softDeleteUser(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.softDeleteUser(id);
    await _refreshUserAfterDirectUpdate(id);
  }

  Future<void> hardDeleteUserDocument(String uid) async {
    final id = uid.trim();

    if (id.isEmpty) return;

    await repo.hardDeleteUserDocument(id);

    final all = [...state.all]..removeWhere((user) => user.uid == id);
    final byId = Map<String, UserData>.from(state.byId)..remove(id);

    final isCurrentDeleted = state.current?.uid == id;

    emit(
      state.copyWith(
        all: all,
        byId: byId,
        setCurrentNull: isCurrentDeleted,
      ),
    );
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
      emit(
        state.copyWith(
          setCurrentNull: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        current: user,
      ),
    );
  }

  void clearCurrentUser() {
    emit(
      state.copyWith(
        setCurrentNull: true,
      ),
    );
  }

  List<String> tenantIdsOf(UserData? user) {
    if (user == null) return const <String>[];

    final ids = <String>[
      ...user.tenantIds,
      ...UserData.tenantIdsFromRawData(user.rawData),
    ];

    return _cleanStringList(ids);
  }

  List<String> tenantIdsOfUid(String uid) {
    final id = uid.trim();

    if (id.isEmpty) return const <String>[];

    return tenantIdsOf(state.byId[id]);
  }

  List<String> get currentTenantIds {
    return tenantIdsOf(state.current);
  }

  String? currentTenantIdOf(UserData? user) {
    if (user == null) return null;

    final active = user.activeTenantId?.trim();

    if (active != null && active.isNotEmpty) return active;

    final raw = user.rawData;

    final value = raw['currentTenantId'] ??
        raw['selectedTenantId'] ??
        raw['activeTenantId'] ??
        raw['lastTenantId'];

    final text = value?.toString().trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }

  String? currentTenantIdOfUid(String uid) {
    final id = uid.trim();

    if (id.isEmpty) return null;

    return currentTenantIdOf(state.byId[id]);
  }

  bool userHasTenantAccess({
    required UserData user,
    required String tenantId,
  }) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) return false;

    return tenantIdsOf(user).contains(cleanTenantId);
  }

  bool currentUserHasTenantAccess(String tenantId) {
    final current = state.current;

    if (current == null) return false;

    return userHasTenantAccess(
      user: current,
      tenantId: tenantId,
    );
  }

  Future<void> setUserTenantAccess({
    required String uid,
    required List<String> tenantIds,
    String? currentTenantId,
    bool refreshAfterSave = true,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;

    await repo.setUserTenantAccess(
      uid: cleanUid,
      tenantIds: tenantIds,
      currentTenantId: currentTenantId,
    );

    if (refreshAfterSave) {
      await _refreshUserAfterDirectUpdate(cleanUid);
    }
  }

  Future<void> addTenantToUser({
    required String uid,
    required String tenantId,
    bool makeCurrent = false,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    await repo.addTenantToUser(
      uid: cleanUid,
      tenantId: cleanTenantId,
      makeCurrent: makeCurrent,
    );

    await _refreshUserAfterDirectUpdate(cleanUid);
  }

  Future<void> removeTenantFromUser({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    await repo.removeTenantFromUser(
      uid: cleanUid,
      tenantId: cleanTenantId,
    );

    await _refreshUserAfterDirectUpdate(cleanUid);
  }

  Future<void> toggleTenantAccessForUser({
    required String uid,
    required String tenantId,
    required bool allow,
  }) async {
    if (allow) {
      await addTenantToUser(
        uid: uid,
        tenantId: tenantId,
      );
      return;
    }

    await removeTenantFromUser(
      uid: uid,
      tenantId: tenantId,
    );
  }

  Future<void> setCurrentTenantForUser({
    required String uid,
    required String tenantId,
  }) async {
    final cleanUid = uid.trim();
    final cleanTenantId = tenantId.trim();

    if (cleanUid.isEmpty || cleanTenantId.isEmpty) return;

    final user = state.byId[cleanUid] ?? await repo.getById(cleanUid);
    final tenantIds = tenantIdsOf(user);

    if (!tenantIds.contains(cleanTenantId)) {
      throw StateError(
        'O usuário não possui acesso à empresa selecionada.',
      );
    }

    await repo.setCurrentTenantForUser(
      uid: cleanUid,
      tenantId: cleanTenantId,
    );

    await _refreshUserAfterDirectUpdate(cleanUid);
  }

  Future<void> clearUserTenantAccess({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;

    await repo.clearUserTenantAccess(uid: cleanUid);
    await _refreshUserAfterDirectUpdate(cleanUid);
  }

  Future<void> _refreshUserAfterDirectUpdate(String uid) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;

    final updated = await repo.getById(cleanUid);

    if (updated == null) {
      await refreshUsers();
      return;
    }

    _upsertUserInState(updated);
  }

  void _upsertUserInState(UserData user) {
    final id = (user.uid ?? '').trim();

    if (id.isEmpty) return;

    final all = [...state.all];
    final index = all.indexWhere((item) => item.uid == id);

    if (index == -1) {
      all.add(user);
    } else {
      all[index] = user;
    }

    final byId = Map<String, UserData>.from(state.byId);
    byId[id] = user;

    final current = state.current?.uid == id ? user : state.current;

    emit(
      state.copyWith(
        all: all,
        byId: byId,
        current: current,
      ),
    );
  }

  void _attachUsersStream() {
    _usersSub?.cancel();

    _usersSub = repo.usersStream().listen(
          (list) {
        if (isClosed) return;

        final byId = <String, UserData>{
          for (final user in list)
            if ((user.uid ?? '').trim().isNotEmpty) user.uid!.trim(): user,
        };

        final currentUid = state.current?.uid?.trim();

        final current = currentUid == null || currentUid.isEmpty
            ? state.current
            : byId[currentUid] ?? state.current;

        emit(
          state.copyWith(
            all: list,
            byId: byId,
            current: current,
            initialized: true,
            loadUsersError: '',
          ),
        );
      },
      onError: (err, [stackTrace]) {
        if (isClosed) return;

        emit(
          state.copyWith(
            loadUsersError: err.toString(),
          ),
        );
      },
    );
  }

  void _attachMeStream() {
    _meSub?.cancel();

    _meSub = repo.currentUserStream().listen(
          (user) {
        if (isClosed) return;

        if (user == null) {
          emit(
            state.copyWith(
              setCurrentNull: true,
            ),
          );
          return;
        }

        final id = (user.uid ?? '').trim();

        if (id.isEmpty) {
          emit(
            state.copyWith(
              current: user,
            ),
          );
          return;
        }

        final all = [...state.all];
        final index = all.indexWhere((item) => item.uid == id);

        if (index == -1) {
          all.add(user);
        } else {
          all[index] = user;
        }

        final byId = Map<String, UserData>.from(state.byId);
        byId[id] = user;

        emit(
          state.copyWith(
            current: user,
            all: all,
            byId: byId,
          ),
        );
      },
      onError: (err, [stackTrace]) {
        if (isClosed) return;

        emit(
          state.copyWith(
            setCurrentNull: true,
          ),
        );
      },
    );
  }

  List<String> _cleanStringList(Iterable<String> values) {
    final list = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }
}