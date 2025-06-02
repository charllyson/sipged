import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInspector {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> inspecionarFirestore({
    required List<String> colecoesRaiz,
    List<String> subcolecoesManuais = const [],
  }) async {
    final Map<String, dynamic> resultado = {};

    for (final colNome in colecoesRaiz) {
      final col = firestore.collection(colNome);
      resultado[colNome] = await _processarColecao(col, subcolecoesManuais);
    }

    return resultado;
  }

  Future<Map<String, dynamic>> _processarColecao(
      CollectionReference col,
      List<String> subcolecoesManuais,
      ) async {
    final Map<String, dynamic> docsMap = {};
    final snapshot = await col.get();

    for (final doc in snapshot.docs) {
      docsMap[doc.id] = await _processarDocumentoRecursivo(doc.reference, subcolecoesManuais);
    }

    return docsMap;
  }

  Future<Map<String, dynamic>> _processarDocumentoRecursivo(
      DocumentReference docRef,
      List<String> subcolecoesManuais,
      ) async {
    final Map<String, dynamic> resultado = {};

    final docSnapshot = await docRef.get();
    final data = docSnapshot.data() as Map<String, dynamic>? ?? {};

    for (final entry in data.entries) {
      resultado[entry.key] = _tipo(entry.value);
    }

    for (final subcolNome in subcolecoesManuais) {
      final subCol = docRef.collection(subcolNome);
      final subSnapshot = await subCol.get();
      final subMap = <String, dynamic>{};

      for (final subDoc in subSnapshot.docs) {
        subMap[subDoc.id] = await _processarDocumentoRecursivo(subDoc.reference, subcolecoesManuais);
      }

      if (subMap.isNotEmpty) {
        resultado['subcol_$subcolNome'] = subMap;
      }
    }

    return resultado;
  }

  String _tipo(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'string';
    if (value is num) return 'number';
    if (value is bool) return 'boolean';
    if (value is Timestamp) return 'timestamp';
    if (value is GeoPoint) return 'geopoint';
    if (value is List) return 'list<${value.map(_tipo).toSet().join(', ')}>';
    if (value is Map) return 'map';
    return 'unknown';
  }
}
