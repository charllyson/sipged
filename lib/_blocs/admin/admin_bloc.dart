// ignore_for_file: unused_import

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';

class AdminBloc extends BlocBase {
  AdminBloc();
/*

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> migrarColecaoInteira() async {
    final snapshot = await firestore.collection('contratos').get();

    for (final doc in snapshot.docs) {
      await migrarDocumento(doc);
    }

    print('Todos os documentos migrados!');
  }

  Future<void> migrarDocumento(DocumentSnapshot doc) async {
    final oldData = Map<String, dynamic>.from(doc.data() as Map);

    final contractId = doc.id;
    final newDocRef = firestore.collection('contracts').doc(contractId);

    // Extrai listas com nome original (caixa alta)
    Map<String, List<Map<String, dynamic>>> listasSeparadas = {};

    for (final entry in oldData.entries.toList()) {
      if (entry.value is List) {
        final list = (entry.value as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        if (list.isNotEmpty) {
          listasSeparadas[entry.key] = list;
          oldData.remove(entry.key);
        }
      }
    }

    // Salva o restante dos dados no novo documento
    await newDocRef.set(oldData);

    // Adiciona as subcoleções com nomes limpos
    for (final entry in listasSeparadas.entries) {
      final nomeOriginal = entry.key;
      final nomeNormalizado = normalizeFieldName(nomeOriginal);

      final list = entry.value;
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        item['order'] = i;
        await newDocRef.collection(nomeNormalizado).add(item);
      }
    }

    print('Documento ${doc.id} migrado com sucesso.');
  }

  /// Remove acentos, espaços e caracteres especiais, e deixa lowercase
  String normalizeFieldName(String input) {
    String normalized = removeDiacritics(input); // remove acentos
    normalized = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''); // remove especiais
    return normalized.toLowerCase();
  }
*/

}
