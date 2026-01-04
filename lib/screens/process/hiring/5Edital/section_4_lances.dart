// lib/screens/process/hiring/5Edital/section_4_lances.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

// System
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';
import 'package:siged/_widgets/windows/company_body_dialog.dart';

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

    // Garante a carga de companies + companiesBodies
    Future.microtask(() async {
      final system = context.read<SetupCubit>();

      if (system.state.companies.isEmpty) {
        await system.loadCompanies();
      }

      final companies = system.state.companies;
      if (companies.isNotEmpty) {
        final parentCompanyId =
            companies.first.companyId ?? companies.first.id;
        await system.ensureCompanySetupLoaded(parentCompanyId);
      }
    });
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

    // companiesBodies disponíveis (empresa selecionada)
    final systemState = context.watch<SetupCubit>().state;
    final List<SetupData> bodies = systemState.companyBodies;

    final List<String> bodyLabels =
    bodies.map((e) => e.label).toList(growable: false);

    // Labels já usados nos lances (p/ manter compatibilidade com dados antigos)
    final Iterable<String> labelsFromRows = _rows
        .map((r) => r.licitanteCtrl.text.trim())
        .where((t) => t.isNotEmpty);

    // União: Cubit + o que já está nas linhas
    final List<String> allLabels = {
      ...bodyLabels,
      ...labelsFromRows,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    SetupData? _findBodyByLabel(String label) {
      final lower = label.trim().toLowerCase();
      try {
        return bodies.firstWhere(
              (c) => c.label.trim().toLowerCase() == lower,
        );
      } catch (_) {
        return null;
      }
    }

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
                const SectionTitle(text: 'Lances'),
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
                    SectionTitle(text: 'Lance ${i + 1}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // LICITANTE usando DropDownButtonChange com companiesBodies
                        SizedBox(
                          width: w3,
                          child: DropDownButtonChange(
                            controller: l.licitanteCtrl,
                            labelText: 'Licitante',
                            enabled: isEditable,
                            items: allLabels,
                            showSpecialAlways: true,
                            specialItemLabel: 'Adicionar empresa',
                            onChanged: (label) {
                              final val = label ?? '';
                              l.licitanteCtrl.text = val;

                              // Aqui não temos CNPJ no lance,
                              // então só propagamos o nome e emitimos mudança
                              final _ = _findBodyByLabel(val);
                              _emitChange();
                            },
                            onAddNewItem: showCreateCompanyBodyDialog,
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: CustomTextField(
                            controller: l.valorCtrl,
                            labelText: 'Valor do lance (R\$)',
                            enabled: isEditable,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: CustomDateField(
                            controller: l.dataHoraCtrl,
                            labelText: 'Data/Hora',
                            enabled: isEditable,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(14),
                              TextInputMask(mask: '99/99/9999 99:99'),
                            ],
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
