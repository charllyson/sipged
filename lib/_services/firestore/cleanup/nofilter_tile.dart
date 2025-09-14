import 'package:flutter/material.dart';
import 'nofilter_util.dart';

class DeleteFieldInSubcollectionTile extends StatelessWidget {
  const DeleteFieldInSubcollectionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.line_axis),
      tileColor: Colors.white10,
      title: const Text('Apagar CAMPO em subcoleção (sem filtro)'),
      subtitle: const Text('Ex.: remover "measurementdata" de todos os docs'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        final params = await _askParams(context);
        if (params == null) return;

        final nav = Navigator.of(context, rootNavigator: true);

        // Dry-run: conta quantos documentos têm o campo
        _showLoading(nav);
        int preview = 0;
        try {
          final c = NoFilterSubcollectionCleaner();
          preview = await c.countDocsWithFieldUnderEachParent(
            parentCollectionPath: params.parent,
            subcollection: params.sub,
            fieldName: params.field,
          );
        } finally {
          _safePop(nav);
        }

        final ok = await _confirm(
          context,
          'Será removido o campo "${params.field}" de $preview documento(s)\n'
              'em: ${params.parent}/*/${params.sub}\n\nDeseja continuar?',
        );
        if (!ok) return;

        // Execução real
        _showLoading(nav);
        int affected = 0;
        try {
          final c = NoFilterSubcollectionCleaner();
          affected = await c.deleteFieldFromAllDocsUnderEachParent(
            parentCollectionPath: params.parent,
            subcollection: params.sub,
            fieldName: params.field,
            dryRun: false,
          );
        } finally {
          _safePop(nav);
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campo removido de $affected documento(s).')),
        );
      },
    );
  }

  // ===== UI helpers

  Future<_Params?> _askParams(BuildContext context) async {
    final parentCtrl = TextEditingController(text: 'contracts');
    final subCtrl    = TextEditingController(text: 'reportsMeasurement');
    final fieldCtrl  = TextEditingController(text: 'measurementdata');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Coleção / Subcoleção / Campo'),
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
                hintText: 'Ex.: reportsMeasurement / adjustmentMeasurement / revisionMeasurement',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fieldCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do campo a remover',
                hintText: 'Ex.: measurementdata',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (parentCtrl.text.trim().isEmpty ||
                  subCtrl.text.trim().isEmpty ||
                  fieldCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return null;
    return _Params(
      parentCtrl.text.trim(),
      subCtrl.text.trim(),
      fieldCtrl.text.trim(),
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
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    ) ??
        false;
  }

  void _showLoading(NavigatorState nav) {
    nav.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _safePop(NavigatorState nav) {
    if (nav.canPop()) {
      nav.pop();
    }
  }
}

class _Params {
  final String parent;
  final String sub;
  final String field;
  _Params(this.parent, this.sub, this.field);
}
