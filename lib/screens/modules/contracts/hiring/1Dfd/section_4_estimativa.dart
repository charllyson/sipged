import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';

import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
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

  String? _tenantId;

  int _fundingNonce = 0;
  int _programsNonce = 0;
  int _expenseNonce = 0;

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _fonteRecursoCtrl = TextEditingController(
      text: d.fonteRecurso ?? '',
    );

    _programaTrabalhoCtrl = TextEditingController(
      text: d.programaTrabalho ?? '',
    );

    _ptresCtrl = TextEditingController(
      text: d.ptres ?? '',
    );

    _naturezaDespesaCtrl = TextEditingController(
      text: d.naturezaDespesa ?? '',
    );

    _estimativaValorCtrl = TextEditingController(
      text: d.estimativaValor != null ? _formatDouble(d.estimativaValor!) : '',
    );

    _metodologiaEstimativaCtrl = TextEditingController(
      text: d.metodologiaEstimativa ?? '',
    );

    _tenantId = _normalizeId(d.companyId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<TenantCubit>().ensureTenantProfileLoaded();
      context.read<TenantCubit>().ensureTenantItemsLoaded();
    });
  }

  @override
  void didUpdateWidget(covariant SectionEstimativa oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _syncControllerText(_fonteRecursoCtrl, d.fonteRecurso ?? '');
    _syncControllerText(_programaTrabalhoCtrl, d.programaTrabalho ?? '');
    _syncControllerText(_ptresCtrl, d.ptres ?? '');
    _syncControllerText(_naturezaDespesaCtrl, d.naturezaDespesa ?? '');
    _syncControllerText(
      _metodologiaEstimativaCtrl,
      d.metodologiaEstimativa ?? '',
    );

    final estimFromData = d.estimativaValor;

    if (estimFromData == null) {
      if (_estimativaValorCtrl.text.isNotEmpty) {
        _estimativaValorCtrl.clear();
      }
    } else {
      final currentParsed = _parseDouble(_estimativaValorCtrl.text);
      final newFormatted = _formatDouble(estimFromData);

      if (currentParsed != estimFromData &&
          _estimativaValorCtrl.text != newFormatted) {
        _estimativaValorCtrl.text = newFormatted;
      }
    }

    final newTenantId = _normalizeId(d.companyId);

    if (_tenantId != newTenantId) {
      _tenantId = newTenantId;
      _fundingNonce++;
      _programsNonce++;
      _expenseNonce++;
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

  String? _normalizeId(String? value) {
    final normalized = (value ?? '').trim();

    return normalized.isEmpty ? null : normalized;
  }

  void _syncControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;

    controller.text = value;
  }

  void _syncTenantFromProfile(TenantData? tenant) {
    if (tenant == null) return;

    final newTenantId = _normalizeId(tenant.tenantId ?? tenant.id);

    if (newTenantId == null) return;
    if (_tenantId == newTenantId) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _tenantId = newTenantId;
        _fundingNonce++;
        _programsNonce++;
        _expenseNonce++;
      });

      _emitChange();
    });
  }

  Future<String?> _askNewLabel(
      BuildContext dialogContext, {
        required String title,
        required String initialValue,
        String labelText = 'Novo nome',
      }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelText,
            ),
            onSubmitted: (value) {
              Navigator.of(ctx).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = result?.trim() ?? '';

    if (trimmed.isEmpty || trimmed == initialValue.trim()) {
      return null;
    }

    return trimmed;
  }

  String _formatDouble(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _parseDouble(String text) {
    final normalized = text.trim();

    if (normalized.isEmpty) return null;

    final value = normalized.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(value);
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      fonteRecurso: _fonteRecursoCtrl.text,
      programaTrabalho: _programaTrabalhoCtrl.text,
      ptres: _ptresCtrl.text,
      naturezaDespesa: _naturezaDespesaCtrl.text,
      estimativaValor: _parseDouble(_estimativaValorCtrl.text),
      metodologiaEstimativa: _metodologiaEstimativaCtrl.text,

      // Mantém compatibilidade com DfdData atual.
      // O campo ainda se chama companyId, mas agora recebe o tenantId.
      companyId: _tenantId ?? widget.data.companyId,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tenantState = context.watch<TenantCubit>().state;
    final tenantCubit = context.read<TenantCubit>();

    final TenantData? tenant = tenantState.tenantProfile;

    _syncTenantFromProfile(tenant);

    final bool hasTenantConfigured = tenant != null;

    final List<TenantItemData> fundingSources = tenantState.fundingSources;
    final List<TenantItemData> programs = tenantState.programs;
    final List<TenantItemData> expenseNatures = tenantState.expenseNatures;

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
                    key: ValueKey(
                      'tenant-funding-$_fundingNonce-${_tenantId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Fonte de recurso',
                    tooltipMessage: !hasTenantConfigured
                        ? 'Configure o contratante no tenant'
                        : null,
                    controller: _fonteRecursoCtrl,
                    items: fundingSources.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar fonte de recurso',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      _fonteRecursoCtrl.text = value ?? '';

                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final created =
                      await tenantCubit.createFundingSource(label);

                      if (!mounted || created == null) return;

                      _fonteRecursoCtrl.text = created.label;

                      _emitChange();
                      setState(() {});
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, oldLabel) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .fundingSources;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final newLabel = await _askNewLabel(
                        ctx,
                        title: 'Editar fonte de recurso',
                        initialValue: oldLabel,
                        labelText: 'Nome da fonte',
                      );

                      if (newLabel == null) return;

                      final updated =
                      await tenantCubit.updateFundingSourceName(
                        target.id,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      if (_fonteRecursoCtrl.text == oldLabel) {
                        _fonteRecursoCtrl.text = updated.label;

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .fundingSources;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await tenantCubit.deleteFundingSource(target.id);

                      if (!mounted) return;

                      if (_fonteRecursoCtrl.text == label) {
                        _fonteRecursoCtrl.clear();

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownChange(
                    key: ValueKey(
                      'tenant-programs-$_programsNonce-${_tenantId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Programa de trabalho / Ação',
                    tooltipMessage: !hasTenantConfigured
                        ? 'Configure o contratante no tenant'
                        : null,
                    controller: _programaTrabalhoCtrl,
                    items: programs.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar programa/ação',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      _programaTrabalhoCtrl.text = value ?? '';

                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final created = await tenantCubit.createProgram(
                        label,
                      );

                      if (!mounted || created == null) return;

                      _programaTrabalhoCtrl.text = created.label;

                      _emitChange();
                      setState(() {});
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, oldLabel) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .programs;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final newLabel = await _askNewLabel(
                        ctx,
                        title: 'Editar programa',
                        initialValue: oldLabel,
                        labelText: 'Nome do programa',
                      );

                      if (newLabel == null) return;

                      final updated = await tenantCubit.updateProgramName(
                        target.id,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      if (_programaTrabalhoCtrl.text == oldLabel) {
                        _programaTrabalhoCtrl.text = updated.label;

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .programs;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await tenantCubit.deleteProgram(target.id);

                      if (!mounted) return;

                      if (_programaTrabalhoCtrl.text == label) {
                        _programaTrabalhoCtrl.clear();

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
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
                    key: ValueKey(
                      'tenant-expense-$_expenseNonce-${_tenantId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Natureza da despesa (ND)',
                    tooltipMessage: !hasTenantConfigured
                        ? 'Configure o contratante no tenant'
                        : null,
                    controller: _naturezaDespesaCtrl,
                    items: expenseNatures.map((e) => e.label).toList(),
                    enabled: widget.isEditable && hasTenantConfigured,
                    validator: null,
                    specialItemLabel: 'Adicionar ND',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      if (!widget.isEditable) return;

                      _naturezaDespesaCtrl.text = value ?? '';

                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem: !widget.isEditable || !hasTenantConfigured
                        ? null
                        : (label) async {
                      final created =
                      await tenantCubit.createExpenseNature(label);

                      if (!mounted || created == null) return;

                      _naturezaDespesaCtrl.text = created.label;

                      _emitChange();
                      setState(() {});
                    },
                    onEditItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, oldLabel) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .expenseNatures;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final newLabel = await _askNewLabel(
                        ctx,
                        title: 'Editar natureza da despesa',
                        initialValue: oldLabel,
                        labelText: 'Nome da natureza da despesa',
                      );

                      if (newLabel == null) return;

                      final updated =
                      await tenantCubit.updateExpenseNatureName(
                        target.id,
                        newLabel,
                      );

                      if (!mounted || updated == null) return;

                      if (_naturezaDespesaCtrl.text == oldLabel) {
                        _naturezaDespesaCtrl.text = updated.label;

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
                    onDeleteItem: widget.isEditable && hasTenantConfigured
                        ? (ctx, label) async {
                      final list = context
                          .read<TenantCubit>()
                          .state
                          .expenseNatures;

                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (item) => item.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await tenantCubit.deleteExpenseNature(target.id);

                      if (!mounted) return;

                      if (_naturezaDespesaCtrl.text == label) {
                        _naturezaDespesaCtrl.clear();

                        _emitChange();
                        setState(() {});
                      }
                    }
                        : null,
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