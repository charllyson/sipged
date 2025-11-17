// lib/screens/process/hiring/5Edital/section_4_lances.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

class SectionLances extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;

  const SectionLances({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionLances> createState() => _SectionLancesState();
}

class _LanceRowControllers {
  final TextEditingController licitanteCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();
  final TextEditingController dataHoraCtrl = TextEditingController();

  _LanceRowControllers();

  _LanceRowControllers.fromMap(Map<String, dynamic> m) {
    licitanteCtrl.text = (m['licitante'] ?? '').toString();
    valorCtrl.text = (m['valor'] ?? '').toString();
    dataHoraCtrl.text = (m['dataHora'] ?? '').toString();
  }

  Map<String, dynamic> toMap() => {
    'licitante': licitanteCtrl.text,
    'valor': valorCtrl.text,
    'dataHora': dataHoraCtrl.text,
  };

  void dispose() {
    licitanteCtrl.dispose();
    valorCtrl.dispose();
    dataHoraCtrl.dispose();
  }
}

class _SectionLancesState extends State<SectionLances> {
  List<_LanceRowControllers> _rows = [];

  @override
  void initState() {
    super.initState();
    _rebuildFromData(widget.data);
  }

  @override
  void didUpdateWidget(covariant SectionLances oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.lancesItems != widget.data.lancesItems) {
      _rebuildFromData(widget.data);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _rebuildFromData(EditalData data) {
    for (final r in _rows) {
      r.dispose();
    }
    _rows = data.lancesItems
        .map((m) => _LanceRowControllers.fromMap(m))
        .toList();
    setState(() {});
  }

  void _emitChange() {
    final updatedItems = _rows.map((r) => r.toMap()).toList();
    final updated = widget.data.copyWith(lancesItems: updatedItems);
    widget.onChanged(updated);
  }

  void _addLance() {
    setState(() {
      _rows.add(_LanceRowControllers());
    });
    _emitChange();
  }

  void _removeLance(int index) {
    if (index < 0 || index >= _rows.length) return;
    final r = _rows.removeAt(index);
    r.dispose();
    setState(() {});
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 3,
          minItemWidth: 260,
          extraPadding: 29,
          spacing: 12,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Lances / Negociação (se aplicável)'),
                OutlinedButton.icon(
                  onPressed: isEditable ? _addLance : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar lance'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Cards
            ...List.generate(_rows.length, (i) {
              final l = _rows[i];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('Lance ${i + 1}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: w3,
                          child: CustomTextField(
                            controller: l.licitanteCtrl,
                            labelText: 'Licitante',
                            enabled: isEditable,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: CustomTextField(
                            controller: l.valorCtrl,
                            labelText: 'Valor do lance (R\$)',
                            enabled: isEditable,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: CustomDateField(
                            controller: l.dataHoraCtrl,
                            labelText: 'Data/Hora',
                            enabled: isEditable,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isEditable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () => _removeLance(i),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          tooltip: 'Remover lance',
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
