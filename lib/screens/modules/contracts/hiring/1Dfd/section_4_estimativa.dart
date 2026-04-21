import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

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
    with SipGedValidation {
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

    context.read<SetupCubit>().loadSystemSetup();
  }

  @override
  void didUpdateWidget(covariant SectionEstimativa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    void sync(TextEditingController c, String v) {
      if (c.text != v) c.text = v;
    }

    sync(_fonteRecursoCtrl, d.fonteRecurso ?? '');
    sync(_programaTrabalhoCtrl, d.programaTrabalho ?? '');
    sync(_ptresCtrl, d.ptres ?? '');
    sync(_naturezaDespesaCtrl, d.naturezaDespesa ?? '');
    sync(_metodologiaEstimativaCtrl, d.metodologiaEstimativa ?? '');

    final estimFromData = d.estimativaValor;
    if (estimFromData == null) {
      if (_estimativaValorCtrl.text.isNotEmpty) _estimativaValorCtrl.clear();
    } else {
      final currentParsed = _parseDouble(_estimativaValorCtrl.text);
      final newFormatted = _formatDouble(estimFromData);
      if (currentParsed != estimFromData &&
          _estimativaValorCtrl.text != newFormatted) {
        _estimativaValorCtrl.text = newFormatted;
      }
    }

    if (oldWidget.data.companyId != d.companyId) {
      _companyId = d.companyId;
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

  void _syncCompanyFromSetup(SetupData? company) {
    if (company == null) return;

    final newCompanyId = (company.companyId ?? company.id).trim();
    if (_companyId == newCompanyId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _companyId = newCompanyId;
      });
      _emitChange();
    });
  }

  String _formatDouble(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

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

  @override
  Widget build(BuildContext context) {
    final systemCubit = context.read<SetupCubit>();
    final setupState = context.watch<SetupCubit>().state;
    final SetupData? company = setupState.companyProfile;

    _syncCompanyFromSetup(company);

    final bool hasCompanyConfigured = company != null;

    final List<SetupData> fundingSources = systemCubit.getFundingSources();
    final List<SetupData> programs = systemCubit.getPrograms();
    final List<SetupData> expenseNatures = systemCubit.getExpenseNatures();

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
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    key: ValueKey('funding-${_companyId ?? "none"}'),
                    width: w3,
                    labelText: 'Fonte de recurso',
                    tooltipMessage: !hasCompanyConfigured
                        ? 'Configure o contratante no setup do sistema'
                        : null,
                    controller: _fonteRecursoCtrl,
                    items: fundingSources.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasCompanyConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar fonte de recurso',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      _fonteRecursoCtrl.text = value ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    key: ValueKey('programs-${_companyId ?? "none"}'),
                    width: w3,
                    labelText: 'Programa de trabalho / Ação',
                    tooltipMessage: !hasCompanyConfigured
                        ? 'Configure o contratante no setup do sistema'
                        : null,
                    controller: _programaTrabalhoCtrl,
                    items: programs.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasCompanyConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar programa/ação',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      _programaTrabalhoCtrl.text = value ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _ptresCtrl,
                    enabled: widget.isEditable,
                    labelText: 'PTRES (opcional)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    key: ValueKey('expense-${_companyId ?? "none"}'),
                    width: w3,
                    labelText: 'Natureza da despesa (ND)',
                    tooltipMessage: !hasCompanyConfigured
                        ? 'Configure o contratante no setup do sistema'
                        : null,
                    controller: _naturezaDespesaCtrl,
                    items: expenseNatures.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasCompanyConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar ND',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      _naturezaDespesaCtrl.text = value ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),
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