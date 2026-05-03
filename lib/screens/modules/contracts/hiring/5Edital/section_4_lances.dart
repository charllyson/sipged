import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'licitante': licitanteCtrl.text,
      'valor': valorCtrl.text,
      'dataHora': dataHoraCtrl.text,
    };
  }

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

    _rebuildFromData(
      widget.data,
      shouldSetState: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
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
    for (final row in _rows) {
      row.dispose();
    }

    super.dispose();
  }

  void _rebuildFromData(
      EditalData data, {
        bool shouldSetState = true,
      }) {
    for (final row in _rows) {
      row.dispose();
    }

    _rows = data.lancesItems.map((m) {
      return _LanceRowControllers.fromMap(m);
    }).toList();

    if (shouldSetState && mounted) {
      setState(() {});
    }
  }

  void _emitChange() {
    final updatedItems = _rows.map((row) => row.toMap()).toList();

    final updated = widget.data.copyWith(
      lancesItems: updatedItems,
    );

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

    final row = _rows.removeAt(index);
    row.dispose();

    setState(() {});

    _emitChange();
  }

  Future<String?> _showCreateTenantCompanyBodyDialog(
      BuildContext context,
      ) async {
    final tenantCubit = context.read<TenantCubit>();

    final nameCtrl = TextEditingController();
    final cnpjCtrl = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Adicionar empresa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome da empresa',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cnpjCtrl,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) {
                  Navigator.of(dialogCtx).pop({
                    'label': nameCtrl.text.trim(),
                    'cnpj': cnpjCtrl.text.trim(),
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop({
                  'label': nameCtrl.text.trim(),
                  'cnpj': cnpjCtrl.text.trim(),
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    cnpjCtrl.dispose();

    if (!mounted || result == null) return null;

    final label = result['label']?.trim() ?? '';
    final cnpj = result['cnpj']?.trim();

    if (label.isEmpty) return null;

    final created = await tenantCubit.createCompanyBody(
      label,
      cnpj: cnpj,
    );

    if (!mounted) return null;

    return created?.label ?? label;
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;

    final tenantState = context.watch<TenantCubit>().state;
    final List<TenantItemData> bodies = tenantState.companyBodies;

    final bodyLabels = bodies.map((e) => e.label).where((e) {
      return e.trim().isNotEmpty;
    });

    final labelsFromRows = _rows.map((row) {
      return row.licitanteCtrl.text.trim();
    }).where((e) {
      return e.isNotEmpty;
    });

    final List<String> allLabels = {
      ...bodyLabels,
      ...labelsFromRows,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
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
            ...List.generate(_rows.length, (i) {
              final row = _rows[i];

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
                        SizedBox(
                          width: w3,
                          child: DropDownChange(
                            controller: row.licitanteCtrl,
                            labelText: 'Licitante',
                            enabled: isEditable,
                            items: allLabels,
                            showSpecialAlways: true,
                            specialItemLabel: 'Adicionar empresa',
                            onChanged: (label) {
                              row.licitanteCtrl.text = label ?? '';
                              _emitChange();
                            },
                            onAddNewItem: _showCreateTenantCompanyBodyDialog,
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: CustomTextField(
                            controller: row.valorCtrl,
                            labelText: 'Valor do lance',
                            enabled: isEditable,
                            keyboardType: TextInputType.number,
                            hintText: 'Ex.: 1.234,56',
                            prefixText: 'R\$ ',
                            inputFormatters: [
                              SipGedMoneyFormatter(),
                            ],
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w3,
                          child: DateFieldChange(
                            controller: row.dataHoraCtrl,
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