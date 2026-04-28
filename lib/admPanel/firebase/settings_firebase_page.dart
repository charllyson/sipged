import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_services/firestore/cleanup/cleanup_subcollections_tile.dart';
import 'package:sipged/_services/firestore/cleanup/selective_delete_tile.dart';
import 'package:sipged/_services/firestore/explorer/firestore_explorer_page.dart';
import 'package:sipged/_services/firestore/migrate/migrate_doc_for_sub_collection.dart';
import 'package:sipged/_services/firestore/migrate/migration.dart';
import 'package:sipged/_services/firestore/firebase_utils.dart';
import 'package:sipged/_services/excel/excel_import_controller.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/admPanel/firebase/section_header.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';

import '../../_widgets/buttons/circle_button_change.dart';
import '../../_widgets/menu/upBar/up_bar.dart';

class SettingsFirebasePage extends StatefulWidget {
  const SettingsFirebasePage({super.key});

  @override
  State<SettingsFirebasePage> createState() => _SettingsFirebasePageState();
}

class _SettingsFirebasePageState extends State<SettingsFirebasePage> {
  void _notify({
    required String title,
    String? subtitle,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Firebase',
        type: type,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'settings_firebase',
        },
      ),
      saveInFirebase: false,
    );
  }

  void _closeLoadingIfMounted() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _handleExcelImport() async {
    final path = await _askPath(
      context,
      hint: 'Ex: actives_oaes ou operation/abc123/accidents',
    );

    if (!mounted || path == null || path.isEmpty) return;

    _showLoading(context);

    try {
      await ImportExcelController.importar(
        context: context,
        path: path,
        onFinished: () {
          _notify(
            title: 'Importação finalizada!',
            type: NotificationType.success,
            duration: const Duration(seconds: 4),
          );
        },
      );
    } catch (e) {
      _notify(
        title: 'Erro na importação',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _closeLoadingIfMounted();
    }
  }

  Future<void> _handleMigration() async {
    _showLoading(context);

    try {
      await migrarAcidentesPorAno();

      _notify(
        title: 'Migração concluída com sucesso!',
        type: NotificationType.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _notify(
        title: 'Erro na migração',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _closeLoadingIfMounted();
    }
  }

  Future<void> _handleDeleteCollection() async {
    final path = await _askPath(
      context,
      hint: 'Ex: actives_oaes ou operation/abc123/accidents',
    );

    if (!mounted || path == null || path.isEmpty) return;

    _showLoading(context);

    try {
      await FirebaseUtils.deleteCollectionCompletamente(
        context: context,
        path: path,
        onFinished: () {
          _notify(
            title: 'Coleção deletada!',
            type: NotificationType.success,
            duration: const Duration(seconds: 4),
          );
        },
      );
    } catch (e) {
      _notify(
        title: 'Erro ao deletar',
        subtitle: '$e',
        type: NotificationType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _closeLoadingIfMounted();
    }
  }

  void _openFirestoreExplorer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FirestoreExplorerPage(),
      ),
    );
  }

  void _openMigrationCollections() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MigrationCollections(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final topSafe = MediaQuery.of(context).padding.top;
    final topPadding = topSafe + 72 + 12;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
              child: CircleButtonChange(),
            ),
          ),
        ),
        toolbarHeight: 72,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxW = constraints.maxWidth;

          if (constraints.maxWidth >= 1600) {
            maxW = 1100;
          }

          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) {
            maxW = 1000;
          }

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
                    onTap: _openFirestoreExplorer,
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader('Importação / Atualização em massa'),
                  TileWidget(
                    title: 'Excel → Firebase (coleção ou subcoleção)',
                    subtitle: 'Importar/atualizar registros via Excel',
                    leading: Icons.upload_file_outlined,
                    onTap: _handleExcelImport,
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader('Migrações'),
                  TileWidget(
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    leading: Icons.merge_type_outlined,
                    onTap: _handleMigration,
                  ),
                  const SizedBox(height: 6),
                  TileWidget(
                    title: 'Migrar coleções (widget)',
                    subtitle: 'Ferramenta visual para migrações',
                    leading: Icons.transfer_within_a_station_outlined,
                    onTap: _openMigrationCollections,
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader('Limpeza & Manutenção'),
                  TileWidget(
                    title: 'Apagar coleção inteira',
                    subtitle: 'Use com cuidado! Operação irreversível',
                    leading: Icons.delete_forever_rounded,
                    onTap: _handleDeleteCollection,
                  ),
                  const SizedBox(height: 8),
                  const CleanUpSubcollectionsTile(),
                  const SizedBox(height: 8),
                  const SelectiveDeleteSubcollectionTile(),
                  const SizedBox(height: 24),
                  BasicCard(
                    isDark: isDark,
                    padding: const EdgeInsets.all(12),
                    borderRadius: 12,
                    backgroundColor: Colors.amber.withValues(alpha: 0.08),
                    borderColor: Colors.amber.withValues(alpha: 0.25),
                    enableShadow: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dica: para rotinas destrutivas, exiba confirmação dupla '
                                '(ex.: digitar o nome da coleção) e considere habilitar '
                                'modo somente leitura em produção.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
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

Future<String?> _askPath(BuildContext context, {String? hint}) async {
  final controller = TextEditingController();

  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Informe o caminho da coleção'),
        content: CustomTextField(
          controller: controller,
          labelText: hint ?? 'Ex: actives_oaes ou operation/abc123/accidents',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                Navigator.of(dialogContext).pop(path);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}

void _showLoading(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Material(
      color: Colors.black26,
      child: Center(
        child: LoadingTreeDots(size: 110),
      ),
    ),
  );
}