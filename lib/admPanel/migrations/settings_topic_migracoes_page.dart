// lib/screens/settings/settings_topic_migracoes_page.dart
import 'package:flutter/material.dart';
import 'package:siged/_services/firestore/cleanup/cleanup_subcollections_tile.dart';
import 'package:siged/_services/firestore/cleanup/selective_delete_tile.dart';
import 'package:siged/_services/firestore/migrate/migrateDocForSubCollection.dart';
import 'package:siged/_services/firestore/migrate/migration.dart';
import 'package:siged/_services/firestore/firebase_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/tiles/tile_widget.dart';
import 'package:siged/admPanel/migrations/firebase_migration_toolkit_page.dart';

import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// 🪟 WindowDialog
import 'package:siged/_widgets/windows/show_window_dialog.dart';


class SettingsTopicMigracoesPage extends StatefulWidget {
  const SettingsTopicMigracoesPage({super.key});

  @override
  State<SettingsTopicMigracoesPage> createState() =>
      _SettingsTopicMigracoesPageState();
}

class _SettingsTopicMigracoesPageState
    extends State<SettingsTopicMigracoesPage> {
  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0; // mantenha igual às outras páginas
    final topPadding = topSafe + barHeight + 12;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          bottom: false,
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
          ),
        ),
        toolbarHeight: barHeight,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) {
            maxW = 1000;
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  _section('Migrações'),
                  TileWidget(
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    leading: Icons.merge_type_outlined,
                    onTap: () async {
                      _loading(context);
                      try {
                        await migrarAcidentesPorAno();
                        if (context.mounted) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text(
                                  'Migração concluída com sucesso!'),
                              type: AppNotificationType.success,
                              leadingLabel: const Text('Firebase'),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Erro na migração'),
                              subtitle: Text('$e'),
                              type: AppNotificationType.error,
                              leadingLabel: const Text('Firebase'),
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  TileWidget(
                    title: 'Migrar coleções (widget)',
                    subtitle: 'Ferramenta visual para migrações complexas',
                    leading: Icons.transfer_within_a_station_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MigrationCollections(),
                      ),
                    ),
                  ),
                  TileWidget(
                    title: 'Painel de migrações Firebase',
                    subtitle: 'Migrar documentos de uma coleção para outra',
                    leading: Icons.auto_fix_high_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FirebaseMigrationToolkitPage(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _section('Limpeza'),
                  const CleanUpSubcollectionsTile(),
                  const SizedBox(height: 8),
                  const SelectiveDeleteSubcollectionTile(),
                  const SizedBox(height: 12),

                  TileWidget(
                    title: 'Apagar coleção inteira',
                    subtitle: 'Operação irreversível — cuidado!',
                    leading: Icons.delete_forever_rounded,
                    onTap: () async {
                      final path = await _askPath(context);
                      if (!context.mounted || path == null || path.isEmpty) {
                        return;
                      }
                      _loading(context);
                      try {
                        await FirebaseUtils.deleteCollectionCompletamente(
                          context: context,
                          path: path,
                          onFinished: () {
                            if (context.mounted) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title:
                                  const Text('Coleção deletada!'),
                                  type: AppNotificationType.success,
                                  leadingLabel: const Text('Firebase'),
                                  duration:
                                  const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (context.mounted) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Erro ao deletar'),
                              subtitle: Text('$e'),
                              type: AppNotificationType.error,
                              leadingLabel: const Text('Firebase'),
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------- helpers UI -------

Widget _section(String text) => Padding(
  padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
  child: Text(
    text,
    style: const TextStyle(fontSize: 13, color: Colors.black54),
  ),
);

// 🪟 Agora usando WindowDialog para perguntar o path
Future<String?> _askPath(BuildContext context) async {
  final controller = TextEditingController();

  return showWindowDialogMac<String>(
    context: context,
    title: 'Informe o caminho da coleção',
    width: 520,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: controller,
                labelText: 'Ex: actives_oaes ou operation/abc123/accidents',
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogCtx).pop(null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final path = controller.text.trim();
                      if (path.isNotEmpty) {
                        Navigator.of(dialogCtx).pop(path);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

void _loading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}
