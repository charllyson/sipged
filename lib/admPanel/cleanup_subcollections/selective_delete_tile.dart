import 'package:flutter/material.dart';
import 'selective_delete_util.dart';

class SelectiveDeleteSubcollectionTile extends StatelessWidget {
  const SelectiveDeleteSubcollectionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_sweep),
      tileColor: Colors.white10,
      title: const Text('Apagar documentos (seletivo) de subcoleção'),
      subtitle: const Text('Informe coleção principal, subcoleção e campo (quando por filtro)'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        final nav = Navigator.of(context, rootNavigator: true);
        final mode = await _askMode(context);
        if (mode == null) return;

        switch (mode) {
          case _Mode.byIds:
            final p = await _askByIds(context);
            if (p == null) return;

            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
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
            } finally {
              if (nav.canPop()) nav.pop();
            }

            if (!context.mounted) return;
            final proceed = await _confirm(context, 'Prévia: $dry documento(s) encontrados.\nApagar mesmo assim?');
            if (!proceed) return;

            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
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
            } finally {
              if (nav.canPop()) nav.pop();
            }

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Apagados: $real documento(s).')),
            );
            break;

          case _Mode.byFilter:
            final p = await _askByFilter(context);
            if (p == null) return;

            // DRY RUN
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
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
            } finally {
              if (nav.canPop()) nav.pop();
            }

            if (!context.mounted) return;
            final proceed = await _confirm(context, 'Prévia: $dry documento(s) encontrados.\nApagar mesmo assim?');
            if (!proceed) return;

            // REAL RUN
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
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
            } finally {
              if (nav.canPop()) nav.pop();
            }

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Apagados: $real documento(s).')),
            );
            break;
        }
      },
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    ) ??
        false;
  }

  // ---------- Escolha do modo ----------
  Future<_Mode?> _askMode(BuildContext context) async {
    return await showDialog<_Mode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Modo de deleção'),
        children: const [
          SimpleDialogOption(
            child: Text('Por IDs (em cada pai)'),
            // ignore: prefer_const_constructors
            onPressed: null,
          ),
        ],
      ),
    ).then((_) async {
      // UI simples: abre outro diálogo para escolher realmente
      return await showDialog<_Mode>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Modo de deleção'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, _Mode.byIds),
              child: const Text('Por IDs (em cada pai)'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, _Mode.byFilter),
              child: const Text('Por Filtro (coleção principal + subcoleção + campo)'),
            ),
          ],
        ),
      );
    });
  }

  // ---------- Parâmetros – por IDs ----------
  Future<_ByIdsParams?> _askByIds(BuildContext context) async {
    final parentCtrl = TextEditingController(text: 'contracts');
    final subCtrl = TextEditingController(text: 'reportsMeasurement'); // ajuste conforme necessário
    final idsCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar por IDs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: parentCtrl,
              decoration: const InputDecoration(
                labelText: 'Coleção principal (pai)',
                hintText: 'Ex.: contracts',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subCtrl,
              decoration: const InputDecoration(
                labelText: 'Subcoleção',
                hintText: 'Ex.: reportsMeasurement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idsCtrl,
              decoration: const InputDecoration(
                labelText: 'IDs (separados por vírgula ou quebra de linha)',
                hintText: 'Ex.: 600txi8J..., abc123, def456',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (parentCtrl.text.trim().isEmpty ||
                  subCtrl.text.trim().isEmpty ||
                  idsCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return null;

    final ids = idsCtrl.text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return _ByIdsParams(parentCtrl.text.trim(), subCtrl.text.trim(), ids);
  }

  // ---------- Parâmetros – por Filtro ----------
  Future<_ByFilterParams?> _askByFilter(BuildContext context) async {
    final parentCtrl = TextEditingController(text: 'contracts'); // ← NOVO: coleção principal
    final subCtrl = TextEditingController(text: 'reportsMeasurement');
    final fieldCtrl = TextEditingController(text: 'migratedFromMeasurements'); // nome do campo
    final valueCtrl = TextEditingController(text: 'true');
    WhereOp op = WhereOp.eq;
    bool useParents = true; // ← NOVO: aplicar em cada pai (recomendado)

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Apagar por Filtro'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: parentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Coleção principal (pai)',
                    hintText: 'Ex.: contracts',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subcoleção',
                    hintText: 'Ex.: reportsMeasurement',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fieldCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Campo para filtrar',
                          hintText: 'Ex.: migratedFromMeasurements',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<WhereOp>(
                      value: op,
                      onChanged: (v) => setState(() => op = v ?? WhereOp.eq),
                      items: const [
                        DropdownMenuItem(value: WhereOp.eq, child: Text('==')),
                        DropdownMenuItem(value: WhereOp.lt, child: Text('<')),
                        DropdownMenuItem(value: WhereOp.lte, child: Text('≤')),
                        DropdownMenuItem(value: WhereOp.gt, child: Text('>')),
                        DropdownMenuItem(value: WhereOp.gte, child: Text('≥')),
                        DropdownMenuItem(value: WhereOp.arrayContains, child: Text('array-contains')),
                        DropdownMenuItem(value: WhereOp.whereIn, child: Text('in')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Valor (para "in", use vírgulas)',
                    hintText: 'Ex.: true  |  123  |  2024-01-01  |  a,b,c',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aplicar em CADA pai (ao invés de collectionGroup)'),
                  subtitle: const Text('Recomendado quando você quer restringir à coleção principal informada'),
                  value: useParents,
                  onChanged: (v) => setState(() => useParents = v),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (subCtrl.text.trim().isEmpty ||
                      fieldCtrl.text.trim().isEmpty ||
                      valueCtrl.text.trim().isEmpty) return;
                  // parent pode ser ignorado se useParents=false
                  if (useParents && parentCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    ) ??
        false;

    if (!ok) return null;

    final dynamic parsed = (op == WhereOp.whereIn)
        ? FieldValueParser.parse(valueCtrl.text, tryList: true)
        : FieldValueParser.parse(valueCtrl.text);

    final filter = WhereFilter(fieldCtrl.text.trim(), op, parsed);
    return _ByFilterParams(
      parent: parentCtrl.text.trim(),
      sub: subCtrl.text.trim(),
      filters: [filter],
      useParents: useParents,
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
