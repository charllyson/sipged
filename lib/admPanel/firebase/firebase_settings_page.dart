import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/adm/firebase_admin_cubit.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_data.dart';
import 'package:sipged/_blocs/system/adm/firebase_admin_state.dart';

import 'package:sipged/_services/excel/excel_import_controller.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';

import 'package:sipged/admPanel/firebase/firebase_section.dart';
import 'package:sipged/admPanel/firebase/firebase_toolkit.dart';

class FirebaseSettingsPage extends StatelessWidget {
  const FirebaseSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAdminCubit(),
      child: const _SettingsFirebaseView(),
    );
  }
}

class _SettingsFirebaseView extends StatefulWidget {
  const _SettingsFirebaseView();

  @override
  State<_SettingsFirebaseView> createState() => _SettingsFirebaseViewState();
}

class _SettingsFirebaseViewState extends State<_SettingsFirebaseView> {
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

  Future<void> _handleExcelImport() async {
    final path = await _askSimplePath(
      context,
      title: 'Importar Excel para Firestore',
      label: 'Caminho da coleção',
      hint:
      'Ex: tenants/{tenantId}/assets/roads/items ou tenants/{tenantId}/contracts/items',
    );

    if (!mounted || path == null || path.isEmpty) return;

    await _runWithDialogLoading(
      action: () async {
        await ImportExcelController.importar(
          context: context,
          path: path,
          onFinished: () {
            _showMessage(
              'Importação finalizada!',
              backgroundColor: Colors.green.shade700,
            );
          },
        );
      },
      errorPrefix: 'Erro na importação',
    );
  }

  Future<void> _handleDeleteCollection() async {
    final path = await _askSimplePath(
      context,
      title: 'Apagar coleção inteira',
      label: 'Caminho da coleção',
      hint:
      'Ex: tenants/{tenantId}/assets/roads/items ou tenants/{tenantId}/contracts/items',
    );

    if (!mounted || path == null || path.isEmpty) return;

    final cubit = context.read<FirebaseAdminCubit>();

    int count;

    try {
      count = await cubit.previewCollectionCount(path);
    } catch (_) {
      return;
    }

    if (!mounted) return;

    if (count == 0) {
      _showMessage(
        'A coleção "$path" não possui documentos.',
        backgroundColor: Colors.blueGrey.shade700,
      );
      return;
    }

    final confirm = await confirmDialog(
      context,
      'Tem certeza que deseja apagar a coleção:\n\n'
          '$path\n\n'
          'Documentos encontrados: $count\n\n'
          'Esta operação é irreversível.',
    );

    if (!mounted || confirm != true) return;

    await cubit.deleteCollectionCompletely(path);
  }

  Future<void> _handleCleanupSubcollections() async {
    final params = await _askCleanupSubcollectionsParams(context);

    if (!mounted || params == null) return;

    final cubit = context.read<FirebaseAdminCubit>();

    Map<String, Map<String, int>> preview;

    try {
      preview = await cubit.previewCleanupSubcollections(params);
    } catch (_) {
      return;
    }

    if (!mounted) return;

    await _showNestedPreviewDialog(
      context,
      title: 'Prévia da limpeza',
      data: preview,
    );

    if (!mounted) return;

    final total = _sumNested(preview);

    if (total == 0) {
      _showMessage(
        'Nenhum subdocumento encontrado para apagar.',
        backgroundColor: Colors.blueGrey.shade700,
      );
      return;
    }

    final confirm = await confirmDialog(
      context,
      'Apagar de verdade?\n\n'
          'Subdocumentos encontrados: $total\n\n'
          'Esta operação é irreversível.',
    );

    if (!mounted || confirm != true) return;

    await cubit.cleanupSubcollections(params);
  }

  Future<void> _handleSelectiveDelete() async {
    final mode = await _askSelectiveDeleteMode(context);

    if (!mounted || mode == null) return;

    switch (mode) {
      case _SelectiveDeleteMode.byIds:
        await _handleSelectiveDeleteByIds();
        break;

      case _SelectiveDeleteMode.byFilter:
        await _handleSelectiveDeleteByFilter();
        break;
    }
  }

  Future<void> _handleSelectiveDeleteByIds() async {
    final params = await _askSelectiveDeleteByIdsParams(context);

    if (!mounted || params == null) return;

    final cubit = context.read<FirebaseAdminCubit>();

    int count;

    try {
      count = await cubit.previewSelectiveDeleteByIds(params);
    } catch (_) {
      return;
    }

    if (!mounted) return;

    final confirm = await confirmDialog(
      context,
      'Prévia: $count documento(s) encontrado(s).\n\n'
          'Apagar mesmo assim?',
    );

    if (!mounted || confirm != true) return;

    await cubit.selectiveDeleteByIds(params);
  }

  Future<void> _handleSelectiveDeleteByFilter() async {
    final params = await _askSelectiveDeleteByFilterParams(context);

    if (!mounted || params == null) return;

    final cubit = context.read<FirebaseAdminCubit>();

    int count;

    try {
      count = await cubit.previewSelectiveDeleteByFilter(params);
    } catch (_) {
      return;
    }

    if (!mounted) return;

    final confirm = await confirmDialog(
      context,
      'Prévia: $count documento(s) encontrado(s).\n\n'
          'Apagar mesmo assim?',
    );

    if (!mounted || confirm != true) return;

    await cubit.selectiveDeleteByFilter(params);
  }

  Future<void> _runWithDialogLoading({
    required Future<void> Function() action,
    required String errorPrefix,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);

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

    try {
      await action();
    } catch (e) {
      _showMessage(
        '$errorPrefix: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  void _openMigrationToolkit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FirebaseToolkit(
          title: 'Copiar dados entre coleções',
        ),
      ),
    );
  }

  int _sumNested(Map<String, Map<String, int>> data) {
    int total = 0;

    for (final item in data.values) {
      for (final value in item.values) {
        total += value;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirebaseAdminCubit, FirebaseAdminState>(
      listenWhen: (previous, current) {
        return previous.message != current.message && current.message != null;
      },
      listener: (context, state) {
        final isError = state.status == FirebaseAdminStatus.failure;

        _showMessage(
          state.message!,
          backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
          duration:
          isError ? const Duration(seconds: 6) : const Duration(seconds: 4),
        );
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final topSafe = MediaQuery.of(context).padding.top;
        const barHeight = 72.0;
        final topPadding = topSafe + barHeight + 12;

        return Stack(
          children: [
            Scaffold(
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
                toolbarHeight: barHeight,
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  double maxW = constraints.maxWidth;

                  if (constraints.maxWidth >= 1600) {
                    maxW = 1100;
                  }

                  if (constraints.maxWidth >= 1200 &&
                      constraints.maxWidth < 1600) {
                    maxW = 1000;
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                        children: [
                          const FirebaseSection(
                            'Exploração & Migração',
                            icon: Icons.storage_rounded,
                          ),
                          const SizedBox(height: 8),
                          TileWidget(
                            title: 'Copiar dados entre coleções',
                            subtitle:
                            'Migrar documentos entre caminhos livres, incluindo tenants/{tenantId}/assets/{tipo}/items',
                            leading: Icons.copy_all_outlined,
                            onTap: _openMigrationToolkit,
                          ),
                          const SizedBox(height: 8),
                          BasicCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            backgroundColor:
                            Colors.blue.withValues(alpha: 0.06),
                            borderColor: Colors.blue.withValues(alpha: 0.18),
                            enableShadow: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Para migração multi-tenant, use caminhos como:\n'
                                        'tenants/{tenantId}/assets/roads/items\n'
                                        'tenants/{tenantId}/assets/oaes/items\n'
                                        'tenants/{tenantId}/assets/oacs/items\n'
                                        'tenants/{tenantId}/assets/railways/items',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const FirebaseSection(
                            'Importação / Atualização em massa',
                            icon: Icons.upload_file_outlined,
                          ),
                          TileWidget(
                            title: 'Excel → Firebase',
                            subtitle:
                            'Importar ou atualizar registros via Excel em uma coleção informada',
                            leading: Icons.upload_file_outlined,
                            onTap: _handleExcelImport,
                          ),
                          const FirebaseSection(
                            'Limpeza & Manutenção',
                            icon: Icons.cleaning_services_outlined,
                          ),
                          TileWidget(
                            title: 'Apagar coleção inteira',
                            subtitle:
                            'Informe o caminho da coleção. Possui prévia antes da exclusão.',
                            leading: Icons.delete_forever_rounded,
                            onTap: _handleDeleteCollection,
                          ),
                          const SizedBox(height: 8),
                          TileWidget(
                            title: 'Apagar subcoleções em massa',
                            subtitle:
                            'Informe uma coleção principal e as subcoleções que serão limpas',
                            leading: Icons.cleaning_services,
                            onTap: _handleCleanupSubcollections,
                          ),
                          const SizedBox(height: 8),
                          TileWidget(
                            title: 'Apagar documentos seletivos de subcoleção',
                            subtitle:
                            'Por IDs ou por filtro, com prévia antes da exclusão',
                            leading: Icons.delete_sweep,
                            onTap: _handleSelectiveDelete,
                          ),
                          const SizedBox(height: 24),
                          BasicCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            backgroundColor:
                            Colors.amber.withValues(alpha: 0.08),
                            borderColor:
                            Colors.amber.withValues(alpha: 0.25),
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
                                    'Área administrativa genérica do Firebase. '
                                        'Nenhuma rotina específica de domínio deve ficar aqui. '
                                        'Operações destrutivas devem sempre passar por prévia antes da execução.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
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
            ),
            if (state.isLoading)
              const Material(
                color: Colors.black38,
                child: Center(
                  child: LoadingTreeDots(size: 110),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _SelectiveDeleteMode {
  byIds,
  byFilter,
}

Future<String?> _askSimplePath(
    BuildContext context, {
      required String title,
      required String label,
      String? hint,
    }) async {
  final controller = TextEditingController();

  try {
    return await showWindowDialog<String>(
      context: context,
      title: title,
      width: 540,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: controller,
                  labelText: hint ?? label,
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
                        final value = controller.text.trim();

                        if (value.isNotEmpty) {
                          Navigator.of(dialogCtx).pop(value);
                        }
                      },
                      child: const Text('Continuar'),
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

Future<FirebaseCleanupSubcollectionsParams?> _askCleanupSubcollectionsParams(
    BuildContext context,
    ) async {
  final collectionCtrl = TextEditingController();
  final subcollectionsCtrl = TextEditingController();

  try {
    return await showWindowDialog<FirebaseCleanupSubcollectionsParams>(
      context: context,
      title: 'Apagar subcoleções em massa',
      width: 560,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: collectionCtrl,
                  labelText:
                  'Coleção principal. Ex: tenants/{tenantId}/assets/roads/items',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: subcollectionsCtrl,
                  labelText: 'Subcoleções separadas por vírgula',
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
                        final collectionPath = collectionCtrl.text.trim();
                        final subs = subcollectionsCtrl.text
                            .split(RegExp(r'[,\n]'))
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        if (collectionPath.isEmpty || subs.isEmpty) return;

                        Navigator.of(dialogCtx).pop(
                          FirebaseCleanupSubcollectionsParams(
                            collectionPath: collectionPath,
                            subcollections: subs,
                          ),
                        );
                      },
                      child: const Text('Continuar'),
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
    collectionCtrl.dispose();
    subcollectionsCtrl.dispose();
  }
}

Future<_SelectiveDeleteMode?> _askSelectiveDeleteMode(
    BuildContext context,
    ) async {
  return showWindowDialog<_SelectiveDeleteMode>(
    context: context,
    title: 'Modo de deleção seletiva',
    width: 520,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag_outlined),
                title: const Text('Por IDs'),
                subtitle: const Text(
                  'Apaga IDs específicos dentro da subcoleção de cada documento pai.',
                ),
                onTap: () => Navigator.of(dialogCtx).pop(
                  _SelectiveDeleteMode.byIds,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.filter_alt_outlined),
                title: const Text('Por filtro'),
                subtitle: const Text(
                  'Apaga documentos encontrados por campo, operador e valor.',
                ),
                onTap: () => Navigator.of(dialogCtx).pop(
                  _SelectiveDeleteMode.byFilter,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(null),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<FirebaseSelectiveDeleteByIdsParams?> _askSelectiveDeleteByIdsParams(
    BuildContext context,
    ) async {
  final parentCtrl = TextEditingController();
  final subCtrl = TextEditingController();
  final idsCtrl = TextEditingController();

  try {
    return await showWindowDialog<FirebaseSelectiveDeleteByIdsParams>(
      context: context,
      title: 'Apagar por IDs',
      width: 560,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: parentCtrl,
                  labelText:
                  'Coleção principal. Ex: tenants/{tenantId}/assets/roads/items',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: subCtrl,
                  labelText: 'Subcoleção',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: idsCtrl,
                  labelText: 'IDs separados por vírgula ou quebra de linha',
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
                        final parent = parentCtrl.text.trim();
                        final sub = subCtrl.text.trim();
                        final ids = idsCtrl.text
                            .split(RegExp(r'[,\n]'))
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        if (parent.isEmpty || sub.isEmpty || ids.isEmpty) {
                          return;
                        }

                        Navigator.of(dialogCtx).pop(
                          FirebaseSelectiveDeleteByIdsParams(
                            parentCollectionPath: parent,
                            subcollection: sub,
                            docIds: ids,
                          ),
                        );
                      },
                      child: const Text('Continuar'),
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
    parentCtrl.dispose();
    subCtrl.dispose();
    idsCtrl.dispose();
  }
}

Future<FirebaseSelectiveDeleteByFilterParams?> _askSelectiveDeleteByFilterParams(
    BuildContext context,
    ) async {
  final parentCtrl = TextEditingController();
  final subCtrl = TextEditingController();
  final fieldCtrl = TextEditingController();
  final valueCtrl = TextEditingController();

  FirebaseWhereOp op = FirebaseWhereOp.eq;
  bool useParents = true;

  try {
    return await showWindowDialog<FirebaseSelectiveDeleteByFilterParams>(
      context: context,
      title: 'Apagar por filtro',
      width: 580,
      child: StatefulBuilder(
        builder: (dialogCtx, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: parentCtrl,
                  labelText:
                  'Coleção principal. Ex: tenants/{tenantId}/assets/roads/items',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: subCtrl,
                  labelText: 'Subcoleção',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: fieldCtrl,
                        labelText: 'Campo',
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: DropdownButton<FirebaseWhereOp>(
                        isExpanded: true,
                        value: op,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => op = value);
                        },
                        items: const [
                          DropdownMenuItem(
                            value: FirebaseWhereOp.eq,
                            child: Text('=='),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.lt,
                            child: Text('<'),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.lte,
                            child: Text('≤'),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.gt,
                            child: Text('>'),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.gte,
                            child: Text('≥'),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.arrayContains,
                            child: Text('array'),
                          ),
                          DropdownMenuItem(
                            value: FirebaseWhereOp.whereIn,
                            child: Text('in'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: valueCtrl,
                  labelText: 'Valor. Para "in", use vírgulas',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Aplicar em cada pai',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Se desligado, usa collectionGroup na subcoleção informada.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: useParents,
                  onChanged: (value) {
                    setState(() => useParents = value);
                  },
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
                        final parent = parentCtrl.text.trim();
                        final sub = subCtrl.text.trim();
                        final field = fieldCtrl.text.trim();
                        final rawValue = valueCtrl.text.trim();

                        if (sub.isEmpty || field.isEmpty || rawValue.isEmpty) {
                          return;
                        }

                        if (useParents && parent.isEmpty) return;

                        final parsed = op == FirebaseWhereOp.whereIn
                            ? FirebaseValueParser.parse(
                          rawValue,
                          tryList: true,
                        )
                            : FirebaseValueParser.parse(rawValue);

                        Navigator.of(dialogCtx).pop(
                          FirebaseSelectiveDeleteByFilterParams(
                            parentCollectionPath: parent,
                            subcollection: sub,
                            filters: [
                              FirebaseWhereFilterData(
                                field: field,
                                op: op,
                                value: parsed,
                              ),
                            ],
                            useParents: useParents,
                          ),
                        );
                      },
                      child: const Text('Continuar'),
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
    parentCtrl.dispose();
    subCtrl.dispose();
    fieldCtrl.dispose();
    valueCtrl.dispose();
  }
}

Future<void> _showNestedPreviewDialog(
    BuildContext context, {
      required String title,
      required Map<String, Map<String, int>> data,
    }) async {
  final text = data.entries.map((entry) {
    final path = entry.key;
    final values = entry.value.entries
        .map((sub) => '  ${sub.key}: ${sub.value}')
        .join('\n');

    return '$path\n$values';
  }).join('\n\n');

  await showWindowDialog<void>(
    context: context,
    title: title,
    width: 620,
    child: Builder(
      builder: (dialogCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text.isEmpty ? '(sem itens)' : text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}