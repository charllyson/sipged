import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

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
        _notify(
          'Coleção não encontrada ou vazia',
          subtitle: '"$path"',
          type: AppNotificationType.warning,
        );
        return;
      }

      if (!context.mounted) return;

      final bool confirm = await confirmDialog(
        context,
        'Tem certeza que deseja apagar a coleção:\n\n'
            '"$path"\n\n'
            'Ela contém $totalDocs documentos.',
      );

      if (!context.mounted) return;
      if (!confirm) return;

      _notify(
        'Apagando documentos…',
        subtitle: '$totalDocs docs em "$path"',
        type: AppNotificationType.info,
      );

      while (true) {
        final querySnapshot = await collectionRef.limit(batchSize).get();
        if (querySnapshot.docs.isEmpty) break;

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        await Future.delayed(const Duration(milliseconds: 250));
      }

      _notify(
        'Coleção deletada com sucesso',
        subtitle: '"$path" • $totalDocs docs',
        type: AppNotificationType.success,
      );

      onFinished?.call();
    } catch (e, stack) {
      final _ = stack;
      _notify(
        'Erro ao deletar coleção',
        subtitle: '"$path": $e',
        type: AppNotificationType.error,
      );
    }
  }

  static void _notify(
      String title, {
        String? subtitle,
        AppNotificationType type = AppNotificationType.info,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        type: type,
      ),
    );
  }
}