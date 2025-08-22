import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:sisged/_repository/system/user_repository.dart';
import 'package:sisged/_datas/system/user_data.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({required this.repo});
  final UserRepository repo;

  UserData? _userData;
  final List<UserData> _list = [];
  final Map<String, UserData> _byId = {};
  StreamSubscription? _sub;         // stream do "users" (realtime)
  StreamSubscription? _meSub;       // stream do usuário atual

  /// Usuário atual (do FirebaseAuth / coleção users)
  UserData? get current => _userData;

  /// Lista imutável com todos os usuários carregados
  List<UserData> get all => List.unmodifiable(_list);

  // Compatibilidade legada
  UserData? get userData => _userData;
  UserData? get user => _userData;
  final List<UserData> _userDataList = [];
  List<UserData> get userDataList => _userDataList;

  void addUser(UserData user) {
    _userDataList.add(user);
    notifyListeners();
  }

  void setUserData(UserData data) {
    _userData = data;
    notifyListeners();
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }

  /// Carrega a lista de usuários uma vez. Se [listenRealtime] for true,
  /// fica escutando mudanças na coleção `users`.
  Future<void> ensureLoaded({bool listenRealtime = false}) async {
    if (_list.isNotEmpty) {
      // Já carregado; ainda assim habilite o realtime se solicitado
      if (listenRealtime && _sub == null) {
        _listenAllUsersRealtime();
      }
      return;
    }

    final users = await repo.getAll();
    _sync(users);

    if (listenRealtime && _sub == null) {
      _listenAllUsersRealtime();
    }
  }

  void _listenAllUsersRealtime() {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((d) => UserData.fromDocument(snapshot: d))
          .toList();
      _sync(list);
    });
  }

  /// Mantém _userData em tempo real para o usuário autenticado
  void bindCurrentUser() {
    _meSub?.cancel();
    _meSub = repo.currentUserStream().listen((u) {
      _userData = u;
      notifyListeners();
    });
  }

  /// Busca por UID com cache: primeiro tenta no `_byId`, se não existir
  /// consulta o Firestore e atualiza o cache.
  Future<UserData?> fetchById(String uid) async {
    if (uid.isEmpty) return null;
    final cached = _byId[uid];
    if (cached != null) return cached;

    final u = await repo.getById(uid);
    if (u != null && (u.id ?? '').isNotEmpty) {
      _byId[u.id!] = u;
      // garante consistência com a lista
      final idx = _list.indexWhere((x) => x.id == u.id);
      if (idx == -1) {
        _list.add(u);
      } else {
        _list[idx] = u;
      }
      notifyListeners();
    }
    return u;
  }

  /// Retorna o UserData do UID, se tiver em cache (rápido).
  /// Para buscar no banco quando não estiver em cache, use [fetchById].
  UserData? dataFor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return _byId[uid];
  }

  /// Retorna um rótulo legível (nome + sobrenome) para o UID.
  /// Fallbacks: mostra `id` se não houver nome; caso nada, retorna `fallback`.
  String labelFor(String? uid, {String fallback = '—'}) {
    if (uid == null || uid.isEmpty) return fallback;
    final u = _byId[uid];
    final name = (u?.name ?? '').trim();
    final surname = (u?.surname ?? '').trim();
    final full = [name, surname].where((s) => s.isNotEmpty).join(' ').trim();
    return full.isEmpty ? (u?.id ?? fallback) : full;
  }

  /// Sincroniza lista e mapa, preservando consistência e notificando listeners.
  void _sync(List<UserData> users) {
    _list
      ..clear()
      ..addAll(users);

    _byId
      ..clear()
      ..addEntries(
        users
            .where((u) => (u.id ?? '').isNotEmpty)
            .map((u) => MapEntry(u.id!, u)),
      );

    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _meSub?.cancel();
    super.dispose();
  }
}
