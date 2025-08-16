import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisged/_widgets/registers/register_class.dart';
import 'package:sisged/_datas/system/user_data.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';

class NotificationBloc {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserBloc _userBloc = UserBloc();

  final Map<String, UserData> _userCache = {};
  final Map<String, Set<String>> _seenCache = {};

  Future<UserData?> getUserCached(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final user = await _userBloc.getUserData(uid: uid);
    if (user != null) _userCache[uid] = user;
    return user;
  }

  String gerarIdUnico(Registro registro) {
    final tipo = registro.original?.runtimeType.toString() ?? registro.tipo;
    String id;
    try {
      id = (registro.original as dynamic)?.idReportMeasurement ?? registro.id ?? '';
    } catch (_) {
      id = registro.id ?? '';
    }

    final dataRedonda = DateTime(
      registro.data.year,
      registro.data.month,
      registro.data.day,
      registro.data.hour,
      registro.data.minute,
      // removido segundos para evitar problemas de reconstrução
    );

    return '$tipo-$id-${dataRedonda.toIso8601String()}';
  }

  Future<Set<String>> carregarIdsVistos(String uid) async {
    if (_seenCache.containsKey(uid)) return _seenCache[uid]!;

    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('registro');

    final doc = await ref.get();
    final data = doc.data();

    final ids = (data?['ids'] as List<dynamic>?)?.cast<String>().toSet() ?? {};

    _seenCache[uid] = ids;
    return ids;
  }

  Future<void> marcarComoVisto(String uid, List<Registro> registros) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc('registro');

    final doc = await ref.get();
    final existentes = List<String>.from(doc.data()?['ids'] ?? []);

    final novos = registros.map(gerarIdUnico).toSet();
    final todos = {...existentes, ...novos}.toList();

    final limitados = todos.take(200).toList();

    await ref.set({'ids': limitados}, SetOptions(merge: true));

    _seenCache[uid] = limitados.toSet();
  }

  String getTipoAlteracao({DateTime? createdAt, DateTime? updatedAt}) {
    if (updatedAt != null && createdAt != null && updatedAt.isAfter(createdAt)) {
      return 'Atualização';
    }
    return 'Criação';
  }
}
