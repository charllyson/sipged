// lib/screens/modules/contracts/measurement/report/report_executed_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_state.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_repository.dart';

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

import '../create/create_detailed_reports_page.dart';
import 'report_executed_form.dart';
import 'report_executed_graph.dart';
import 'report_executed_table.dart';

class ReportExecutedPage extends StatelessWidget {
  const ReportExecutedPage({
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
    final contractId = contractData.id?.trim();

    if (contractId == null || contractId.isEmpty) {
      return const Center(
        child: Text(
          'Salve o contrato antes de cadastrar medições.',
          textAlign: TextAlign.center,
        ),
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
              'Empresa ativa não selecionada para carregar medições.',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (permissionState.current == null) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        return BlocProvider<ReportExecutedCubit>(
          key: ValueKey<String>('report-executed-$tenantId-$contractId'),
          create: (context) {
            return ReportExecutedCubit(
              repository: ReportExecutedRepository(
                tenantId: tenantId,
              ),
              initialPermissions: permissionState.current,
              initialTenantId: tenantId,
              moduleId: 'operation_measurements',
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

              context.read<ReportExecutedCubit>().updatePermissions(
                permissions: permissionState.current,
                tenantId: nextTenantId,
              );
            },
            child: _ReportMeasurementView(
              contractData: contractData,
              tenantId: tenantId,
            ),
          ),
        );
      },
    );
  }
}

class _ReportMeasurementView extends StatefulWidget {
  const _ReportMeasurementView({
    required this.contractData,
    required this.tenantId,
  });

  final ContractData contractData;
  final String tenantId;

  @override
  State<_ReportMeasurementView> createState() {
    return _ReportMeasurementViewState();
  }
}

class _ReportMeasurementViewState extends State<_ReportMeasurementView> {
  late DfdRepository _dfdRepository;
  late ReportPaidRepository _paymentRepository;
  late AdditivesRepository _additivesRepository;

  DfdData? _dfdData;

  double _valorDemanda = 0.0;
  double _totalAditivos = 0.0;

  List<ReportPaidData> _payments = <ReportPaidData>[];

  int? _selectedIndex;
  ReportExecutedData? _selectedMeasurement;

  bool _isSaving = false;

  List<Attachment> _sideItems = <Attachment>[];
  int? _selectedSideIndex;

  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  bool formValidated = false;

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
    _loadDfdAggregatesAndPayments();

    orderCtrl.addListener(_validateForm);
    processCtrl.addListener(_validateForm);
    valueCtrl.addListener(_validateForm);
    dateCtrl.addListener(_validateForm);
  }

  @override
  void didUpdateWidget(covariant _ReportMeasurementView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldContractId = oldWidget.contractData.id?.trim() ?? '';
    final newContractId = widget.contractData.id?.trim() ?? '';

    if (oldWidget.tenantId != widget.tenantId ||
        oldContractId != newContractId) {
      _configureRepositories();

      setState(() {
        _dfdData = null;
        _valorDemanda = 0.0;
        _totalAditivos = 0.0;
        _payments = <ReportPaidData>[];
        _selectedIndex = null;
        _selectedMeasurement = null;
        _sideItems = <Attachment>[];
        _selectedSideIndex = null;
        formValidated = false;
      });

      _loadDfdAggregatesAndPayments();
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
        'tenantId é obrigatório para carregar medições.',
      );
    }

    _dfdRepository = DfdRepository(
      tenantId: tenantId,
    );

    _paymentRepository = ReportPaidRepository(
      tenantId: tenantId,
    );

    _additivesRepository = AdditivesRepository(
      tenantId: tenantId,
    );
  }

  Future<void> _loadDfdAggregatesAndPayments() async {
    await Future.wait([
      _loadDfdAndAggregates(),
      _loadPaymentsForContract(),
    ]);
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
      debugPrint('Falha ao carregar pagamentos do contrato em medições: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _payments = <ReportPaidData>[];
      });
    }
  }

  Future<void> _loadDfdAndAggregates() async {
    final contractId = _contractId;

    if (contractId.isEmpty) return;

    DfdData? dfd;
    double valorDemanda = 0.0;
    double totalAditivos = 0.0;

    try {
      dfd = await _dfdRepository.readDataForContract(contractId);
      valorDemanda = dfd?.valorDemanda ?? 0.0;
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD do contrato em medições: $e');
      debugPrintStack(stackTrace: stack);
      valorDemanda = 0.0;
    }

    try {
      final list = await _additivesRepository.ensureForContract(contractId);

      totalAditivos = list.fold<double>(
        0.0,
            (previousTotal, item) {
          return previousTotal + (item.additiveValue ?? 0.0);
        },
      );
    } catch (e, stack) {
      debugPrint('Falha ao carregar aditivos do contrato em medições: $e');
      debugPrintStack(stackTrace: stack);
      totalAditivos = 0.0;
    }

    if (!mounted) return;

    setState(() {
      _dfdData = dfd;
      _valorDemanda = valorDemanda;
      _totalAditivos = totalAditivos;
    });
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return v;
  }

  double _totalPaymentValue(ReportPaidData payment) {
    return _positive(payment.paymentValue) +
        _positive(payment.inssPaymentValue) +
        _positive(payment.irpfPaymentValue) +
        _positive(payment.issPaymentValue);
  }

  double _sumPaymentsTotal(List<ReportPaidData> payments) {
    return payments.fold<double>(
      0.0,
          (previousTotal, payment) {
        return previousTotal + _totalPaymentValue(payment);
      },
    );
  }

  List<ReportPaidData> _paymentsForMeasurement(
      ReportExecutedData measurement,
      ) {
    final measurementId = measurement.id?.trim() ?? '';
    final measurementOrder = measurement.order;

    return _payments.where((payment) {
      final paymentMeasurementId = payment.measurementId?.trim() ?? '';

      if (measurementId.isNotEmpty && paymentMeasurementId == measurementId) {
        return true;
      }

      if (paymentMeasurementId.isEmpty &&
          measurementOrder != null &&
          payment.measurementOrder == measurementOrder) {
        return true;
      }

      if (measurementId.isEmpty &&
          measurementOrder != null &&
          payment.measurementOrder == measurementOrder) {
        return true;
      }

      return false;
    }).toList();
  }

  List<double> _buildPaymentValuesForMeasurements(
      List<ReportExecutedData> measurements,
      ) {
    return measurements.map((measurement) {
      final list = _paymentsForMeasurement(measurement);

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
      kind: NotificationMeasurementKind.bulletin,
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
      measurementId:
      extra['measurementId']?.toString() ?? _selectedMeasurement?.id,
      measurementNumber: extra['measurementProcess']?.toString() ??
          _selectedMeasurement?.numberprocess,
      measurementOrder: extra['measurementOrder']?.toString() ??
          _selectedMeasurement?.order?.toString(),
      measurementDate: _selectedMeasurement?.date,
      measurementValue: _selectedMeasurement?.value,
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
      debugPrint('Falha ao enviar notificação de medição: $e');
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

  int _nextAvailableOrder(List<ReportExecutedData> list) {
    final existing = list
        .map((item) => item.order ?? 0)
        .where((order) => order > 0)
        .toSet();

    if (existing.isEmpty) return 1;

    for (int i = 1; i <= existing.length + 1; i++) {
      if (!existing.contains(i)) return i;
    }

    final max = existing.reduce((a, b) => a > b ? a : b);

    return max + 1;
  }

  void _fillFieldsFromMeasurement(
      List<ReportExecutedData> all,
      ReportExecutedData? measurement,
      int? index,
      ) {
    _selectedMeasurement = measurement;
    _selectedIndex = index;

    if (measurement == null) {
      final next = _nextAvailableOrder(all);

      orderCtrl.text = next.toString();
      processCtrl.clear();
      valueCtrl.clear();
      dateCtrl.clear();

      setState(() {
        _sideItems = <Attachment>[];
        _selectedSideIndex = null;
      });

      _validateForm();
      return;
    }

    orderCtrl.text = (measurement.order ?? '').toString();
    processCtrl.text = measurement.numberprocess ?? '';
    valueCtrl.text = SipGedFormatMoney.brlNoSymbol(measurement.value);

    if (measurement.date != null) {
      final d = measurement.date!;

      dateCtrl.text =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else {
      dateCtrl.clear();
    }

    final attachments = measurement.attachments ?? <Attachment>[];

    setState(() {
      _sideItems = List<Attachment>.from(attachments);
      _selectedSideIndex = attachments.isNotEmpty ? 0 : null;
    });

    _validateForm();
  }

  void _applySideItemsFromWidget(List<dynamic> newItems) {
    final onlyAttachments = newItems.whereType<Attachment>().toList();

    setState(() {
      _sideItems = List<Attachment>.from(onlyAttachments);

      if (_sideItems.isEmpty) {
        _selectedSideIndex = null;
      } else {
        final index = _selectedSideIndex ?? 0;
        _selectedSideIndex = index.clamp(0, _sideItems.length - 1).toInt();
      }

      if (_selectedMeasurement != null) {
        _selectedMeasurement!.attachments =
        _sideItems.isEmpty ? null : List<Attachment>.from(_sideItems);
      }
    });
  }

  Future<void> _removeAttachmentAt(int index) async {
    if (index < 0 || index >= _sideItems.length) return;

    final cubit = context.read<ReportExecutedCubit>();

    if (!cubit.canEditContract(widget.contractData)) {
      await _safeNotify(
        title: 'Sem permissão para remover anexo',
        subtitle: _contractSummary,
        details: 'Você não possui permissão de edição neste contrato.',
        status: NotificationStatus.error,
      );
      return;
    }

    final ok = await confirmDialog(
      context,
      'Remover este arquivo?',
    );

    if (!ok) return;

    final measurement = _selectedMeasurement;

    if (measurement == null ||
        measurement.id == null ||
        measurement.id!.trim().isEmpty) {
      return;
    }

    final attachment = _sideItems[index];

    try {
      await cubit.deleteAttachment(
        contract: widget.contractData,
        contractId: _contractId,
        measurementId: measurement.id!,
        attachment: attachment,
      );

      if (!mounted) return;

      setState(() {
        _sideItems.removeAt(index);

        if (_sideItems.isEmpty) {
          _selectedSideIndex = null;
        } else {
          _selectedSideIndex = index.clamp(0, _sideItems.length - 1).toInt();
        }

        _selectedMeasurement!.attachments =
        _sideItems.isEmpty ? null : List<Attachment>.from(_sideItems);
      });

      final actorName = _currentActorLabel();

      await _safeNotify(
        title: 'Arquivo removido da medição',
        subtitle: _contractSummary,
        details: '${attachment.label} removido por $actorName.',
        status: NotificationStatus.warning,
        saveInBell: true,
        sendPush: true,
        extra: <String, dynamic>{
          'action': 'measurement_attachment_deleted',
          'measurementId': measurement.id,
          'measurementOrder': measurement.order,
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


  @override
  Widget build(BuildContext context) {
    final contractId = _contractId;

    return BlocConsumer<ReportExecutedCubit, ReportExecutedState>(
      listener: (context, state) {
        if (state.status != ReportExecutedStatus.success) return;

        final list = state.measurements;

        if (_selectedMeasurement == null) {
          _fillFieldsFromMeasurement(list, null, null);
          return;
        }

        final index = list.indexWhere(
              (item) => item.id == _selectedMeasurement!.id,
        );

        if (index >= 0) {
          _fillFieldsFromMeasurement(list, list[index], index);
        } else {
          _fillFieldsFromMeasurement(list, null, null);
        }
      },
      builder: (context, state) {
        final cubit = context.read<ReportExecutedCubit>();
        final navigator = Navigator.of(context);

        if (state.status == ReportExecutedStatus.loading &&
            state.measurements.isEmpty) {
          return const Center(
            child: LoadingTreeDots(size: 110),
          );
        }

        if (state.status == ReportExecutedStatus.failure) {
          return Center(
            child: Text(
              state.error ?? 'Erro ao carregar medições.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final measurements = state.measurements;
        final uploading = state.uploading;
        final uploadProgress = state.uploadProgress;

        final canCreate = cubit.canCreateContract(widget.contractData);
        final canEdit = cubit.canEditContract(widget.contractData);
        final canDelete = cubit.canDeleteContract(widget.contractData);

        final formEditable = _selectedMeasurement == null ? canCreate : canEdit;

        final canEditAttachments = _selectedMeasurement != null &&
            _selectedMeasurement?.id != null &&
            _selectedMeasurement!.id!.trim().isNotEmpty &&
            canEdit;

        final labels = measurements
            .map((measurement) => (measurement.order ?? 0).toString())
            .toList();

        final values = measurements
            .map((measurement) => measurement.value ?? 0.0)
            .toList();

        final measurementIds = measurements
            .map((measurement) => measurement.id?.trim() ?? '')
            .toList();

        final measurementOrders = measurements
            .map((measurement) => measurement.order)
            .toList();

        final paymentValues = _buildPaymentValuesForMeasurements(measurements);

        final totalMedicoes = cubit.sum(measurements);
        final totalPagamentos = _sumPaymentsTotal(_payments);

        final totalDisponivel = _valorDemanda + _totalAditivos;
        final saldo = totalDisponivel - totalMedicoes;

        final selectedIndex = _selectedIndex;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(text: 'Gráfico das medições'),
                        ReportExecutedGraph(
                          labels: labels,
                          values: values,
                          measurementIds: measurementIds,
                          measurementOrders: measurementOrders,
                          payments: _payments,
                          paymentValues: paymentValues,
                          totalPagamentos: totalPagamentos,
                          valorTotal: totalDisponivel,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: selectedIndex,
                          onSelectIndex: (index) {
                            if (index < 0 || index >= measurements.length) {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });

                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );

                              return;
                            }

                            final measurement = measurements[index];

                            setState(() {
                              _selectedIndex = index;
                              _selectedMeasurement = measurement;
                            });

                            _fillFieldsFromMeasurement(
                              measurements,
                              measurement,
                              index,
                            );
                          },
                        ),
                        const SectionTitle(
                          text: 'Cadastrar medições no sistema',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ReportExecutedForm(
                            isEditable: formEditable,
                            formValidated: formValidated,
                            selectedReportMeasurement: _selectedMeasurement,
                            currentReportMeasurementId:
                            _selectedMeasurement?.id,
                            contractData: widget.contractData,
                            orderController: orderCtrl,
                            processNumberController: processCtrl,
                            dateController: dateCtrl,
                            valueController: valueCtrl,
                            sideLoading: uploading,
                            sideUploadProgress: uploadProgress,
                            onPaymentsChanged: _loadPaymentsForContract,
                            onClear: () {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });

                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );
                            },
                            onAddSideItem: canEditAttachments
                                ? () async {
                              final measurement = _selectedMeasurement;

                              if (measurement == null ||
                                  measurement.id == null ||
                                  measurement.id!.trim().isEmpty) {
                                await _safeNotify(
                                  title: 'Salve a medição primeiro',
                                  subtitle: _contractSummary,
                                  details:
                                  'Depois você poderá anexar arquivos.',
                                  status: NotificationStatus.info,
                                );
                                return;
                              }

                              try {
                                final attachment =
                                await cubit.pickAndUploadAttachment(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  measurementId: measurement.id!,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _sideItems = [
                                    ..._sideItems,
                                    attachment,
                                  ];
                                  _selectedSideIndex =
                                      _sideItems.length - 1;
                                  _selectedMeasurement!.attachments =
                                  List<Attachment>.from(_sideItems);
                                });

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Arquivo anexado à medição',
                                  subtitle: _contractSummary,
                                  details:
                                  '${attachment.label} anexado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'measurement_attachment_created',
                                    'measurementId': measurement.id,
                                    'measurementOrder':
                                    measurement.order,
                                    'attachmentLabel': attachment.label,
                                    'attachmentUrl': attachment.url,
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
                            onSave: () async {
                              if (!formEditable) {
                                await _safeNotify(
                                  title: 'Sem permissão para salvar medição',
                                  subtitle: _contractSummary,
                                  details:
                                  'Você não possui permissão para criar ou editar medição neste contrato.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              final ok = await confirmDialog(
                                context,
                                'Deseja salvar esta medição?',
                              );

                              if (!ok) return;

                              final date = _parseDate(dateCtrl.text);

                              if (date == null) {
                                await _safeNotify(
                                  title: 'Data da medição inválida',
                                  subtitle: _contractSummary,
                                  details: 'Use o formato dd/MM/aaaa.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              if (contractId.isEmpty) {
                                await _safeNotify(
                                  title: 'Contrato inválido',
                                  subtitle: _contractSummary,
                                  details:
                                  'Não foi possível identificar o contrato.',
                                  status: NotificationStatus.error,
                                );
                                return;
                              }

                              if (!mounted) return;

                              setState(() => _isSaving = true);

                              final isNew = _selectedMeasurement?.id == null;

                              final data = ReportExecutedData(
                                id: _selectedMeasurement?.id,
                                contractId: contractId,
                                order: int.tryParse(orderCtrl.text),
                                numberprocess: processCtrl.text.trim(),
                                value: _parseCurrency(valueCtrl.text),
                                date: date,
                                attachments: _sideItems.isEmpty
                                    ? null
                                    : List<Attachment>.from(_sideItems),
                              );

                              try {
                                await cubit.saveOrUpdate(
                                  contract: widget.contractData,
                                  data: data,
                                );

                                await _loadPaymentsForContract();

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: isNew
                                      ? 'Medição criada'
                                      : 'Medição atualizada',
                                  subtitle: _contractSummary,
                                  details: isNew
                                      ? 'Boletim ${data.order ?? '-'} criado por $actorName.'
                                      : 'Boletim ${data.order ?? '-'} atualizado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action': isNew
                                        ? 'measurement_created'
                                        : 'measurement_updated',
                                    'measurementId':
                                    data.id ?? _selectedMeasurement?.id,
                                    'measurementOrder': data.order,
                                    'measurementProcess': data.numberprocess,
                                    'measurementValue': data.value,
                                    'measurementDate':
                                    data.date?.toIso8601String(),
                                  },
                                );
                              } catch (e) {
                                await _safeNotify(
                                  title: 'Erro ao salvar medição',
                                  subtitle: _contractSummary,
                                  details: '$e',
                                  status: NotificationStatus.error,
                                  duration: const Duration(seconds: 6),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                            onOpenMemoDeCalculo: null,
                            onOpenBoletimDeMedicao: () async {
                              final measurement = _selectedMeasurement;

                              if (measurement == null ||
                                  measurement.id == null ||
                                  measurement.id!.trim().isEmpty) {
                                await _safeNotify(
                                  title: 'Selecione uma medição',
                                  subtitle: _contractSummary,
                                  details:
                                  'Selecione ou salve uma medição para abrir o boletim.',
                                  status: NotificationStatus.info,
                                );
                                return;
                              }

                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => CreateDetailedReportPage(
                                    titulo:
                                    'Boletim ${measurement.order ?? '-'}',
                                    contractData: widget.contractData,
                                    measurement: measurement,
                                  ),
                                ),
                              );
                            },
                            sideItems: _sideItems,
                            selectedSideIndex: _selectedSideIndex,
                            onTapSideItem: (index) {
                              setState(() => _selectedSideIndex = index);
                            },
                            onDeleteSideItem:
                            canEditAttachments ? _removeAttachmentAt : null,
                            onSideItemsChanged: canEditAttachments
                                ? _applySideItemsFromWidget
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

                              final measurement = _selectedMeasurement;

                              if (measurement == null ||
                                  measurement.id == null ||
                                  measurement.id!.trim().isEmpty) {
                                return false;
                              }

                              try {
                                await cubit.renameAttachmentLabel(
                                  contract: widget.contractData,
                                  contractId: contractId,
                                  measurementId: measurement.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                final actorName = _currentActorLabel();

                                await _safeNotify(
                                  title: 'Anexo de medição renomeado',
                                  subtitle: _contractSummary,
                                  details:
                                  '${newItem.label} renomeado por $actorName.',
                                  status: NotificationStatus.success,
                                  saveInBell: true,
                                  sendPush: true,
                                  extra: <String, dynamic>{
                                    'action':
                                    'measurement_attachment_renamed',
                                    'measurementId': measurement.id,
                                    'measurementOrder': measurement.order,
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
                          ),
                        ),
                        const SectionTitle(
                          text: 'Medições cadastradas no sistema',
                        ),
                        ReportExecutedTable(
                          onTapItem: (ReportExecutedData data) {
                            final index = measurements.indexWhere(
                                  (item) => item.id == data.id,
                            );

                            if (index < 0) return;

                            setState(() {
                              _selectedIndex = index;
                              _selectedMeasurement = data;
                            });

                            _fillFieldsFromMeasurement(
                              measurements,
                              data,
                              index,
                            );
                          },
                          onDelete: (id) async {
                            if (!canDelete) {
                              await _safeNotify(
                                title: 'Sem permissão para apagar medição',
                                subtitle: _contractSummary,
                                details:
                                'Você não possui permissão de exclusão neste contrato.',
                                status: NotificationStatus.error,
                              );
                              return;
                            }

                            final ok = await confirmDialog(
                              context,
                              'Deseja realmente apagar esta medição?',
                            );

                            if (!ok) return;

                            if (contractId.isEmpty) {
                              await _safeNotify(
                                title: 'Contrato inválido',
                                subtitle: _contractSummary,
                                details:
                                'Não foi possível identificar o contrato.',
                                status: NotificationStatus.error,
                              );
                              return;
                            }

                            if (!mounted) return;

                            final deletedMeasurement = measurements.firstWhere(
                                  (item) => item.id == id,
                              orElse: () => ReportExecutedData(id: id),
                            );

                            setState(() => _isSaving = true);

                            try {
                              await cubit.delete(
                                contract: widget.contractData,
                                contractId: contractId,
                                measurementId: id,
                              );

                              await _loadPaymentsForContract();

                              final actorName = _currentActorLabel();

                              await _safeNotify(
                                title: 'Medição apagada',
                                subtitle: _contractSummary,
                                details: deletedMeasurement.order != null
                                    ? 'Boletim ${deletedMeasurement.order} removido por $actorName.'
                                    : 'Boletim removido por $actorName.',
                                status: NotificationStatus.warning,
                                saveInBell: true,
                                sendPush: true,
                                extra: <String, dynamic>{
                                  'action': 'measurement_deleted',
                                  'measurementId': id,
                                  'measurementOrder': deletedMeasurement.order,
                                  'measurementProcess':
                                  deletedMeasurement.numberprocess,
                                  'measurementValue': deletedMeasurement.value,
                                  'measurementDate': deletedMeasurement.date
                                      ?.toIso8601String(),
                                },
                              );
                            } catch (e) {
                              await _safeNotify(
                                title: 'Erro ao apagar medição',
                                subtitle: _contractSummary,
                                details: '$e',
                                status: NotificationStatus.error,
                                duration: const Duration(seconds: 6),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
                              }
                            }

                            if (!mounted) return;

                            if (_selectedMeasurement?.id == id) {
                              setState(() {
                                _selectedIndex = null;
                                _selectedMeasurement = null;
                              });

                              _fillFieldsFromMeasurement(
                                measurements,
                                null,
                                null,
                              );
                            }
                          },
                          measurementsData: measurements,
                          payments: _payments,
                          valorInicial: _valorDemanda,
                          valorAditivos: _totalAditivos,
                          valorTotal: totalDisponivel,
                          saldo: saldo,
                          contractData: widget.contractData,
                          selectedMeasurement: _selectedMeasurement,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            if (_isSaving || uploading)
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