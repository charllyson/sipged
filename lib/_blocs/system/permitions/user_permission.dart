import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

enum UserProfile {
  administrador,
  desenvolvedor,
  gestorRegional,
  fiscal,
  colaborador,
  leitor,
}

/// Codec centralizado:
/// - parse do Firestore -> enum
/// - serialize do enum -> Firestore
/// - label para UI
/// - mantém compatibilidade com legado
class UserRoleCodec {
  const UserRoleCodec._();

  static const Map<UserProfile, String> _ids = {
    UserProfile.administrador: 'ADMINISTRADOR',
    UserProfile.desenvolvedor: 'DESENVOLVEDOR',
    UserProfile.gestorRegional: 'GESTOR_REGIONAL',
    UserProfile.fiscal: 'FISCAL',
    UserProfile.colaborador: 'COLABORADOR',
    UserProfile.leitor: 'LEITOR',
  };

  static const Map<UserProfile, String> _labels = {
    UserProfile.administrador: 'Administrador',
    UserProfile.desenvolvedor: 'Desenvolvedor',
    UserProfile.gestorRegional: 'Gestor Regional',
    UserProfile.fiscal: 'Fiscal',
    UserProfile.colaborador: 'Colaborador',
    UserProfile.leitor: 'Leitor',
  };

  /// Retorna o ID estável para persistência no Firestore.
  static String serialize(UserProfile role) => _ids[role]!;

  /// Label amigável para UI.
  static String label(UserProfile role) => _labels[role]!;

  /// Parse tolerante:
  /// - aceita baseRole/baseProfile antigos
  /// - aceita caixa variada
  /// - aceita enum antigo ou novo
  /// - aceita legado "CONVIDADO"
  static UserProfile parse(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return UserProfile.leitor;

    final upper = value.toUpperCase();
    if (upper == 'CONVIDADO') return UserProfile.leitor;

    // 1) tenta pelos IDs estáveis do banco
    for (final entry in _ids.entries) {
      if (entry.value == upper) return entry.key;
    }

    // 2) normalização extra
    final normalizedUpper = upper.replaceAll('-', '_').replaceAll(' ', '_');
    for (final entry in _ids.entries) {
      if (entry.value == normalizedUpper) return entry.key;
    }

    // 3) compatibilidade com enum.name novo (lowerCamelCase)
    for (final role in UserProfile.values) {
      if (role.name.toLowerCase() == value.toLowerCase()) {
        return role;
      }
    }

    // 4) compatibilidade manual com nomes antigos/variantes
    switch (normalizedUpper) {
      case 'GESTORREGIONAL':
      case 'GESTOR_REGIONAL':
        return UserProfile.gestorRegional;
      case 'ADMINISTRADOR':
        return UserProfile.administrador;
      case 'DESENVOLVEDOR':
        return UserProfile.desenvolvedor;
      case 'FISCAL':
        return UserProfile.fiscal;
      case 'COLABORADOR':
        return UserProfile.colaborador;
      case 'LEITOR':
        return UserProfile.leitor;
    }

    return UserProfile.leitor;
  }
}

/// Fonte única de verdade para papel do usuário.
/// Lê baseRole e cai para baseProfile (legado).
UserProfile roleForUser(UserData user) {
  final data = user.userSnap?.data();
  if (data is Map<String, dynamic>) {
    final raw =
        (data['baseRole'] as String?) ?? (data['baseProfile'] as String?);
    return UserRoleCodec.parse(raw);
  }
  return UserProfile.leitor;
}

/// Persistência:
/// grava sempre baseRole com ID estável.
/// Opcionalmente grava baseProfile também para compatibilidade.
Future<void> setUserRole(
    UserData user,
    UserProfile newRole, {
      bool writeLegacyBaseProfile = false,
    }) async {
  final uid = user.uid;
  if (uid == null || uid.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('users').doc(uid);

  final roleId = UserRoleCodec.serialize(newRole);

  final payload = <String, dynamic>{
    'baseRole': roleId,
  };

  if (writeLegacyBaseProfile) {
    payload['baseProfile'] = roleId;
  }

  await ref.set(payload, SetOptions(merge: true));
}