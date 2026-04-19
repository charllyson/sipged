import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/auto_complete_change.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

import 'package:sipged/_widgets/list/files/side_list_box.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';

class EmpenhoFormSection extends StatefulWidget {
  final NumberFormat currency;

  const EmpenhoFormSection({
    super.key,
    required this.currency,
  });

  @override
  State<EmpenhoFormSection> createState() => _EmpenhoFormSectionState();
}

class _EmpenhoFormSectionState extends State<EmpenhoFormSection> {
  String _s(Object? v) => (v is String ? v : v?.toString() ?? '').trim();

  late final TextEditingController _companyCtrl;
  late final TextEditingController _fonteCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _demandaCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _dateCtrl;

  int _companyNonce = 0;

  List<DfdData> _dfds = const [];
  bool _loadingDfds = false;

  @override
  void initState() {
    super.initState();

    _companyCtrl = TextEditingController();
    _fonteCtrl = TextEditingController();
    _numeroCtrl = TextEditingController();
    _demandaCtrl = TextEditingController();
    _totalCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

    final setupCubit = context.read<SetupCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setupCubit.loadCompanies();
      await _loadDfds();
    });
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _fonteCtrl.dispose();
    _numeroCtrl.dispose();
    _demandaCtrl.dispose();
    _totalCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDfds() async {
    if (_loadingDfds) return;
    setState(() => _loadingDfds = true);

    try {
      final snap =
      await FirebaseFirestore.instance.collectionGroup('objeto').limit(1500).get();

      final map = <String, DfdData>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final descricao = (data['descricaoObjeto'] ?? '').toString().trim();
        if (descricao.isEmpty) continue;

        final segments = doc.reference.path.split('/');
        String? contractId;
        for (int i = 0; i < segments.length - 1; i++) {
          if (segments[i] == 'contracts' && i + 1 < segments.length) {
            contractId = segments[i + 1];
            break;
          }
        }
        if ((contractId ?? '').trim().isEmpty) continue;

        final dfd = DfdData(
          contractId: contractId,
          descricaoObjeto: descricao,
        );

        final key = '${contractId!}__${descricao.toLowerCase()}';
        map[key] = dfd;
      }

      final list = map.values.toList()
        ..sort(
              (a, b) =>
              (a.descricaoObjeto ?? '').compareTo(b.descricaoObjeto ?? ''),
        );

      if (!mounted) return;
      setState(() => _dfds = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dfds = const []);
    } finally {
      if (mounted) {
        setState(() => _loadingDfds = false);
      }
    }
  }

  void _syncFromState(EmpenhoState s) {
    if (_companyCtrl.text != s.companyLabel) _companyCtrl.text = s.companyLabel;
    if (_fonteCtrl.text != s.fundingSourceLabel) {
      _fonteCtrl.text = s.fundingSourceLabel;
    }
    if (_numeroCtrl.text != s.numero) _numeroCtrl.text = s.numero;
    if (_demandaCtrl.text != s.demandLabel) _demandaCtrl.text = s.demandLabel;
    if (_totalCtrl.text != s.totalText) _totalCtrl.text = s.totalText;

    final dt = s.date;
    final desired = (dt == null) ? '' : SipGedFormatDates.dateToDdMMyyyy(dt);
    if (_dateCtrl.text != desired) _dateCtrl.text = desired;
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

  DfdData? _findDfdByContractId(String id) {
    final target = id.trim();
    if (target.isEmpty) return null;
    try {
      return _dfds.firstWhere((d) => (d.contractId ?? '').trim() == target);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpenhoCubit, EmpenhoState>(
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
      child: BlocBuilder<EmpenhoCubit, EmpenhoState>(
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

              final empCubit = context.read<EmpenhoCubit>();
              final formOk = empCubit.formValidated;
              final somaFatias = empCubit.somaFatias;
              final totalValue = empCubit.totalValue;

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
                      final localEmpCubit = context.read<EmpenhoCubit>();
                      final sysCubit = context.read<SetupCubit>();

                      final selectedLabel = _s(label);

                      if (selectedLabel.isEmpty) {
                        localEmpCubit.clearCompany();
                        localEmpCubit.setFundingSourceId(null);
                        localEmpCubit.setFundingSourceLabel('');
                        localEmpCubit.clearFundingSourceId();

                        if (!mounted) return;
                        setState(() => _companyNonce++);
                        return;
                      }

                      final SetupData selected = companies.firstWhere(
                            (c) => c.label == selectedLabel,
                        orElse: () => companies.first,
                      );

                      final selectedCompanyId =
                      (selected.companyId ?? selected.id).trim();

                      localEmpCubit.setCompanyId(selectedCompanyId);
                      localEmpCubit.setCompanyLabel(selected.label);

                      localEmpCubit.setFundingSourceId(null);
                      localEmpCubit.setFundingSourceLabel('');
                      localEmpCubit.clearFundingSourceId();

                      if (!mounted) return;
                      setState(() => _companyNonce++);

                      await sysCubit.ensureCompanySetupLoaded(selectedCompanyId);
                    },
                    onCreateNewItem: (label) async {
                      final sysCubit = context.read<SetupCubit>();
                      final localEmpCubit = context.read<EmpenhoCubit>();

                      final newLabel = _s(label);
                      if (newLabel.isEmpty) return;

                      final created = await sysCubit.createCompany(newLabel);
                      if (created == null) return;

                      final selectedCompanyId =
                      (created.companyId ?? created.id).trim();

                      localEmpCubit.setCompanyId(selectedCompanyId);
                      localEmpCubit.setCompanyLabel(created.label);

                      localEmpCubit.setFundingSourceId(null);
                      localEmpCubit.setFundingSourceLabel('');
                      localEmpCubit.clearFundingSourceId();

                      if (!mounted) return;
                      setState(() => _companyNonce++);

                      await sysCubit.ensureCompanySetupLoaded(selectedCompanyId);
                    },
                  ),
                  DropDownChange(
                    key: ValueKey(
                      'funding-$_companyNonce-${st.companyId ?? "none"}',
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
                      final localEmpCubit = context.read<EmpenhoCubit>();
                      final selectedLabel = _s(label);

                      if (selectedLabel.isEmpty) {
                        localEmpCubit.setFundingSourceId(null);
                        localEmpCubit.setFundingSourceLabel('');
                        localEmpCubit.clearFundingSourceId();
                        return;
                      }

                      final SetupData selected = fundingSources.firstWhere(
                            (f) => f.label == selectedLabel,
                        orElse: () => fundingSources.first,
                      );

                      localEmpCubit.setFundingSourceLabel(selected.label);
                      localEmpCubit.setFundingSourceId(
                        selected.genericId ?? selected.id,
                      );
                    },
                    onCreateNewItem: (companySelected && childrenLoadedForCompany)
                        ? (label) async {
                      final sysCubit = context.read<SetupCubit>();
                      final localEmpCubit = context.read<EmpenhoCubit>();

                      final newLabel = _s(label);
                      if (newLabel.isEmpty) return;

                      final created = await sysCubit.createFundingSource(
                        companyId,
                        newLabel,
                      );
                      if (created == null) return;

                      localEmpCubit.setFundingSourceLabel(created.label);
                      localEmpCubit.setFundingSourceId(
                        created.genericId ?? created.id,
                      );
                    }
                        : null,
                    onEditItem: (companySelected && childrenLoadedForCompany)
                        ? (oldLabel, newLabel) async {
                      final localEmpCubit = context.read<EmpenhoCubit>();

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
                        localEmpCubit.setFundingSourceLabel(updated.label);
                      }
                    }
                        : null,
                    onDeleteItem: (companySelected && childrenLoadedForCompany)
                        ? (ctx, label) async {
                      final localEmpCubit = context.read<EmpenhoCubit>();

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
                        localEmpCubit.setFundingSourceLabel('');
                        localEmpCubit.setFundingSourceId(null);
                        localEmpCubit.clearFundingSourceId();
                      }
                    }
                        : null,
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _numeroCtrl,
                    labelText: 'Número do empenho',
                    onChanged: (v) => context.read<EmpenhoCubit>().setNumero(v),
                  ),
                  DateFieldChange(
                    width: inputsWidth,
                    controller: _dateCtrl,
                    labelText: 'Data do empenho',
                    initialValue: st.date,
                    enabled: true,
                    onChanged: (dt) => context.read<EmpenhoCubit>().setDate(dt),
                  ),
                  AutoCompleteChange<DfdData>(
                    controller: _demandaCtrl,
                    label: 'Creditar em',
                    hint: _loadingDfds
                        ? 'Carregando demandas…'
                        : 'Digite para buscar',
                    enabled: !_loadingDfds && _dfds.isNotEmpty,
                    allList: _dfds,
                    initialId: (st.demandContractId ?? '').trim().isEmpty
                        ? null
                        : st.demandContractId!.trim(),
                    idOf: (d) => (d.contractId ?? '').trim(),
                    displayOf: (d) => (d.descricaoObjeto ?? '').trim(),
                    match: (d, qLower) {
                      final desc = (d.descricaoObjeto ?? '').toLowerCase();
                      return desc.contains(qLower);
                    },
                    onChanged: (id) {
                      final demandContractId = id.trim();
                      final cubit = context.read<EmpenhoCubit>();

                      if (demandContractId.isEmpty) {
                        cubit.clearDemand();
                        return;
                      }

                      final sel = _findDfdByContractId(demandContractId);
                      final label =
                      (sel?.descricaoObjeto ?? _demandaCtrl.text).trim();

                      cubit.setDemandContractId(demandContractId);
                      cubit.setDemandLabel(label);
                    },
                  ),
                  CustomTextField(
                    width: inputsWidth,
                    controller: _totalCtrl,
                    labelText: 'Valor total',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => context.read<EmpenhoCubit>().setTotalText(v),
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
                        ? () => context.read<EmpenhoCubit>().saveOrUpdate()
                        : null,
                  ),
                  const SizedBox(width: 12),
                  if (st.selected != null)
                    TextButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Limpar'),
                      onPressed: () => context.read<EmpenhoCubit>().select(null),
                    ),
                ],
              );

              final resumo = Row(
                children: [
                  Expanded(
                    child: Text(
                      'Soma das fatias: ${widget.currency.format(somaFatias)}',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Total: ${widget.currency.format(totalValue)}',
                      textAlign: TextAlign.right,
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
                title: 'Arquivos do Empenho',
                items: st.attachments,
                selectedIndex: st.selectedSideIndex,
                onAddPressed: null,
                onTap: (i) => context.read<EmpenhoCubit>().selectSideIndex(i),
                onDelete: (i) =>
                    context.read<EmpenhoCubit>().deleteAttachmentAt(i),
                onItemsChanged: (items) {
                  context.read<EmpenhoCubit>().setAttachmentsFromUi(items);
                },
                onRenamePersist: ({
                  required int index,
                  required dynamic oldItem,
                  required dynamic newItem,
                }) async {
                  final oldAtt = oldItem is Attachment ? oldItem : null;
                  final newAtt = newItem is Attachment ? newItem : null;
                  if (oldAtt == null || newAtt == null) return false;

                  return context.read<EmpenhoCubit>().persistRenameAttachment(
                    index: index,
                    oldItem: oldAtt,
                    newItem: newAtt,
                  );
                },
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
                      SizedBox(width: sideWidth, child: side),
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