import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';

import 'package:sipged/_blocs/modules/financial/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/financial/budget/budget_state.dart';

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
  String _s(Object? v) => (v is String ? v : v?.toString() ?? '').trim();

  late final TextEditingController _companyCtrl;
  late final TextEditingController _fonteCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;

  int _companyNonce = 0;

  @override
  void initState() {
    super.initState();

    _companyCtrl = TextEditingController();
    _fonteCtrl = TextEditingController();
    _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
    _codeCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _amountCtrl = TextEditingController();

    final setupCubit = context.read<SetupCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setupCubit.loadCompanies();
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

  void _syncFromState(BudgetState s) {
    if (_companyCtrl.text != s.companyLabel) _companyCtrl.text = s.companyLabel;
    if (_fonteCtrl.text != s.fundingSourceLabel) {
      _fonteCtrl.text = s.fundingSourceLabel;
    }
    final desiredYear = s.year <= 0 ? '' : s.year.toString();
    if (_yearCtrl.text != desiredYear) _yearCtrl.text = desiredYear;
    if (_codeCtrl.text != s.budgetCode) _codeCtrl.text = s.budgetCode;
    if (_descCtrl.text != s.description) _descCtrl.text = s.description;
    if (_amountCtrl.text != s.amountText) _amountCtrl.text = s.amountText;
  }

  SetupData? _findByLabel(List<SetupData> list, String label) {
    final low = label.trim().toLowerCase();
    if (low.isEmpty) return null;
    for (final s in list) {
      final l = s.label.trim().toLowerCase();
      if (l == low) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BudgetCubit, BudgetState>(
      listenWhen: (prev, curr) =>
      (prev.companyId ?? '').trim() != (curr.companyId ?? '').trim(),
      listener: (context, st) async {
        final companyId = (st.companyId ?? '').trim();
        if (companyId.isEmpty) return;

        final setupCubit = context.read<SetupCubit>();
        await setupCubit.ensureCompanySetupLoaded(companyId);

        if (!mounted) return;
        setState(() => _companyNonce++);
      },
      child: BlocBuilder<BudgetCubit, BudgetState>(
        builder: (context, st) {
          _syncFromState(st);

          final theme = Theme.of(context);
          final bool isDark = theme.brightness == Brightness.dark;

          final setupCubit = context.watch<SetupCubit>();
          final companies = setupCubit.state.companies;

          final companyId = (st.companyId ?? '').trim();
          final bool companySelected = companyId.isNotEmpty;

          final bool childrenLoadedForCompany =
              companySelected && setupCubit.state.selectedCompanyId == companyId;

          final fundingSources = childrenLoadedForCompany
              ? setupCubit.getFundingSourcesForCompany(companyId)
              : const <SetupData>[];

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 700;
              final double sideWidth =
              isSmallScreen ? constraints.maxWidth : 300.0;

              final double inputsWidth = responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                reservedWidth: isSmallScreen ? 0.0 : (sideWidth + 12.0),
                spacing: 12.0,
                margin: 12.0,
                extraPadding: 24.0,
                spaceBetweenReserved: 12.0,
              );

              final double minCardHeight = isSmallScreen ? 260.0 : 170.0;

              final budgetCubit = context.read<BudgetCubit>();
              final formOk = budgetCubit.formValidated;
              final amountValue = budgetCubit.amountValue;

              final camposWrap = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DropDownChange(
                    width: inputsWidth,
                    labelText: 'Contratante',
                    controller: _companyCtrl,
                    items: companies.map((e) => e.label).toList(),
                    specialItemLabel: 'Adicionar contratante',
                    menuMaxHeight: 260,
                    onChanged: (label) async {
                      final localBudgetCubit = context.read<BudgetCubit>();
                      final sysCubit = context.read<SetupCubit>();

                      final selectedLabel = _s(label);

                      if (selectedLabel.isEmpty) {
                        localBudgetCubit.clearCompany();
                        localBudgetCubit.setFundingSourceId(null);
                        localBudgetCubit.setFundingSourceLabel('');
                        localBudgetCubit.clearFundingSourceId();

                        if (!mounted) return;
                        setState(() => _companyNonce++);
                        return;
                      }

                      final SetupData selected = companies.firstWhere(
                            (c) => c.label == selectedLabel,
                        orElse: () => companies.first,
                      );

                      final id = (selected.companyId ?? selected.id).trim();

                      localBudgetCubit.setCompanyId(id);
                      localBudgetCubit.setCompanyLabel(selected.label);

                      localBudgetCubit.setFundingSourceId(null);
                      localBudgetCubit.setFundingSourceLabel('');
                      localBudgetCubit.clearFundingSourceId();

                      if (!mounted) return;
                      setState(() => _companyNonce++);

                      await sysCubit.ensureCompanySetupLoaded(id);
                    },
                    onCreateNewItem: (label) async {
                      final sysCubit = context.read<SetupCubit>();
                      final localBudgetCubit = context.read<BudgetCubit>();

                      final newLabel = _s(label);
                      if (newLabel.isEmpty) return;

                      final created = await sysCubit.createCompany(newLabel);
                      if (created == null) return;

                      final id = (created.companyId ?? created.id).trim();

                      localBudgetCubit.setCompanyId(id);
                      localBudgetCubit.setCompanyLabel(created.label);

                      localBudgetCubit.setFundingSourceId(null);
                      localBudgetCubit.setFundingSourceLabel('');
                      localBudgetCubit.clearFundingSourceId();

                      if (!mounted) return;
                      setState(() => _companyNonce++);

                      await sysCubit.ensureCompanySetupLoaded(id);
                    },
                  ),
                  DropDownChange(
                    showSpecialAlways: true,
                    key: ValueKey(
                      'budget-funding-$_companyNonce-${st.companyId ?? "none"}',
                    ),
                    width: inputsWidth,
                    labelText: 'Fonte de recurso',
                    controller: _fonteCtrl,
                    enabled: companySelected && childrenLoadedForCompany,
                    tooltipMessage: !companySelected
                        ? 'Selecione o contratante'
                        : (!childrenLoadedForCompany ? 'Carregando fontes…' : null),
                    items: fundingSources.map((e) => e.label).toList(),
                    specialItemLabel: 'Adicionar fonte',
                    menuMaxHeight: 260,
                    onChanged: (label) {
                      final localBudgetCubit = context.read<BudgetCubit>();
                      final selectedLabel = _s(label);

                      if (selectedLabel.isEmpty) {
                        localBudgetCubit.setFundingSourceId(null);
                        localBudgetCubit.setFundingSourceLabel('');
                        localBudgetCubit.clearFundingSourceId();
                        return;
                      }

                      final SetupData selected = fundingSources.firstWhere(
                            (f) => f.label == selectedLabel,
                        orElse: () => fundingSources.first,
                      );

                      localBudgetCubit.setFundingSourceLabel(selected.label);
                      localBudgetCubit.setFundingSourceId(
                        (selected.genericId ?? selected.id).trim(),
                      );
                    },
                    onCreateNewItem: (companySelected && childrenLoadedForCompany)
                        ? (label) async {
                      final sysCubit = context.read<SetupCubit>();
                      final localBudgetCubit =
                      context.read<BudgetCubit>();

                      final newLabel = _s(label);
                      if (newLabel.isEmpty) return;

                      final created = await sysCubit.createFundingSource(
                        companyId,
                        newLabel,
                      );
                      if (created == null) return;

                      localBudgetCubit
                          .setFundingSourceLabel(created.label);
                      localBudgetCubit.setFundingSourceId(
                        (created.genericId ?? created.id).trim(),
                      );
                    }
                        : null,
                    onEditItem: (companySelected && childrenLoadedForCompany)
                        ? (oldLabel, newLabel) async {
                      final localBudgetCubit =
                      context.read<BudgetCubit>();

                      final oldL = _s(oldLabel);
                      final newL = _s(newLabel);
                      if (oldL.isEmpty || newL.isEmpty) return;

                      final target = _findByLabel(fundingSources, oldL);
                      if (target == null) return;

                      final sourceId =
                      (target.genericId ?? target.id).trim();
                      if (sourceId.isEmpty) return;

                      final updated =
                      await setupCubit.updateFundingSourceName(
                        companyId,
                        sourceId,
                        newL,
                      );
                      if (updated == null) return;

                      if (_fonteCtrl.text.trim().toLowerCase() ==
                          oldL.toLowerCase()) {
                        _fonteCtrl.text = updated.label;
                        localBudgetCubit
                            .setFundingSourceLabel(updated.label);
                      }
                    }
                        : null,
                    onDeleteItem: (companySelected && childrenLoadedForCompany)
                        ? (ctx, label) async {
                      final localBudgetCubit =
                      context.read<BudgetCubit>();

                      final lab = _s(label);
                      if (lab.isEmpty) return;

                      final target = _findByLabel(fundingSources, lab);
                      if (target == null) return;

                      final sourceId =
                      (target.genericId ?? target.id).trim();
                      if (sourceId.isEmpty) return;

                      await setupCubit.deleteFundingSource(
                        companyId,
                        sourceId,
                      );

                      if (_fonteCtrl.text.trim().toLowerCase() ==
                          lab.toLowerCase()) {
                        _fonteCtrl.clear();
                        localBudgetCubit.setFundingSourceLabel('');
                        localBudgetCubit.setFundingSourceId(null);
                        localBudgetCubit.clearFundingSourceId();
                      }
                    }
                        : null,
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _yearCtrl,
                    labelText: 'Exercício (Ano)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => context.read<BudgetCubit>().setYearText(v),
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _codeCtrl,
                    labelText: 'Código (opcional)',
                    onChanged: (v) =>
                        context.read<BudgetCubit>().setBudgetCode(v),
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _descCtrl,
                    labelText: 'Descrição',
                    onChanged: (v) =>
                        context.read<BudgetCubit>().setDescription(v),
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _amountCtrl,
                    labelText: 'Valor orçado',
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        context.read<BudgetCubit>().setAmountText(v),
                  ),
                ],
              );

              final botoes = Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(st.selected == null ? 'Salvar' : 'Atualizar'),
                    onPressed: formOk
                        ? () => context.read<BudgetCubit>().saveOrUpdate()
                        : null,
                  ),
                  const SizedBox(width: 12),
                  if (st.selected != null)
                    TextButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Limpar'),
                      onPressed: () => context.read<BudgetCubit>().select(null),
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

              final side = SideListBox(
                title: 'Arquivos do Orçamento',
                items: st.attachments,
                selectedIndex: st.selectedSideIndex,
                onAddPressed: null,
                onTap: (i) => context.read<BudgetCubit>().selectSideIndex(i),
                onDelete: (i) =>
                    context.read<BudgetCubit>().deleteAttachmentAt(i),
                enableRename: true,
                onItemsChanged: (newItems) {
                  final list = newItems.whereType<Attachment>().toList();
                  context.read<BudgetCubit>().setAttachments(list);
                },
                onRenamePersist: null,
                width: sideWidth,
              );

              return BasicCard(
                isDark: isDark,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minCardHeight),
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
                      const SizedBox.shrink(),
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
      ),
    );
  }
}