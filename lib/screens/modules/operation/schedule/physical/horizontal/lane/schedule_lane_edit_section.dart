import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_style.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';

import 'schedule_lane_row.dart';

class ScheduleLaneEdit extends StatefulWidget {
  const ScheduleLaneEdit({
    super.key,
    required this.initialRows,
    required this.selectedServiceKey,
    this.selectedServiceLabel,
  });

  final List<ScheduleRoadData> initialRows;

  /// Serviço selecionado nos botões laterais (ex.: "asfalto", "base"...)
  final String selectedServiceKey;

  /// (Opcional) rótulo bonito do serviço para exibir no cabeçalho
  final String? selectedServiceLabel;

  @override
  State<ScheduleLaneEdit> createState() => _ScheduleLaneEditState();
}

class _ScheduleLaneEditState extends State<ScheduleLaneEdit> {
  final List<ScheduleRoadData> _rows = [];
  final Set<String> _lockedIds = {};

  late List<bool> _allowedForSelected;

  bool get _isGeral => widget.selectedServiceKey.toLowerCase() == 'geral';

  @override
  void initState() {
    super.initState();

    _allowedForSelected = [];

    for (final r in widget.initialRows) {
      final nome = (r.nome ?? '').trim();

      final row = ScheduleRoadData.laneEditor(
        faixaIndex: r.faixaIndex,
        pos: r.pos ?? '',
        nome: nome,
        altura: r.altura ?? 20.0,
        anchor: r.anchor,
        allowedByService: r.allowedByService,
        color: ScheduleRoadStyle.colorForFaixa(nome),
      );

      _rows.add(row);
      _allowedForSelected.add(r.isAllowed(widget.selectedServiceKey));
    }

    if (_rows.isNotEmpty) {
      final lockCount = _rows.length < 3 ? _rows.length : 3;
      final start = (_rows.length - lockCount) ~/ 2;
      for (int i = start; i < start + lockCount; i++) {
        final id = _rows[i].editorId;
        if (id != null) {
          _lockedIds.add(id);
        }
      }
    }

    if (_rows.isEmpty) {
      for (int i = 0; i < 3; i++) {
        final row = ScheduleRoadData.laneEditor(
          faixaIndex: i,
          pos: '',
          nome: '',
          altura: 20,
          color: ScheduleRoadStyle.colorForFaixa(''),
        );
        _rows.add(row);
        if (row.editorId != null) {
          _lockedIds.add(row.editorId!);
        }
        _allowedForSelected.add(true);
      }
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.disposeEditorControllers();
    }
    super.dispose();
  }

  bool _canRemoveIndex(int i) {
    if (_rows.length <= 3) return false;
    final id = _rows[i].editorId;
    if (id == null) return true;
    return !_lockedIds.contains(id);
  }

  void _addAbove() {
    setState(() {
      _rows.insert(
        0,
        ScheduleRoadData.laneEditor(
          faixaIndex: 0,
          pos: '',
          nome: '',
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
        ScheduleRoadData.laneEditor(
          faixaIndex: _rows.length,
          pos: '',
          nome: '',
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
      final row = _rows.removeAt(i);
      row.disposeEditorControllers();
      _allowedForSelected.removeAt(i);
    });
  }

  void _onNameChanged(int i, String value) {
    setState(() {
      _rows[i] = _rows[i].copyWith(
        nome: value,
        color: ScheduleRoadStyle.colorForFaixa(value),
      );
    });
  }

  void _onPosChanged(int i, String value) {
    setState(() {
      _rows[i] = _rows[i].copyWith(pos: value);
    });
  }

  List<ScheduleRoadData> _collectResult() {
    return List<ScheduleRoadData>.generate(_rows.length, (i) {
      final original = (i < widget.initialRows.length)
          ? widget.initialRows[i]
          : ScheduleRoadData.lane(
        faixaIndex: i,
        pos: '',
        nome: '',
        altura: 20,
      );

      final merged = Map<String, bool>.from(original.allowedByService);
      merged[widget.selectedServiceKey.toLowerCase()] = _allowedForSelected[i];

      return ScheduleRoadData.lane(
        faixaIndex: i,
        pos: _rows[i].resolvedPos,
        nome: _rows[i].resolvedNome,
        altura: _rows[i].resolvedAltura,
        anchor: original.anchor,
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
                      ScheduleLaneRow(
                        index: i,
                        data: _rows[i],
                        canRemove: _canRemoveIndex(i),
                        onRemove: () => _removeAt(i),
                        onPosChanged: (v) => _onPosChanged(i, v),
                        onNameChanged: (v) => _onNameChanged(i, v),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Checkbox(
                            value: _allowedForSelected[i],
                            onChanged: _isGeral
                                ? null
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
                      .pop<List<ScheduleRoadData>>(_collectResult()),
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