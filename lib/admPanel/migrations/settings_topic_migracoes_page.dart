import 'package:flutter/material.dart';

import 'package:sipged/admPanel/firebase/cleanup_subcollections_tile.dart';
import 'package:sipged/admPanel/firebase/firebase_utils.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';
import 'package:sipged/admPanel/firebase/migrate_doc_for_sub_collection.dart';
import 'package:sipged/admPanel/firebase/migration.dart';
import 'package:sipged/admPanel/firebase/selective_delete_tile.dart';
import 'package:sipged/admPanel/migrations/firebase_migration_toolkit_page.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';

class SettingsTopicMigracoesPage extends StatefulWidget {
  const SettingsTopicMigracoesPage({super.key});

  @override
  State<SettingsTopicMigracoesPage> createState() =>
      _SettingsTopicMigracoesPageState();
}

class _SettingsTopicMigracoesPageState
    extends State<SettingsTopicMigracoesPage> {
  void _showMessage(
      String message, {
        Color? backgroundColor,
        Duration duration = const Duration(seconds: 4),
      }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  void _closeLoadingIfMounted() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _handleMigrarAcidentesPorAno() async {
    _loading(context);

    try {
      await migrarAcidentesPorAno();

      _showMessage(
        'Migração concluída com sucesso!',
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showMessage(
        'Erro na migração: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _closeLoadingIfMounted();
    }
  }

  Future<void> _handleDeleteCollection() async {
    final path = await _askPath(context);

    if (!mounted || path == null || path.isEmpty) {
      return;
    }

    _loading(context);

    try {
      await FirebaseUtils.deleteCollectionCompletamente(
        context: context,
        path: path,
        onFinished: () {
          _showMessage(
            'Coleção deletada!',
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          );
        },
      );
    } catch (e) {
      _showMessage(
        'Erro ao deletar: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      _closeLoadingIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    const barHeight = 72.0;
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
              child: CircleButtonChange(),
            ),
          ),
        ),
        toolbarHeight: barHeight,
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
                  _section('Migrações'),
                  TileWidget(
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    leading: Icons.merge_type_outlined,
                    onTap: _handleMigrarAcidentesPorAno,
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
                    onTap: _handleDeleteCollection,
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

Widget _section(String text) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black54,
      ),
    ),
  );
}

Future<String?> _askPath(BuildContext context) async {
  final controller = TextEditingController();

  try {
    return await showWindowDialog<String>(
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
                      onPressed: () => Navigator.of(dialogCtx).pop(null),
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
  } finally {
    controller.dispose();
  }
}

void _loading(BuildContext context) {
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