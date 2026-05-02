import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class FirebaseUtils {
  static Future<void> deleteCollectionCompletamente({
    required BuildContext context,
    required String path,
    VoidCallback? onFinished,
  }) async {
    final collectionRef = FirebaseFirestore.instance.collection(path);
    const int batchSize = 500;

    try {
      final totalDocsSnapshot = await collectionRef.get();
      final totalDocs = totalDocsSnapshot.docs.length;

      if (totalDocs == 0) {
        return;
      }

      if (!context.mounted) return;

      final bool confirm = await confirmDialog(
        context,
        'Tem certeza que deseja apagar a coleção:\n\n'
            '"$path"\n\n'
            'Ela contém $totalDocs documentos.',
      );

      if (!confirm) return;

      while (true) {
        final querySnapshot = await collectionRef.limit(batchSize).get();

        if (querySnapshot.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      onFinished?.call();
    } catch (_) {
      return;
    }
  }
}