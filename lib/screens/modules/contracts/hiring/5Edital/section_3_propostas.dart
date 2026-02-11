// lib/screens/modules/contracts/hiring/5Edital/section_3_propostas.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/modules/contracts/hiring/5Edital/edital_data.dart';
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_widgets/windows/company_body_dialog.dart';

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

  _PropostaRowControllers.fromMap(Map<String, dynamic> m) {
    licitanteCtrl.text = (m['licitante'] ?? '').toString();
    cnpjCtrl.text = (m['cnpj'] ?? '').toString();
    valorCtrl.text = (m['valor'] ?? '').toString();
    statusCtrl.text = (m['status'] ?? '').toString();
    motivoDesclassCtrl.text = (m['motivoDesclass'] ?? '').toString();
    linkCtrl.text = (m['link'] ?? '').toString();
  }

  Map<String, dynamic> toMap() => {
    'licitante': licitanteCtrl.text,
    'cnpj': cnpjCtrl.text,
    'valor': valorCtrl.text,
    'status': statusCtrl.text,
    'motivoDesclass': motivoDesclassCtrl.text,
    'link': linkCtrl.text,
  };

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
    _rebuildFromData(widget.data);

    // Garante que as companies + companiesBodies foram carregadas
    Future.microtask(() async {
      final system = context.read<SetupCubit>();

      // carrega lista de companies se ainda não tiver
      if (system.state.companies.isEmpty) {
        await system.loadCompanies();
      }

      final companies = system.state.companies;
      if (companies.isNotEmpty) {
        // usa a primeira company como "pai" padrão
        final parentCompanyId =
            companies.first.companyId ?? companies.first.id;

        // carrega todo o setup (inclui companyBodies) para essa empresa
        await system.ensureCompanySetupLoaded(parentCompanyId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SectionPropostas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.propostasItems != widget.data.propostasItems ||
        oldWidget.data.vencedor != widget.data.vencedor ||
        oldWidget.data.highlightWinner != widget.data.highlightWinner) {
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
    _rows = data.propostasItems
        .map((m) => _PropostaRowControllers.fromMap(m))
        .toList();
    setState(() {});
  }

  void _emitChange() {
    final updatedItems = _rows.map((r) => r.toMap()).toList();
    final updated = widget.data.copyWith(propostasItems: updatedItems);
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
    final r = _rows.removeAt(index);
    r.dispose();
    setState(() {});
    _emitChange();
  }

  /// Limpa o vencedor (mantém as propostas, só tira o destaque/fields)
  void _clearWinner() {
    final updated = widget.data.copyWith(
      vencedor: '',
      vencedorCnpj: '',
      valorVencedor: '',
      highlightWinner: false,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final cData = widget.data;
    final isEditable = widget.isEditable;

    final hasWinner =
        cData.vencedor.isNotEmpty && cData.highlightWinner == true;

    final winnerBg = Colors.green.shade50;
    final winnerBorder = Colors.green.shade600;

    // Lista de companiesBodies do SetupCubit (já da empresa selecionada)
    final systemState = context.watch<SetupCubit>().state;
    final List<SetupData> bodies = systemState.companyBodies;

    // Labels vindos do Cubit
    final List<String> bodyLabels =
    bodies.map((e) => e.label).toList(growable: false);

    // Labels já usados nas propostas (garante compatibilidade com dados antigos)
    final Iterable<String> labelsFromRows = _rows
        .map((r) => r.licitanteCtrl.text.trim())
        .where((t) => t.isNotEmpty);

    // União: Cubit + o que já está nas linhas
    final List<String> allLabels = {
      ...bodyLabels,
      ...labelsFromRows,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    SetupData? findBodyByLabel(String label) {
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
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

            // Cards de propostas
            ...List.generate(_rows.length, (i) {
              final p = _rows[i];

              final isWinner =
                  hasWinner && cData.vencedor == p.licitanteCtrl.text;

              final statusText = p.statusCtrl.text.trim();
              final isClassificada =
                  statusText.toLowerCase() == 'classificada';

              final chipBg =
              isClassificada ? Colors.blue.shade50 : Colors.red.shade50;
              final chipFg =
              isClassificada ? Colors.blue.shade700 : Colors.red.shade700;

              final cardBg = isWinner ? winnerBg : Colors.grey.shade100;
              final cardBorder = isWinner ? winnerBorder : Colors.grey;

              // Regra: não pode remover a ÚNICA proposta se ela for vencedora
              final bool canRemoveCard =
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
                      color: Colors.green.withOpacity(0.18),
                    ),
                  ]
                      : const [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha de cabeçalho do card
                    Row(
                      children: [
                        Text(
                          'Proposta ${i + 1}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
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

                        // 🏆 Vencedor
                        if (isWinner) ...[
                          const SizedBox(width: 8),
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
                        ],

                        const Spacer(),

                        if (isEditable) ...[
                          if (!hasWinner)
                            TextButton.icon(
                              onPressed: widget.onDefinirVencedorEIr == null
                                  ? null
                                  : () => widget.onDefinirVencedorEIr!(i),
                              icon: const Icon(
                                Icons.emoji_events_outlined,
                                size: 18,
                              ),
                              label: const Text('Definir vencedor'),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: canRemoveCard
                                ? 'Remover proposta'
                                : 'Não é possível remover a única proposta vencedora',
                            onPressed: canRemoveCard
                                ? () => _removeProposta(i)
                                : null,
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Campos da proposta
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // LICITANTE como dropdown (companiesBodies)
                        SizedBox(
                          width: w4,
                          child: DropDownButtonChange(
                            controller: p.licitanteCtrl,
                            labelText: 'Licitante',
                            enabled: isEditable,
                            items: allLabels,
                            showSpecialAlways: true,
                            specialItemLabel: 'Adicionar empresa',
                            onChanged: (label) {
                              final val = label ?? '';
                              p.licitanteCtrl.text = val;

                              final body = findBodyByLabel(val);
                              if (body?.cnpjCompanyContracted != null &&
                                  body!.cnpjCompanyContracted!
                                      .trim()
                                      .isNotEmpty) {
                                p.cnpjCtrl.text = body.cnpjCompanyContracted!;
                              }

                              _emitChange();
                            },
                            // fluxo completo de criação
                            onAddNewItem: showCreateCompanyBodyDialog,
                          ),
                        ),

                        SizedBox(
                          width: w4,
                          child: CustomTextField(
                            controller: p.cnpjCtrl,
                            labelText: 'CNPJ',
                            enabled: false, // travado para edição
                            readOnly: true,
                          ),
                        ),
                        SizedBox(
                          width: w4,
                          child: CustomTextField(
                            controller: p.valorCtrl,
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
                          child: DropDownButtonChange(
                            enabled: isEditable,
                            labelText: 'Status',
                            controller: p.statusCtrl,
                            items: HiringData.statusProposta,
                            onChanged: (v) {
                              p.statusCtrl.text = v ?? '';
                              _emitChange();
                            },
                          ),
                        ),

                        SizedBox(
                          width: w1,
                          child: CustomTextField(
                            controller: p.motivoDesclassCtrl,
                            labelText: 'Motivo da desclassificação',
                            enabled: isEditable,
                            maxLines: 2,
                            onChanged: (_) => _emitChange(),
                          ),
                        ),

                        SizedBox(
                          width: w1,
                          child: CustomTextField(
                            controller: p.linkCtrl,
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
