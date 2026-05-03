import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:sipged/screens/modules/contracts/hiring/4Cotacao/fornecedor_card.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

class SectionRespostasFornecedores extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final int fornCount;
  final VoidCallback? onAdd;
  final VoidCallback? onRemoveOne;
  final void Function(CotacaoData updated) onChanged;

  const SectionRespostasFornecedores({
    super.key,
    required this.data,
    required this.isEditable,
    required this.fornCount,
    required this.onChanged,
    this.onAdd,
    this.onRemoveOne,
  });

  @override
  State<SectionRespostasFornecedores> createState() =>
      _SectionRespostasFornecedoresState();
}

class _SectionRespostasFornecedoresState
    extends State<SectionRespostasFornecedores> {
  late final TextEditingController _f1NomeCtrl;
  late final TextEditingController _f1CnpjCtrl;
  late final TextEditingController _f1ValorCtrl;
  late final TextEditingController _f1DataCtrl;
  late final TextEditingController _f1LinkCtrl;

  late final TextEditingController _f2NomeCtrl;
  late final TextEditingController _f2CnpjCtrl;
  late final TextEditingController _f2ValorCtrl;
  late final TextEditingController _f2DataCtrl;
  late final TextEditingController _f2LinkCtrl;

  late final TextEditingController _f3NomeCtrl;
  late final TextEditingController _f3CnpjCtrl;
  late final TextEditingController _f3ValorCtrl;
  late final TextEditingController _f3DataCtrl;
  late final TextEditingController _f3LinkCtrl;

  bool _syncing = false;

  List<TextEditingController> get _allControllers => [
    _f1NomeCtrl,
    _f1CnpjCtrl,
    _f1ValorCtrl,
    _f1DataCtrl,
    _f1LinkCtrl,
    _f2NomeCtrl,
    _f2CnpjCtrl,
    _f2ValorCtrl,
    _f2DataCtrl,
    _f2LinkCtrl,
    _f3NomeCtrl,
    _f3CnpjCtrl,
    _f3ValorCtrl,
    _f3DataCtrl,
    _f3LinkCtrl,
  ];

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _f1NomeCtrl = TextEditingController(text: d.f1Nome ?? '');
    _f1CnpjCtrl = TextEditingController(text: d.f1Cnpj ?? '');
    _f1ValorCtrl = TextEditingController(text: d.f1Valor ?? '');
    _f1DataCtrl = TextEditingController(text: d.f1DataRecebimento ?? '');
    _f1LinkCtrl = TextEditingController(text: d.f1LinkProposta ?? '');

    _f2NomeCtrl = TextEditingController(text: d.f2Nome ?? '');
    _f2CnpjCtrl = TextEditingController(text: d.f2Cnpj ?? '');
    _f2ValorCtrl = TextEditingController(text: d.f2Valor ?? '');
    _f2DataCtrl = TextEditingController(text: d.f2DataRecebimento ?? '');
    _f2LinkCtrl = TextEditingController(text: d.f2LinkProposta ?? '');

    _f3NomeCtrl = TextEditingController(text: d.f3Nome ?? '');
    _f3CnpjCtrl = TextEditingController(text: d.f3Cnpj ?? '');
    _f3ValorCtrl = TextEditingController(text: d.f3Valor ?? '');
    _f3DataCtrl = TextEditingController(text: d.f3DataRecebimento ?? '');
    _f3LinkCtrl = TextEditingController(text: d.f3LinkProposta ?? '');

    _attachListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });
  }

  void _attachListeners() {
    for (final controller in _allControllers) {
      controller.addListener(_emitChange);
    }
  }

  void _removeListeners() {
    for (final controller in _allControllers) {
      controller.removeListener(_emitChange);
    }
  }

  void _syncController(TextEditingController controller, String? value) {
    final text = value ?? '';

    if (controller.text == text) return;

    controller.text = text;
  }

  @override
  void didUpdateWidget(covariant SectionRespostasFornecedores oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _syncing = true;

    _syncController(_f1NomeCtrl, d.f1Nome);
    _syncController(_f1CnpjCtrl, d.f1Cnpj);
    _syncController(_f1ValorCtrl, d.f1Valor);
    _syncController(_f1DataCtrl, d.f1DataRecebimento);
    _syncController(_f1LinkCtrl, d.f1LinkProposta);

    _syncController(_f2NomeCtrl, d.f2Nome);
    _syncController(_f2CnpjCtrl, d.f2Cnpj);
    _syncController(_f2ValorCtrl, d.f2Valor);
    _syncController(_f2DataCtrl, d.f2DataRecebimento);
    _syncController(_f2LinkCtrl, d.f2LinkProposta);

    _syncController(_f3NomeCtrl, d.f3Nome);
    _syncController(_f3CnpjCtrl, d.f3Cnpj);
    _syncController(_f3ValorCtrl, d.f3Valor);
    _syncController(_f3DataCtrl, d.f3DataRecebimento);
    _syncController(_f3LinkCtrl, d.f3LinkProposta);

    _syncing = false;
  }

  @override
  void dispose() {
    _removeListeners();

    for (final controller in _allControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _emitChange() {
    if (_syncing) return;

    final updated = widget.data.copyWith(
      f1Nome: _f1NomeCtrl.text,
      f1Cnpj: _f1CnpjCtrl.text,
      f1Valor: _f1ValorCtrl.text,
      f1DataRecebimento: _f1DataCtrl.text,
      f1LinkProposta: _f1LinkCtrl.text,
      f2Nome: _f2NomeCtrl.text,
      f2Cnpj: _f2CnpjCtrl.text,
      f2Valor: _f2ValorCtrl.text,
      f2DataRecebimento: _f2DataCtrl.text,
      f2LinkProposta: _f2LinkCtrl.text,
      f3Nome: _f3NomeCtrl.text,
      f3Cnpj: _f3CnpjCtrl.text,
      f3Valor: _f3ValorCtrl.text,
      f3DataRecebimento: _f3DataCtrl.text,
      f3LinkProposta: _f3LinkCtrl.text,
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

  void _applyFornecedor({
    required int index,
    required String? label,
    required List<TenantItemData> bodies,
  }) {
    final nomes = [_f1NomeCtrl, _f2NomeCtrl, _f3NomeCtrl];
    final cnpjs = [_f1CnpjCtrl, _f2CnpjCtrl, _f3CnpjCtrl];

    if (index < 0 || index >= nomes.length) return;

    final value = label ?? '';

    nomes[index].text = value;

    final body = _findBodyByLabel(bodies, value);
    final cnpj = _cnpjFromBody(body);

    if (cnpj != null) {
      cnpjs[index].text = cnpj;
    } else if (value.isEmpty) {
      cnpjs[index].clear();
    }

    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final nomes = [_f1NomeCtrl, _f2NomeCtrl, _f3NomeCtrl];
    final cnpjs = [_f1CnpjCtrl, _f2CnpjCtrl, _f3CnpjCtrl];
    final valores = [_f1ValorCtrl, _f2ValorCtrl, _f3ValorCtrl];
    final datas = [_f1DataCtrl, _f2DataCtrl, _f3DataCtrl];
    final links = [_f1LinkCtrl, _f2LinkCtrl, _f3LinkCtrl];

    final tenantState = context.watch<TenantCubit>().state;
    final List<TenantItemData> bodies = tenantState.companyBodies;

    final bodyLabels = bodies.map((e) => e.label).where((e) {
      return e.trim().isNotEmpty;
    });

    final fornecedoresFromCtrls = nomes.map((e) => e.text.trim()).where((e) {
      return e.isNotEmpty;
    });

    final List<String> allLabels = {
      ...bodyLabels,
      ...fornecedoresFromCtrls,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final safeCount = widget.fornCount.clamp(1, 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Respostas dos Fornecedores'),
        const SizedBox(height: 8),
        ...List.generate(
          safeCount,
              (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FornecedorCard(
                title: 'Fornecedor ${i + 1}',
                enabled: widget.isEditable,
                nomeCtrl: nomes[i],
                cnpjCtrl: cnpjs[i],
                valorCtrl: valores[i],
                dataCtrl: datas[i],
                linkCtrl: links[i],
                fornecedoresLabels: allLabels,
                onAddNewEmpresa: _showCreateTenantCompanyBodyDialog,
                onChangedFornecedor: (label) {
                  _applyFornecedor(
                    index: i,
                    label: label,
                    bodies: bodies,
                  );
                },
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 8),
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (widget.onRemoveOne != null &&
                      widget.isEditable &&
                      safeCount > 1)
                    TextButton.icon(
                      onPressed: widget.onRemoveOne,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Remover fornecedor'),
                    ),
                  if (widget.onAdd != null && widget.isEditable && safeCount < 3)
                    OutlinedButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar fornecedor'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}