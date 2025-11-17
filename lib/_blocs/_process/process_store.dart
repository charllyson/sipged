import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'process_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

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

  /// Contrato atualmente selecionado (quando aplicável)
  ProcessData? get selected => _selected;

  /// Warmup inicial, chamado uma única vez a partir do MenuListPage.
  /// Usa o usuário atual para aplicar ACL básica (admin vê tudo).
  Future<void> warmup(UserData currentUser) async {
    if (initialized) return;
    await refresh(currentUser: currentUser);
    initialized = true;
  }

  /// Recarrega a lista de contratos do Firestore.
  /// Se `currentUser` for informado, aplica filtro de ACL.
  Future<void> refresh({UserData? currentUser}) async {
    if (loading) return;

    loading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('contracts').get();

      final List<ProcessData> loaded = [];

      for (final doc in snapshot.docs) {
        try {
          loaded.add(ProcessData.fromDocument(snapshot: doc));
        } catch (e, st) {
          if (kDebugMode) {
            // Se UM documento der erro, não derrubamos a lista inteira
            print(
              'ProcessStore.refresh: erro ao converter contrato ${doc.id}: $e\n$st',
            );
          }
        }
      }

      final filtered = _applyAclFilter(loaded, currentUser);

      _all
        ..clear()
        ..addAll(filtered);
    } catch (e, st) {
      if (kDebugMode) {
        // Ajuda em debug caso algo dê MUITO errado na leitura
        print('ProcessStore.refresh error: $e\n$st');
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Aplica regra simples de ACL:
  /// - administrador vê tudo
  /// - demais veem apenas contratos onde possuem permissionContractId[uid]['read'] == true
  List<ProcessData> _applyAclFilter(
      List<ProcessData> source,
      UserData? user,
      ) {
    if (user == null) return source;

    final baseProfile = (user.baseProfile ?? '').toLowerCase();
    if (baseProfile == 'administrador' || baseProfile == 'admin') {
      return source;
    }

    final uid = user.uid;
    if (uid == null || uid.isEmpty) return source;

    return source.where((p) {
      final perms = p.permissionContractId[uid];
      if (perms == null) return false;
      final canRead = perms['read'] ?? false;
      return canRead;
    }).toList();
  }

  /// Seleciona um contrato para uso em outras telas
  void select(ProcessData process) {
    _selected = process;
    notifyListeners();
  }

  /// Remove um contrato do Firestore e do cache local.
  Future<void> delete(String id) async {
    try {
      await _db.collection('contracts').doc(id).delete();
    } catch (e, st) {
      if (kDebugMode) {
        print('ProcessStore.delete Firestore error: $e\n$st');
      }
      // Mesmo que o delete remoto falhe, ainda removemos do cache
    }

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
    } catch (e, st) {
      if (kDebugMode) {
        print('ProcessStore.getById error: $e\n$st');
      }
      return null;
    }
  }
}
