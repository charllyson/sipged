import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deleteFirstCollectionFirestore({
  required String collectionPath,
  int batchSize = 100,
}) async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection(collectionPath);

  bool documentosRestantes = true;

  while (documentosRestantes) {
    final snapshot = await collection.limit(batchSize).get();

    if (snapshot.docs.isEmpty) {
      documentosRestantes = false;
      break;
    }

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    await Future.delayed(const Duration(milliseconds: 300)); // evita sobrecarga
  }
}

Future<void> deleteDocumentIDFirestore({
  required String collectionPath,
  required String documentId,
}) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.collection(collectionPath).doc(documentId);
  await docRef.delete();

}
