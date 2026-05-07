import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_blocs/system/tenant/tenant_data.dart';
import 'package:sipged/_blocs/system/tenant/tenant_state.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/auto_complete_change.dart';
import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'package:sipged/_blocs/modules/financial/empenhos/empenho_cubit.dart';
import 'package:sipged/_blocs/modules/financial/empenhos/empenho_state.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_dates.dart';

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
  late final TextEditingController _companyCtrl;
  late final TextEditingController _fonteCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _demandaCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _dateCtrl;

  int _fundingNonce = 0;
  bool _startupLoaded = false;

  @override
  void initState() {
    super.initState();

    _companyCtrl = TextEditingController();
    _fonteCtrl = TextEditingController();
    _numeroCtrl = TextEditingController();
    _demandaCtrl = TextEditingController();
    _totalCtrl = TextEditingController();
    _dateCtrl = TextEditingController();

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
    _numeroCtrl.dispose();
    _demandaCtrl.dispose();
    _totalCtrl.dispose();
    _dateCtrl.dispose();

    super.dispose();
  }

  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
  }

  void _syncFromState(EmpenhoState state) {
    if (_companyCtrl.text != state.companyLabel) {
      _companyCtrl.text = state.companyLabel;
    }

    if (_fonteCtrl.text != state.fundingSourceLabel) {
      _fonteCtrl.text = state.fundingSourceLabel;
    }

    if (_numeroCtrl.text != state.numero) {
      _numeroCtrl.text = state.numero;
    }

    if (_demandaCtrl.text != state.demandLabel) {
      _demandaCtrl.text = state.demandLabel;
    }

    if (_totalCtrl.text != state.totalText) {
      _totalCtrl.text = state.totalText;
    }

    final date = state.date;
    final desired = date == null ? '' : SipGedFormatDates.dateToDdMMyyyy(date);

    if (_dateCtrl.text != desired) {
      _dateCtrl.text = desired;
    }
  }

  void _syncCompanyFromTenant(TenantData? tenant) {
    if (tenant == null) return;

    final companyId = (tenant.companyId ?? tenant.tenantId ?? tenant.id).trim();
    final companyLabel = (tenant.companyName ?? tenant.label).trim();

    if (companyId.isEmpty && companyLabel.isEmpty) return;

    final cubit = context.read<EmpenhoCubit>();
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

  DfdData? _findDfdByContractId(
      List<DfdData> dfds,
      String id,
      ) {
    final target = id.trim();

    if (target.isEmpty) return null;

    try {
      return dfds.firstWhere(
            (d) => (d.contractId ?? '').trim() == target,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpenhoCubit, EmpenhoState>(
      builder: (context, empenhoState) {
        _syncFromState(empenhoState);

        return BlocBuilder<TenantCubit, TenantState>(
          builder: (context, tenantState) {
            final tenant = tenantState.tenantProfile;
            final fundingSources = tenantState.fundingSources;

            _syncCompanyFromTenant(tenant);

            final companyConfigured = tenant != null;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 700;
                final sideWidth = isSmallScreen ? constraints.maxWidth : 300.0;

                final inputsWidth = responsiveInputWidth(
                  context: context,
                  itemsPerLine: 4,
                  reservedWidth: isSmallScreen ? 0.0 : sideWidth + 12.0,
                  spacing: 12.0,
                  margin: 12.0,
                  extraPadding: 24.0,
                  spaceBetweenReserved: 12.0,
                );

                final minCardHeight = isSmallScreen ? 260.0 : 170.0;

                final empCubit = context.read<EmpenhoCubit>();
                final formOk = empCubit.formValidated;
                final somaFatias = empCubit.somaFatias;
                final totalValue = empCubit.totalValue;

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
                      key: ValueKey('empenho-funding-$_fundingNonce'),
                      width: inputsWidth,
                      labelText: 'Fonte de recurso',
                      controller: _fonteCtrl,
                      enabled: companyConfigured,
                      tooltipMessage: !companyConfigured
                          ? 'Configure o contratante no setup do sistema'
                          : null,
                      items: fundingSources,
                      specialItemLabel: 'Adicionar fonte',
                      showSpecialAlways: true,
                      menuMaxHeight: 260,
                      onChanged: (label) {
                        final cubit = context.read<EmpenhoCubit>();
                        final selectedLabel = _s(label);

                        if (selectedLabel.isEmpty) {
                          cubit.clearFundingSourceId();
                          cubit.setFundingSourceLabel('');
                          return;
                        }

                        final selected = _findByLabel(
                          fundingSources,
                          selectedLabel,
                        );

                        if (selected == null) return;

                        cubit.setFundingSourceLabel(selected);
                        cubit.setFundingSourceId(selected);
                      },
                      onCreateNewItem: companyConfigured
                          ? (label) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final cubit = context.read<EmpenhoCubit>();

                        final newLabel = _s(label);

                        if (newLabel.isEmpty) return;

                        final created = await tenantCubit
                            .createFundingSource(newLabel);

                        if (!mounted || created == null) return;

                        cubit.setFundingSourceLabel(created);
                        cubit.setFundingSourceId(created);

                        setState(() => _fundingNonce++);
                      }
                          : null,
                      onEditItem: companyConfigured
                          ? (ctx, oldLabel) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final cubit = context.read<EmpenhoCubit>();

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
                          cubit.setFundingSourceLabel(updated);
                          cubit.setFundingSourceId(updated);
                        }

                        setState(() => _fundingNonce++);
                      }
                          : null,
                      onDeleteItem: companyConfigured
                          ? (ctx, label) async {
                        final tenantCubit = context.read<TenantCubit>();
                        final cubit = context.read<EmpenhoCubit>();

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
                          cubit.setFundingSourceLabel('');
                          cubit.clearFundingSourceId();
                        }

                        setState(() => _fundingNonce++);
                      }
                          : null,
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _numeroCtrl,
                      labelText: 'Número do empenho',
                      onChanged: (v) {
                        context.read<EmpenhoCubit>().setNumero(v);
                      },
                    ),
                    DateFieldChange(
                      width: inputsWidth,
                      controller: _dateCtrl,
                      labelText: 'Data do empenho',
                      initialValue: empenhoState.date,
                      enabled: true,
                      onChanged: (date) {
                        context.read<EmpenhoCubit>().setDate(date);
                      },
                    ),
                    AutoCompleteChange<DfdData>(
                      controller: _demandaCtrl,
                      label: 'Creditar em',
                      hint: empenhoState.loadingDfds
                          ? 'Carregando demandas…'
                          : 'Digite para buscar',
                      enabled: !empenhoState.loadingDfds &&
                          empenhoState.dfds.isNotEmpty,
                      allList: empenhoState.dfds,
                      initialId:
                      (empenhoState.demandContractId ?? '').trim().isEmpty
                          ? null
                          : empenhoState.demandContractId!.trim(),
                      idOf: (d) {
                        return (d.contractId ?? '').trim();
                      },
                      displayOf: (d) {
                        return (d.descricaoObjeto ?? '').trim();
                      },
                      match: (d, qLower) {
                        final desc = (d.descricaoObjeto ?? '').toLowerCase();
                        final cid = (d.contractId ?? '').toLowerCase();

                        return desc.contains(qLower) || cid.contains(qLower);
                      },
                      onChanged: (id) {
                        final demandContractId = id.trim();
                        final cubit = context.read<EmpenhoCubit>();

                        if (demandContractId.isEmpty) {
                          cubit.clearDemand();
                          return;
                        }

                        final selected = _findDfdByContractId(
                          empenhoState.dfds,
                          demandContractId,
                        );

                        final label =
                        (selected?.descricaoObjeto ?? _demandaCtrl.text)
                            .trim();

                        cubit.setDemandContractId(demandContractId);
                        cubit.setDemandLabel(label);
                      },
                    ),
                    CustomTextField(
                      width: inputsWidth,
                      controller: _totalCtrl,
                      labelText: 'Valor total',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        context.read<EmpenhoCubit>().setTotalText(v);
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
                        empenhoState.selected == null
                            ? 'Salvar'
                            : 'Atualizar',
                      ),
                      onPressed: formOk
                          ? () => context.read<EmpenhoCubit>().saveOrUpdate()
                          : null,
                    ),
                    const SizedBox(width: 12),
                    if (empenhoState.selected != null)
                      TextButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Limpar'),
                        onPressed: () {
                          context.read<EmpenhoCubit>().select(null);
                        },
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

                final side = BoxListFiles(
                  title: 'Arquivos do Empenho',
                  items: empenhoState.attachments,
                  selectedIndex: empenhoState.selectedSideIndex,
                  onAddPressed: null,
                  onTap: (i) {
                    context.read<EmpenhoCubit>().selectSideIndex(i);
                  },
                  onDelete: (i) {
                    context.read<EmpenhoCubit>().deleteAttachmentAt(i);
                  },
                  onItemsChanged: (items) {
                    context.read<EmpenhoCubit>().setAttachmentsFromUi(items);
                  },
                  onRenamePersist: ({
                    required int index,
                    required dynamic oldItem,
                    required dynamic newItem,
                  }) async {
                    final cubit = context.read<EmpenhoCubit>();

                    final oldAttachment =
                    oldItem is Attachment ? oldItem : null;
                    final newAttachment =
                    newItem is Attachment ? newItem : null;

                    if (oldAttachment == null || newAttachment == null) {
                      return false;
                    }

                    return cubit.persistRenameAttachment(
                      index: index,
                      oldItem: oldAttachment,
                      newItem: newAttachment,
                    );
                  },
                  width: sideWidth,
                );

                return BasicCard(
                  isDark: Theme.of(context).brightness == Brightness.dark,
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
                        SizedBox(
                          width: sideWidth,
                          child: side,
                        ),
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