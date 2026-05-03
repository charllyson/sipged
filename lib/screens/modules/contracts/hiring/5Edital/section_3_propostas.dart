import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class SectionPropostas extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;
  final void Function(int index)? onDefinirVencedorEIr;

  const SectionPropostas({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
    this.onDefinirVencedorEIr,
  });

  @override
  State<SectionPropostas> createState() => _SectionPropostasState();
}

class _PropostaRowControllers {
  final TextEditingController licitanteCtrl = TextEditingController();
  final TextEditingController cnpjCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();
  final TextEditingController statusCtrl = TextEditingController();
  final TextEditingController motivoDesclassCtrl = TextEditingController();
  final TextEditingController linkCtrl = TextEditingController();

  _PropostaRowControllers();

  _PropostaRowControllers.fromMap(Map<String, dynamic> map) {
    licitanteCtrl.text = (map['licitante'] ?? '').toString();
    cnpjCtrl.text = (map['cnpj'] ?? '').toString();
    valorCtrl.text = (map['valor'] ?? '').toString();
    statusCtrl.text = (map['status'] ?? '').toString();
    motivoDesclassCtrl.text = (map['motivoDesclass'] ?? '').toString();
    linkCtrl.text = (map['link'] ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'licitante': licitanteCtrl.text,
      'cnpj': cnpjCtrl.text,
      'valor': valorCtrl.text,
      'status': statusCtrl.text,
      'motivoDesclass': motivoDesclassCtrl.text,
      'link': linkCtrl.text,
    };
  }

  void dispose() {
    licitanteCtrl.dispose();
    cnpjCtrl.dispose();
    valorCtrl.dispose();
    statusCtrl.dispose();
    motivoDesclassCtrl.dispose();
    linkCtrl.dispose();
  }
}

class _SectionPropostasState extends State<SectionPropostas> {
  List<_PropostaRowControllers> _rows = [];

  @override
  void initState() {
    super.initState();

    _rebuildFromData(widget.data, shouldSetState: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant SectionPropostas oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldRebuild =
        oldWidget.data.propostasItems != widget.data.propostasItems ||
            oldWidget.data.vencedor != widget.data.vencedor ||
            oldWidget.data.highlightWinner != widget.data.highlightWinner;

    if (shouldRebuild) {
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

    _rows = data.propostasItems.map((map) {
      return _PropostaRowControllers.fromMap(map);
    }).toList();

    if (shouldSetState && mounted) {
      setState(() {});
    }
  }

  void _emitChange() {
    final updatedItems = _rows.map((row) => row.toMap()).toList();

    final updated = widget.data.copyWith(
      propostasItems: updatedItems,
    );

    widget.onChanged(updated);
  }

  void _addProposta() {
    setState(() {
      _rows.add(_PropostaRowControllers());
    });

    _emitChange();
  }

  void _removeProposta(int index) {
    if (index < 0 || index >= _rows.length) return;

    final row = _rows.removeAt(index);
    row.dispose();

    setState(() {});

    _emitChange();
  }

  void _clearWinner() {
    final updated = widget.data.copyWith(
      vencedor: '',
      vencedorCnpj: '',
      valorVencedor: '',
      highlightWinner: false,
    );

    widget.onChanged(updated);
  }

  TenantItemData? _findBodyByLabel(
      List<TenantItemData> bodies,
      String label,
      ) {
    final lower = label.trim().toLowerCase();

    if (lower.isEmpty) return null;

    for (final body in bodies) {
      if (body.label.trim().toLowerCase() == lower) {
        return body;
      }
    }

    return null;
  }

  String? _cnpjFromBody(TenantItemData? body) {
    final cnpj = body?.extra['cnpj']?.toString().trim();

    if (cnpj == null || cnpj.isEmpty) return null;

    return cnpj;
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

  void _applyLicitante({
    required _PropostaRowControllers row,
    required String? label,
    required List<TenantItemData> bodies,
  }) {
    final value = label ?? '';

    row.licitanteCtrl.text = value;

    final body = _findBodyByLabel(bodies, value);
    final cnpj = _cnpjFromBody(body);

    if (cnpj != null) {
      row.cnpjCtrl.text = cnpj;
    } else if (value.isEmpty) {
      row.cnpjCtrl.clear();
    }

    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isEditable = widget.isEditable;

    final hasWinner =
        data.vencedor.trim().isNotEmpty && data.highlightWinner == true;

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
        final w1 = inputW1(context, constraints);

        final w4 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 4,
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
                const SectionTitle(text: 'Propostas recebidas'),
                OutlinedButton.icon(
                  onPressed: isEditable ? _addProposta : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar proposta'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Text(
                  'Nenhuma proposta cadastrada. Clique em "Adicionar proposta" para começar.',
                ),
              ),
            ...List.generate(_rows.length, (index) {
              final row = _rows[index];

              final isWinner = hasWinner &&
                  data.vencedor.trim() == row.licitanteCtrl.text.trim();

              final statusText = row.statusCtrl.text.trim();
              final isClassificada =
                  statusText.toLowerCase() == 'classificada';

              final chipBg =
              isClassificada ? Colors.blue.shade50 : Colors.red.shade50;
              final chipFg =
              isClassificada ? Colors.blue.shade700 : Colors.red.shade700;

              final cardBg =
              isWinner ? Colors.green.shade50 : Colors.grey.shade100;
              final cardBorder = isWinner ? Colors.green.shade600 : Colors.grey;

              final canRemoveCard =
              !isEditable ? false : (_rows.length > 1 || !isWinner);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cardBorder,
                    width: isWinner ? 2 : 1,
                  ),
                  boxShadow: isWinner
                      ? [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: Colors.green.withValues(alpha: 0.18),
                    ),
                  ]
                      : const [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Proposta ${index + 1}',
                          style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (statusText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isClassificada
                                      ? Icons.check_circle_outline
                                      : Icons.highlight_off_outlined,
                                  size: 16,
                                  color: chipFg,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: chipFg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isWinner)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onPressed: isEditable ? _clearWinner : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 18,
                                  color: Colors.amber.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vencedor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: Colors.red.shade600,
                                ),
                              ],
                            ),
                          ),
                        if (isEditable && !hasWinner)
                          TextButton.icon(
                            onPressed: widget.onDefinirVencedorEIr == null
                                ? null
                                : () => widget.onDefinirVencedorEIr!(index),
                            icon: const Icon(
                              Icons.emoji_events_outlined,
                              size: 18,
                            ),
                            label: const Text('Definir vencedor'),
                          ),
                        if (isEditable)
                          IconButton(
                            tooltip: canRemoveCard
                                ? 'Remover proposta'
                                : 'Não é possível remover a única proposta vencedora',
                            onPressed: canRemoveCard
                                ? () => _removeProposta(index)
                                : null,
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: w4,
                          child: DropDownChange(
                            controller: row.licitanteCtrl,
                            labelText: 'Licitante',
                            enabled: isEditable,
                            items: allLabels,
                            showSpecialAlways: true,
                            specialItemLabel: 'Adicionar empresa',
                            onChanged: (label) {
                              _applyLicitante(
                                row: row,
                                label: label,
                                bodies: bodies,
                              );
                            },
                            onAddNewItem: _showCreateTenantCompanyBodyDialog,
                          ),
                        ),
                        SizedBox(
                          width: w4,
                          child: CustomTextField(
                            controller: row.cnpjCtrl,
                            labelText: 'CNPJ',
                            enabled: false,
                            readOnly: true,
                          ),
                        ),
                        SizedBox(
                          width: w4,
                          child: CustomTextField(
                            controller: row.valorCtrl,
                            labelText: 'Valor (R\$)',
                            enabled: isEditable,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w4,
                          child: DropDownChange(
                            enabled: isEditable,
                            labelText: 'Status',
                            controller: row.statusCtrl,
                            items: HiringData.statusProposta,
                            onChanged: (value) {
                              row.statusCtrl.text = value ?? '';
                              _emitChange();
                            },
                          ),
                        ),
                        SizedBox(
                          width: w1,
                          child: CustomTextField(
                            controller: row.motivoDesclassCtrl,
                            labelText: 'Motivo da desclassificação',
                            enabled: isEditable,
                            maxLines: 2,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                        SizedBox(
                          width: w1,
                          child: CustomTextField(
                            controller: row.linkCtrl,
                            labelText: 'Link da proposta',
                            enabled: isEditable,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),
                      ],
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