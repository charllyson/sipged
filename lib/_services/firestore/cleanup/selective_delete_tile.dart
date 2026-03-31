// lib/screens/algum_lugar/selective_delete_subcollection_tile.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';
import 'selective_delete_util.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class SelectiveDeleteSubcollectionTile extends StatelessWidget {
  const SelectiveDeleteSubcollectionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return TileWidget(
      leading: Icons.delete_sweep,
      tileColor: Colors.white10,
      title: 'Apagar documentos (seletivo) de subcoleção',
      subtitle:
      'Informe coleção principal, subcoleção e campo (quando por filtro)',
      onTap: () async {
        final nav = Navigator.of(context, rootNavigator: true);
        final mode = await _askMode(context);
        if (mode == null) return;

        switch (mode) {
          case _Mode.byIds:
            {
              final p = await _askByIds(context);
              if (p == null) return;

              // DRY RUN
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
                );
              }
              int dry = 0;
              try {
                final deleter = SubcollectionSelectiveDeleter();
                dry = await deleter.deleteIdsUnderEachParent(
                  parentCollectionPath: p.parent,
                  subcollection: p.sub,
                  docIds: p.ids,
                  dryRun: true,
                );
              } catch (e) {
                if (nav.canPop()) nav.pop();
                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Falha no dry-run'),
                    subtitle: Text('$e'),
                    type: AppNotificationType.error,
                    leadingLabel: const Text('Limpeza'),
                    duration: const Duration(seconds: 6),
                  ),
                );
                return;
              } finally {
                if (nav.canPop()) nav.pop();
              }

              if (!context.mounted) return;
              final proceed = await confirmDialog(
                context,
                'Prévia: $dry documento(s) encontrados.\nApagar mesmo assim?',
              );
              if (!proceed) return;

              // REAL RUN
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
                );
              }
              int real = 0;
              try {
                final deleter = SubcollectionSelectiveDeleter();
                real = await deleter.deleteIdsUnderEachParent(
                  parentCollectionPath: p.parent,
                  subcollection: p.sub,
                  docIds: p.ids,
                  dryRun: false,
                );
              } catch (e) {
                if (nav.canPop()) nav.pop();
                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Erro ao apagar documentos'),
                    subtitle: Text('$e'),
                    type: AppNotificationType.error,
                    leadingLabel: const Text('Limpeza'),
                    duration: const Duration(seconds: 6),
                  ),
                );
                return;
              } finally {
                if (nav.canPop()) nav.pop();
              }

              if (!context.mounted) return;
              NotificationCenter.instance.show(
                AppNotification(
                  title: Text('Apagados: $real documento(s).'),
                  type: AppNotificationType.success,
                  leadingLabel: const Text('Limpeza'),
                  duration: const Duration(seconds: 4),
                ),
              );
              break;
            }

          case _Mode.byFilter:
            {
              final p = await _askByFilter(context);
              if (p == null) return;

              // DRY RUN
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
                );
              }
              int dry = 0;
              try {
                final deleter = SubcollectionSelectiveDeleter();
                dry = p.useParents
                    ? await deleter.deleteWhereUnderEachParent(
                  parentCollectionPath: p.parent,
                  subcollection: p.sub,
                  filters: p.filters,
                  dryRun: true,
                )
                    : await deleter.deleteWhereInCollectionGroup(
                  subcollection: p.sub,
                  filters: p.filters,
                  dryRun: true,
                );
              } catch (e) {
                if (nav.canPop()) nav.pop();
                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Falha no dry-run'),
                    subtitle: Text('$e'),
                    type: AppNotificationType.error,
                    leadingLabel: const Text('Limpeza'),
                    duration: const Duration(seconds: 6),
                  ),
                );
                return;
              } finally {
                if (nav.canPop()) nav.pop();
              }

              if (!context.mounted) return;
              final proceed = await confirmDialog(
                context,
                'Prévia: $dry documento(s) encontrados.\nApagar mesmo assim?',
              );
              if (!proceed) return;

              // REAL RUN
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                  const Center(child: CircularProgressIndicator()),
                );
              }
              int real = 0;
              try {
                final deleter = SubcollectionSelectiveDeleter();
                real = p.useParents
                    ? await deleter.deleteWhereUnderEachParent(
                  parentCollectionPath: p.parent,
                  subcollection: p.sub,
                  filters: p.filters,
                  dryRun: false,
                )
                    : await deleter.deleteWhereInCollectionGroup(
                  subcollection: p.sub,
                  filters: p.filters,
                  dryRun: false,
                );
              } catch (e) {
                if (nav.canPop()) nav.pop();
                NotificationCenter.instance.show(
                  AppNotification(
                    title: const Text('Erro ao apagar documentos'),
                    subtitle: Text('$e'),
                    type: AppNotificationType.error,
                    leadingLabel: const Text('Limpeza'),
                    duration: const Duration(seconds: 6),
                  ),
                );
                return;
              } finally {
                if (nav.canPop()) nav.pop();
              }

              if (!context.mounted) return;
              NotificationCenter.instance.show(
                AppNotification(
                  title: Text('Apagados: $real documento(s).'),
                  type: AppNotificationType.success,
                  leadingLabel: const Text('Limpeza'),
                  duration: const Duration(seconds: 4),
                ),
              );
              break;
            }
        }
      },
    );
  }

  // ---------- Escolha do modo ----------
  Future<_Mode?> _askMode(BuildContext context) async {
    return showWindowDialog<_Mode>(
      context: context,
      title: 'Modo de deleção',
      width: 480,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione como deseja localizar os documentos que serão apagados:',
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Por IDs (em cada pai)'),
                  subtitle: const Text(
                    'Informe manualmente os IDs dos documentos em cada subcoleção.',
                  ),
                  onTap: () => Navigator.of(dialogCtx).pop(_Mode.byIds),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Por Filtro (coleção principal + subcoleção + campo)',
                  ),
                  subtitle: const Text(
                    'Use um campo/valor para localizar automaticamente os documentos.',
                  ),
                  onTap: () => Navigator.of(dialogCtx).pop(_Mode.byFilter),
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

  // ---------- Parâmetros – por IDs ----------
  Future<_ByIdsParams?> _askByIds(BuildContext context) async {
    final parentCtrl = TextEditingController(text: 'contracts');
    final subCtrl = TextEditingController(text: 'reportsMeasurement');
    final idsCtrl = TextEditingController();

    return showWindowDialog<_ByIdsParams>(
      context: context,
      title: 'Apagar por IDs',
      width: 520,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: parentCtrl,
                  labelText: 'Coleção principal (pai)',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: subCtrl,
                  labelText: 'Subcoleção',
                    ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: idsCtrl,
                  labelText: 'IDs (separados por vírgula ou quebra de linha)',
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
                        if (parentCtrl.text.trim().isEmpty ||
                            subCtrl.text.trim().isEmpty ||
                            idsCtrl.text.trim().isEmpty) {
                          return;
                        }

                        final ids = idsCtrl.text
                            .split(RegExp(r'[,\n]'))
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        Navigator.of(dialogCtx).pop(
                          _ByIdsParams(
                            parentCtrl.text.trim(),
                            subCtrl.text.trim(),
                            ids,
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
  }

  // ---------- Parâmetros – por Filtro ----------
  Future<_ByFilterParams?> _askByFilter(BuildContext context) async {
    final parentCtrl = TextEditingController(text: 'contracts');
    final subCtrl = TextEditingController(text: 'reportsMeasurement');
    final fieldCtrl =
    TextEditingController(text: 'migratedFromMeasurements');
    final valueCtrl = TextEditingController(text: 'true');
    WhereOp op = WhereOp.eq;
    bool useParents = true;

    return showWindowDialog<_ByFilterParams>(
      context: context,
      title: 'Apagar por Filtro',
      width: 520,
      child: StatefulBuilder(
        builder: (dialogCtx, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: parentCtrl,
                  labelText: 'Coleção principal (pai)',
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
                        labelText: 'Campo para filtrar',
                        ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<WhereOp>(
                      value: op,
                      onChanged: (v) =>
                          setState(() => op = v ?? WhereOp.eq),
                      items: const [
                        DropdownMenuItem(
                            value: WhereOp.eq, child: Text('==')),
                        DropdownMenuItem(
                            value: WhereOp.lt, child: Text('<')),
                        DropdownMenuItem(
                            value: WhereOp.lte, child: Text('≤')),
                        DropdownMenuItem(
                            value: WhereOp.gt, child: Text('>')),
                        DropdownMenuItem(
                            value: WhereOp.gte, child: Text('≥')),
                        DropdownMenuItem(
                            value: WhereOp.arrayContains,
                            child: Text('array-contains')),
                        DropdownMenuItem(
                            value: WhereOp.whereIn, child: Text('in')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: valueCtrl,
                  labelText: 'Valor (para "in", use vírgulas)',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                      'Aplicar em CADA pai (ao invés de collectionGroup)'),
                  subtitle: const Text(
                      'Recomendado quando você quer restringir à coleção principal informada'),
                  value: useParents,
                  onChanged: (v) => setState(() => useParents = v),
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
                        if (subCtrl.text.trim().isEmpty ||
                            fieldCtrl.text.trim().isEmpty ||
                            valueCtrl.text.trim().isEmpty) {
                          return;
                        }
                        if (useParents &&
                            parentCtrl.text.trim().isEmpty) {
                          return;
                        }

                        final dynamic parsed =
                        (op == WhereOp.whereIn)
                            ? FieldValueParser.parse(
                          valueCtrl.text,
                          tryList: true,
                        )
                            : FieldValueParser.parse(
                          valueCtrl.text,
                        );

                        final filter = WhereFilter(
                          fieldCtrl.text.trim(),
                          op,
                          parsed,
                        );

                        Navigator.of(dialogCtx).pop(
                          _ByFilterParams(
                            parent: parentCtrl.text.trim(),
                            sub: subCtrl.text.trim(),
                            filters: [filter],
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
  }
}

enum _Mode { byIds, byFilter }

class _ByIdsParams {
  final String parent;
  final String sub;
  final List<String> ids;
  _ByIdsParams(this.parent, this.sub, this.ids);
}

class _ByFilterParams {
  final String parent;
  final String sub;
  final List<WhereFilter> filters;
  final bool useParents;
  _ByFilterParams({
    required this.parent,
    required this.sub,
    required this.filters,
    required this.useParents,
  });
}
