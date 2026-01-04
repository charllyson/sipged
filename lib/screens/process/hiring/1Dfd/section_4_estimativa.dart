import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionEstimativa extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionEstimativa({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionEstimativa> createState() => _SectionEstimativaState();
}

class _SectionEstimativaState extends State<SectionEstimativa>
    with FormValidationMixin {
  // controllers
  late final TextEditingController _fonteRecursoCtrl;
  late final TextEditingController _programaTrabalhoCtrl;
  late final TextEditingController _ptresCtrl;
  late final TextEditingController _naturezaDespesaCtrl;
  late final TextEditingController _estimativaValorCtrl;
  late final TextEditingController _metodologiaEstimativaCtrl;

  String? _companyId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _fonteRecursoCtrl = TextEditingController(text: d.fonteRecurso ?? '');
    _programaTrabalhoCtrl = TextEditingController(text: d.programaTrabalho ?? '');
    _ptresCtrl = TextEditingController(text: d.ptres ?? '');
    _naturezaDespesaCtrl = TextEditingController(text: d.naturezaDespesa ?? '');
    _estimativaValorCtrl = TextEditingController(
      text: d.estimativaValor != null ? _formatDouble(d.estimativaValor!) : '',
    );
    _metodologiaEstimativaCtrl =
        TextEditingController(text: d.metodologiaEstimativa ?? '');

    _companyId = d.companyId;

    _resolveCompanyIdFromData();
  }

  @override
  void didUpdateWidget(covariant SectionEstimativa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      // Campos simples de texto
      final fonte = d.fonteRecurso ?? '';
      final programa = d.programaTrabalho ?? '';
      final ptres = d.ptres ?? '';
      final natureza = d.naturezaDespesa ?? '';
      final metod = d.metodologiaEstimativa ?? '';

      if (_fonteRecursoCtrl.text != fonte) {
        _fonteRecursoCtrl.text = fonte;
      }
      if (_programaTrabalhoCtrl.text != programa) {
        _programaTrabalhoCtrl.text = programa;
      }
      if (_ptresCtrl.text != ptres) {
        _ptresCtrl.text = ptres;
      }
      if (_naturezaDespesaCtrl.text != natureza) {
        _naturezaDespesaCtrl.text = natureza;
      }
      if (_metodologiaEstimativaCtrl.text != metod) {
        _metodologiaEstimativaCtrl.text = metod;
      }

      // 🔥 Campo numérico com cuidado para não sobrescrever enquanto digita
      final estimFromData = d.estimativaValor;
      if (estimFromData == null) {
        // Se o dado externo ficou null, só limpa se ainda tiver algo
        if (_estimativaValorCtrl.text.isNotEmpty) {
          _estimativaValorCtrl.clear();
        }
      } else {
        final currentParsed = _parseDouble(_estimativaValorCtrl.text);
        final newFormatted = _formatDouble(estimFromData);

        // Só muda o texto se o valor numérico atual for diferente
        // do valor recebido de fora. Se for igual, significa que
        // foi a própria digitação que acabou de atualizar o dado.
        if (currentParsed != estimFromData &&
            _estimativaValorCtrl.text != newFormatted) {
          _estimativaValorCtrl.text = newFormatted;
        }
      }

      // Company / setup
      if (oldWidget.data.companyId != widget.data.companyId) {
        _companyId = widget.data.companyId;
        if (_companyId != null && _companyId!.isNotEmpty) {
          final systemCubit = context.read<SetupCubit>();
          systemCubit.ensureCompanySetupLoaded(_companyId!);
        }
      }

      if (oldWidget.data.orgaoDemandante != widget.data.orgaoDemandante) {
        _resolveCompanyIdFromData();
      }
    }
  }

  @override
  void dispose() {
    _fonteRecursoCtrl.dispose();
    _programaTrabalhoCtrl.dispose();
    _ptresCtrl.dispose();
    _naturezaDespesaCtrl.dispose();
    _estimativaValorCtrl.dispose();
    _metodologiaEstimativaCtrl.dispose();
    super.dispose();
  }

  String _formatDouble(double value) {
    // "1234.56" -> "1234,56"
    final s = value.toStringAsFixed(2);
    return s.replaceAll('.', ',');
  }

  double? _parseDouble(String text) {
    final s = text.trim();
    if (s.isEmpty) return null;
    final normalized = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      fonteRecurso: _fonteRecursoCtrl.text,
      programaTrabalho: _programaTrabalhoCtrl.text,
      ptres: _ptresCtrl.text,
      naturezaDespesa: _naturezaDespesaCtrl.text,
      estimativaValor: _parseDouble(_estimativaValorCtrl.text),
      metodologiaEstimativa: _metodologiaEstimativaCtrl.text,
      companyId: _companyId ?? widget.data.companyId,
    );
    widget.onChanged(updated);
  }

  Future<void> _resolveCompanyIdFromData() async {
    if (!mounted) return;
    if (_companyId != null && _companyId!.isNotEmpty) {
      final systemCubit = context.read<SetupCubit>();
      systemCubit.ensureCompanySetupLoaded(_companyId!);
      return;
    }

    final label = (widget.data.orgaoDemandante ?? '').trim();
    if (label.isEmpty) return;

    final systemCubit = context.read<SetupCubit>();
    if (systemCubit.state.companies.isEmpty) {
      await systemCubit.loadCompanies();
    }

    final id = systemCubit.findCompanyIdByLabel(label);
    if (!mounted || id == null) return;

    setState(() {
      _companyId = id;
    });

    systemCubit.ensureCompanySetupLoaded(id);
  }

  @override
  Widget build(BuildContext context) {
    final systemCubit = context.read<SetupCubit>();
    context.watch<SetupCubit>(); // rebuild

    if (_companyId != null && _companyId!.isNotEmpty) {
      systemCubit.ensureCompanySetupLoaded(_companyId!);
    }

    final List<SetupData> fundingSources =
    systemCubit.getFundingSourcesForCompany(_companyId);
    final List<SetupData> programs =
    systemCubit.getProgramsForCompany(_companyId);
    final List<SetupData> expenseNatures =
    systemCubit.getExpenseNaturesForCompany(_companyId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Estimativa Orçamentária (preliminar)'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Fonte de recurso
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'funding-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Fonte de recurso',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _fonteRecursoCtrl,
                    items: fundingSources.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar fonte de recurso',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      final text = value ?? '';
                      if (_fonteRecursoCtrl.text != text) {
                        _fonteRecursoCtrl.text = text;
                      }
                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem:
                    (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created =
                      await systemCubit.createFundingSource(
                        _companyId!,
                        label,
                      );
                      if (created != null) {
                        _fonteRecursoCtrl.text = created.label;
                        _emitChange();
                        setState(() {});
                      }
                    },

                    // editar fonte de recurso
                    onEditItem:
                    (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list =
                      systemCubit.getFundingSourcesForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (f) => f.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final updated = await systemCubit
                          .updateFundingSourceName(
                        _companyId!,
                        target.id,
                        newLabel,
                      );

                      if (updated != null &&
                          _fonteRecursoCtrl.text == oldLabel) {
                        setState(() {
                          _fonteRecursoCtrl.text = updated.label;
                        });
                        _emitChange();
                      }
                    }
                        : null,

                    // deletar fonte de recurso
                    onDeleteItem:
                    (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list =
                      systemCubit.getFundingSourcesForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (f) => f.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await systemCubit.deleteFundingSource(
                        _companyId!,
                        target.id,
                      );

                      if (_fonteRecursoCtrl.text == label) {
                        setState(() {
                          _fonteRecursoCtrl.clear();
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                // Programa de trabalho / Ação
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'programs-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Programa de trabalho / Ação',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _programaTrabalhoCtrl,
                    items: programs.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar programa/ação',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      final text = value ?? '';
                      if (_programaTrabalhoCtrl.text != text) {
                        _programaTrabalhoCtrl.text = text;
                      }
                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem:
                    (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created =
                      await systemCubit.createProgram(
                        _companyId!,
                        label,
                      );
                      if (created != null) {
                        _programaTrabalhoCtrl.text = created.label;
                        _emitChange();
                        setState(() {});
                      }
                    },

                    // editar programa
                    onEditItem:
                    (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list =
                      systemCubit.getProgramsForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (p) => p.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final updated =
                      await systemCubit.updateProgramName(
                        _companyId!,
                        target.id,
                        newLabel,
                      );

                      if (updated != null &&
                          _programaTrabalhoCtrl.text == oldLabel) {
                        setState(() {
                          _programaTrabalhoCtrl.text = updated.label;
                        });
                        _emitChange();
                      }
                    }
                        : null,

                    // deletar programa
                    onDeleteItem:
                    (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list =
                      systemCubit.getProgramsForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (p) => p.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await systemCubit.deleteProgram(
                        _companyId!,
                        target.id,
                      );

                      if (_programaTrabalhoCtrl.text == label) {
                        setState(() {
                          _programaTrabalhoCtrl.clear();
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                // PTRES
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _ptresCtrl,
                    enabled: widget.isEditable,
                    labelText: 'PTRES (opcional)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Natureza da despesa (ND)
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'expense-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Natureza da despesa (ND)',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _naturezaDespesaCtrl,
                    items: expenseNatures.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar ND',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      final text = value ?? '';
                      if (_naturezaDespesaCtrl.text != text) {
                        _naturezaDespesaCtrl.text = text;
                      }
                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem:
                    (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created =
                      await systemCubit.createExpenseNature(
                        _companyId!,
                        label,
                      );
                      if (created != null) {
                        _naturezaDespesaCtrl.text = created.label;
                        _emitChange();
                        setState(() {});
                      }
                    },

                    // editar ND
                    onEditItem:
                    (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list =
                      systemCubit.getExpenseNaturesForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (n) => n.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final updated =
                      await systemCubit.updateExpenseNatureName(
                        _companyId!,
                        target.id,
                        newLabel,
                      );

                      if (updated != null &&
                          _naturezaDespesaCtrl.text == oldLabel) {
                        setState(() {
                          _naturezaDespesaCtrl.text = updated.label;
                        });
                        _emitChange();
                      }
                    }
                        : null,

                    // deletar ND
                    onDeleteItem:
                    (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list =
                      systemCubit.getExpenseNaturesForCompany(
                          _companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (n) => n.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await systemCubit.deleteExpenseNature(
                        _companyId!,
                        target.id,
                      );

                      if (_naturezaDespesaCtrl.text == label) {
                        setState(() {
                          _naturezaDespesaCtrl.clear();
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                // Estimativa de valor
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _estimativaValorCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Estimativa de valor (R\$)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Metodologia da estimativa
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _metodologiaEstimativaCtrl,
                    enabled: widget.isEditable,
                    labelText:
                    'Metodologia da estimativa (ex.: SINAPI, DER, etc.)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
