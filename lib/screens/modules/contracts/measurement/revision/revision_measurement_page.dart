// lib/screens/modules/contracts/measurement/revision/revision_measurement_page.dart

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_state.dart';

import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/revision/revision_paid_repository.dart';

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

import 'revision_measurement_form_section.dart';
import 'revision_measurement_graph_section.dart';
import 'revision_measurement_table_section.dart';

class RevisionMeasurement extends StatelessWidget {
  const RevisionMeasurement({
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
        child: Text('Contrato inválido para revisões.'),
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
              'Empresa ativa não selecionada para carregar revisões.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (permissionState.current == null) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        return BlocProvider<RevisionMeasurementCubit>(
          key: ValueKey<String>(
            'revision-measurement-$tenantId-$contractId',
          ),
          create: (context) {
            return RevisionMeasurementCubit(
              repository: RevisionMeasurementRepository(
                tenantId: tenantId,
              ),
              initialPermissions: permissionState.current,
              initialTenantId: tenantId,
              moduleId: 'operation_measurements_revisions',
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

              context.read<RevisionMeasurementCubit>().updatePermissions(
                permissions: permissionState.current,
                tenantId: nextTenantId,
              );
            },
            child: _RevisionMeasurementView(
              contractData: contractData,
              tenantId: tenantId,
            ),
          ),
        );
      },
    );
  }
}

class _RevisionMeasurementView extends StatefulWidget {
  const _RevisionMeasurementView({
    required this.contractData,
    required this.tenantId,
  });

  final ContractData contractData;
  final String tenantId;

  @override
  State<_RevisionMeasurementView> createState() {
    return _RevisionMeasurementViewState();
  }
}

class _RevisionMeasurementViewState extends State<_RevisionMeasurementView> {
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  late DfdRepository _dfdRepository;
  late RevisionPaidRepository _paymentRepository;

  DfdData? _dfdData;

  List<RevisionPaidData> _payments = <RevisionPaidData>[];

  bool formValidated = false;

  int? _selectedSideIndex;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String get _contractSummary {
    final descricaoObjeto = _dfdData?.descricaoObjeto?.trim();

    if (descricaoObjeto != null && descricaoObjeto.isNotEmpty) {
      return descricaoObjeto;
    }

    final displaySummary = widget.contractData.displaySummary.trim();

    if (displaySummary.isNotEmpty &&
        !_looksLikeIdOnly(displaySummary)) {
      return displaySummary;
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

  bool _looksLikeIdOnly(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return false;

    final withoutSeparators = clean.replaceAll(RegExp(r'[-_/.\s]'), '');

    if (withoutSeparators.length < 16) return false;

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(withoutSeparators);
    final hasNumber = RegExp(r'[0-9]').hasMatch(withoutSeparators);

    return hasLetter && hasNumber;
  }

  @override
  void initState() {
    super.initState();

    _configureRepositories();
    _loadInitialData();

    orderCtrl.addListener(_validateForm);
    processCtrl.addListener(_validateForm);
    valueCtrl.addListener(_validateForm);
    dateCtrl.addListener(_validateForm);
  }

  @override
  void didUpdateWidget(covariant _RevisionMeasurementView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = oldWidget.contractData.id?.trim() ?? '';
    final newContractId = widget.contractData.id?.trim() ?? '';

    if (oldWidget.tenantId != widget.tenantId ||
        oldContractId != newContractId) {
      _configureRepositories();

      setState(() {
        _dfdData = null;
        _payments = <RevisionPaidData>[];
        _selectedSideIndex = null;
        formValidated = false;
      });

      _loadInitialData();
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

    if (tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para carregar revisões.',
      );
    }

    _dfdRepository = DfdRepository(
      tenantId: tenantId,
    );

    _paymentRepository = RevisionPaidRepository(
      tenantId: tenantId,
    );
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDfdDisplayData(),
      _loadPaymentsForContract(),
    ]);
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
      debugPrint('Falha ao carregar DFD do contrato em revisão: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _loadPaymentsForContract() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    try {
      final payments = await _paymentRepository.getPaymentsByContract(
        contractId: contractId,
      );

      if (!mounted) return;

      setState(() {
        _payments = payments;
      });
    } catch (e, stack) {
      debugPrint('Falha ao carregar pagamentos do contrato em revisões: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _payments = <RevisionPaidData>[];
      });
    }
  }

  double _roundMoney(double value) {
    if (!value.isFinite) return 0.0;

    final rounded = (value * 100).roundToDouble() / 100;

    if (rounded == 0.0) return 0.0;

    return rounded;
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return _roundMoney(v);
  }

  double _totalPaymentValue(RevisionPaidData payment) {
    return _roundMoney(
      _positive(payment.paymentValue) +
          _positive(payment.inssPaymentValue) +
          _positive(payment.irpfPaymentValue) +
          _positive(payment.issPaymentValue),
    );
  }

  double _sumPaymentsTotal(List<RevisionPaidData> payments) {
    return payments.fold<double>(
      0.0,
          (previousTotal, payment) {
        return _roundMoney(previousTotal + _totalPaymentValue(payment));
      },
    );
  }

  List<RevisionPaidData> _paymentsForRevision(
      RevisionMeasurementData revision,
      ) {
    final revisionId = revision.id?.trim() ?? '';
    final revisionOrder = revision.order;

    return _payments.where((payment) {
      final paymentContractId = payment.contractId?.trim() ?? '';
      final revisionContractId = revision.contractId?.trim() ?? '';

      if (revisionContractId.isNotEmpty &&
          paymentContractId.isNotEmpty &&
          paymentContractId != revisionContractId) {
        return false;
      }

      final paymentRevisionId = payment.revisionId?.trim() ?? '';

      if (revisionId.isNotEmpty && paymentRevisionId == revisionId) {
        return true;
      }

      if (paymentRevisionId.isEmpty &&
          revisionOrder != null &&
          payment.revisionOrder == revisionOrder) {
        return true;
      }

      if (revisionId.isEmpty &&
          revisionOrder != null &&
          payment.revisionOrder == revisionOrder) {
        return true;
      }

      return false;
    }).toList();
  }

  List<double> _buildPaymentValuesForRevisions(
      List<RevisionMeasurementData> revisions,
      ) {
    return revisions.map((revision) {
      final list = _paymentsForRevision(revision);

      return _sumPaymentsTotal(list);
    }).toList();
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
      kind: NotificationMeasurementKind.revision,
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
      revisionId: extra['revisionId']?.toString(),
      revisionNumber: extra['revisionProcess']?.toString(),
      revisionOrder: extra['revisionOrder']?.toString(),
      revisionDate: _parseDateTimeFromExtra(extra['revisionDate']),
      revisionValue: extra['revisionValue'] is num
          ? extra['revisionValue'] as num
          : null,
      measurementId: extra['revisionId']?.toString(),
      measurementNumber: extra['revisionProcess']?.toString(),
      measurementOrder: extra['revisionOrder']?.toString(),
      measurementValue: extra['revisionValue'] is num
          ? extra['revisionValue'] as num
          : null,
      action: extra['action']?.toString(),
      attachmentLabel: extra['attachmentLabel']?.toString(),
      attachmentUrl: extra['attachmentUrl']?.toString(),
      oldAttachmentLabel: extra['oldAttachmentLabel']?.toString(),
      newAttachmentLabel: extra['newAttachmentLabel']?.toString(),
      extra: extra,
    );
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
      debugPrint('Falha ao enviar notificação de revisão: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  DateTime? _parseDateTimeFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
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

  int _computeNextOrder(RevisionMeasurementState state) {
    if (state.revisions.isEmpty) return 1;

    final maxOrder = state.revisions
        .map((item) => item.order ?? 0)
        .fold<int>(0, (prev, curr) => math.max(prev, curr));

    return maxOrder + 1;
  }

  void _fillFieldsFromSelected(RevisionMeasurementState state) {
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
    final cubit = context.read<RevisionMeasurementCubit>();
    final contractId = widget.contractData.id?.toString().trim();

    return BlocConsumer<RevisionMeasurementCubit, RevisionMeasurementState>(
      listener: (context, state) {
        _fillFieldsFromSelected(state);
      },
      builder: (context, state) {
        if (state.status == RevisionMeasurementStatus.loading &&
            state.revisions.isEmpty) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        if (state.status == RevisionMeasurementStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Erro ao carregar revisões.',
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

        final revisions = state.revisions;

        final labels = revisions
            .map((item) => (item.order ?? 0).toString())
            .toList();

        final values = revisions.map((item) => item.value ?? 0.0).toList();

        final revisionIds = revisions.map((item) => item.id?.trim() ?? '').toList();

        final revisionOrders = revisions.map((item) => item.order).toList();

        final paymentValues = _buildPaymentValuesForRevisions(revisions);

        final total = revisions.fold<double>(
          0.0,
              (previousTotal, item) {
            return _roundMoney(previousTotal + (item.value ?? 0.0));
          },
        );

        final totalPagamentos = _sumPaymentsTotal(_payments);

        final valorTotalDisponivel = total;

        final saldo = _roundMoney(valorTotalDisponivel - total);

        final selectedIndex = state.selectedIndex;
        final nextOrder = _computeNextOrder(state);

        final usedOrders = revisions
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
                        const SectionTitle(text: 'Gráfico das revisões'),
                        RevisionMeasurementGraphSection(
                          labels: labels,
                          values: values,
                          revisionIds: revisionIds,
                          revisionOrders: revisionOrders,
                          payments: _payments,
                          paymentValues: paymentValues,
                          totalPagamentos: totalPagamentos,
                          valorTotal: valorTotalDisponivel,
                          totalMedicoes: total,
                          selectedIndex: selectedIndex,
                          onSelectIndex: cubit.selectByIndex,
                        ),
                        const SectionTitle(
                          text: 'Cadastrar revisão no sistema',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: RevisionMeasurementFormSection(
                            isEditable: canEditCurrentForm,
                            formValidated: formValidated,
                            selectedRevisionMeasurement: state.selected,
                            currentRevisionMeasurementId: state.selected?.id,
                            contractData: widget.contractData,
                            orderRevisionController: orderCtrl,
                            processNumberRevisionController: processCtrl,
                            dateRevisionController: dateCtrl,
                            valueRevisionController: valueCtrl,
                            sideLoading: state.uploading,
                            sideUploadProgress: state.uploadProgress,
                            onPaymentsChanged: _loadPaymentsForContract,
                            onSave: () async {
                              if (!canEditCurrentForm) {
                                await _safeNotify(
                                  title: 'Sem permissão para salvar revisão',
                                  subtitle: _contractSummary,
                                  details:
                                  'Você não possui permissão para criar ou editar revisão neste contrato.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar esta revisão?',
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
                                  title: 'Data da revisão inválida',
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

                              final data = RevisionMeasurementData(
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
                                final revisionId = await cubit.saveOrUpdate(
                                  contract: widget.contractData,
                                  data: data,
                                );

                                await _loadPaymentsForContract();

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: isNew
                                      ? 'Revisão criada'
                                      : 'Revisão atualizada',
                                  subtitle: _contractSummary,
                                  details: isNew
                                      ? 'Revisão ${data.order ?? '-'} criada por $actorName.'
                                      : 'Revisão ${data.order ?? '-'} atualizada por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action': isNew
                                        ? 'revision_created'
                                        : 'revision_updated',
                                    'revisionId': revisionId,
                                    'revisionOrder': data.order,
                                    'revisionProcess': data.numberprocess,
                                    'revisionValue': data.value,
                                    'revisionDate':
                                    data.date?.toIso8601String(),
                                  },
                                );
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Erro ao salvar revisão',
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
                                  revisionId: state.selected!.id!,
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
                                  title: 'Arquivo anexado à revisão',
                                  subtitle: _contractSummary,
                                  details: uploaded != null
                                      ? '${uploaded.label} anexado por $actorName.'
                                      : 'Upload concluído por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'revision_attachment_created',
                                    'revisionId': state.selected!.id,
                                    'revisionOrder':
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
                              cubit.selectAttachmentIndex(index);

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

                              if (index < 0 ||
                                  index >= attachments.length) {
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
                                  revisionId: selected!.id!,
                                  attachment: attachment,
                                );

                                if (mounted) {
                                  setState(() {
                                    _selectedSideIndex = null;
                                  });
                                }

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Arquivo removido da revisão',
                                  subtitle: _contractSummary,
                                  details:
                                  '${attachment.label} removido por $actorName.',
                                  status: NotificationStatus.warning,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'revision_attachment_deleted',
                                    'revisionId': selected.id,
                                    'revisionOrder': selected.order,
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
                                  title:
                                  'Sem permissão para renomear anexo',
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
                                  revisionId: selected!.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Anexo de revisão renomeado',
                                  subtitle: _contractSummary,
                                  details:
                                  '${newItem.label} renomeado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action': 'revision_attachment_renamed',
                                    'revisionId': selected.id,
                                    'revisionOrder': selected.order,
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

                              try {
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
                              } catch (e) {
                                await _safeNotify(
                                  title:
                                  'Erro ao atualizar anexos da revisão',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              }
                            }
                                : null,
                            orderOptions: orderOptions,
                            greyOrderItems: greyOrderItems,
                            onChangedOrder: (value) {
                              final picked = int.tryParse(value ?? '');

                              if (picked == null || picked <= 0) return;

                              final index = revisions.indexWhere(
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
                          text: 'Revisões cadastradas no sistema',
                        ),
                        RevisionMeasurementTableSection(
                          onTapItem: (RevisionMeasurementData data) {
                            final index = revisions.indexWhere(
                                  (item) => item.id == data.id,
                            );

                            if (index >= 0) {
                              cubit.selectByIndex(index);
                            }
                          },
                          onDelete: (id) async {
                            if (!canDelete) {
                              await _safeNotify(
                                title: 'Sem permissão para apagar revisão',
                                subtitle: _contractSummary,
                                details:
                                'Você não possui permissão de exclusão neste contrato.',
                                status: NotificationStatus.error,
                              );
                              return;
                            }

                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta revisão?',
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

                            final deleted = revisions.firstWhere(
                                  (item) => item.id == id,
                              orElse: () {
                                return RevisionMeasurementData(id: id);
                              },
                            );

                            try {
                              await cubit.delete(
                                contract: widget.contractData,
                                contractId: contractId,
                                revisionId: id,
                              );

                              await _loadPaymentsForContract();

                              final actorName = _currentActorLabel();

                              await _safeNotify(
                                title: 'Revisão apagada',
                                subtitle: _contractSummary,
                                details: deleted.order != null
                                    ? 'Revisão ${deleted.order} removida por $actorName.'
                                    : 'Revisão removida por $actorName.',
                                status: NotificationStatus.warning,
                                saveInBell: true,
                                sendPush: true,
                                extra: <String, dynamic>{
                                  'action': 'revision_deleted',
                                  'revisionId': id,
                                  'revisionOrder': deleted.order,
                                  'revisionProcess': deleted.numberprocess,
                                  'revisionValue': deleted.value,
                                  'revisionDate':
                                  deleted.date?.toIso8601String(),
                                },
                              );
                            } catch (e) {
                              await _safeNotify(
                                title: 'Erro ao apagar revisão',
                                subtitle: _contractSummary,
                                details: '$e',
                                status: NotificationStatus.error,
                                duration: const Duration(seconds: 6),
                              );
                            }
                          },
                          revisionMeasurementsData: revisions,
                          payments: _payments,
                          valorTotal: valorTotalDisponivel,
                          balance: saldo,
                          contractData: widget.contractData,
                          selectedRevisionMeasurement: state.selected,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            if (state.isSaving || state.uploading)
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