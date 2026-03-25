import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'process_data.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

// 🔹 Regras de permissão centralizadas
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/_blocs/system/permitions/module_permission.dart' as perms;

/// Store central de contratos (ProcessData).
/// Mantém um cache em memória e avisa listeners via ChangeNotifier.
class ProcessStore extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;
  bool initialized = false;

  final List<ProcessData> _all = [];
  ProcessData? _selected;

  /// Lista imutável de contratos carregados
  List<ProcessData> get all => List.unmodifiable(_all);

  /// Usa o usuário atual para aplicar ACL básica (via regras centralizadas).
  Future<void> warmup(UserData currentUser) async {
    if (initialized) return;
    await refresh(currentUser: currentUser);
    initialized = true;
  }

  /// Recarrega a lista de contratos do Firestore.
  Future<void> refresh({UserData? currentUser}) async {
    if (loading) return;

    loading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('contracts').get();

      final List<ProcessData> loaded = [];

      for (final doc in snapshot.docs) {
        loaded.add(ProcessData.fromDocument(snapshot: doc));
      }

      // 🔹 Aplica ACL usando a MESMA regra do sistema (userCanOnContract)
      final filtered = _applyAclFilter(loaded, currentUser);

      _all
        ..clear()
        ..addAll(filtered);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Aplica regra de ACL unificada:
  /// - ADMINISTRADOR / DESENVOLVEDOR veem tudo
  /// - Demais perfis usam perms.userCanOnContract (módulo "contracts", ação "read")
  List<ProcessData> _applyAclFilter(
      List<ProcessData> source,
      UserData? user,
      ) {
    if (user == null) return source;

    final baseRole = roles.roleForUser(user);

    // 🔹 Admin & Dev: acesso total, independente da ACL do documento
    if (baseRole == roles.UserProfile.ADMINISTRADOR ||
        baseRole == roles.UserProfile.DESENVOLVEDOR) {
      return source;
    }

    // 🔹 Demais perfis: delega para regra centralizada de permissão por documento
    return source.where((contract) {
      return perms.userCanOnContract(
        user: user,
        contract: contract,
        action: 'read',
      );
    }).toList();
  }

  /// Seleciona um contrato para uso em outras telas
  void select(ProcessData process) {
    _selected = process;
    notifyListeners();
  }

  /// Remove um contrato do Firestore e do cache local.
  Future<void> delete(String id) async {
    await _db.collection('contracts').doc(id).delete();
    _all.removeWhere((p) => p.id == id);
    if (_selected?.id == id) {
      _selected = null;
    }
    notifyListeners();
  }

  ProcessData? _findInCache(String id) {
    try {
      return _all.firstWhere((p) => (p.id ?? '') == id);
    } catch (_) {
      return null;
    }
  }

  /// Obtém contrato por ID usando primeiro o cache local.
  /// Se não encontrar, tenta buscar 1x no Firestore, adiciona ao cache e devolve.
  Future<ProcessData?> getById(String id) async {
    if (id.isEmpty) return null;

    final cached = _findInCache(id);
    if (cached != null) return cached;

    try {
      final doc = await _db.collection('contracts').doc(id).get();
      if (!doc.exists) return null;

      final process = ProcessData.fromDocument(snapshot: doc);
      _all.add(process);
      notifyListeners();
      return process;
    } catch (e) {
      return null;
    }
  }
}
