import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';

class SectionResultado extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;
  final GlobalKey? keyResultado;

  const SectionResultado({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
    this.keyResultado,
  });

  @override
  State<SectionResultado> createState() => _SectionResultadoState();
}

class _SectionResultadoState extends State<SectionResultado> {
  late final TextEditingController _vencedorCtrl;
  late final TextEditingController _vencedorCnpjCtrl;
  late final TextEditingController _valorVencedorCtrl;
  late final TextEditingController _dataResultadoCtrl;
  late final TextEditingController _adjudicacaoDataCtrl;
  late final TextEditingController _homologacaoDataCtrl;
  late final TextEditingController _adjudicacaoLinkCtrl;
  late final TextEditingController _homologacaoLinkCtrl;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _vencedorCtrl = TextEditingController(text: d.vencedor);
    _vencedorCnpjCtrl = TextEditingController(text: d.vencedorCnpj);
    _valorVencedorCtrl = TextEditingController(text: d.valorVencedor);
    _dataResultadoCtrl = TextEditingController(text: d.dataResultado);
    _adjudicacaoDataCtrl = TextEditingController(text: d.adjudicacaoData);
    _homologacaoDataCtrl = TextEditingController(text: d.homologacaoData);
    _adjudicacaoLinkCtrl = TextEditingController(text: d.adjudicacaoLink);
    _homologacaoLinkCtrl = TextEditingController(text: d.homologacaoLink);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant SectionResultado oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _syncing = true;

    _syncController(_vencedorCtrl, d.vencedor);
    _syncController(_vencedorCnpjCtrl, d.vencedorCnpj);
    _syncController(_valorVencedorCtrl, d.valorVencedor);
    _syncController(_dataResultadoCtrl, d.dataResultado);
    _syncController(_adjudicacaoDataCtrl, d.adjudicacaoData);
    _syncController(_homologacaoDataCtrl, d.homologacaoData);
    _syncController(_adjudicacaoLinkCtrl, d.adjudicacaoLink);
    _syncController(_homologacaoLinkCtrl, d.homologacaoLink);

    _syncing = false;
  }

  @override
  void dispose() {
    _vencedorCtrl.dispose();
    _vencedorCnpjCtrl.dispose();
    _valorVencedorCtrl.dispose();
    _dataResultadoCtrl.dispose();
    _adjudicacaoDataCtrl.dispose();
    _homologacaoDataCtrl.dispose();
    _adjudicacaoLinkCtrl.dispose();
    _homologacaoLinkCtrl.dispose();

    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.text = value;
  }

  void _emitChange({bool? highlightWinner}) {
    if (_syncing) return;

    final updated = widget.data.copyWith(
      vencedor: _vencedorCtrl.text,
      vencedorCnpj: _vencedorCnpjCtrl.text,
      valorVencedor: _valorVencedorCtrl.text,
      dataResultado: _dataResultadoCtrl.text,
      adjudicacaoData: _adjudicacaoDataCtrl.text,
      homologacaoData: _homologacaoDataCtrl.text,
      adjudicacaoLink: _adjudicacaoLinkCtrl.text,
      homologacaoLink: _homologacaoLinkCtrl.text,
      highlightWinner: highlightWinner ?? widget.data.highlightWinner,
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

  void _applyWinner({
    required String? label,
    required List<TenantItemData> bodies,
  }) {
    final value = label ?? '';

    _vencedorCtrl.text = value;

    final body = _findBodyByLabel(bodies, value);
    final cnpj = _cnpjFromBody(body);

    if (cnpj != null) {
      _vencedorCnpjCtrl.text = cnpj;
    } else if (value.isEmpty) {
      _vencedorCnpjCtrl.clear();
    }

    _emitChange(
      highlightWinner: value.trim().isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final isEditable = widget.isEditable;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasWinner =
        data.vencedor.trim().isNotEmpty && data.highlightWinner == true;

    final baseBg = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : Colors.grey.shade100;

    final baseBorder = colorScheme.outlineVariant;

    final winnerBg = Colors.green.shade50;
    final winnerBorder = Colors.green.shade600;

    final cardBg = hasWinner ? winnerBg : baseBg;
    final cardBorder = hasWinner ? winnerBorder : baseBorder;

    final tenantState = context.watch<TenantCubit>().state;
    final List<TenantItemData> bodies = tenantState.companyBodies;

    final bodyLabels = bodies.map((e) => e.label).where((e) {
      return e.trim().isNotEmpty;
    });

    final currentWinner = _vencedorCtrl.text.trim();

    final List<String> allLabels = {
      ...bodyLabels,
      if (currentWinner.isNotEmpty) currentWinner,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 4,
          minItemWidth: 260,
          extraPadding: 32,
          spacing: 12,
        );

        return KeyedSubtree(
          key: widget.keyResultado,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cardBorder,
                width: hasWinner ? 2 : 1,
              ),
              boxShadow: hasWinner
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
                    const SectionTitle(text: 'Resultado'),
                    if (hasWinner)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vencedor definido',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: w4,
                      child: DropDownChange(
                        controller: _vencedorCtrl,
                        labelText: 'Vencedor',
                        enabled: isEditable,
                        items: allLabels,
                        showSpecialAlways: true,
                        specialItemLabel: 'Adicionar empresa',
                        onChanged: (label) {
                          _applyWinner(
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
                        controller: _vencedorCnpjCtrl,
                        labelText: 'CNPJ do vencedor',
                        enabled: false,
                        readOnly: true,
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _valorVencedorCtrl,
                        labelText: 'Valor vencedor (R\$)',
                        enabled: isEditable,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: DateFieldChange(
                        controller: _dataResultadoCtrl,
                        labelText: 'Data do resultado',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: DateFieldChange(
                        controller: _adjudicacaoDataCtrl,
                        labelText: 'Data da adjudicação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: DateFieldChange(
                        controller: _homologacaoDataCtrl,
                        labelText: 'Data da homologação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _adjudicacaoLinkCtrl,
                        labelText: 'Link da adjudicação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _homologacaoLinkCtrl,
                        labelText: 'Link da homologação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}