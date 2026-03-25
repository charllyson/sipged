// lib/_blocs/system/permitions/user_permission.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

enum UserProfile {
  ADMINISTRADOR,
  DESENVOLVEDOR,
  GESTOR_REGIONAL,
  FISCAL,
  COLABORADOR,
  LEITOR,
}

/// Codec centralizado: parse, serialize e label num só lugar.
/// - Aceita baseRole/baseProfile
/// - Aceita variações de caixa/espacos
/// - Aceita legado "CONVIDADO"
class UserRoleCodec {
  static UserProfile parse(String? raw) {
    final up = (raw ?? '').trim().toUpperCase();

    // suporte legado e tolerância
    if (up.isEmpty) return UserProfile.LEITOR;
    if (up == 'CONVIDADO') return UserProfile.LEITOR;

    // tentativa direta pelo enum.name
    for (final r in UserProfile.values) {
      if (r.name == up) return r;
    }

    // tolerância extra (caso venha com espaço, traço etc.)
    final normalized = up.replaceAll('-', '_').replaceAll(' ', '_');
    for (final r in UserProfile.values) {
      if (r.name == normalized) return r;
    }

    return UserProfile.LEITOR;
  }

  static String serialize(UserProfile role) => role.name;

  static String label(UserProfile role) {
    switch (role) {
      case UserProfile.ADMINISTRADOR:
        return 'Administrador';
      case UserProfile.DESENVOLVEDOR:
        return 'Desenvolvedor';
      case UserProfile.GESTOR_REGIONAL:
        return 'Gestor Regional';
      case UserProfile.FISCAL:
        return 'Fiscal';
      case UserProfile.COLABORADOR:
        return 'Colaborador';
      case UserProfile.LEITOR:
        return 'Leitor';
    }
  }
}

/// Fonte única de verdade para papel do usuário.
/// ✅ lê baseRole e cai para baseProfile (legado)
UserProfile roleForUser(UserData user) {
  final data = user.userSnap?.data();
  if (data is Map<String, dynamic>) {
    final raw = (data['baseRole'] as String?) ?? (data['baseProfile'] as String?);
    return UserRoleCodec.parse(raw);
  }
  return UserProfile.LEITOR;
}

/// Persistência: grava sempre baseRole com id estável (enum.name).
/// (Opcional) pode gravar também baseProfile para apps antigos.
Future<void> setUserRole(
    UserData user,
    UserProfile newRole, {
      bool writeLegacyBaseProfile = false,
    }) async {
  final uid = user.uid;
  if (uid == null || uid.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  final payload = <String, dynamic>{
    'baseRole': UserRoleCodec.serialize(newRole),
  };

  if (writeLegacyBaseProfile) {
    payload['baseProfile'] = UserRoleCodec.serialize(newRole);
  }

  await ref.set(payload, SetOptions(merge: true));
}
