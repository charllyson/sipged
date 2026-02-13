// lib/screens/modules/operation/schedule/schedule_lane_edit_section.dart
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_style.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_row_data.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

import 'schedule_lane_row.dart';

class ScheduleLaneEdit extends StatefulWidget {
  const ScheduleLaneEdit({
    super.key,
    required this.initialRows,
    required this.selectedServiceKey,
    this.selectedServiceLabel,
  });

  final List<ScheduleLaneClass> initialRows;

  /// Serviço selecionado nos botões laterais (ex.: "asfalto", "base"...)
  final String selectedServiceKey;

  /// (Opcional) rótulo bonito do serviço para exibir no cabeçalho
  final String? selectedServiceLabel;

  @override
  State<ScheduleLaneEdit> createState() => _ScheduleLaneEditState();
}

class _ScheduleLaneEditState extends State<ScheduleLaneEdit> {
  final List<ScheduleLaneRowData> _rows = [];
  final Set<String> _lockedIds = {}; // manter tua lógica de travar 3 linhas

  // estado local: por linha, se a faixa é aplicável ao serviço atual
  late List<bool> _allowedForSelected;

  bool get _isGeral => widget.selectedServiceKey.toLowerCase() == 'geral';

  @override
  void initState() {
    super.initState();

    _allowedForSelected = [];

    // monta as linhas iniciais
    for (final r in widget.initialRows) {
      _rows.add(
        ScheduleLaneRowData(
          id: UniqueKey().toString(),
          posCtrl: TextEditingController(text: r.pos),
          nameCtrl: TextEditingController(text: r.nome),
          altura: r.altura,
          color: ScheduleRoadStyle.colorForFaixa(r.nome),
        ),
      );
      // default true se não tiver chave gravada
      _allowedForSelected.add(r.isAllowed(widget.selectedServiceKey));
    }

    // trava 3 linhas centrais (se existirem)
    if (_rows.isNotEmpty) {
      final lockCount = _rows.length < 3 ? _rows.length : 3;
      final start = (_rows.length - lockCount) ~/ 2;
      for (int i = start; i < start + lockCount; i++) {
        _lockedIds.add(_rows[i].id);
      }
    }

    // se não houver linhas, cria 3 travadas
    if (_rows.isEmpty) {
      for (final pos in const ['', '', '']) {
        final id = UniqueKey().toString();
        _rows.add(
          ScheduleLaneRowData(
            id: id,
            posCtrl: TextEditingController(text: pos),
            nameCtrl: TextEditingController(text: ''),
            altura: 20,
            color: ScheduleRoadStyle.colorForFaixa(''),
          ),
        );
        _lockedIds.add(id);
        _allowedForSelected.add(true);
      }
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.posCtrl.dispose();
      r.nameCtrl.dispose();
    }
    super.dispose();
  }

  bool _canRemoveIndex(int i) {
    if (_rows.length <= 3) return false;
    return !_lockedIds.contains(_rows[i].id);
  }

  void _addAbove() {
    setState(() {
      _rows.insert(
        0,
        ScheduleLaneRowData(
          id: UniqueKey().toString(),
          posCtrl: TextEditingController(text: ''),
          nameCtrl: TextEditingController(text: ''),
          altura: 20,
          color: ScheduleRoadStyle.colorForFaixa(''),
        ),
      );
      _allowedForSelected.insert(0, true);
    });
  }

  void _addBelow() {
    setState(() {
      _rows.add(
        ScheduleLaneRowData(
          id: UniqueKey().toString(),
          posCtrl: TextEditingController(text: ''),
          nameCtrl: TextEditingController(text: ''),
          altura: 20,
          color: ScheduleRoadStyle.colorForFaixa(''),
        ),
      );
      _allowedForSelected.add(true);
    });
  }

  void _removeAt(int i) {
    if (!_canRemoveIndex(i)) return;
    setState(() {
      _rows.removeAt(i);
      _allowedForSelected.removeAt(i);
    });
  }

  void _onNameChanged(int i, String value) {
    setState(() => _rows[i].color = ScheduleRoadStyle.colorForFaixa(value));
  }

  List<ScheduleLaneClass> _collectResult() {
    // Preserva allowedByService existentes, alterando apenas a key do serviço atual
    return List<ScheduleLaneClass>.generate(_rows.length, (i) {
      final original = (i < widget.initialRows.length)
          ? widget.initialRows[i]
          : const ScheduleLaneClass(pos: '', nome: '', altura: 20);

      final merged = Map<String, bool>.from(original.allowedByService);
      merged[widget.selectedServiceKey.toLowerCase()] = _allowedForSelected[i];

      return ScheduleLaneClass(
        pos: _rows[i].posCtrl.text.trim(),
        nome: _rows[i].nameCtrl.text.trim(),
        altura: _rows[i].altura,
        allowedByService: merged,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final maxW = screen.width * 0.92;
    final dialogW = maxW.clamp(360.0, 820.0);

    final serviceLabel =
    (widget.selectedServiceLabel ?? widget.selectedServiceKey).toUpperCase();

    return WindowDialog(
      title: 'Editar faixas de $serviceLabel',
      width: dialogW,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      onClose: () => Navigator.of(context).maybePop(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: screen.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Conteúdo scrollável
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addAbove,
                        icon: const Icon(Icons.vertical_align_top),
                        label: const Text('Adicionar faixa acima'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    for (int i = 0; i < _rows.length; i++) ...[
                      // Linha base (pos/nome/altura/cor)
                      ScheduleLaneRow(
                        index: i,
                        data: _rows[i],
                        canRemove: _canRemoveIndex(i),
                        onRemove: () => _removeAt(i),
                        onPosChanged: (_) {},
                        onNameChanged: (v) => _onNameChanged(i, v),
                      ),
                      const SizedBox(height: 6),

                      // Checkbox único por faixa
                      Row(
                        children: [
                          Checkbox(
                            value: _allowedForSelected[i],
                            onChanged: _isGeral
                                ? null // desabilita corretamente em "GERAL"
                                : (v) {
                              if (v == null) return;
                              setState(() => _allowedForSelected[i] = v);
                            },
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _isGeral
                                  ? 'Selecione um serviço específico para configurar aplicabilidade por faixa.'
                                  : 'Aplicável ao serviço atual ($serviceLabel)',
                              style: TextStyle(
                                fontSize: 13,
                                color: _isGeral
                                    ? Colors.black38
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 18),
                    ],

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addBelow,
                        icon: const Icon(Icons.vertical_align_bottom),
                        label: const Text('Adicionar faixa abaixo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pop<List<ScheduleLaneClass>>(_collectResult()),
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
