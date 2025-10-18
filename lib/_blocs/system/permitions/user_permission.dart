import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

/// Papel global do usuário
enum BaseRole {
  ADMINISTRADOR,
  DESENVOLVEDOR,
  GESTOR_REGIONAL,
  FISCAL,
  COLABORADOR,
  LEITOR,
}

/// Converte string → enum com tolerância a valores legados
BaseRole _parseBaseRole(String? raw) {
  final up = (raw ?? '').trim().toUpperCase();
  switch (up) {
    case 'ADMINISTRADOR': return BaseRole.ADMINISTRADOR;
    case 'DESENVOLVEDOR': return BaseRole.DESENVOLVEDOR;
    case 'GESTOR_REGIONAL': return BaseRole.GESTOR_REGIONAL;
    case 'FISCAL': return BaseRole.FISCAL;
    case 'COLABORADOR': return BaseRole.COLABORADOR;
    case 'LEITOR':
    case 'CONVIDADO':
    default:
      return BaseRole.LEITOR;
  }
}

/// Rótulo amigável
String baseRoleLabel(BaseRole r) {
  switch (r) {
    case BaseRole.ADMINISTRADOR:   return 'Administrador';
    case BaseRole.DESENVOLVEDOR:   return 'Desenvolvedor';
    case BaseRole.GESTOR_REGIONAL: return 'Gestor Regional';
    case BaseRole.FISCAL:          return 'Fiscal';
    case BaseRole.COLABORADOR:     return 'Colaborador';
    case BaseRole.LEITOR:          return 'Leitor';
  }
}

/// Lê o papel global do usuário a partir do UserData / Firestore
BaseRole roleForUser(UserData user) {
  // Prioriza o snapshot do Firestore (users/{uid})
  final data = user.userSnap?.data();
  if (data is Map<String, dynamic>) {
    final raw = (data['baseRole'] as String?) ?? (data['baseProfile'] as String?);
    return _parseBaseRole(raw);
  }
  // Fallback seguro
  return BaseRole.LEITOR;
}

/// Persiste o papel global no Firestore (users/{uid})
Future<void> setUserRole(UserData user, BaseRole newRole) async {
  final uid = user.id;
  if (uid == null || uid.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('users').doc(uid);
  await ref.set(
    {
      'baseRole': newRole.name, // campo canônico
      // se ainda houver telas legadas lendo baseProfile, reative a linha abaixo:
      // 'baseProfile': newRole.name,
    },
    SetOptions(merge: true),
  );
}
