// lib/screens/modules/contracts/measurement/report/report_measurement.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_state.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_repository.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_measurements.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';

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

  final ProcessData contractData;

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

    return BlocProvider(
      create: (context) {
        final permissionState = context.read<PermissionCubit>().state;

        return ReportExecutedCubit(
          initialPermissions: permissionState.current,
          initialTenantId: permissionState.activeTenantId,
          moduleId: 'operation_measurements',
        )..loadByContract(contractId);
      },
      child: BlocListener<PermissionCubit, PermissionState>(
        listenWhen: (previous, current) {
          return previous.current != current.current ||
              previous.activeTenantId != current.activeTenantId;
        },
        listener: (context, permissionState) {
          context.read<ReportExecutedCubit>().updatePermissions(
            permissions: permissionState.current,
            tenantId: permissionState.activeTenantId,
          );
        },
        child: _ReportMeasurementView(contractData: contractData),
      ),
    );
  }
}

class _ReportMeasurementView extends StatefulWidget {
  const _ReportMeasurementView({
    required this.contractData,
  });

  final ProcessData contractData;

  @override
  State<_ReportMeasurementView> createState() => _ReportMeasurementViewState();
}

class _ReportMeasurementViewState extends State<_ReportMeasurementView> {
  final DfdRepository _dfdRepository = DfdRepository();

  final ReportPaidRepository _paymentRepository =
  ReportPaidRepository();

  DfdData? _dfdData;

  double _valorDemanda = 0.0;
  double _totalAditivos = 0.0;

  List<ReportPaidData> _payments =
  <ReportPaidData>[];

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

    if (_contractId.isNotEmpty) return 'Contrato $_contractId';

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

    _loadDfdAggregatesAndPayments();

    orderCtrl.addListener(_validateForm);
    processCtrl.addListener(_validateForm);
    valueCtrl.addListener(_validateForm);
    dateCtrl.addListener(_validateForm);
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

  Future<void> _loadDfdAggregatesAndPayments() async {
    await Future.wait([
      _loadDfdAndAggregates(),
      _loadPaymentsForContract(),
    ]);
  }

  Future<void> _loadPaymentsForContract() async {
    final cid = _contractId;

    if (cid.isEmpty) return;

    try {
      final payments = await _paymentRepository.getPaymentsByContract(
        contractId: cid,
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
    final cid = _contractId;

    if (cid.isEmpty) return;

    DfdData? dfd;
    double valorDemanda = 0.0;
    double totalAditivos = 0.0;

    try {
      dfd = await _dfdRepository.readDataForContract(cid);
      valorDemanda = dfd?.valorDemanda ?? 0.0;
    } catch (e, stack) {
      debugPrint('Falha ao carregar DFD do contrato em medições: $e');
      debugPrintStack(stackTrace: stack);
      valorDemanda = 0.0;
    }

    try {
      final additivesRepo = AdditivesRepository();
      final list = await additivesRepo.ensureForContract(cid);

      totalAditivos = list.fold<double>(
        0.0,
            (previousTotal, item) => previousTotal + (item.additiveValue ?? 0.0),
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
          (previousTotal, payment) => previousTotal + _totalPaymentValue(payment),
    );
  }

  List<ReportPaidData> _paymentsForMeasurement(
      ReportExecutedData measurement,
      ) {
    final measurementId = measurement.id?.trim() ?? '';
    final measurementOrder = measurement.order;

    final list = _payments.where((payment) {
      final paymentMeasurementId = payment.measurementId?.trim() ?? '';

      if (measurementId.isNotEmpty && paymentMeasurementId == measurementId) {
        return true;
      }

      if (paymentMeasurementId.isEmpty &&
          measurementOrder != null &&
          payment.measurementOrder == measurementOrder) {
        return true;
      }

      return false;
    }).toList();

    return list;
  }

  List<double> _buildPaymentValuesForMeasurements(
      List<ReportExecutedData> measurements,
      ) {
    return measurements.map((measurement) {
      final list = _paymentsForMeasurement(measurement);

      return _sumPaymentsTotal(list);
    }).toList();
  }

  String _resolveActorName(String? uid) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final meta = widget.contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final fullName = (meta['fullName'] ??
            meta['displayName'] ??
            meta['nameComplete'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? '').toString().trim();
        final surname = (meta['surname'] ?? '').toString().trim();

        final composed = [name, surname]
            .where((item) => item.trim().isNotEmpty)
            .join(' ')
            .trim();

        if (composed.isNotEmpty) return composed;

        final email = (meta['email'] ?? '').toString().trim();
        if (email.isNotEmpty) return email;
      }
    }

    final displayName = currentUser?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = currentUser?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Usuário';
  }

  String _resolveActorPhotoUrl(String? uid) {
    final cleanUid = uid?.trim();

    if (cleanUid != null && cleanUid.isNotEmpty) {
      final users = context.read<UserCubit>().state.all;

      for (final item in users) {
        if ((item.uid ?? '').trim() == cleanUid) {
          final photo = item.urlPhoto?.trim() ?? '';
          if (photo.isNotEmpty) return photo;
        }
      }

      final meta = widget.contractData.participantsInfo[cleanUid];

      if (meta != null) {
        final photo = (meta['urlPhoto'] ??
            meta['photoUrl'] ??
            meta['photoURL'] ??
            meta['profilePhotoUrl'] ??
            '')
            .toString()
            .trim();

        if (photo.isNotEmpty) return photo;
      }
    }

    final firebasePhoto =
        FirebaseAuth.instance.currentUser?.photoURL?.trim() ?? '';

    if (firebasePhoto.isNotEmpty) return firebasePhoto;

    return '';
  }

  DateTime? _parseDateTimeFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;

    final parts = text.split('/');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);

        if (parsed.day == day &&
            parsed.month == month &&
            parsed.year == year) {
          return parsed;
        }
      }
    }

    return null;
  }

  num? _parseNumFromExtra(dynamic value) {
    if (value == null) return null;

    if (value is num) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final normalized = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    return num.tryParse(normalized);
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

    const route = 'operation_measurements';
    const notificationSource = 'measurements';

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();
    final actorName = _resolveActorName(currentUserId);
    final actorPhotoUrl = _resolveActorPhotoUrl(currentUserId);

    final delivery = saveInBell || sendPush
        ? NotificationDelivery.localBellAndPush
        : NotificationDelivery.localOnly;

    await NotificationMeasurements.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle ?? _contractSummary,
      details: details,
      leadingLabel: 'Medição',
      module: route,
      notificationSource: notificationSource,
      source: 'measurement_notification',
      kind: NotificationMeasurementKind.bulletin,
      status: type ?? status,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      includeCurrentUser: true,
      delivery: delivery,
      measurementId:
      extra['measurementId']?.toString() ?? _selectedMeasurement?.id,
      measurementNumber: extra['measurementProcess']?.toString() ??
          _selectedMeasurement?.numberprocess,
      measurementOrder: extra['measurementOrder']?.toString() ??
          _selectedMeasurement?.order?.toString(),
      measurementDate: _parseDateTimeFromExtra(extra['measurementDate']) ??
          _selectedMeasurement?.date,
      measurementValue: _parseNumFromExtra(extra['measurementValue']) ??
          _selectedMeasurement?.value,
      extra: <String, dynamic>{
        'route': route,
        'module': route,
        'source': 'measurement_notification',
        'sourceKey': notificationSource,
        'subSource': notificationSource,
        'notificationSource': notificationSource,
        'actorId': currentUserId,
        'actorName': actorName,
        if (actorPhotoUrl.isNotEmpty) 'actorPhotoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoUrl': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'photoURL': actorPhotoUrl,
        if (actorPhotoUrl.isNotEmpty) 'profilePhotoUrl': actorPhotoUrl,
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'processNumber': _contractNumber,
        'processoAdministrativo': _dfdData?.processoAdministrativo,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        'descricaoObjeto': _dfdData?.descricaoObjeto,
        'nomeDemanda': _contractSummary,
        'measurementKind': NotificationMeasurementKind.bulletin.name,
        ...extra,
      },
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
      setState(() => formValidated = ok);
    }
  }

  double _parseCurrency(String text) {
    return SipGedFormatMoney.parseBrl(text) ?? 0.0;
  }

  DateTime? _parseDate(String text) {
    final parts = text.split('/');

    if (parts.length != 3) return null;

    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);

    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    final date = DateTime(y, m, d);

    if (date.day != d || date.month != m || date.year != y) {
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
        _selectedSideIndex = index.clamp(0, _sideItems.length - 1);
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

    final ok = await confirmDialog(
      context,
      'Remover este arquivo?',
    );

    if (!ok) return;

    final measurement = _selectedMeasurement;

    if (measurement == null ||
        measurement.id == null ||
        measurement.id!.isEmpty) {
      return;
    }

    final attachment = _sideItems[index];

    try {
      await cubit.deleteAttachment(
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
          _selectedSideIndex = index.clamp(0, _sideItems.length - 1);
        }

        _selectedMeasurement!.attachments =
        _sideItems.isEmpty ? null : List<Attachment>.from(_sideItems);
      });

      final actorName = _resolveActorName(
        FirebaseAuth.instance.currentUser?.uid,
      );

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
                            isEditable: true,
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
                            onAddSideItem: () async {
                              final measurement = _selectedMeasurement;

                              if (measurement == null ||
                                  measurement.id == null ||
                                  measurement.id!.isEmpty) {
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
                                  contractId: contractId,
                                  measurementId: measurement.id!,
                                );

                                if (!mounted) return;

                                setState(() {
                                  _sideItems = [..._sideItems, attachment];
                                  _selectedSideIndex = _sideItems.length - 1;
                                  _selectedMeasurement!.attachments =
                                  List<Attachment>.from(_sideItems);
                                });

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

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
                                    'measurementOrder': measurement.order,
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
                            },
                            onSave: () async {
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
                                await cubit.saveOrUpdate(data);
                                await _loadPaymentsForContract();

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

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
                                    'measurementId': data.id,
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
                                  measurement.id!.isEmpty) {
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
                            onDeleteSideItem: _removeAttachmentAt,
                            onSideItemsChanged: _applySideItemsFromWidget,
                            onRenamePersist: ({
                              required int index,
                              required Attachment oldItem,
                              required Attachment newItem,
                            }) async {
                              final measurement = _selectedMeasurement;

                              if (measurement == null ||
                                  measurement.id == null ||
                                  measurement.id!.isEmpty) {
                                return false;
                              }

                              try {
                                await cubit.renameAttachmentLabel(
                                  contractId: contractId,
                                  measurementId: measurement.id!,
                                  oldItem: oldItem,
                                  newItem: newItem,
                                );

                                final actorName = _resolveActorName(
                                  FirebaseAuth.instance.currentUser?.uid,
                                );

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
                                contractId: contractId,
                                measurementId: id,
                              );

                              await _loadPaymentsForContract();

                              final actorName = _resolveActorName(
                                FirebaseAuth.instance.currentUser?.uid,
                              );

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
            if (_isSaving)
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