// lib/screens/modules/contracts/hiring/4Cotacao/section_4_respostas_fornecedores.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/windows/company_body_dialog.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_data.dart';
import 'package:siged/screens/modules/contracts/hiring/4Cotacao/fornecedor_card.dart';

// System / Companies
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

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

    // Garante carga de companies + companiesBodies (via SetupCubit novo)
    Future.microtask(() async {
      final system = context.read<SetupCubit>();

      // Se ainda não tem nenhuma company em memória, carrega
      if (system.state.companies.isEmpty) {
        await system.loadCompanies();
      }

      final companies = system.state.companies;
      if (companies.isNotEmpty) {
        // Aqui pegamos a primeira empresa como "pai" padrão.
        // Se quiser vincular à companyId da CotacaoData depois, é só trocar aqui.
        final parentCompanyId =
            companies.first.companyId ?? companies.first.id;

        // Usa o helper que criamos para carregar tudo da empresa
        await system.ensureCompanySetupLoaded(parentCompanyId);
      }
    });
  }

  void _attachListeners() {
    for (final c in [
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
    ]) {
      c.addListener(_emitChange);
    }
  }

  @override
  void didUpdateWidget(
      covariant SectionRespostasFornecedores oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_f1NomeCtrl, d.f1Nome);
      _sync(_f1CnpjCtrl, d.f1Cnpj);
      _sync(_f1ValorCtrl, d.f1Valor);
      _sync(_f1DataCtrl, d.f1DataRecebimento);
      _sync(_f1LinkCtrl, d.f1LinkProposta);

      _sync(_f2NomeCtrl, d.f2Nome);
      _sync(_f2CnpjCtrl, d.f2Cnpj);
      _sync(_f2ValorCtrl, d.f2Valor);
      _sync(_f2DataCtrl, d.f2DataRecebimento);
      _sync(_f2LinkCtrl, d.f2LinkProposta);

      _sync(_f3NomeCtrl, d.f3Nome);
      _sync(_f3CnpjCtrl, d.f3Cnpj);
      _sync(_f3ValorCtrl, d.f3Valor);
      _sync(_f3DataCtrl, d.f3DataRecebimento);
      _sync(_f3LinkCtrl, d.f3LinkProposta);
    }
  }

  @override
  void dispose() {
    for (final c in [
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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emitChange() {
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

  @override
  Widget build(BuildContext context) {
    final nomes = [_f1NomeCtrl, _f2NomeCtrl, _f3NomeCtrl];
    final cnpjs = [_f1CnpjCtrl, _f2CnpjCtrl, _f3CnpjCtrl];
    final valores = [_f1ValorCtrl, _f2ValorCtrl, _f3ValorCtrl];
    final datas = [_f1DataCtrl, _f2DataCtrl, _f3DataCtrl];
    final links = [_f1LinkCtrl, _f2LinkCtrl, _f3LinkCtrl];

    // ========= companiesBodies disponíveis =========
    final systemState = context.watch<SetupCubit>().state;

    // Agora pegamos direto da lista plana
    final List<SetupData> bodies = systemState.companyBodies;

    final List<String> bodyLabels =
    bodies.map((e) => e.label).toList(growable: false);

    // nomes já preenchidos nos campos (p/ manter compatibilidade)
    final fornecedoresFromCtrls = [
      _f1NomeCtrl.text.trim(),
      _f2NomeCtrl.text.trim(),
      _f3NomeCtrl.text.trim(),
    ].where((t) => t.isNotEmpty);

    // União: labels do Cubit + o que já está nos campos
    final List<String> allLabels = {
      ...bodyLabels,
      ...fornecedoresFromCtrls,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Respostas dos Fornecedores'),
        const SizedBox(height: 8),
        ...List.generate(
          widget.fornCount,
              (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FornecedorCard(
              title: 'Fornecedor ${i + 1}',
              enabled: widget.isEditable,
              nomeCtrl: nomes[i],
              cnpjCtrl: cnpjs[i],
              valorCtrl: valores[i],
              dataCtrl: datas[i],
              linkCtrl: links[i],

              // Dropdown de companiesBodies
              fornecedoresLabels: allLabels,
              onAddNewEmpresa: showCreateCompanyBodyDialog,
              onChangedFornecedor: (label) {
                final val = label ?? '';
                nomes[i].text = val;

                final body = _findBodyByLabel(val);
                if (body?.cnpjCompanyContracted != null &&
                    body!.cnpjCompanyContracted!.trim().isNotEmpty) {
                  cnpjs[i].text = body.cnpjCompanyContracted!;
                }
                // listeners dos controllers disparam _emitChange()
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 8),
            Row(
              children: [
                if (widget.onRemoveOne != null &&
                    widget.isEditable &&
                    widget.fornCount > 1)
                  TextButton.icon(
                    onPressed: widget.onRemoveOne,
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Remover fornecedor'),
                  ),
                const SizedBox(width: 8),
                if (widget.onAdd != null &&
                    widget.isEditable &&
                    widget.fornCount < 3)
                  OutlinedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar fornecedor'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
