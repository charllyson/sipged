import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';

import 'package:sipged/_blocs/modules/financial/loa/loa_cubit.dart';
import 'package:sipged/_blocs/modules/financial/loa/loa_state.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class BudgetFormSection extends StatefulWidget {
  final NumberFormat currency;

  const BudgetFormSection({
    super.key,
    required this.currency,
  });

  @override
  State<BudgetFormSection> createState() => _BudgetFormSectionState();
}

class _BudgetFormSectionState extends State<BudgetFormSection> {
  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
  }

  late final TextEditingController _companyCtrl;
  late final TextEditingController _fonteCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  int _fundingNonce = 0;
  bool _startupLoaded = false;

  @override
  void initState() {
    super.initState();

    _companyCtrl = TextEditingController();
    _fonteCtrl = TextEditingController();
    _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    _codeCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _startupLoaded) return;

      _startupLoaded = true;

      final tenantCubit = context.read<TenantCubit>();

      tenantCubit.ensureTenantProfileLoaded();
      tenantCubit.ensureTenantItemsLoaded();
    });
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _fonteCtrl.dispose();
    _yearCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();

    super.dispose();
  }

  void _syncFromState(LOAState state) {
    if (_companyCtrl.text != state.companyLabel) {
      _companyCtrl.text = state.companyLabel;
    }

    if (_fonteCtrl.text != state.fundingSourceLabel) {
      _fonteCtrl.text = state.fundingSourceLabel;
    }

    final desiredYear = state.year <= 0 ? '' : state.year.toString();

    if (_yearCtrl.text != desiredYear) {
      _yearCtrl.text = desiredYear;
    }

    if (_codeCtrl.text != state.budgetCode) {
      _codeCtrl.text = state.budgetCode;
    }

    if (_descCtrl.text != state.description) {
      _descCtrl.text = state.description;
    }

    if (_amountCtrl.text != state.amountText) {
      _amountCtrl.text = state.amountText;
    }
  }

  void _syncCompanyFromTenant(TenantData? tenant) {
    if (tenant == null) return;

    final companyId = (tenant.companyId ?? tenant.tenantId ?? tenant.id).trim();
    final companyLabel = (tenant.companyName ?? tenant.label).trim();

    if (companyId.isEmpty && companyLabel.isEmpty) return;

    final cubit = context.read<LOACubit>();
    final state = cubit.state;

    final needsUpdate = (state.companyId ?? '').trim() != companyId ||
        state.companyLabel.trim() != companyLabel;

    if (!needsUpdate) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      cubit.setCompanyId(companyId);
      cubit.setCompanyLabel(companyLabel);

      setState(() => _fundingNonce++);
    });
  }

  String? _findByLabel(
      List<String> list,
      String label,
      ) {
    final target = label.trim().toLowerCase();

    if (target.isEmpty) return null;

    for (final item in list) {
      if (item.trim().toLowerCase() == target) {
        return item.trim();
      }
    }

    return null;
  }

  Future<String?> _askNewLabel(
      BuildContext context, {
        required String title,
        required String initialValue,
        String labelText = 'Novo nome',
      }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: labelText,
            ),
            onSubmitted: (value) {
              Navigator.of(dialogCtx).pop(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop(controller.text.trim());
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = result?.trim();

    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed == initialValue.trim()) return null;

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LOACubit, LOAState>(
      builder: (context, budgetState) {
        _syncFromState(budgetState);

        return BlocBuilder<TenantCubit, TenantState>(
          builder: (context, tenantState) {
            final theme = Theme.of(context);
            final bool isDark = theme.brightness == Brightness.dark;

            final tenant = tenantState.tenantProfile;
            final fundingSources = tenantState.fundingSources;

            _syncCompanyFromTenant(tenant);

            final bool companyConfigured = tenant != null;

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isSmallScreen = constraints.maxWidth < 700;
                final double sideWidth =
                isSmallScreen ? constraints.maxWidth : 300.0;

                final double inputsWidth = responsiveInputWidth(
                  context: context,
                  itemsPerLine: 4,
                  reservedWidth: isSmallScreen ? 0.0 : sideWidth + 12.0,
                  spacing: 12.0,
                  margin: 12.0,
                  extraPadding: 24.0,
                  spaceBetweenReserved: 12.0,
                );

                final double minCardHeight = isSmallScreen ? 260.0 : 170.0;

                final budgetCubit = context.read<LOACubit>();
                final formOk = budgetCubit.formValidated;
                final amountValue = budgetCubit.amountValue;

                final camposWrap = Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomTextField(
                      width: inputsWidth,
                      labelText: 'Contratante',
                      controller: _companyCtrl,
                      enabled: false,
                      readOnly: true,
                      hintText: companyConfigured
                          ? null
                          : 'Configure o contratante no setup do sistema',
                    ),
                    DropDownChange(
                      showSpecialAlways: true,
                      key: ValueKey('budget-funding-$_fundingNonce'),
                      width: inputsWidth,
                      labelText: 'Fonte de recurso',
                      controller: _fonteCtrl,
                      enabled: companyConfigured,
                      tooltipMessage: !companyConfigured
                          ? 'Configure o contratante no setup do sistema'
                          : null,
                      items: fundingSources,
                      specialItemLabel: 'Adicionar fonte',
                      menuMaxHeight: 260,
                      onChanged: (label) {
                        final localBudgetCubit = context.read<LOACubit>();
                        final selectedLabel = _s(label);

                        if (selectedLabel.isEmpty) {
                          localBudgetCubit.setFundingSourceId(null);
                          localBudgetCubit.setFundingSourceLabel('');
                          localBudgetCubit.clearFundingSourceId();
                          return;
                        }

                        final selected = _findByLabel(
                          fundingSources,
                          selectedLabel,
                        );

                        if (selected == null) return;

                        localBudgetCubit.setFundingSourceLabel(selected);
                        localBudgetCubit.setFundingSourceId(selected);
                      },
                      onCreateNewItem: companyConfigured
                          ? (label) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final localBudgetCubit =
                        context.read<LOACubit>();

                        final newLabel = _s(label);

                        if (newLabel.isEmpty) return;

                        final created = await tenantCubit
                            .createFundingSource(newLabel);

                        if (!mounted || created == null) return;

                        localBudgetCubit.setFundingSourceLabel(created);
                        localBudgetCubit.setFundingSourceId(created);

                        setState(() => _fundingNonce++);
                      }
                          : null,
                      onEditItem: companyConfigured
                          ? (ctx, oldLabel) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final localBudgetCubit =
                        context.read<LOACubit>();

                        final oldL = _s(oldLabel);

                        if (oldL.isEmpty) return;

                        final target = _findByLabel(
                          fundingSources,
                          oldL,
                        );

                        if (target == null) return;

                        final newLabel = await _askNewLabel(
                          ctx,
                          title: 'Editar fonte de recurso',
                          initialValue: oldL,
                          labelText: 'Nome da fonte',
                        );

                        if (!mounted || newLabel == null) return;

                        final updated =
                        await tenantCubit.updateFundingSourceName(
                          target,
                          newLabel,
                        );

                        if (!mounted || updated == null) return;

                        if (_fonteCtrl.text.trim().toLowerCase() ==
                            oldL.toLowerCase()) {
                          _fonteCtrl.text = updated;
                          localBudgetCubit
                              .setFundingSourceLabel(updated);
                          localBudgetCubit.setFundingSourceId(updated);
                        }

                        setState(() => _fundingNonce++);
                      }
                          : null,
                      onDeleteItem: companyConfigured
                          ? (ctx, label) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final localBudgetCubit =
                        context.read<LOACubit>();

                        final lab = _s(label);

                        if (lab.isEmpty) return;

                        final target = _findByLabel(
                          fundingSources,
                          lab,
                        );

                        if (target == null) return;

                        await tenantCubit.deleteFundingSource(target);

                        if (!mounted) return;

                        if (_fonteCtrl.text.trim().toLowerCase() ==
                            lab.toLowerCase()) {
                          _fonteCtrl.clear();
                          localBudgetCubit.setFundingSourceLabel('');
                          localBudgetCubit.setFundingSourceId(null);
                          localBudgetCubit.clearFundingSourceId();
                        }

                        setState(() => _fundingNonce++);
                      }
                          : null,
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _yearCtrl,
                      labelText: 'Exercício (Ano)',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        context.read<LOACubit>().setYearText(v);
                      },
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _codeCtrl,
                      labelText: 'Código (opcional)',
                      onChanged: (v) {
                        context.read<LOACubit>().setBudgetCode(v);
                      },
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _descCtrl,
                      labelText: 'Descrição',
                      onChanged: (v) {
                        context.read<LOACubit>().setDescription(v);
                      },
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _amountCtrl,
                      labelText: 'Valor orçado',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        context.read<LOACubit>().setAmountText(v);
                      },
                    ),
                  ],
                );

                final botoes = Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(
                        budgetState.selected == null ? 'Salvar' : 'Atualizar',
                      ),
                      onPressed: formOk
                          ? () => context.read<LOACubit>().saveOrUpdate()
                          : null,
                    ),
                    const SizedBox(width: 12),
                    if (budgetState.selected != null)
                      TextButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Limpar'),
                        onPressed: () {
                          context.read<LOACubit>().select(null);
                        },
                      ),
                  ],
                );

                final resumo = Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Valor: ${widget.currency.format(amountValue)}',
                      ),
                    ),
                  ],
                );

                final corpo = Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    camposWrap,
                    const SizedBox(height: 12),
                    resumo,
                    const SizedBox(height: 12),
                    botoes,
                  ],
                );

                final side = BoxListFiles(
                  title: 'Arquivos do Orçamento',
                  items: budgetState.attachments,
                  selectedIndex: budgetState.selectedSideIndex,
                  onAddPressed: null,
                  onTap: (i) {
                    context.read<LOACubit>().selectSideIndex(i);
                  },
                  onDelete: (i) {
                    context.read<LOACubit>().deleteAttachmentAt(i);
                  },
                  enableRename: true,
                  onItemsChanged: (newItems) {
                    final list = newItems.whereType<Attachment>().toList();
                    context.read<LOACubit>().setAttachments(list);
                  },
                  onRenamePersist: null,
                  width: sideWidth,
                );

                return BasicCard(
                  isDark: isDark,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minCardHeight,
                    ),
                    child: isSmallScreen
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        side,
                        const SizedBox(height: 12),
                        corpo,
                      ],
                    )
                        : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        side,
                        const SizedBox(width: 12),
                        Expanded(child: corpo),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}