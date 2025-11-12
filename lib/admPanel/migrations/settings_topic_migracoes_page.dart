import 'package:flutter/material.dart';
import 'package:siged/_services/firestore/cleanup/cleanup_subcollections_tile.dart';
import 'package:siged/_services/firestore/cleanup/selective_delete_tile.dart';
import 'package:siged/_services/firestore/migrate/migrateDocForSubCollection.dart';
import 'package:siged/_services/firestore/migrate/migration.dart';
import 'package:siged/_services/firestore/firebase_utils.dart';

import '../../_widgets/buttons/back_circle_button.dart';
import '../../_widgets/upBar/up_bar.dart';

import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class SettingsTopicMigracoesPage extends StatelessWidget {
  const SettingsTopicMigracoesPage({super.key});

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
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) maxW = 1000;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  _section('Migrações'),
                  _tile(
                    context,
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    icon: Icons.merge_type_outlined,
                    onTap: () async {
                      _loading(context);
                      try {
                        await migrarAcidentesPorAno();
                        if (context.mounted) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Migração concluída com sucesso!'),
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
                  _tile(
                    context,
                    title: 'Migrar coleções (widget)',
                    subtitle: 'Ferramenta visual para migrações complexas',
                    icon: Icons.transfer_within_a_station_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MigrationCollections()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _section('Limpeza'),
                  const CleanUpSubcollectionsTile(),
                  const SizedBox(height: 8),
                  SelectiveDeleteSubcollectionTile(),
                  const SizedBox(height: 12),

                  _tile(
                    context,
                    title: 'Apagar coleção inteira',
                    subtitle: 'Operação irreversível — cuidado!',
                    icon: Icons.delete_forever_rounded,
                    onTap: () async {
                      final path = await _askPath(context);
                      if (!context.mounted || path == null || path.isEmpty) return;
                      _loading(context);
                      try {
                        await FirebaseUtils.deleteCollectionCompletamente(
                          context: context,
                          path: path,
                          onFinished: () {
                            if (context.mounted) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Coleção deletada!'),
                                  type: AppNotificationType.success,
                                  leadingLabel: const Text('Firebase'),
                                  duration: const Duration(seconds: 4),
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

Widget _tile(
    BuildContext context, {
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      Color? tileColor,
    }) {
  final bg = tileColor ?? Colors.white10;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: Colors.black.withOpacity(0.04),
        splashColor: Colors.black.withOpacity(0.08),
        child: Container(
          color: Colors.black12,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ),
  );
}

Future<String?> _askPath(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Informe o caminho da coleção'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Ex: actives_oaes ou process/abc123/accidents',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final path = controller.text.trim();
            if (path.isNotEmpty) Navigator.pop(context, path);
          },
          child: const Text('OK'),
        ),
      ],
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
