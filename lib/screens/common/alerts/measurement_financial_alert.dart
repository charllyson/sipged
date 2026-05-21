import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_repository.dart';

import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_data.dart';
import 'package:sipged/_blocs/modules/financial/payments/report/report_paid_repository.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class MeasurementFinancialAlert extends StatefulWidget {
  const MeasurementFinancialAlert({
    super.key,
    required this.contract,
    this.dfdData,
  });

  final ContractData contract;
  final DfdData? dfdData;

  static void clearCache() {
    _MeasurementFinancialAlertState.clearCache();
  }

  @override
  State<MeasurementFinancialAlert> createState() {
    return _MeasurementFinancialAlertState();
  }
}

class _MeasurementFinancialAlertState extends State<MeasurementFinancialAlert>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static final Map<String, Future<_MeasurementFinancialAlertInfo?>>
  _futureCache = <String, Future<_MeasurementFinancialAlertInfo?>>{};

  static final Map<String, _MeasurementFinancialAlertInfo?> _resultCache =
  <String, _MeasurementFinancialAlertInfo?>{};

  static final Map<String, DfdRepository> _dfdRepoByTenant =
  <String, DfdRepository>{};

  static final Map<String, AdditivesRepository> _additivesRepoByTenant =
  <String, AdditivesRepository>{};

  static final Map<String, ApostillesRepository> _apostillesRepoByTenant =
  <String, ApostillesRepository>{};

  static final Map<String, ReportExecutedRepository> _measurementsRepoByTenant =
  <String, ReportExecutedRepository>{};

  static final Map<String, ReportPaidRepository> _paymentsRepoByTenant =
  <String, ReportPaidRepository>{};

  static final Map<String, AdjustmentMeasurementRepository>
  _adjustmentsRepoByTenant = <String, AdjustmentMeasurementRepository>{};

  static final Map<String, RevisionMeasurementRepository>
  _revisionsRepoByTenant = <String, RevisionMeasurementRepository>{};

  static void clearCache() {
    _futureCache.clear();
    _resultCache.clear();

    _dfdRepoByTenant.clear();
    _additivesRepoByTenant.clear();
    _apostillesRepoByTenant.clear();
    _measurementsRepoByTenant.clear();
    _paymentsRepoByTenant.clear();
    _adjustmentsRepoByTenant.clear();
    _revisionsRepoByTenant.clear();
  }

  final GlobalKey _buttonKey = GlobalKey();
  final ValueNotifier<int> _balloonTick = ValueNotifier<int>(0);

  late final AnimationController _positionWatcher;
  late Future<_MeasurementFinancialAlertInfo?> _future;

  OverlayEntry? _entry;
  Offset? _initialAnchor;

  String? _activeTenantId;
  String? _activeContractId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final permissionState = context.read<PermissionCubit>().state;

    _activeTenantId = _cleanNullableTenantId(permissionState.activeTenantId);
    _activeContractId = _cleanNullableContractId(widget.contract.id);

    _future = _getCachedFuture(
      contract: widget.contract,
      tenantId: _activeTenantId,
      dfdData: widget.dfdData,
    );

    _positionWatcher = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_watchAnchorPosition);
  }

  @override
  void didUpdateWidget(covariant MeasurementFinancialAlert oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextContractId = _cleanNullableContractId(widget.contract.id);

    final contractChanged = _activeContractId != nextContractId;
    final dfdChanged = oldWidget.dfdData != widget.dfdData;

    if (!contractChanged && !dfdChanged) {
      return;
    }

    _removeOverlay();

    _activeContractId = nextContractId;

    _future = _getCachedFuture(
      contract: widget.contract,
      tenantId: _activeTenantId,
      dfdData: widget.dfdData,
      preferProvidedData: true,
    );
  }

  @override
  void dispose() {
    _removeOverlay();

    _positionWatcher.removeListener(_watchAnchorPosition);
    _positionWatcher.dispose();

    _balloonTick.dispose();

    super.dispose();
  }

  String? _cleanNullableTenantId(String? tenantId) {
    final clean = tenantId?.trim();

    if (clean == null || clean.isEmpty) {
      return null;
    }

    return clean;
  }

  String? _cleanNullableContractId(String? contractId) {
    final clean = contractId?.trim();

    if (clean == null || clean.isEmpty) {
      return null;
    }

    return clean;
  }

  String? _cacheKey({
    required String? tenantId,
    required String? contractId,
  }) {
    final cleanTenantId = _cleanNullableTenantId(tenantId);
    final cleanContractId = _cleanNullableContractId(contractId);

    if (cleanTenantId == null || cleanContractId == null) {
      return null;
    }

    return '$cleanTenantId::$cleanContractId';
  }

  DfdRepository _dfdRepository(String tenantId) {
    return _dfdRepoByTenant.putIfAbsent(
      tenantId,
          () => DfdRepository(
        tenantId: tenantId,
      ),
    );
  }

  AdditivesRepository _additivesRepository(String tenantId) {
    return _additivesRepoByTenant.putIfAbsent(
      tenantId,
          () => AdditivesRepository(
        tenantId: tenantId,
      ),
    );
  }

  ApostillesRepository _apostillesRepository(String tenantId) {
    return _apostillesRepoByTenant.putIfAbsent(
      tenantId,
          () => ApostillesRepository(
        tenantId: tenantId,
      ),
    );
  }

  ReportExecutedRepository _measurementsRepository(String tenantId) {
    return _measurementsRepoByTenant.putIfAbsent(
      tenantId,
          () => ReportExecutedRepository(
        tenantId: tenantId,
      ),
    );
  }

  ReportPaidRepository _paymentsRepository(String tenantId) {
    return _paymentsRepoByTenant.putIfAbsent(
      tenantId,
          () => ReportPaidRepository(
        tenantId: tenantId,
      ),
    );
  }

  AdjustmentMeasurementRepository _adjustmentsRepository(String tenantId) {
    return _adjustmentsRepoByTenant.putIfAbsent(
      tenantId,
          () => AdjustmentMeasurementRepository(
        tenantId: tenantId,
      ),
    );
  }

  RevisionMeasurementRepository _revisionsRepository(String tenantId) {
    return _revisionsRepoByTenant.putIfAbsent(
      tenantId,
          () => RevisionMeasurementRepository(
        tenantId: tenantId,
      ),
    );
  }

  Future<_MeasurementFinancialAlertInfo?> _getCachedFuture({
    required ContractData contract,
    required String? tenantId,
    DfdData? dfdData,
    bool preferProvidedData = false,
  }) {
    final key = _cacheKey(
      tenantId: tenantId,
      contractId: contract.id,
    );

    if (key == null) {
      return Future<_MeasurementFinancialAlertInfo?>.value(null);
    }

    if (!preferProvidedData && _resultCache.containsKey(key)) {
      return Future<_MeasurementFinancialAlertInfo?>.value(_resultCache[key]);
    }

    if (!preferProvidedData) {
      final cachedFuture = _futureCache[key];

      if (cachedFuture != null) {
        return cachedFuture;
      }
    }

    final future = _loadInfo(
      contract: contract,
      tenantId: tenantId,
      dfdData: dfdData,
    ).then((result) {
      _resultCache[key] = result;
      return result;
    }).catchError((error) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar alerta financeiro '
            'key=$key error=$error',
      );

      _futureCache.remove(key);
      return null;
    });

    _futureCache[key] = future;

    return future;
  }

  Future<DfdData?> _loadDfd({
    required String tenantId,
    required String contractId,
    DfdData? provided,
  }) async {
    if (provided != null) {
      return provided;
    }

    try {
      return await _dfdRepository(tenantId).readDataForContract(contractId);
    } catch (error) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar DFD '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return null;
    }
  }

  Future<double> _loadAdditivesValue({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      final list = await _additivesRepository(tenantId).ensureForContract(
        contractId,
      );

      return list.fold<double>(
        0.0,
            (total, item) => total + (item.additiveValue ?? 0.0),
      );
    } catch (error) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar aditivos '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return 0.0;
    }
  }

  Future<double> _loadApostillesValue({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      final value = await _apostillesRepository(tenantId).getAllApostillesValue(
        contractId,
      );

      return value.isFinite ? value : 0.0;
    } catch (error) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar apostilamentos '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return 0.0;
    }
  }

  Future<List<ReportExecutedData>> _loadMeasurements({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _measurementsRepository(tenantId).getAllMeasurementsOfContract(
        uidContract: contractId,
      );
    } catch (error, stack) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar medições '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );
      debugPrintStack(stackTrace: stack);

      return const <ReportExecutedData>[];
    }
  }

  Future<List<AdjustmentMeasurementData>> _loadAdjustments({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _adjustmentsRepository(tenantId).getAllAdjustmentsOfContract(
        uidContract: contractId,
      );
    } catch (error, stack) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar reajustes '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );
      debugPrintStack(stackTrace: stack);

      return const <AdjustmentMeasurementData>[];
    }
  }

  Future<List<RevisionMeasurementData>> _loadRevisions({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _revisionsRepository(tenantId).getAllRevisionsOfContract(
        uidContract: contractId,
      );
    } catch (error, stack) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar revisões '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );
      debugPrintStack(stackTrace: stack);

      return const <RevisionMeasurementData>[];
    }
  }

  Future<List<ReportPaidData>> _loadPayments({
    required String tenantId,
    required String contractId,
  }) async {
    try {
      return await _paymentsRepository(tenantId).getPaymentsByContract(
        contractId: contractId,
      );
    } catch (error) {
      debugPrint(
        '[MeasurementFinancialAlert] Erro ao carregar pagamentos '
            'tenantId=$tenantId contractId=$contractId error=$error',
      );

      return const <ReportPaidData>[];
    }
  }

  double _positive(double? value) {
    final v = value ?? 0.0;

    if (!v.isFinite || v <= 0) return 0.0;

    return v;
  }

  double _retentionsValue(ReportPaidData payment) {
    return _positive(payment.inssPaymentValue) +
        _positive(payment.irpfPaymentValue) +
        _positive(payment.issPaymentValue);
  }

  double _paymentTotalValue(ReportPaidData payment) {
    return _positive(payment.paymentValue) + _retentionsValue(payment);
  }

  Future<_MeasurementFinancialAlertInfo?> _loadInfo({
    required ContractData contract,
    required String? tenantId,
    DfdData? dfdData,
  }) async {
    final cleanTenantId = _cleanNullableTenantId(tenantId);
    final cleanContractId = _cleanNullableContractId(contract.id);

    if (cleanTenantId == null || cleanContractId == null) {
      return null;
    }

    final dfd = await _loadDfd(
      tenantId: cleanTenantId,
      contractId: cleanContractId,
      provided: dfdData,
    );

    final results = await Future.wait<dynamic>([
      _loadAdditivesValue(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadApostillesValue(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadMeasurements(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadPayments(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadAdjustments(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
      _loadRevisions(
        tenantId: cleanTenantId,
        contractId: cleanContractId,
      ),
    ]);

    final valorInicial = dfd?.valorDemanda ?? 0.0;
    final valorAditivos = results[0] as double;
    final valorApostilamentos = results[1] as double;

    final measurements = results[2] as List<ReportExecutedData>;
    final payments = results[3] as List<ReportPaidData>;
    final adjustments = results[4] as List<AdjustmentMeasurementData>;
    final revisions = results[5] as List<RevisionMeasurementData>;

    final totalMedicoes = measurements.fold<double>(
      0.0,
          (total, item) => total + (item.value ?? 0.0),
    );

    final totalRetencoes = payments.fold<double>(
      0.0,
          (total, item) => total + _retentionsValue(item),
    );

    final totalPagamentos = payments.fold<double>(
      0.0,
          (total, item) => total + _paymentTotalValue(item),
    );

    final totalReajustes = adjustments.fold<double>(
      0.0,
          (total, item) => total + (item.value ?? 0.0),
    );

    final totalRevisoes = revisions.fold<double>(
      0.0,
          (total, item) => total + (item.value ?? 0.0),
    );

    final valorTotalContrato = valorInicial + valorAditivos;
    final saldoContrato = valorTotalContrato - totalMedicoes;
    final saldoMedidoNaoPago = totalMedicoes - totalPagamentos;
    final saldoApostilamento = valorApostilamentos - totalReajustes;

    final ultimaMedicao = _latestMeasurement(measurements);
    final ultimoPagamento = _latestPayment(payments);

    return _MeasurementFinancialAlertInfo(
      contractId: cleanContractId,
      tenantId: cleanTenantId,
      valorInicial: valorInicial,
      valorAditivos: valorAditivos,
      valorTotalContrato: valorTotalContrato,
      totalMedicoes: totalMedicoes,
      totalPagamentos: totalPagamentos,
      totalRetencoes: totalRetencoes,
      saldoContrato: saldoContrato,
      saldoMedidoNaoPago: saldoMedidoNaoPago,
      valorApostilamentos: valorApostilamentos,
      totalReajustes: totalReajustes,
      saldoApostilamento: saldoApostilamento,
      totalRevisoes: totalRevisoes,
      quantidadeMedicoes: measurements.length,
      quantidadePagamentos: payments.length,
      quantidadeReajustes: adjustments.length,
      quantidadeRevisoes: revisions.length,
      ultimaMedicaoOrdem: ultimaMedicao?.order,
      ultimaMedicaoValor: ultimaMedicao?.value,
      ultimaMedicaoData: ultimaMedicao?.date,
      ultimoPagamentoValor: ultimoPagamento == null
          ? null
          : _paymentTotalValue(ultimoPagamento),
      ultimoPagamentoData: ultimoPagamento?.paymentDate,
    );
  }

  ReportExecutedData? _latestMeasurement(List<ReportExecutedData> items) {
    if (items.isEmpty) return null;

    final list = List<ReportExecutedData>.from(items);

    list.sort((a, b) {
      final dateA = a.date ?? DateTime(1900);
      final dateB = b.date ?? DateTime(1900);

      final dateCompare = dateB.compareTo(dateA);

      if (dateCompare != 0) return dateCompare;

      final orderA = a.order ?? 0;
      final orderB = b.order ?? 0;

      return orderB.compareTo(orderA);
    });

    return list.first;
  }

  ReportPaidData? _latestPayment(List<ReportPaidData> items) {
    if (items.isEmpty) return null;

    final list = List<ReportPaidData>.from(items);

    list.sort((a, b) {
      final dateA = a.paymentDate ?? DateTime(1900);
      final dateB = b.paymentDate ?? DateTime(1900);

      return dateB.compareTo(dateA);
    });

    return list.first;
  }

  String _money(double? value) {
    if (value == null) return '—';

    return SipGedFormatMoney.doubleToText(value);
  }

  String _date(DateTime? value) {
    if (value == null) return '—';

    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString().padLeft(4, '0');

    return '$d/$m/$y';
  }

  String _tooltipMessage(_MeasurementFinancialAlertInfo info) {
    if (info.saldoContrato < 0) {
      return 'Medições acima do valor contratado';
    }

    if (info.saldoMedidoNaoPago > 0) {
      return 'Há medição com saldo pendente de pagamento';
    }

    if (info.quantidadeMedicoes == 0) {
      return 'Contrato sem medições cadastradas';
    }

    return 'Resumo financeiro do contrato';
  }

  IconData _iconFor(_MeasurementFinancialAlertInfo info) {
    if (info.saldoContrato < 0) {
      return Icons.warning_amber_rounded;
    }

    if (info.saldoMedidoNaoPago > 0) {
      return Icons.payments_outlined;
    }

    if (info.quantidadeMedicoes == 0) {
      return Icons.receipt_long_outlined;
    }

    return Icons.account_balance_wallet_outlined;
  }

  Color _colorFor(_MeasurementFinancialAlertInfo info) {
    if (info.saldoContrato < 0) {
      return Colors.redAccent;
    }

    if (info.saldoMedidoNaoPago > 0) {
      return Colors.orange;
    }

    if (info.quantidadeMedicoes == 0) {
      return Colors.blueGrey;
    }

    return Colors.green;
  }

  List<BalloonTileData> _itemsFor(_MeasurementFinancialAlertInfo info) {
    final statusColor = _colorFor(info);
    final statusIcon = _iconFor(info);

    final String situacao;
    if (info.saldoContrato < 0) {
      situacao = 'Medições acima do valor contratado';
    } else if (info.saldoMedidoNaoPago > 0) {
      situacao = 'Saldo medido pendente de pagamento';
    } else if (info.quantidadeMedicoes == 0) {
      situacao = 'Sem medições cadastradas';
    } else {
      situacao = 'Medições e pagamentos equilibrados';
    }

    return [
      BalloonTileData.simple(
        id: 'situacao',
        title: situacao,
        subtitle: 'Alerta financeiro da execução',
        icon: statusIcon,
        accentColor: statusColor,
        highlighted: true,
      ),
      BalloonTileData.simple(
        id: 'valor_inicial',
        title: 'Valor contratado inicial',
        subtitle: _money(info.valorInicial),
        icon: Icons.request_quote_outlined,
        accentColor: const Color(0xFF1B2031),
      ),
      BalloonTileData.simple(
        id: 'valor_aditivos',
        title: 'Valor dos aditivos',
        subtitle: _money(info.valorAditivos),
        icon: Icons.add_chart_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'valor_total',
        title: 'Valor contratado + aditivos',
        subtitle: _money(info.valorTotalContrato),
        icon: Icons.functions_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'total_medicoes',
        title: 'Total medido',
        subtitle:
        '${_money(info.totalMedicoes)} em ${info.quantidadeMedicoes} medição(ões)',
        icon: Icons.receipt_long_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'total_pagamentos',
        title: 'Total pago',
        subtitle:
        '${_money(info.totalPagamentos)} em ${info.quantidadePagamentos} pagamento(s)',
        icon: Icons.payments_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'retencoes',
        title: 'Retenções pagas',
        subtitle: _money(info.totalRetencoes),
        icon: Icons.percent_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'saldo_contrato',
        title: 'Saldo do contrato',
        subtitle: _money(info.saldoContrato),
        icon: Icons.account_balance_wallet_outlined,
        accentColor: info.saldoContrato < 0 ? Colors.redAccent : Colors.green,
      ),
      BalloonTileData.simple(
        id: 'saldo_medido_nao_pago',
        title: 'Saldo medido ainda não pago',
        subtitle: _money(info.saldoMedidoNaoPago),
        icon: Icons.pending_actions_outlined,
        accentColor:
        info.saldoMedidoNaoPago > 0 ? Colors.orange : Colors.green,
      ),
      BalloonTileData.simple(
        id: 'apostilamentos',
        title: 'Apostilamentos disponíveis',
        subtitle: _money(info.valorApostilamentos),
        icon: Icons.fact_check_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'reajustes',
        title: 'Total de reajustes',
        subtitle:
        '${_money(info.totalReajustes)} em ${info.quantidadeReajustes} reajuste(s)',
        icon: Icons.trending_up_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'saldo_apostilamento',
        title: 'Saldo do apostilamento',
        subtitle: _money(info.saldoApostilamento),
        icon: Icons.savings_outlined,
        accentColor:
        info.saldoApostilamento < 0 ? Colors.redAccent : Colors.green,
      ),
      BalloonTileData.simple(
        id: 'revisoes',
        title: 'Total de revisões',
        subtitle:
        '${_money(info.totalRevisoes)} em ${info.quantidadeRevisoes} revisão(ões)',
        icon: Icons.manage_history_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'ultima_medicao',
        title: 'Última medição',
        subtitle: info.ultimaMedicaoOrdem == null
            ? '—'
            : 'Ordem ${info.ultimaMedicaoOrdem} • ${_money(info.ultimaMedicaoValor)} • ${_date(info.ultimaMedicaoData)}',
        icon: Icons.history_outlined,
        accentColor: Colors.blueGrey,
      ),
      BalloonTileData.simple(
        id: 'ultimo_pagamento',
        title: 'Último pagamento',
        subtitle: info.ultimoPagamentoValor == null
            ? '—'
            : '${_money(info.ultimoPagamentoValor)} • ${_date(info.ultimoPagamentoData)}',
        icon: Icons.event_available_outlined,
        accentColor: Colors.blueGrey,
      ),
    ];
  }

  void _toggleOverlay(_MeasurementFinancialAlertInfo info) {
    if (_entry != null) {
      _removeOverlay();
      return;
    }

    _showOverlay(info);
  }

  Offset? _resolveButtonCenterGlobal() {
    final currentContext = _buttonKey.currentContext;

    if (currentContext == null) return null;

    final render = currentContext.findRenderObject();

    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return null;
    }

    return render.localToGlobal(
      render.size.center(Offset.zero),
    );
  }

  bool _isAnchorStillValid(Offset anchor) {
    final size = MediaQuery.of(context).size;
    final safeTop = MediaQuery.of(context).padding.top;

    const estimatedUpBarHeight = 64.0;
    final minVisibleY = safeTop + estimatedUpBarHeight;

    if (anchor.dy < minVisibleY) return false;
    if (anchor.dy > size.height - 24) return false;
    if (anchor.dx < 0) return false;
    if (anchor.dx > size.width) return false;

    return true;
  }

  void _watchAnchorPosition() {
    if (_entry == null) return;
    if (!_positionWatcher.isAnimating) return;

    final currentAnchor = _resolveButtonCenterGlobal();

    if (currentAnchor == null) {
      _removeOverlay();
      return;
    }

    if (!_isAnchorStillValid(currentAnchor)) {
      _removeOverlay();
      return;
    }

    final initialAnchor = _initialAnchor;

    if (initialAnchor == null) {
      _initialAnchor = currentAnchor;
      return;
    }

    final movedDistance = (currentAnchor - initialAnchor).distance;

    if (movedDistance > 4) {
      _removeOverlay();
      return;
    }

    _balloonTick.value++;
    _entry?.markNeedsBuild();
  }

  void _startPositionWatcher() {
    if (_positionWatcher.isAnimating) return;

    _positionWatcher.repeat();
  }

  void _stopPositionWatcher() {
    if (!_positionWatcher.isAnimating) return;

    _positionWatcher.stop();
    _positionWatcher.reset();
  }

  void _showOverlay(_MeasurementFinancialAlertInfo info) {
    final overlay = Overlay.of(context);
    final overlayRender = overlay.context.findRenderObject();

    if (overlayRender is! RenderBox) {
      return;
    }

    final initialAnchor = _resolveButtonCenterGlobal();

    if (initialAnchor == null) {
      return;
    }

    if (!_isAnchorStillValid(initialAnchor)) {
      return;
    }

    _initialAnchor = initialAnchor;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              overlayBox: overlayRender,
              globalAnchorBuilder: _resolveButtonCenterGlobal,
              rebuildListenable: _balloonTick,
              width: 370,
              maxHeight: 440,
              tipSide: BalloonTipSide.top,
              topGap: 4,
              title: 'Alerta financeiro',
              headerIcon: Icons.account_balance_wallet_outlined,
              emptyMessage: 'Nenhum dado financeiro encontrado.',
              items: _itemsFor(info),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
    _startPositionWatcher();
  }

  void _removeOverlay() {
    _stopPositionWatcher();
    _initialAnchor = null;
    _entry?.remove();
    _entry = null;
  }

  Widget _buildButton(_MeasurementFinancialAlertInfo info) {
    final color = _colorFor(info);
    final icon = _iconFor(info);

    return Tooltip(
      message: _tooltipMessage(info),
      child: SizedBox.square(
        dimension: 23,
        child: IconButton(
          key: _buttonKey,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          splashRadius: 18,
          icon: Icon(
            icon,
            color: color,
            size: 21,
          ),
          onPressed: () {
            _toggleOverlay(info);
          },
        ),
      ),
    );
  }

  Widget _buildEmptySpace() {
    return const SizedBox.square(
      dimension: 23,
    );
  }

  Widget _buildLoading() {
    return SizedBox.square(
      dimension: 23,
      child: Center(
        child: SizedBox.square(
          dimension: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blueGrey.shade400,
          ),
        ),
      ),
    );
  }

  void _reloadForPermissionState(PermissionState permissionState) {
    final nextTenantId = _cleanNullableTenantId(permissionState.activeTenantId);

    if (_activeTenantId == nextTenantId) return;

    _removeOverlay();

    setState(() {
      _activeTenantId = nextTenantId;

      _future = _getCachedFuture(
        contract: widget.contract,
        tenantId: _activeTenantId,
        dfdData: widget.dfdData,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final contractId = _cleanNullableContractId(widget.contract.id);

    if (contractId == null) {
      return _buildEmptySpace();
    }

    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        _reloadForPermissionState(permissionState);
      },
      child: FutureBuilder<_MeasurementFinancialAlertInfo?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          final info = snapshot.data;

          if (info == null) {
            return _buildEmptySpace();
          }

          return _buildButton(info);
        },
      ),
    );
  }
}

class _MeasurementFinancialAlertInfo {
  const _MeasurementFinancialAlertInfo({
    required this.contractId,
    required this.tenantId,
    required this.valorInicial,
    required this.valorAditivos,
    required this.valorTotalContrato,
    required this.totalMedicoes,
    required this.totalPagamentos,
    required this.totalRetencoes,
    required this.saldoContrato,
    required this.saldoMedidoNaoPago,
    required this.valorApostilamentos,
    required this.totalReajustes,
    required this.saldoApostilamento,
    required this.totalRevisoes,
    required this.quantidadeMedicoes,
    required this.quantidadePagamentos,
    required this.quantidadeReajustes,
    required this.quantidadeRevisoes,
    this.ultimaMedicaoOrdem,
    this.ultimaMedicaoValor,
    this.ultimaMedicaoData,
    this.ultimoPagamentoValor,
    this.ultimoPagamentoData,
  });

  final String contractId;
  final String tenantId;

  final double valorInicial;
  final double valorAditivos;
  final double valorTotalContrato;

  final double totalMedicoes;
  final double totalPagamentos;
  final double totalRetencoes;

  final double saldoContrato;
  final double saldoMedidoNaoPago;

  final double valorApostilamentos;
  final double totalReajustes;
  final double saldoApostilamento;

  final double totalRevisoes;

  final int quantidadeMedicoes;
  final int quantidadePagamentos;
  final int quantidadeReajustes;
  final int quantidadeRevisoes;

  final int? ultimaMedicaoOrdem;
  final double? ultimaMedicaoValor;
  final DateTime? ultimaMedicaoData;

  final double? ultimoPagamentoValor;
  final DateTime? ultimoPagamentoData;
}