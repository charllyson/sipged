// lib/_blocs/system/permitions/contract_permission.dart
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/permitions/user_permission.dart' as roles;
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import '../module/module_data.dart';
import 'module_permission.dart' as mp;

/// ACL de contratos (document-level permissions).
/// - ADMINISTRADOR/DESENVOLVEDOR: acesso total (bypass)
/// - demais: precisa ter permissão no módulo + permissão no contrato
///
/// Observação:
/// - `permissionContractId` é o mapa de ACL no ProcessData:
///   { uid: {read:true, edit:false, ...}, ... }
class ContractPermissions {
  const ContractPermissions._();

  /// Perfis com acesso total ao sistema.
  static bool isSuperUser(UserData user) {
    final r = roles.roleForUser(user);
    return r == roles.UserProfile.administrador ||
        r == roles.UserProfile.desenvolvedor;
  }

  /// UID normalizado (trim) ou string vazia.
  static String _uid(UserData user) => (user.uid ?? '').trim();

  /// Converte a permissão do contrato em `ModulePermissions` (objeto forte).
  static mp.ModulePermissions docPermsOf(ProcessData contract, String uid) {
    final raw = contract.permissionContractId[uid];

    // ❗Null / tipo inesperado => sem permissões
    if (raw == null) {
      return mp.ModulePermissions.none;
    }

    // Converte chaves para String e valores para dynamic
    final m = <String, dynamic>{};
    raw.forEach((key, value) {
      m[key] = value;
    });

    return mp.ModulePermissions.fromMap(m);
  }

  /// Verifica ACL do contrato (apenas documento).
  /// Não considera permissão de módulo.
  static bool canOnDoc({
    required UserData user,
    required ProcessData contract,
    required String action, // read|create|edit|delete|approve
  }) {
    if (isSuperUser(user)) return true;

    final uid = _uid(user);
    if (uid.isEmpty) return false;

    final p = docPermsOf(contract, uid);

    // Regra: "read" é verdadeiro se qualquer ação estiver liberada
    // (quem pode editar/deletar/aprovar também precisa conseguir abrir)
    return switch (action) {
      'read' => p.read || p.create || p.edit || p.delete || p.approve,
      'create' => p.create || p.edit || p.delete || p.approve,
      'edit' => p.edit || p.delete || p.approve,
      'delete' => p.delete || p.approve,
      'approve' => p.approve,
      _ => false,
    };
  }

  /// Verifica permissão completa (RBAC módulo + ACL contrato).
  /// Use isso em lista/telas/botões.
  static bool can({
    required UserData user,
    required ProcessData contract,
    required String action, // read|create|edit|delete|approve
    String module = ModuleData.modContractsList,
  }) {
    // 1) precisa poder no módulo (RBAC)
    if (!mp.userCanModule(user: user, module: module, action: action)) {
      return false;
    }

    // 2) admins/devs passam direto
    if (isSuperUser(user)) return true;

    // 3) precisa estar na ACL do contrato
    return canOnDoc(user: user, contract: contract, action: action);
  }

  /// Filtra contratos visíveis para o usuário.
  /// - Admin/Dev: tudo
  /// - demais: somente os que passam em `can(..., action:'read')`
  static List<ProcessData> filterVisible({
    required UserData user,
    required Iterable<ProcessData> contracts,
    String module = ModuleData.modContractsList,
  }) {
    if (isSuperUser(user)) return contracts.toList(growable: false);

    return contracts
        .where(
          (c) => can(
        user: user,
        contract: c,
        action: 'read',
        module: module,
      ),
    )
        .toList(growable: false);
  }

  /// Helper para construir um map de ACL já normalizado (5 chaves),
  /// útil ao adicionar participante.
  static Map<String, bool> initialParticipantPerms() => mp.initialDocPerms();

  /// Helper: normaliza `permissionContractId[uid]` (5 chaves) para UI/exports.
  static Map<String, bool> normalizedDocPermMap(ProcessData contract, String uid) {
    final p = docPermsOf(contract, uid);
    return p.toBoolMap();
  }
}
