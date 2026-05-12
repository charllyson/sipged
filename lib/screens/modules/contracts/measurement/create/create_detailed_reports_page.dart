// lib/screens/modules/contracts/measurement/create/create_detailed_reports_page.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_data.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';

import 'package:sipged/_blocs/system/notification/helpers/notification_measurements.dart';
import 'package:sipged/_blocs/system/notification/notification_delivery.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/table/magic/magic_adapter.dart';
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';
import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;

import 'package:sipged/screens/modules/contracts/measurement/create/launcher_pdf.dart';
import 'package:sipged/screens/modules/contracts/measurement/create/measurement_report_header.dart';

import 'package:sipged/_services/pdf/pdf_preview_launcher_stub.dart'
if (dart.library.html)
'package:sipged/_services/pdf/pdf_preview_launcher_web.dart';

class CreateDetailedReportPage extends StatefulWidget {
  const CreateDetailedReportPage({
    super.key,
    required this.titulo,
    required this.contractData,
    this.measurement,
  });

  final String titulo;
  final ContractData contractData;
  final ReportExecutedData? measurement;

  @override
  State<CreateDetailedReportPage> createState() {
    return _CreateDetailedReportPageState();
  }
}

class _CreateDetailedReportPageState extends State<CreateDetailedReportPage> {
  final bc.MagicTableController _ctrl = bc.MagicTableController(
    cellPadHorizontal: const EdgeInsets.symmetric(horizontal: 12).horizontal,
  );

  late final String _tenantId;
  late final DfdRepository _dfdRepository;
  late final BudgetCubit _budgetCubit;

  bool _loading = true;
  String? _error;

  DfdData? _dfdData;

  final Map<String, Map<String, dynamic>> _items = <String, Map<String, dynamic>>{};
  final Map<String, double> _lastSavedPeriod = <String, double>{};

  static const String _kItemKey = 'item_key';
  static const String _kQtyPrev = 'qty_prev';
  static const String _kQtyPeriod = 'qty_period';
  static const String _kQtyAccum = 'qty_accum';
  static const String _kQtySaldo = 'qty_saldo';
  static const String _kValPrev = 'val_prev';
  static const String _kValPeriod = 'val_period';
  static const String _kValAccum = 'val_accum';
  static const String _kValSaldo = 'val_saldo';

  int _idxQtdContrato = -1;
  int _idxPU = -1;
  int _idxQtyPrev = -1;
  int _idxQtyPeriod = -1;

  Timer? _debounceSave;

  bool _hasPendingMeasurementChanges = false;
  DateTime? _lastPushNotificationAt;

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

    final permissionState = context.read<PermissionCubit>().state;

    _tenantId = _resolveRequiredTenantId(permissionState);

    _dfdRepository = DfdRepository(
      tenantId: _tenantId,
    );

    _budgetCubit = BudgetCubit(
      repository: BudgetRepository(
        //tenantId: _tenantId,
      ),
    );

    _bootstrap();
  }

  @override
  void dispose() {
    _debounceSave?.cancel();
    _ctrl.removeListener(_onControllerChanged);
    _budgetCubit.close();
    super.dispose();
  }

  String _resolveRequiredTenantId(PermissionState permissionState) {
    final tenantId = permissionState.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw ArgumentError(
        'tenantId é obrigatório para CreateDetailedReportPage.',
      );
    }

    return tenantId;
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
      debugPrint('Falha ao carregar DFD no boletim detalhado: $e');
      debugPrintStack(stackTrace: stack);
    }
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
            meta['nomeCompleto'] ??
            meta['nome'] ??
            '')
            .toString()
            .trim();

        if (fullName.isNotEmpty) return fullName;

        final name = (meta['name'] ?? meta['nome'] ?? '').toString().trim();

        final surname =
        (meta['surname'] ?? meta['sobrenome'] ?? '').toString().trim();

        final composed = <String>[
          name,
          surname,
        ].where((item) => item.trim().isNotEmpty).join(' ').trim();

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

  List<String> _contractNotificationRecipients({
    required String? currentUserId,
  }) {
    final current = currentUserId?.trim();
    final ids = <String>{};

    for (final entry in widget.contractData.permissionContractId.entries) {
      final userId = entry.key.trim();

      if (userId.isEmpty) continue;

      final perms = entry.value;

      final canRead = perms['read'] == true ||
          perms['view'] == true ||
          perms['create'] == true ||
          perms['edit'] == true ||
          perms['update'] == true ||
          perms['delete'] == true ||
          perms['admin'] == true ||
          perms['owner'] == true;

      if (!canRead) continue;

      if (current != null && current.isNotEmpty && userId == current) {
        continue;
      }

      ids.add(userId);
    }

    for (final userId in widget.contractData.participantsInfo.keys) {
      final clean = userId.trim();

      if (clean.isEmpty) continue;

      if (current != null && current.isNotEmpty && clean == current) {
        continue;
      }

      ids.add(clean);
    }

    return ids.toList();
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
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
    bool saveInBell = false,
    bool sendPush = false,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) async {
    if (!mounted) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid.trim();

    final actorName = _resolveActorName(currentUserId);

    final recipients = _contractNotificationRecipients(
      currentUserId: currentUserId,
    );

    final measurement = widget.measurement;

    final delivery = saveInBell || sendPush
        ? NotificationDelivery.localBellAndPush
        : NotificationDelivery.localOnly;

    await NotificationMeasurements.show(
      context: context,
      contract: widget.contractData,
      title: title,
      subtitle: subtitle,
      details: details ?? _contractSummary,
      leadingLabel: 'Boletim',
      module: 'contracts_measurement_report',
      kind: NotificationMeasurementKind.bulletin,
      status: type,
      duration: duration,
      saveInBell: saveInBell,
      sendPush: sendPush,
      actorId: currentUserId,
      actorName: actorName,
      targetUserIds: recipients,
      includeCurrentUser: true,
      delivery: delivery,
      measurementId: extra['measurementId']?.toString() ?? measurement?.id,
      measurementNumber:
      extra['measurementProcess']?.toString() ?? measurement?.numberprocess,
      measurementOrder:
      extra['measurementOrder']?.toString() ?? measurement?.order?.toString(),
      measurementDate:
      _parseDateTimeFromExtra(extra['measurementDate']) ?? measurement?.date,
      measurementValue:
      _parseNumFromExtra(extra['measurementValue']) ?? measurement?.value,
      extra: <String, dynamic>{
        'tenantId': _tenantId,
        'companyId': _tenantId,
        'route': 'contracts_measurement_report',
        'module': 'contracts_measurement_report',
        'source': 'measurement_report_notification',
        'sourceKey': 'contracts_measurement_report',
        'subSource': 'contracts_measurement_report',
        'notificationSource': 'contracts_measurement_report',
        'actorId': currentUserId,
        'actorName': actorName,
        'contractId': _contractId,
        'contractNumber': _contractNumber,
        'processNumber': _contractNumber,
        'processoAdministrativo': _dfdData?.processoAdministrativo,
        'contractTitle': _contractSummary,
        'contractSummary': _contractSummary,
        'descricaoObjeto': _dfdData?.descricaoObjeto,
        'nomeDemanda': _contractSummary,
        'measurementKind': NotificationMeasurementKind.bulletin.name,
        'measurementId': measurement?.id,
        'measurementOrder': measurement?.order,
        'measurementProcess': measurement?.numberprocess,
        'measurementDate': measurement?.date?.toIso8601String(),
        'measurementValue': measurement?.value,
        ...extra,
      },
    );
  }

  Future<void> _notifyMeasurementReportChangedIfNeeded() async {
    if (!_hasPendingMeasurementChanges) return;
    if (!mounted) return;

    final measurement = widget.measurement;

    if (measurement == null ||
        measurement.id == null ||
        measurement.id!.trim().isEmpty) {
      return;
    }

    final now = DateTime.now();

    if (_lastPushNotificationAt != null) {
      final diff = now.difference(_lastPushNotificationAt!);

      if (diff.inSeconds < 30) {
        return;
      }
    }

    _lastPushNotificationAt = now;
    _hasPendingMeasurementChanges = false;

    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'Boletim de medição atualizado',
      subtitle: 'Boletim ${measurement.order ?? '-'} alterado por $actorName.',
      type: NotificationStatus.success,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'measurement_report_updated',
        'measurementId': measurement.id,
        'measurementOrder': measurement.order,
        'measurementValue': measurement.value,
        'measurementDate': measurement.date?.toIso8601String(),
      },
    );
  }

  Future<void> _notifyPdfPreviewGenerated() async {
    final measurement = widget.measurement;

    if (measurement == null ||
        measurement.id == null ||
        measurement.id!.trim().isEmpty) {
      return;
    }

    final actorName = _resolveActorName(
      FirebaseAuth.instance.currentUser?.uid,
    );

    await _notify(
      title: 'PDF do boletim gerado',
      subtitle:
      'Boletim ${measurement.order ?? '-'} pré-visualizado por $actorName.',
      type: NotificationStatus.info,
      saveInBell: true,
      sendPush: true,
      extra: <String, dynamic>{
        'action': 'measurement_report_pdf_previewed',
        'measurementId': measurement.id,
        'measurementOrder': measurement.order,
      },
    );
  }

  Future<void> _notifyWarning(String message) async {
    await _notify(
      title: 'Atenção',
      subtitle: message,
      type: NotificationStatus.warning,
      saveInBell: false,
      sendPush: false,
    );
  }

  Future<void> _notifyError(String message) async {
    await _notify(
      title: 'Erro',
      subtitle: message,
      type: NotificationStatus.error,
      saveInBell: false,
      sendPush: false,
      duration: const Duration(seconds: 6),
    );
  }

  void _onControllerChanged() {
    if (!_ctrl.hasData || _idxQtyPeriod < 0) return;

    bool changed = false;

    for (int r = 1; r < _ctrl.tableData.length; r++) {
      final row = _ctrl.tableData[r];
      final itemId = row.isNotEmpty ? row[0].toString() : null;

      if (itemId == null || itemId.trim().isEmpty) continue;

      _validateAndClampPeriodIfNeeded(r);

      final period = _parseBR(_ctrl.tableData[r][_idxQtyPeriod]);
      final prev = _parseBR(_ctrl.tableData[r][_idxQtyPrev]);

      final last = _lastSavedPeriod[itemId];

      if (last == null || (period - last).abs() > 1e-9) {
        _persistMeasurementItem(
          itemId,
          prev: prev,
          period: period,
        );

        _lastSavedPeriod[itemId] = period;
        changed = true;
      }
    }

    if (changed) {
      _hasPendingMeasurementChanges = true;
    }

    _scheduleSaveBreakdown();
    _updateMeasurementValueFromGrid();
  }

  Future<void> _persistMeasurementItem(
      String budgetItemId, {
        required double prev,
        required double period,
      }) async {
    final contractId = widget.contractData.id?.trim();
    final measurementId = widget.measurement?.id?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (measurementId == null || measurementId.isEmpty) return;

    final accum = prev + period;

    final rowIndex = _ctrl.tableData.indexWhere(
          (row) => row.isNotEmpty && row[0] == budgetItemId,
    );

    final qtdContrato = _qtdContratoRowRobusto(rowIndex);
    final saldoQtd = (qtdContrato - accum).clamp(0.0, double.infinity);

    final pu = (() {
      if (_idxPU >= 0 &&
          rowIndex >= 0 &&
          rowIndex < _ctrl.tableData.length &&
          _idxPU < _ctrl.tableData[rowIndex].length) {
        return _parseBR(_ctrl.tableData[rowIndex][_idxPU]);
      }

      return 0.0;
    })();

    final valPrev = prev * pu;
    final valPeriod = period * pu;
    final valAccum = accum * pu;
    final valBal = saldoQtd * pu;

    final payload = <String, dynamic>{
      'tenantId': _tenantId,
      'companyId': _tenantId,
      'contractId': contractId,
      'measurementId': measurementId,
      'budgetItemId': budgetItemId,
      'qtyPrev': prev,
      'qtyPeriod': period,
      'qtyAccum': accum,
      'qtyContractBal': saldoQtd,
      'valPrev': valPrev,
      'valPeriod': valPeriod,
      'valAccum': valAccum,
      'valContractBal': valBal,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    };

    _items[budgetItemId] = <String, dynamic>{
      ...(_items[budgetItemId] ?? <String, dynamic>{}),
      ...payload,
    };
  }

  Future<void> _saveBreakdownFromController() async {
    final contractId = widget.contractData.id?.trim();
    final measurementId = widget.measurement?.id?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (measurementId == null || measurementId.isEmpty) return;

    MagicAdapter.buildDomainFromController(controller: _ctrl);

    await _notifyMeasurementReportChangedIfNeeded();
  }

  void _scheduleSaveBreakdown() {
    _debounceSave?.cancel();

    _debounceSave = Timer(
      const Duration(milliseconds: 900),
          () async {
        await _saveBreakdownFromController();
      },
    );
  }

  Future<void> _updateMeasurementValueFromGrid() async {
    final contractId = widget.contractData.id?.trim();
    final measurementId = widget.measurement?.id?.trim();

    if (contractId == null || contractId.isEmpty) return;
    if (measurementId == null || measurementId.isEmpty) return;

    _ctrl.sumByKey(_kValPeriod);
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _loadDfdDisplayData();

      final contractId = widget.contractData.id?.trim();

      if (contractId == null || contractId.isEmpty) {
        throw Exception('Contrato sem ID.');
      }

      await _budgetCubit.ensureFor(contractId);

      final BudgetData? budget = _budgetCubit.state.dataFor(contractId);

      if (budget == null || budget.isEmpty) {
        _ctrl.loadFromSnapshot(
          table: const <List<String>>[<String>[]],
          colTypesAsString: const <String>[],
          widths: const <double>[],
        );
      } else {
        MagicAdapter.loadControllerFromDomain(
          controller: _ctrl,
          data: budget,
        );
      }

      _applySchemaWithGroups();
      _hydrateQuantitiesFromItems();

      _ctrl.addListener(_onControllerChanged);
    } catch (e) {
      _error = 'Falha ao carregar dados: $e';
      await _notifyError(_error!);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _parseBR(String value) {
    return _ctrl.parseBR(value) ?? 0.0;
  }

  int _findHeaderIndexLoose(List<String> candidates) {
    String norm(String value) {
      final up = value.toUpperCase().trim();

      const from = 'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
      const to = 'AAAAAEEEEIIIIOOOOOUUUUC';

      var out = up;

      for (int i = 0; i < from.length; i++) {
        out = out.replaceAll(from[i], to[i]);
      }

      out = out.replaceAll(RegExp(r'[^A-Z0-9]'), '');

      return out;
    }

    final headersNorm = _ctrl.headers.map(norm).toList();
    final candsNorm = candidates.map(norm).toList();

    for (final candidate in candsNorm) {
      final index = headersNorm.indexOf(candidate);

      if (index >= 0) return index;
    }

    for (int i = 0; i < headersNorm.length; i++) {
      for (final candidate in candsNorm) {
        if (headersNorm[i].contains(candidate)) return i;
      }
    }

    for (int i = 0; i < headersNorm.length; i++) {
      for (final candidate in candsNorm) {
        if (candidate.contains(headersNorm[i])) return i;
      }
    }

    return -1;
  }

  double _qtdContratoRowRobusto(int row) {
    if (_idxQtdContrato >= 0 &&
        row >= 0 &&
        row < _ctrl.tableData.length &&
        _idxQtdContrato < _ctrl.tableData[row].length) {
      final q = _parseBR(_ctrl.tableData[row][_idxQtdContrato]);

      if (q > 0) return q.toDouble();
    }

    final idxTotalContrato = _findHeaderIndexLoose(
      <String>[
        'Total (R\$)',
        'Total R\$',
        'Total',
      ],
    );

    final idxPUlocal = (_idxPU >= 0)
        ? _idxPU
        : _findHeaderIndexLoose(
      <String>[
        'Unitário (UN)',
        'Unitário',
        'Preço Unitário',
        'Preco Unitario',
        'Preço (R\$)',
        'PU',
        'Unitário (R\$)',
      ],
    );

    final total = (idxTotalContrato >= 0 &&
        row >= 0 &&
        row < _ctrl.tableData.length &&
        idxTotalContrato < _ctrl.tableData[row].length)
        ? _parseBR(_ctrl.tableData[row][idxTotalContrato])
        : 0.0;

    final pu = (idxPUlocal >= 0 &&
        row >= 0 &&
        row < _ctrl.tableData.length &&
        idxPUlocal < _ctrl.tableData[row].length)
        ? _parseBR(_ctrl.tableData[row][idxPUlocal])
        : 0.0;

    if (total > 0 && pu > 0) {
      return (total / pu).toDouble();
    }

    return 0.0;
  }

  void _validateAndClampPeriodIfNeeded(int row) {
    if (_idxQtyPeriod < 0) return;
    if (_idxQtyPrev < 0) return;

    if (row < 0 || row >= _ctrl.tableData.length) return;
    if (_idxQtyPeriod >= _ctrl.tableData[row].length) return;
    if (_idxQtyPrev >= _ctrl.tableData[row].length) return;

    final qtyStr = _ctrl.tableData[row][_idxQtyPeriod];
    final qty = _parseBR(qtyStr);

    final qtdContrato = _qtdContratoRowRobusto(row);

    final prevStr = _ctrl.tableData[row][_idxQtyPrev];
    final prev = _parseBR(prevStr);

    final saldoDisponivel = (qtdContrato - prev).clamp(
      0.0,
      double.infinity,
    );

    if (qty > saldoDisponivel) {
      final novo = saldoDisponivel;

      _ctrl.setCellValue(
        row,
        _idxQtyPeriod,
        _ctrl.formatNumberBR(
          novo,
          decimals: 2,
          trimZeros: true,
        ),
      );

      _notifyWarning(
        'A quantidade medida não pode ultrapassar o saldo do contrato '
            '(${_ctrl.formatNumberBR(saldoDisponivel, decimals: 2)}).',
      );
    }

    _ctrl.recomputeRow(row);
  }

  void _applySchemaWithGroups() {
    if (!_ctrl.hasData) return;

    final legacyCols = <bc.ColumnMeta>[];

    for (int c = 0; c < _ctrl.colCount; c++) {
      final title = (c < _ctrl.headers.length)
          ? _ctrl.headers[c]
          : _ctrl.excelColName(c);

      final key = (c == 0) ? _kItemKey : 'legacy_$c';

      legacyCols.add(
        bc.ColumnMeta(
          key: key,
          title: title,
          type: bc.ColumnType.text,
          editable: false,
          group: 'CONTRATO',
        ),
      );
    }

    _idxQtdContrato = _findHeaderIndexLoose(
      <String>[
        'Quantidade',
        'Quantidade do contrato',
        'Qtde Contratada',
      ],
    );

    _idxPU = _findHeaderIndexLoose(
      <String>[
        'Unitário',
        'Preço Unitário',
        'PU',
        'Unitário (R\$)',
      ],
    );

    double unitPriceRow(int row) {
      if (_idxPU >= 0 &&
          row >= 0 &&
          row < _ctrl.tableData.length &&
          _idxPU < _ctrl.tableData[row].length) {
        final value = _parseBR(_ctrl.tableData[row][_idxPU]);

        if (value > 0) return value.toDouble();
      }

      return 0.0;
    }

    final metas = <bc.ColumnMeta>[
      ...legacyCols,
      bc.ColumnMeta(
        key: _kQtyPrev,
        title: 'Acumulado Anterior',
        type: bc.ColumnType.number,
        editable: false,
        group: 'QUANTIDADE',
      ),
      bc.ColumnMeta(
        key: _kQtyPeriod,
        title: 'Medido no Período',
        type: bc.ColumnType.number,
        editable: true,
        group: 'QUANTIDADE',
        normalizeOnCommit: (raw) {
          final d = _ctrl.parseBR(raw) ?? 0.0;

          return _ctrl.formatNumberBR(
            d,
            decimals: 2,
            trimZeros: true,
          );
        },
      ),
      bc.ColumnMeta(
        key: _kQtyAccum,
        title: 'Acumulado Atual',
        type: bc.ColumnType.number,
        editable: false,
        group: 'QUANTIDADE',
        compute: (row, values, ctrl) {
          final prev =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;

          final period =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;

          return ctrl.formatNumberBR(
            prev + period,
            decimals: 2,
            trimZeros: true,
          );
        },
      ),
      bc.ColumnMeta(
        key: _kQtySaldo,
        title: 'Saldo do Contrato',
        type: bc.ColumnType.number,
        editable: false,
        group: 'QUANTIDADE',
        compute: (row, values, ctrl) {
          final accum =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyAccum)]) ?? 0.0;

          final qtdC = _qtdContratoRowRobusto(row);
          final saldo = qtdC - accum;

          return ctrl.formatNumberBR(
            saldo,
            decimals: 2,
            trimZeros: true,
          );
        },
      ),
      bc.ColumnMeta(
        key: _kValPrev,
        title: 'Acumulado Anterior',
        type: bc.ColumnType.money,
        editable: false,
        group: 'VALOR',
        compute: (row, values, ctrl) {
          final prev =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;

          final pu = unitPriceRow(row);

          return ctrl.formatMoneyBR(prev * pu);
        },
      ),
      bc.ColumnMeta(
        key: _kValPeriod,
        title: 'Medido no Período',
        type: bc.ColumnType.money,
        editable: false,
        group: 'VALOR',
        compute: (row, values, ctrl) {
          final periodQty =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;

          final pu = unitPriceRow(row);

          return ctrl.formatMoneyBR(periodQty * pu);
        },
      ),
      bc.ColumnMeta(
        key: _kValAccum,
        title: 'Acumulado Atual',
        type: bc.ColumnType.money,
        editable: false,
        group: 'VALOR',
        compute: (row, values, ctrl) {
          final prev =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;

          final period =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;

          final pu = unitPriceRow(row);

          return ctrl.formatMoneyBR((prev + period) * pu);
        },
      ),
      bc.ColumnMeta(
        key: _kValSaldo,
        title: 'Saldo do Contrato',
        type: bc.ColumnType.money,
        editable: false,
        group: 'VALOR',
        compute: (row, values, ctrl) {
          final pu = unitPriceRow(row);
          final qtdContrato = _qtdContratoRowRobusto(row);

          final accumQty =
              ctrl.parseBR(values[ctrl.colIndexByKey(_kQtyAccum)]) ?? 0.0;

          final saldoVal = (qtdContrato - accumQty) * pu;

          return ctrl.formatMoneyBR(saldoVal);
        },
      ),
    ];

    _ctrl.setSchema(
      schema: metas,
      setHeaderFromSchema: true,
    );

    _idxQtyPrev = _ctrl.colIndexByKey(_kQtyPrev);
    _idxQtyPeriod = _ctrl.colIndexByKey(_kQtyPeriod);
  }

  void _hydrateQuantitiesFromItems() {
    if (!_ctrl.hasData || _idxQtyPrev < 0 || _idxQtyPeriod < 0) return;

    for (int r = 1; r < _ctrl.tableData.length; r++) {
      final row = _ctrl.tableData[r];
      final itemId = row.isNotEmpty ? row[0] : null;

      if (itemId == null) continue;

      final saved = _items[itemId];

      if (saved == null) continue;

      final prevRaw = saved['qtyPrev'];
      final periodRaw = saved['qtyPeriod'];

      final prev = prevRaw is num ? prevRaw.toDouble() : 0.0;
      final period = periodRaw is num ? periodRaw.toDouble() : 0.0;

      _ctrl.setCellValue(
        r,
        _idxQtyPrev,
        _ctrl.formatNumberBR(
          prev,
          decimals: 2,
          trimZeros: true,
        ),
      );

      _ctrl.setCellValue(
        r,
        _idxQtyPeriod,
        _ctrl.formatNumberBR(
          period,
          decimals: 2,
          trimZeros: true,
        ),
      );

      _lastSavedPeriod[itemId] = period;
    }

    _ctrl.recomputeAll();
  }

  @override
  Widget build(BuildContext context) {
    final Widget table = _loading
        ? const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Carregando boletim de medição...'),
          SizedBox(height: 12),
          LoadingTreeDots(
            size: 56,
            centered: false,
          ),
        ],
      ),
    )
        : (_error != null
        ? Center(
      child: Text(
        _error!,
        textAlign: TextAlign.center,
      ),
    )
        : MagicTableChanged(
      controller: _ctrl,
      onInit: (_) async {},
      selectAllOnEdit: false,
      bottomScrollGap: 0,
      rightScrollGap: 0,
      allowAddColumn: false,
      allowRemoveColumn: false,
      allowAddRow: false,
      useExternalVScroll: true,
    ));

    return Scaffold(
      appBar: UpBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: CircleButtonChange(
            icon: Icons.close,
          ),
        ),
        titleWidgets: [
          Text(widget.titulo),
        ],
        actions: [
          IconButton(
            tooltip: 'Pré-visualizar PDF',
            onPressed: () async {
              try {
                final navigator = Navigator.of(context);

                final bytes = await buildPdfBytes(
                  ctrl: _ctrl,
                  contractData: widget.contractData,
                  measurement: widget.measurement,
                );

                if (!mounted) return;

                await launchPdfPreview(
                  navigator.context,
                  bytes,
                  fileName: 'Boletim_Medicao.pdf',
                );

                await _notifyPdfPreviewGenerated();
              } catch (e) {
                await _notifyError(
                  'Falha ao gerar pré-visualização do PDF: $e',
                );
              }
            },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const BackgroundChange(),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: MeasurementReportHeader(
                          contract: widget.contractData,
                          measurement: widget.measurement,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: table,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}