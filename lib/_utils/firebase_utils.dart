import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class FirebaseUtils {
  static Future<void> deleteCollectionCompletamente({
    required BuildContext context,
    required String path,
    VoidCallback? onFinished,
  }) async {
    final collectionRef = FirebaseFirestore.instance.collection(path);
    const int batchSize = 500;

    try {
      // Etapa 1: verificar e contar documentos
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

      // Etapa 2: pedir confirmação
      final bool confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Tem certeza que deseja apagar a coleção:\n\n"$path"\n\nEla contém $totalDocs documentos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apagar tudo'),
            ),
          ],
        ),
      ) ??
          false;

      if (!confirm) return;

      // Etapa 3: início
      _notify(
        'Apagando documentos…',
        subtitle: '$totalDocs docs em "$path"',
        type: AppNotificationType.info,
      );

      // Etapa 4: apagar por lote
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

      // Etapa 5: sucesso
      _notify(
        'Coleção deletada com sucesso',
        subtitle: '"$path" • $totalDocs docs',
        type: AppNotificationType.success,
      );

      onFinished?.call();
    } catch (e, stack) {
      debugPrint('❌ Erro ao deletar coleção "$path": $e');
      debugPrint(stack.toString());

      _notify(
        'Erro ao deletar coleção',
        subtitle: '"$path": $e',
        type: AppNotificationType.error,
      );
    }
  }

  // 🔔 helper de notificação
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
