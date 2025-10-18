// lib/_blocs/system/permitions/page_permission.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/system/permitions/user_permission.dart' as up;
import 'package:siged/_blocs/process/contracts/contract_data.dart';

/// ====== CHAVES PADRÃO ======
const kPermKeys = <String>['read','create','edit','delete','approve'];

/// ====== MODELO DE PERMISSÕES ======
class Perms {
  final bool read, create, edit, delete, approve;

  const Perms({
    this.read = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
    this.approve = false,
  });

  Perms copyWith({
    bool? read, bool? create, bool? edit, bool? delete, bool? approve,
  }) => Perms(
    read:    read    ?? this.read,
    create:  create  ?? this.create,
    edit:    edit    ?? this.edit,
    delete:  delete  ?? this.delete,
    approve: approve ?? this.approve,
  );

  /// Merge por OR — qualquer true prevalece.
  Perms merge(Perms other) => Perms(
    read:    read    || other.read,
    create:  create  || other.create,
    edit:    edit    || other.edit,
    delete:  delete  || other.delete,
    approve: approve || other.approve,
  );

  Map<String, bool> toBoolMap() => {
    'read': read,
    'create': create,
    'edit': edit,
    'delete': delete,
    'approve': approve,
  };

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(toBoolMap());

  factory Perms.fromMap(Map<String, dynamic>? m) {
    m ??= const {};
    return Perms(
      read:    m['read']    == true,
      create:  m['create']  == true,
      edit:    m['edit']    == true,
      delete:  m['delete']  == true,
      approve: m['approve'] == true,
    );
  }

  static const none = Perms();
}

/// ====== HELPERS BÁSICOS ======

/// Normaliza para as 5 chaves (faltantes = false).
Map<String, bool> normalizePermMap(Map<String, bool>? raw) {
  final r = raw ?? const {};
  return { for (final k in kPermKeys) k: r[k] == true };
}

/// ACL mínima quando um usuário entra num documento específico (ex.: contrato).
Map<String, bool> initialDocPerms() => const {
  'read': true, 'create': false, 'edit': false, 'delete': false, 'approve': false,
};

/// Converte qualquer mapa dinâmico para 5 chaves normalizadas.
Map<String, bool> toFiveKeys(Map? raw) =>
    normalizePermMap((raw ?? const {}).cast<String, bool>());

/// ====== DEFAULTS POR PAPEL GLOBAL (MÓDULO) ======
/// Política mista:
/// - ADMINISTRADOR/DESENVOLVEDOR: tudo liberado por padrão
/// - DEMAIS papéis: tudo false → nada aparece até marcar o checkbox (override.read)
Perms defaultPermsForRole(up.BaseRole role) {
  switch (role) {
    case up.BaseRole.ADMINISTRADOR:
    case up.BaseRole.DESENVOLVEDOR:
      return const Perms(read: true, create: true, edit: true, delete: true, approve: true);

    case up.BaseRole.GESTOR_REGIONAL:
    case up.BaseRole.FISCAL:
    case up.BaseRole.COLABORADOR:
    case up.BaseRole.LEITOR:
      return const Perms(); // todos false
  }
}

/// ====== OVERRIDES POR MÓDULO NO USUÁRIO ======
Perms getOverrideForUserModule(UserData user, String module) {
  final data = user.userSnap?.data();
  final raw = (data?['moduleOverrides'] as Map?)?.cast<String, dynamic>();
  if (raw == null) return Perms.none;
  final mod = (raw[module] as Map?)?.cast<String, dynamic>();
  if (mod == null) return Perms.none;
  return Perms.fromMap(mod);
}

Future<void> setOverrideForUserModule(UserData user, String module, Perms perms) async {
  final uid = user.id;
  if (uid == null || uid.isEmpty) return;
  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  await ref.set({'moduleOverrides': {module: perms.toMap()}}, SetOptions(merge: true));
}

/// (Opcional) Helper para obter permissões efetivas já mescladas
Perms effectiveModulePerms(UserData user, String module) {
  final base = defaultPermsForRole(up.roleForUser(user));
  final ov   = getOverrideForUserModule(user, module);
  return base.merge(ov);
}

/// ====== CHECAGENS (UI / ROUTER / AÇÕES) ======
/// Visibilidade do menu (Drawer) e acesso básico à página.
/// Agora é **estrito por read**: só aparece se read == true (após checkbox).
bool userCanModule({
  required UserData user,
  required String module,
  required String action, // read|create|edit|delete|approve
}) {
  final eff = effectiveModulePerms(user, module);

  switch (action) {
    case 'read':    return eff.read; // <<< EXIGÊNCIA ESTRITA
    case 'create':  return eff.create || eff.edit || eff.delete || eff.approve;
    case 'edit':    return eff.edit   || eff.delete || eff.approve;
    case 'delete':  return eff.delete || eff.approve;
    case 'approve': return eff.approve;
  }
  return false;
}

/// Regras complementares por documento (ex.: contrato).
/// A página pode permitir leitura se o módulo tiver read (já filtrado acima),
/// e travar botões de edição quando o documento não conceder.
bool userCanOnContract({
  required UserData user,
  required ContractData contract,
  required String action, // read|create|edit|delete|approve
}) {
  // Primeiro: precisa ter acesso ao módulo 'contracts' para a ação.
  if (!userCanModule(user: user, module: 'contracts', action: action)) {
    return false;
  }

  final uid = user.id ?? '';
  final docPerms = contract.permissionContractId[uid];

  // Se não houver ACL específica no documento:
  // - Para 'read': permite, pois o módulo já passou (checkbox + papel)
  // - Para ações de escrita: nega (até que admin libere no documento)
  if (docPerms == null) {
    if (action == 'read') return true;
    return false;
  }

  final p = Perms.fromMap(docPerms);

  switch (action) {
    case 'read':    return p.read || p.create || p.edit || p.delete || p.approve;
    case 'create':  return p.create || p.edit || p.delete || p.approve;
    case 'edit':    return p.edit   || p.delete || p.approve;
    case 'delete':  return p.delete || p.approve;
    case 'approve': return p.approve;
  }
  return false;
}
