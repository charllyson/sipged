import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class FirebaseUtils {
  static Future<void> deleteCollectionCompletamente({
    required BuildContext context,
    required String path,
    VoidCallback? onFinished,
  }) async {
    final notificationCubit = context.read<NotificationCubit>();
    final collectionRef = FirebaseFirestore.instance.collection(path);
    const int batchSize = 500;

    try {
      final totalDocsSnapshot = await collectionRef.get();
      final totalDocs = totalDocsSnapshot.docs.length;

      if (totalDocs == 0) {
        _notify(
          notificationCubit,
          'Coleção não encontrada ou vazia',
          subtitle: '"$path"',
          type: NotificationType.warning,
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

      if (!confirm) return;

      _notify(
        notificationCubit,
        'Apagando documentos…',
        subtitle: '$totalDocs docs em "$path"',
        type: NotificationType.info,
      );

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

      _notify(
        notificationCubit,
        'Coleção deletada com sucesso',
        subtitle: '"$path" • $totalDocs docs',
        type: NotificationType.success,
      );

      onFinished?.call();
    } catch (e) {
      _notify(
        notificationCubit,
        'Erro ao deletar coleção',
        subtitle: '"$path": $e',
        type: NotificationType.error,
      );
    }
  }

  static void _notify(
      NotificationCubit notificationCubit,
      String title, {
        String? subtitle,
        NotificationType type = NotificationType.info,
      }) {
    notificationCubit.show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Firestore',
        type: type,
        extra: const <String, dynamic>{
          'module': 'firebase_utils',
        },
      ),
      saveInFirebase: false,
    );
  }
}