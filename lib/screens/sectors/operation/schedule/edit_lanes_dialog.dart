import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import 'lane_preview.dart';
import 'package:flutter/material.dart';
import 'lane_preview.dart';

class EditLanesDialog extends StatefulWidget {
  final List<String> initialLabels;
  const EditLanesDialog({super.key, required this.initialLabels});

  @override
  State<EditLanesDialog> createState() => _EditLanesDialogState();
}

class _EditLanesDialogState extends State<EditLanesDialog> {
  static const double kRowHeight = 44;
  static const double kBetweenRows = 12;
  final _formKey = GlobalKey<FormState>();
  late List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final base = widget.initialLabels.isEmpty
        ? <String>['MARGEM LE', 'CANTEIRO CENTRAL', 'MARGEM LD']
        : List<String>.from(widget.initialLabels);
    while (base.length < 3) {
      base.add('FAIXA ${base.length + 1}');
    }
    _ctrls = [for (final l in base) TextEditingController(text: l)];
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- ações extremos ----------
  void _addAboveTop() {
    setState(() => _ctrls.insert(0, TextEditingController(text: '')));
  }

  void _removeTop() {
    if (_ctrls.length <= 3) return;
    final c = _ctrls.removeAt(0);
    c.dispose();
    setState(() {});
  }

  void _addBelowBottom() {
    setState(() => _ctrls.add(TextEditingController(text: '')));
  }

  void _removeBottom() {
    if (_ctrls.length <= 3) return;
    final c = _ctrls.removeLast();
    c.dispose();
    setState(() {});
  }

  Widget _buttonsForRow(int i) {
    final last = _ctrls.length - 1;
    final onlyBase = _ctrls.length == 3;

    // topo
    if (i == 0) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        if (!onlyBase)
          IconButton(
            tooltip: 'Remover faixa do topo',
            icon: const Icon(Icons.remove_circle),
            color: Colors.red,
            onPressed: _removeTop,
          ),
        IconButton(
          tooltip: 'Adicionar faixa acima',
          icon: const Icon(Icons.add_circle),
          color: Colors.green,
          onPressed: _addAboveTop,
        ),
      ]);
    }

    // último
    if (i == last) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        if (!onlyBase)
          IconButton(
            tooltip: 'Remover faixa do fim',
            icon: const Icon(Icons.remove_circle),
            color: Colors.red,
            onPressed: _removeBottom,
          ),
        IconButton(
          tooltip: 'Adicionar faixa abaixo',
          icon: const Icon(Icons.add_circle),
          color: Colors.green,
          onPressed: _addBelowBottom,
        ),
      ]);
    }

    // intermediárias: sem botões
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Editar nomes das faixas'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: _ctrls.length,
            separatorBuilder: (_, __) => const SizedBox(height: kBetweenRows),
            itemBuilder: (_, i) {
              return Row(
                children: [
                  // preview de faixa (lateral toca nas vizinhas, central mantém tamanho)
                  LanePreview(
                    label: _ctrls[i].text,
                    aboveLabel: i > 0 ? _ctrls[i - 1].text : null,
                    belowLabel: i < _ctrls.length - 1 ? _ctrls[i + 1].text : null,
                    rowHeight: kRowHeight,
                    gap: kBetweenRows,
                  ),
                  const SizedBox(width: 8),
                  // campo
                  Expanded(
                    child: TextFormField(
                      controller: _ctrls[i],
                      decoration: InputDecoration(
                        labelText: 'Faixa ${i + 1}',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                      onChanged: (_) => setState(() {}), // atualiza o preview
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // botões (somente extremidades)
                  SizedBox(width: 100, height: kRowHeight, child: _buttonsForRow(i)),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final labels =
            _ctrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
            Navigator.pop(context, labels);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
