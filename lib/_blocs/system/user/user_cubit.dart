// lib/_blocs/system/user/user_cubit.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_repository.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository repo;

  StreamSubscription<List<UserData>>? _usersSub;
  StreamSubscription<UserData?>? _meSub;

  UserCubit(this.repo) : super(const UserState());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol {
    return _db.collection('users');
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _usersCol.doc(uid.trim());
  }

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
        loadUsersError: null,
      ),
    );

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
        for (final u in users)
          if ((u.uid ?? '').isNotEmpty) u.uid!: u,
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
        loadUsersError: null,
      ),
    );

    try {
      final users = await repo.getAll();

      final byId = <String, UserData>{
        for (final u in users)
          if ((u.uid ?? '').isNotEmpty) u.uid!: u,
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
    try {
      await repo.save(user);
      _upsertUserInState(user);
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
    final raw = user?.userSnap?.data();

    if (raw == null) return const <String>[];

    return _tenantIdsFromMap(raw);
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
    final raw = user?.userSnap?.data();

    if (raw == null) return null;

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

    final cleanedTenantIds = _cleanStringList(tenantIds);

    final cleanCurrentTenantId = currentTenantId?.trim();

    final effectiveCurrentTenantId = cleanCurrentTenantId != null &&
        cleanCurrentTenantId.isNotEmpty &&
        cleanedTenantIds.contains(cleanCurrentTenantId)
        ? cleanCurrentTenantId
        : cleanedTenantIds.isNotEmpty
        ? cleanedTenantIds.first
        : null;

    final tenantAccessUpdates = <String, dynamic>{};

    for (final tenantId in cleanedTenantIds) {
      tenantAccessUpdates[tenantId] = {
        'enabled': true,
      };
    }

    final data = <String, dynamic>{
      'tenantIds': cleanedTenantIds,
      'allowedTenantIds': cleanedTenantIds,
      'accessibleTenantIds': cleanedTenantIds,
      'companyIds': cleanedTenantIds,
      'allowedCompanyIds': cleanedTenantIds,
      'accessibleCompanyIds': cleanedTenantIds,
      'tenantAccess': tenantAccessUpdates,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (effectiveCurrentTenantId == null || effectiveCurrentTenantId.isEmpty) {
      data['currentTenantId'] = FieldValue.delete();
      data['selectedTenantId'] = FieldValue.delete();
      data['activeTenantId'] = FieldValue.delete();
      data['lastTenantId'] = FieldValue.delete();
    } else {
      data['currentTenantId'] = effectiveCurrentTenantId;
      data['selectedTenantId'] = effectiveCurrentTenantId;
      data['activeTenantId'] = effectiveCurrentTenantId;
      data['lastTenantId'] = effectiveCurrentTenantId;
    }

    await _userDoc(cleanUid).set(
      data,
      SetOptions(merge: true),
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

    final user = state.byId[cleanUid] ?? await repo.getById(cleanUid);
    final currentTenantIds = tenantIdsOf(user);

    final updatedTenantIds = _replaceOrAppendString(
      currentTenantIds,
      cleanTenantId,
    );

    final currentTenantId = makeCurrent
        ? cleanTenantId
        : currentTenantIdOf(user) ?? cleanTenantId;

    await _userDoc(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: {
            'enabled': true,
          },
        },
        'tenantIds': updatedTenantIds,
        'allowedTenantIds': updatedTenantIds,
        'accessibleTenantIds': updatedTenantIds,
        'companyIds': updatedTenantIds,
        'allowedCompanyIds': updatedTenantIds,
        'accessibleCompanyIds': updatedTenantIds,
        'currentTenantId': currentTenantId,
        'selectedTenantId': currentTenantId,
        'activeTenantId': currentTenantId,
        'lastTenantId': currentTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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

    final user = state.byId[cleanUid] ?? await repo.getById(cleanUid);
    final currentTenantIds = tenantIdsOf(user);

    final updatedTenantIds = _removeStringItem(
      currentTenantIds,
      cleanTenantId,
    );

    final oldCurrentTenantId = currentTenantIdOf(user);

    final nextCurrentTenantId =
    oldCurrentTenantId == cleanTenantId ? null : oldCurrentTenantId;

    await _userDoc(cleanUid).set(
      {
        'tenantAccess': {
          cleanTenantId: FieldValue.delete(),
        },
        'tenantsAccess': {
          cleanTenantId: FieldValue.delete(),
        },
        'companyAccess': {
          cleanTenantId: FieldValue.delete(),
        },
        'companiesAccess': {
          cleanTenantId: FieldValue.delete(),
        },
        'tenantRoles': {
          cleanTenantId: FieldValue.delete(),
        },
        'tenantModuleOverrides': {
          cleanTenantId: FieldValue.delete(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await setUserTenantAccess(
      uid: cleanUid,
      tenantIds: updatedTenantIds,
      currentTenantId: nextCurrentTenantId,
    );
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

    await _userDoc(cleanUid).set(
      {
        'currentTenantId': cleanTenantId,
        'selectedTenantId': cleanTenantId,
        'activeTenantId': cleanTenantId,
        'lastTenantId': cleanTenantId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _refreshUserAfterDirectUpdate(cleanUid);
  }

  Future<void> clearUserTenantAccess({
    required String uid,
  }) async {
    final cleanUid = uid.trim();

    if (cleanUid.isEmpty) return;

    await _userDoc(cleanUid).set(
      {
        'tenantIds': <String>[],
        'allowedTenantIds': <String>[],
        'accessibleTenantIds': <String>[],
        'companyIds': <String>[],
        'allowedCompanyIds': <String>[],
        'accessibleCompanyIds': <String>[],
        'tenantAccess': <String, dynamic>{},
        'tenantsAccess': <String, dynamic>{},
        'companyAccess': <String, dynamic>{},
        'companiesAccess': <String, dynamic>{},
        'tenantRoles': <String, dynamic>{},
        'tenantModuleOverrides': <String, dynamic>{},
        'currentTenantId': FieldValue.delete(),
        'selectedTenantId': FieldValue.delete(),
        'activeTenantId': FieldValue.delete(),
        'lastTenantId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

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
    final idx = all.indexWhere((x) => x.uid == id);

    if (idx == -1) {
      all.add(user);
    } else {
      all[idx] = user;
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
          for (final u in list)
            if ((u.uid ?? '').isNotEmpty) u.uid!: u,
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
      onError: (err, [st]) {
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
        final idx = all.indexWhere((item) => item.uid == id);

        if (idx == -1) {
          all.add(user);
        } else {
          all[idx] = user;
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
      onError: (err, [st]) {
        if (isClosed) return;

        emit(
          state.copyWith(
            setCurrentNull: true,
          ),
        );
      },
    );
  }

  List<String> _tenantIdsFromMap(Map<String, dynamic> data) {
    final ids = <String>[
      ..._listFromDynamic(data['tenantIds']),
      ..._listFromDynamic(data['allowedTenantIds']),
      ..._listFromDynamic(data['accessibleTenantIds']),
      ..._listFromDynamic(data['companyIds']),
      ..._listFromDynamic(data['allowedCompanyIds']),
      ..._listFromDynamic(data['accessibleCompanyIds']),
      ..._mapKeysFromDynamic(data['tenantAccess']),
      ..._mapKeysFromDynamic(data['tenantsAccess']),
      ..._mapKeysFromDynamic(data['companyAccess']),
      ..._mapKeysFromDynamic(data['companiesAccess']),
      ..._mapKeysFromDynamic(data['tenantRoles']),
      ..._mapKeysFromDynamic(data['tenantModuleOverrides']),
    ];

    return _cleanStringList(ids);
  }

  List<String> _listFromDynamic(dynamic value) {
    if (value == null) return const <String>[];

    if (value is List) {
      return _cleanStringList(
        value
            .map((item) => item?.toString() ?? '')
            .where((item) => item.trim().isNotEmpty),
      );
    }

    if (value is String) {
      return _cleanStringList(
        value
            .split(RegExp(r'[\n,;]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      );
    }

    return const <String>[];
  }

  List<String> _mapKeysFromDynamic(dynamic value) {
    if (value is! Map) return const <String>[];

    final keys = <String>[];

    for (final entry in value.entries) {
      final key = entry.key?.toString().trim() ?? '';

      if (key.isEmpty) continue;

      final rawValue = entry.value;

      if (rawValue is Map) {
        final enabled = rawValue['enabled'];
        final active = rawValue['active'];
        final allowed = rawValue['allowed'];

        if (enabled == false || active == false || allowed == false) {
          continue;
        }
      }

      keys.add(key);
    }

    return _cleanStringList(keys);
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

  List<String> _replaceOrAppendString(
      List<String> list,
      String value,
      ) {
    final clean = value.trim();

    if (clean.isEmpty) return _cleanStringList(list);

    final updated = [...list];

    final index = updated.indexWhere(
          (item) => item.trim().toLowerCase() == clean.toLowerCase(),
    );

    if (index < 0) {
      updated.add(clean);
    } else {
      updated[index] = clean;
    }

    return _cleanStringList(updated);
  }

  List<String> _removeStringItem(
      List<String> list,
      String value,
      ) {
    final clean = value.trim().toLowerCase();

    if (clean.isEmpty) return _cleanStringList(list);

    return _cleanStringList(
      list.where(
            (item) => item.trim().toLowerCase() != clean,
      ),
    );
  }
}