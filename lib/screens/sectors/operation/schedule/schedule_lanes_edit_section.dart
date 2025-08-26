// COMPLETO (puro)
import 'package:flutter/material.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_style.dart';
import 'package:sisged/_widgets/schedule/schedule_lane_class.dart';
import 'package:sisged/_widgets/schedule/schedule_lane_row_data.dart';

import 'schedule_lane_row.dart';

class ScheduleLanesEdit extends StatefulWidget {
  const ScheduleLanesEdit({
    super.key,
    required this.initialRows,
  });

  final List<ScheduleLaneClass> initialRows;

  @override
  State<ScheduleLanesEdit> createState() => _ScheduleLanesEditState();
}

class _ScheduleLanesEditState extends State<ScheduleLanesEdit> {
  final List<ScheduleLaneRowData> _rows = [];
  final Set<String> _lockedIds = {}; // 3 faixas-base

  @override
  void initState() {
    super.initState();

    for (final r in widget.initialRows) {
      _rows.add(ScheduleLaneRowData(
        id: UniqueKey().toString(),
        posCtrl: TextEditingController(text: r.pos),
        nameCtrl: TextEditingController(text: r.nome),
        altura: r.altura,
        color: ScheduleStyle.colorForFaixa(r.nome),
      ));
    }

    if (_rows.isNotEmpty) {
      final lockCount = _rows.length < 3 ? _rows.length : 3;
      final start = (_rows.length - lockCount) ~/ 2;
      for (int i = start; i < start + lockCount; i++) {
        _lockedIds.add(_rows[i].id);
      }
    }

    if (_rows.isEmpty) {
      for (final pos in const ['','','']) {
        final id = UniqueKey().toString();
        _rows.add(ScheduleLaneRowData(
          id: id,
          posCtrl: TextEditingController(text: pos),
          nameCtrl: TextEditingController(text: ''),
          altura: 20,
          color: ScheduleStyle.colorForFaixa(''),
        ));
        _lockedIds.add(id);
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
          color: ScheduleStyle.colorForFaixa(''),
        ),
      );
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
          color: ScheduleStyle.colorForFaixa(''),
        ),
      );
    });
  }

  void _removeAt(int i) {
    if (!_canRemoveIndex(i)) return;
    setState(() => _rows.removeAt(i));
  }

  void _onNameChanged(int i, String value) {
    setState(() => _rows[i].color = ScheduleStyle.colorForFaixa(value));
  }

  List<ScheduleLaneClass> _collectResult() {
    return _rows.map((r) => ScheduleLaneClass(
      pos: r.posCtrl.text.trim(),
      nome: r.nameCtrl.text.trim(),
      altura: r.altura,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.92;
    final dialogW = maxW.clamp(360.0, 820.0);

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Editar faixas'),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogW),
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
                  onPosChanged: (_) {},
                  onNameChanged: (v) => _onNameChanged(i, v),
                ),
                const SizedBox(height: 10),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop<List<ScheduleLaneClass>>(_collectResult()),
          icon: const Icon(Icons.save),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}
