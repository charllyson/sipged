// lib/screens/modules/contracts/measurement/adjustment/adjustment_measurement_page.dart

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_state.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_measurements.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'adjustment_measurement_form_section.dart';
import 'adjustment_measurement_graph_section.dart';
import 'adjustment_measurement_table_section.dart';

class AdjustmentMeasurement extends StatelessWidget {
  const AdjustmentMeasurement({
    super.key,
    required this.contractData,
  });

  final ContractData contractData;

  String? _resolveTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }

    return tenantId;
  }

  @override
  Widget build(BuildContext context) {
    final contractId = contractData.id?.toString().trim();

    if (contractId == null || contractId.isEmpty) {
      return const Center(
        child: Text('Contrato inválido para reajustes.'),
      );
    }

    return BlocBuilder<PermissionCubit, PermissionState>(
      buildWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId ||
            previous.current != current.current;
      },
      builder: (context, permissionState) {
        final tenantId = _resolveTenantId(permissionState);

        if (tenantId == null) {
          return const Center(
            child: Text(
              'Empresa ativa não selecionada para carregar reajustes.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return BlocProvider<AdjustmentMeasurementCubit>(
          key: ValueKey<String>(
            'adjustment-measurement-$tenantId-$contractId',
          ),
          create: (context) {
            return AdjustmentMeasurementCubit(
              repository: AdjustmentMeasurementRepository(
                tenantId: tenantId,
              ),
              initialPermissions: permissionState.current,
              initialTenantId: tenantId,
              moduleId: 'operation_measurements_adjustments',
            )..loadByContract(
              contractId,
              contract: contractData,
            );
          },
          child: BlocListener<PermissionCubit, PermissionState>(
            listenWhen: (previous, current) {
              return previous.current != current.current ||
                  previous.activeTenantId != current.activeTenantId;
            },
            listener: (context, permissionState) {
              final nextTenantId = _resolveTenantId(permissionState);

              if (nextTenantId == null) return;

              context.read<AdjustmentMeasurementCubit>().updatePermissions(
                permissions: permissionState.current,
                tenantId: nextTenantId,
              );
            },
            child: _AdjustmentMeasurementView(
              contractData: contractData,
              tenantId: tenantId,
            ),
          ),
        );
      },
    );
  }
}

class _AdjustmentMeasurementView extends StatefulWidget {
  const _AdjustmentMeasurementView({
    required this.contractData,
    required this.tenantId,
  });

  final ContractData contractData;
  final String tenantId;

  @override
  State<_AdjustmentMeasurementView> createState() {
    return _AdjustmentMeasurementViewState();
  }
}

class _AdjustmentMeasurementViewState extends State<_AdjustmentMeasurementView> {
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  late DfdRepository _dfdRepository;
  late ApostillesRepository _apostillesRepository;

  DfdData? _dfdData;

  double _totalApostillesValue = 0.0;

  bool formValidated = false;

  int? _selectedSideIndex;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractSummary {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    if (_contractId.isNotEmpty) {
      return 'Contrato $_contractId';
    }

    return 'Contrato sem identificação';
  }

  String get _contractNumber {
    final processoAdministrativo = _dfdData?.processoAdministrativo?.trim();

    if (processoAdministrativo != null && processoAdministrativo.isNotEmpty) {
      return processoAdministrativo;
    }

    return _contractId;
  }

  @override
  void initState() {
    super.initState();

    _configureRepositories();

    _loadDfdDisplayData();
    _loadApostillesValue();

    orderCtrl.addListener(_validateForm);
    processCtrl.addListener(_validateForm);
    valueCtrl.addListener(_validateForm);
    dateCtrl.addListener(_validateForm);
  }

  @override
  void didUpdateWidget(covariant _AdjustmentMeasurementView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = oldWidget.contractData.id?.trim() ?? '';
    final newContractId = widget.contractData.id?.trim() ?? '';

    if (oldWidget.tenantId != widget.tenantId ||
        oldContractId != newContractId) {
      _configureRepositories();

      setState(() {
        _dfdData = null;
        _totalApostillesValue = 0.0;
        _selectedSideIndex = null;
      });

      _loadDfdDisplayData();
      _loadApostillesValue();
    }
  }

  @override
  void dispose() {
    orderCtrl
      ..removeListener(_validateForm)
      ..dispose();

    processCtrl
      ..removeListener(_validateForm)
      ..dispose();

    valueCtrl
      ..removeListener(_validateForm)
      ..dispose();

    dateCtrl
      ..removeListener(_validateForm)
      ..dispose();

    super.dispose();
  }

  void _configureRepositories() {
    final tenantId = widget.tenantId.trim();

    _dfdRepository = DfdRepository(
      tenantId: tenantId,
    );

    _apostillesRepository = ApostillesRepository(
      tenantId: tenantId,
    );
  }

  Future<void> _loadDfdDisplayData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    try {
      final dfd = await _dfdRepository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _dfdData = dfd;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD do contrato em reajuste: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _loadApostillesValue() async {
    final contractId = _contractId;

    if (contractId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _totalApostillesValue = 0.0;
      });

      return;
    }

    try {
      final total = await _apostillesRepository.getAllApostillesValue(
        contractId,
      );

      if (!mounted) return;

      setState(() {
        _totalApostillesValue = total.isFinite ? total : 0.0;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar total de apostilamentos em reajuste: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _totalApostillesValue = 0.0;
      });
    }
  }

  String _currentActorLabel() {
    final currentUser = FirebaseAuth.instance.currentUser;

    final displayName = currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = currentUser?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  Future<void> _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,
    NotificationStatus? type,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    await NotificationMeasurements.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle ?? _contractSummary,
      details: details,
      kind: NotificationMeasurementKind.adjustment,
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: FirebaseAuth.instance.currentUser?.uid,
      includeCurrentUser: true,
      tenantId: widget.tenantId,
      companyId: widget.tenantId,
      contractId: _contractId,
      contractNumber: _contractNumber,
      processNumber: _contractNumber,
      processoAdministrativo: _dfdData?.processoAdministrativo,
      contractTitle: _contractSummary,
      contractSummary: _contractSummary,
      descricaoObjeto: _dfdData?.descricaoObjeto,
      nomeDemanda: _contractSummary,
      adjustmentId: extra['adjustmentId']?.toString(),
      adjustmentNumber: extra['adjustmentProcess']?.toString(),
      adjustmentOrder: extra['adjustmentOrder']?.toString(),
      adjustmentDate: _parseExtraDate(extra['adjustmentDate']),
      adjustmentValue:
      extra['adjustmentValue'] is num ? extra['adjustmentValue'] as num : null,
      action: extra['action']?.toString(),
      attachmentLabel: extra['attachmentLabel']?.toString(),
      attachmentUrl: extra['attachmentUrl']?.toString(),
      oldAttachmentLabel: extra['oldAttachmentLabel']?.toString(),
      newAttachmentLabel: extra['newAttachmentLabel']?.toString(),
      extra: extra,
    );
  }

  DateTime? _parseExtraDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  Future<void> _safeNotify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus status = NotificationStatus.info,
    NotificationStatus? type,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    try {
      await _notify(
        title: title,
        subtitle: subtitle,
        details: details,
        status: status,
        type: type,
        duration: duration,
        saveInBell: saveInBell,
        sendPush: sendPush,
        extra: extra,
      );
    } catch (e, stack) {
      debugPrint('Falha ao enviar notificação de reajuste: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  void _validateForm() {
    final ok = orderCtrl.text.trim().isNotEmpty &&
        processCtrl.text.trim().isNotEmpty &&
        valueCtrl.text.trim().isNotEmpty &&
        dateCtrl.text.trim().isNotEmpty;

    if (formValidated != ok && mounted) {
      setState(() {
        formValidated = ok;
      });
    }
  }

  int _computeNextOrder(AdjustmentMeasurementState state) {
    if (state.adjustments.isEmpty) return 1;

    final maxOrder = state.adjustments
        .map((item) => item.order ?? 0)
        .fold<int>(0, (prev, curr) => math.max(prev, curr));

    return maxOrder + 1;
  }

  void _fillFieldsFromSelected(AdjustmentMeasurementState state) {
    final selected = state.selected;

    _selectedSideIndex = null;

    if (selected == null) {
      orderCtrl.text = _computeNextOrder(state).toString();
      processCtrl.clear();
      valueCtrl.clear();
      dateCtrl.clear();
      _validateForm();
      return;
    }

    orderCtrl.text = (selected.order ?? '').toString();
    processCtrl.text = selected.numberprocess ?? '';
    valueCtrl.text = SipGedFormatMoney.brlNoSymbol(selected.value);

    if (selected.date != null) {
      final date = selected.date!;

      dateCtrl.text =
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else {
      dateCtrl.clear();
    }

    _validateForm();
  }

  int? _parseInt(String text) {
    return int.tryParse(
      text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
  }

  double _parseCurrency(String text) {
    return SipGedFormatMoney.parseBrl(text) ?? 0.0;
  }

  DateTime? _parseDate(String text) {
    final parts = text.split('/');

    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final date = DateTime(year, month, day);

    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    return date;
  }

  List<Attachment> _onlyAttachments(List<dynamic> items) {
    return items.whereType<Attachment>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdjustmentMeasurementCubit>();
    final contractId = widget.contractData.id?.toString().trim();

    return BlocConsumer<AdjustmentMeasurementCubit, AdjustmentMeasurementState>(
      listener: (context, state) {
        _fillFieldsFromSelected(state);
      },
      builder: (context, state) {
        if (state.status == AdjustmentMeasurementStatus.loading &&
            state.adjustments.isEmpty) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        if (state.status == AdjustmentMeasurementStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Erro ao carregar reajustes.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final canCreate = cubit.canCreateContract(widget.contractData);
        final canEdit = cubit.canEditContract(widget.contractData);
        final canDelete = cubit.canDeleteContract(widget.contractData);

        final canEditCurrentForm = state.selected == null ? canCreate : canEdit;
        final canEditAttachments = state.selected != null && canEdit;

        final labels = state.adjustments
            .map((item) => (item.order ?? 0).toString())
            .toList();

        final values = state.adjustments.map((item) => item.value ?? 0.0).toList();

        final total = state.adjustments.fold<double>(
          0.0,
              (previousTotal, item) => previousTotal + (item.value ?? 0.0),
        );

        final totalApostilles = _totalApostillesValue;
        final totalAdditives = 0.0;

        final valorTotalDisponivel = totalApostilles;
        final saldo = valorTotalDisponivel - total;

        final selectedIndex = state.selectedIndex;
        final nextOrder = _computeNextOrder(state);

        final usedOrders = state.adjustments
            .map((item) => item.order)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

        final orderOptions = <String>[
          ...usedOrders.map((order) => order.toString()),
          if (!usedOrders.contains(nextOrder)) nextOrder.toString(),
        ];

        final greyOrderItems = usedOrders.map((order) => order.toString()).toSet();

        final attachments = state.attachments;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Gráfico dos reajustes'),
                        AdjustmentMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotalDisponivel,
                          totalMedicoes: total,
                          selectedIndex: selectedIndex,
                          onSelectIndex: cubit.selectByIndex,
                        ),
                        const SectionTitle(
                          text: 'Cadastrar reajuste no sistema',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: AdjustmentMeasurementFormSection(
                            isEditable: canEditCurrentForm,
                            formValidated: formValidated,
                            selectedAdjustmentMeasurement: state.selected,
                            currentAdjustmentMeasurementId: state.selected?.id,
                            contractData: widget.contractData,
                            orderAdjustmentController: orderCtrl,
                            processNumberAdjustmentController: processCtrl,
                            dateAdjustmentController: dateCtrl,
                            valueAdjustmentController: valueCtrl,
                            sideLoading: state.uploading,
                            sideUploadProgress: state.uploadProgress,
                            onSave: () async {
                              if (!canEditCurrentForm) {
                                await _safeNotify(
                                  title: 'Sem permissão para salvar reajuste',
                                  subtitle: _contractSummary,
                                  details:
                                  'Você não possui permissão para criar ou editar reajuste neste contrato.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar este reajuste?',
                              );

                              if (!ok) return;

                              final parsedOrder = _parseInt(orderCtrl.text);

                              final effectiveOrder =
                              parsedOrder == null || parsedOrder <= 0
                                  ? _computeNextOrder(state)
                                  : parsedOrder;

                              final value = _parseCurrency(valueCtrl.text);
                              final date = _parseDate(dateCtrl.text);

                              if (date == null) {
                                await _safeNotify(
                                  title: 'Data do reajuste inválida',
                                  subtitle: _contractSummary,
                                  details: 'Use o formato dd/MM/aaaa.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              if (contractId == null || contractId.isEmpty) {
                                await _safeNotify(
                                  title: 'Contrato inválido',
                                  subtitle: _contractSummary,
                                  details:
                                  'Não foi possível identificar o contrato.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              final isNew = state.selected?.id == null;

                              final data = AdjustmentMeasurementData(
                                id: state.selected?.id,
                                contractId: contractId,
                                order: effectiveOrder,
                                numberprocess: processCtrl.text.trim(),
                                value: value,
                                date: date,
                                attachments: state.selected?.attachments,
                                pdfUrl: state.selected?.pdfUrl,
                              );

                              try {
                                await cubit.saveOrUpdate(
                                  contract: widget.contractData,
                                  data: data,
                                );

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: isNew
                                      ? 'Reajuste criado'
                                      : 'Reajuste atualizado',
                                  subtitle: _contractSummary,
                                  details: isNew
                                      ? 'Reajuste ${data.order ?? '-'} criado por $actorName.'
                                      : 'Reajuste ${data.order ?? '-'} atualizado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action': isNew
                                        ? 'adjustment_created'
                                        : 'adjustment_updated',
                                    'adjustmentId': data.id ?? state.selected?.id,
                                    'adjustmentOrder': data.order,
                                    'adjustmentProcess': data.numberprocess,
                                    'adjustmentValue': data.value,
                                    'adjustmentDate':
                                    data.date?.toIso8601String(),
                                  },
                                );
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Erro ao salvar reajuste',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            },
                            onClear: () {
                              cubit.clearSelection();

                              setState(() {
                                _selectedSideIndex = null;
                              });
                            },
                            sideItems: attachments,
                            selectedSideIndex: _selectedSideIndex,
                            onAddSideItem: canEditAttachments &&
                                state.selected != null &&
                                state.selected?.id != null &&
                                contractId != null &&
                                contractId.isNotEmpty
                                ? () async {
                              try {
                                await cubit.pickAndUploadAttachment(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  adjustmentId: state.selected!.id!,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _selectedSideIndex =
                                  cubit.state.attachments.isNotEmpty
                                      ? cubit.state.attachments.length -
                                      1
                                      : null;
                                });

                                final uploaded =
                                cubit.state.attachments.isNotEmpty
                                    ? cubit.state.attachments.last
                                    : null;

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Arquivo anexado ao reajuste',
                                  subtitle: _contractSummary,
                                  details: uploaded != null
                                      ? '${uploaded.label} anexado por $actorName.'
                                      : 'Upload concluído por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_added',
                                    'adjustmentId': state.selected!.id,
                                    'adjustmentOrder':
                                    state.selected!.order,
                                    'attachmentLabel': uploaded?.label,
                                    'attachmentUrl': uploaded?.url,
                                  },
                                );
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Falha ao anexar arquivo',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            }
                                : null,
                            onTapSideItem: (index) {
                              setState(() {
                                _selectedSideIndex = index;
                              });
                            },
                            onDeleteSideItem: canEditAttachments
                                ? (index) async {
                              if (contractId == null ||
                                  contractId.isEmpty) {
                                return;
                              }

                              final selected = state.selected;

                              if (selected?.id == null) return;

                              if (index < 0 || index >= attachments.length) {
                                return;
                              }

                              final attachment = attachments[index];

                              final ok = await confirmDialog(
                                context,
                                'Remover este arquivo?',
                              );

                              if (!ok) return;

                              try {
                                await cubit.deleteAttachment(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  adjustmentId: selected!.id!,
                                  attachment: attachment,
                                );

                                if (mounted) {
                                  setState(() {
                                    _selectedSideIndex = null;
                                  });
                                }

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Arquivo removido do reajuste',
                                  subtitle: _contractSummary,
                                  details:
                                  '${attachment.label} removido por $actorName.',
                                  status: NotificationStatus.warning,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_deleted',
                                    'adjustmentId': selected.id,
                                    'adjustmentOrder': selected.order,
                                    'attachmentLabel': attachment.label,
                                    'attachmentUrl': attachment.url,
                                  },
                                );
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Erro ao remover arquivo',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            }
                                : null,
                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              if (!canEditAttachments) {
                                await _safeNotify(
                                  title: 'Sem permissão para renomear anexo',
                                  subtitle: _contractSummary,
                                  details:
                                  'Você não possui permissão de edição neste contrato.',
                                  status: NotificationStatus.error,
                                );
                                return false;
                              }

                              if (contractId == null || contractId.isEmpty) {
                                return false;
                              }

                              final selected = state.selected;

                              if (selected?.id == null) return false;

                              try {
                                await cubit.renameAttachmentLabel(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  adjustmentId: selected!.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Anexo de reajuste renomeado',
                                  subtitle: _contractSummary,
                                  details:
                                  '${newItem.label} renomeado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'adjustment_attachment_renamed',
                                    'adjustmentId': selected.id,
                                    'adjustmentOrder': selected.order,
                                    'oldAttachmentLabel': oldItem.label,
                                    'newAttachmentLabel': newItem.label,
                                    'attachmentUrl': newItem.url,
                                  },
                                );

                                return true;
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Falha ao renomear anexo',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );

                                return false;
                              }
                            },
                            onSideItemsChanged: canEditAttachments
                                ? (newItems) async {
                              final next = _onlyAttachments(newItems);

                              await cubit.updateAttachments(
                                contract: widget.contractData,
                                attachments: next,
                              );

                              if (!mounted) return;

                              setState(() {
                                if (next.isEmpty) {
                                  _selectedSideIndex = null;
                                } else {
                                  _selectedSideIndex =
                                      (_selectedSideIndex ?? 0).clamp(
                                        0,
                                        next.length - 1,
                                      );
                                }
                              });
                            }
                                : null,
                            orderOptions: orderOptions,
                            greyOrderItems: greyOrderItems,
                            onChangedOrder: (value) {
                              final picked = int.tryParse(value ?? '');

                              if (picked == null || picked <= 0) return;

                              final index = state.adjustments.indexWhere(
                                    (item) => (item.order ?? -1) == picked,
                              );

                              if (index >= 0) {
                                cubit.selectByIndex(index);
                              } else {
                                cubit.clearSelection();
                                orderCtrl.text = picked.toString();
                              }
                            },
                          ),
                        ),
                        const SectionTitle(
                          text: 'Reajustes cadastrados no sistema',
                        ),
                        AdjustmentMeasurementTableSection(
                          onTapItem: (AdjustmentMeasurementData data) {
                            final index = state.adjustments.indexWhere(
                                  (item) => item.id == data.id,
                            );

                            if (index >= 0) {
                              cubit.selectByIndex(index);
                            }
                          },
                          onDelete: (id) async {
                            if (!canDelete) {
                              await _safeNotify(
                                title: 'Sem permissão para apagar reajuste',
                                subtitle: _contractSummary,
                                details:
                                'Você não possui permissão de exclusão neste contrato.',
                                status: NotificationStatus.error,
                              );
                              return;
                            }

                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar este reajuste?',
                            );

                            if (!ok) return;

                            if (contractId == null || contractId.isEmpty) {
                              await _safeNotify(
                                title: 'Contrato inválido',
                                subtitle: _contractSummary,
                                details:
                                'Não foi possível identificar o contrato.',
                                status: NotificationStatus.error,
                              );
                              return;
                            }

                            final deleted = state.adjustments.firstWhere(
                                  (item) => item.id == id,
                              orElse: () {
                                return AdjustmentMeasurementData(id: id);
                              },
                            );

                            try {
                              await cubit.delete(
                                contract: widget.contractData,
                                contractId: contractId,
                                adjustmentId: id,
                              );

                              final actorName = _currentActorLabel();

                              await _safeNotify(
                                title: 'Reajuste apagado',
                                subtitle: _contractSummary,
                                details: deleted.order != null
                                    ? 'Reajuste ${deleted.order} removido por $actorName.'
                                    : 'Reajuste removido por $actorName.',
                                status: NotificationStatus.warning,
                                saveInBell: true,
                                sendPush: true,
                                extra: <String, dynamic>{
                                  'action': 'adjustment_deleted',
                                  'adjustmentId': id,
                                  'adjustmentOrder': deleted.order,
                                  'adjustmentProcess': deleted.numberprocess,
                                  'adjustmentValue': deleted.value,
                                  'adjustmentDate':
                                  deleted.date?.toIso8601String(),
                                },
                              );
                            } catch (e) {
                              await _safeNotify(
                                title: 'Erro ao apagar reajuste',
                                subtitle: _contractSummary,
                                details: '$e',
                                status: NotificationStatus.error,
                                duration: const Duration(seconds: 6),
                              );
                            }
                          },
                          adjustmentMeasurementsData: state.adjustments,
                          valueApostilles: totalApostilles,
                          valueRevisions: totalAdditives,
                          valorTotal: valorTotalDisponivel,
                          balance: saldo,
                          contractData: widget.contractData,
                          selectedAdjustmentMeasurement: state.selected,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            if (state.isSaving)
              Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  const Center(
                    child: LoadingTreeDots(size: 120),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}