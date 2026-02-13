import 'package:flutter/material.dart';
import 'package:sipged/_services/firestore/cleanup/cleanup_subcollections_tile.dart';
import 'package:sipged/_services/firestore/cleanup/selective_delete_tile.dart';
import 'package:sipged/_services/firestore/explorer/firestore_explorer_page.dart';
import 'package:sipged/_services/firestore/migrate/migrateDocForSubCollection.dart';
import 'package:sipged/_services/firestore/migrate/migration.dart';

// Importando suas páginas/tiles já existentes
import 'package:sipged/_services/firestore/firebase_utils.dart';
import 'package:sipged/_services/excel/excel_import_controller.dart';
import 'package:sipged/_widgets/info/section_header.dart';
import 'package:sipged/_widgets/info/tip_box.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';

import '../../_widgets/buttons/back_circle_button.dart';
import '../../_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class SettingsTopicFirebasePage extends StatelessWidget {
  const SettingsTopicFirebasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final topPadding = topSafe + 72 + 12; // conteúdo visível desde o início

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // conteúdo rola por baixo da app bar
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
        toolbarHeight: 72,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Centraliza e limita a largura em telas grandes
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) maxW = 1000;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  const SectionHeader('Exploração & Ferramentas'),
                  TileWidget(
                    title: 'Verificar coleções e documentos (Cloud Firestore)',
                    subtitle: 'Coleções e subcoleções',
                    leading: Icons.storage_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FirestoreExplorerPage()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SectionHeader('Importação / Atualização em massa'),
                  TileWidget(
                    title: 'Excel → Firebase (coleção ou subcoleção)',
                    subtitle: 'Importar/atualizar registros via Excel',
                    leading: Icons.upload_file_outlined,
                    onTap: () async {
                      final path = await _askPath(context,
                          hint: 'Ex: actives_oaes ou operation/abc123/accidents');
                      if (!context.mounted || path == null || path.isEmpty) return;

                      _showLoading(context);
                      try {
                        await ImportExcelController.importar(
                          context: context,
                          path: path,
                          onFinished: () {
                            if (context.mounted) {
                              NotificationCenter.instance.show(
                                AppNotification(
                                  title: const Text('Importação finalizada!'),
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
                              title: const Text('Erro na importação'),
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
                  const SizedBox(height: 12),

                  const SectionHeader('Migrações'),
                  TileWidget(
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    leading: Icons.merge_type_outlined,
                    onTap: () async {
                      _showLoading(context);
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
                  const SizedBox(height: 6),
                  TileWidget(
                    title: 'Migrar coleções (widget)',
                    subtitle: 'Ferramenta visual para migrações',
                    leading: Icons.transfer_within_a_station_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MigrationCollections()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SectionHeader('Limpeza & Manutenção'),
                  TileWidget(
                    title: 'Apagar coleção inteira',
                    subtitle: 'Use com cuidado! Operação irreversível',
                    leading: Icons.delete_forever_rounded,
                    onTap: () async {
                      final path = await _askPath(context,
                          hint: 'Ex: actives_oaes ou operation/abc123/accidents');
                      if (!context.mounted || path == null || path.isEmpty) return;

                      _showLoading(context);
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
                  const SizedBox(height: 8),
                  const CleanUpSubcollectionsTile(),
                  const SizedBox(height: 8),
                  SelectiveDeleteSubcollectionTile(),
                  const SizedBox(height: 24),

                  const TipBox(
                    text:
                    'Dica: para rotinas destrutivas, exiba confirmação dupla (ex.: digitar o nome da coleção) e considere habilitar “modo somente leitura” em produção.',
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

// ---------------- helpers UI ----------------

Future<String?> _askPath(BuildContext context, {String? hint}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Informe o caminho da coleção'),
      content: CustomTextField(
        controller: controller,
        labelText: hint ?? 'Ex: actives_oaes ou operation/abc123/accidents',
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

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

