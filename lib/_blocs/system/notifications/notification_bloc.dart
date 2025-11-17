import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/registers/register_class.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class NotificationBloc {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Caches simples
  final Map<String, UserData> _userCache = {};
  final Map<String, Set<String>> _seenCache = {};

  /// Busca de usuário com cache, direto no Firestore (sem UserBloc)
  Future<UserData?> getUserCached(String uid) async {
    if (uid.isEmpty) return null;
    final cached = _userCache[uid];
    if (cached != null) return cached;

    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;

    final user = UserData.fromDocument(snapshot: snap);
    _userCache[uid] = user;
    return user;
  }

  /// Gera um id único por registro para persistir em "vistos"
  String gerarIdUnico(Registro registro) {
    final tipo = registro.original?.runtimeType.toString() ?? registro.tipo;
    String id;
    try {
      // tenta alguns campos comuns que costumam ser id do objeto original
      id = (registro.original as dynamic)?.uid ??
          (registro.original as dynamic)?.uid ??
          (registro.original as dynamic)?.uid ??
          registro.id ??
          '';
    } catch (_) {
      id = registro.id ?? '';
    }

    // arredonda a data para minuto (evita duplicatas por reconstrução)
    final d = registro.data;
    final dataRedonda = DateTime(d.year, d.month, d.day, d.hour, d.minute);

    return '$tipo-$id-${dataRedonda.toIso8601String()}';
  }

  /// Lê os ids "vistos" do usuário (com cache)
  Future<Set<String>> carregarIdsVistos(String uid) async {
    if (uid.isEmpty) return <String>{};
    final cached = _seenCache[uid];
    if (cached != null) return cached;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('registro');

    final doc = await ref.get();
    final data = doc.data();
    final ids = (data?['ids'] as List<dynamic>?)?.cast<String>().toSet() ?? <String>{};

    _seenCache[uid] = ids;
    return ids;
  }

  /// Marca uma lista de registros como vistos para o usuário
  Future<void> marcarComoVisto(String uid, List<Registro> registros) async {
    if (uid.isEmpty) return;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('registro');

    final doc = await ref.get();
    final existentes = List<String>.from(doc.data()?['ids'] ?? const <String>[]);

    final novos = registros.map(gerarIdUnico).toSet();
    final todos = {...existentes, ...novos}.toList();

    // mantém tamanho controlado (ex.: últimos 200)
    final limitados = todos.take(200).toList();

    await ref.set({'ids': limitados}, SetOptions(merge: true));
    _seenCache[uid] = limitados.toSet();
  }

  /// Utilitário para exibir "Criação" ou "Atualização"
  String getTipoAlteracao({DateTime? createdAt, DateTime? updatedAt}) {
    if (updatedAt != null && createdAt != null && updatedAt.isAfter(createdAt)) {
      return 'Atualização';
    }
    return 'Criação';
  }
}
