// lib/screens/modules/operation/schedule/financial/physfin_widget.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/physics_finance_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/physics_finance_repository.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/physics_finance_state.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/permission/permission_cubit.dart';
import 'package:sipged/_blocs/system/permission/permission_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'banner_tip.dart';
import 'busy_overlay.dart';
import 'measure_text.dart';
import 'percent_dialog.dart';
import 'physfin_models.dart';
import 'physfin_table.dart';

void _unawaited(Future<void> future) {}

class PhysFinWidget extends StatefulWidget {
  final ContractData contractData;
  final bool chronogramMode;

  const PhysFinWidget({
    super.key,
    required this.contractData,
    this.chronogramMode = false,
  });

  @override
  State<PhysFinWidget> createState() => _PhysFinWidgetState();
}

class _PhysFinWidgetState extends State<PhysFinWidget> {
  final NumberFormat _brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

  final Map<String, List<double>> _percentGrid = <String, List<double>>{};

  PhysicsFinanceCubit? _physicsFinanceCubit;

  String? _tenantId;
  TrData? _trData;

  bool _loadingTr = false;
  bool _saving = false;

  String get _contractId => widget.contractData.id?.trim() ?? '';

  String? _activeTenantIdOf(BuildContext context) {
    final tenantId = context.read<PermissionCubit>().state.activeTenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }

    return tenantId;
  }

  String _requireTenantId({
    required String contextName,
  }) {
    final tenantId = _tenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('tenantId é obrigatório em $contextName.');
    }

    return tenantId;
  }

  PhysicsFinanceCubit _createPhysicsFinanceCubit(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw Exception('tenantId é obrigatório para PhysicsFinanceCubit.');
    }

    return PhysicsFinanceCubit(
      tenantId: cleanTenantId,
      repository: PhysicsFinanceRepository(
        tenantId: cleanTenantId,
      ),
    );
  }

  void _initCubitFromPermission() {
    final tenantId = _activeTenantIdOf(context);

    if (tenantId == null || tenantId.isEmpty) {
      _tenantId = null;
      _physicsFinanceCubit = null;
      return;
    }

    _tenantId = tenantId;
    _physicsFinanceCubit = _createPhysicsFinanceCubit(tenantId);
  }

  @override
  void initState() {
    super.initState();

    _initCubitFromPermission();

    if (_physicsFinanceCubit != null) {
      _unawaited(_loadTrData());
    }
  }

  @override
  void didUpdateWidget(covariant PhysFinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.contractData.id != widget.contractData.id) {
      _percentGrid.clear();
      _physicsFinanceCubit?.clear();
      _unawaited(_loadTrData());
    }
  }

  @override
  void dispose() {
    _physicsFinanceCubit?.close();
    super.dispose();
  }

  void _handleTenantChanged(String? tenantId) {
    final cleanTenantId = tenantId?.trim();

    if (cleanTenantId == null || cleanTenantId.isEmpty) {
      _percentGrid.clear();

      final oldCubit = _physicsFinanceCubit;

      setState(() {
        _tenantId = null;
        _trData = null;
        _loadingTr = false;
        _physicsFinanceCubit = null;
      });

      oldCubit?.close();

      _notify(
        title: 'Empresa ativa não selecionada',
        subtitle:
        'Selecione uma empresa para carregar o planejamento físico-financeiro.',
        type: NotificationStatus.warning,
      );

      return;
    }

    try {
      final oldCubit = _physicsFinanceCubit;

      _percentGrid.clear();

      final newCubit = _createPhysicsFinanceCubit(cleanTenantId);

      setState(() {
        _tenantId = cleanTenantId;
        _trData = null;
        _loadingTr = false;
        _physicsFinanceCubit = newCubit;
      });

      oldCubit?.close();

      _unawaited(_loadTrData());
    } catch (e) {
      _notify(
        title: 'Erro ao atualizar empresa ativa',
        subtitle: e.toString(),
        type: NotificationStatus.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _loadTrData() async {
    final contractId = _contractId;

    if (contractId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _trData = null;
        _loadingTr = false;
      });

      return;
    }

    final tenantId = _tenantId?.trim();

    if (tenantId == null || tenantId.isEmpty) {
      if (!mounted) return;

      setState(() {
        _trData = null;
        _loadingTr = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingTr = true;
      });
    }

    try {
      final repository = TrRepository(
        tenantId: tenantId,
      );

      final data = await repository.readDataForContract(contractId);

      if (!mounted) return;

      setState(() {
        _trData = data;
        _loadingTr = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _trData = null;
        _loadingTr = false;
      });
    }
  }

  String _serviceKey(dynamic service) {
    try {
      final dynamic value = service.key;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.id;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.serviceKey;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    return service.hashCode.toString();
  }

  String _serviceLabel(dynamic service) {
    try {
      final dynamic value = service.labelText;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.labelSection;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.description;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.descricao;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.name;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.nome;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.serviceName;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic value = service.title;

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    final String key = _serviceKey(service);

    if (key.trim().isEmpty) {
      return 'Serviço';
    }

    return key;
  }

  void _notify({
    required String title,
    String? subtitle,
    String? details,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        details: details,
        leadingLabel: 'Físico-financeiro',
        type: type,
        duration: duration,
      ),
    );
  }

  Future<void> _notifySaved({String? detail}) async {
    if (mounted) {
      setState(() {
        _saving = true;
      });
    }

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      _notify(
        title: 'Planejamento físico-financeiro',
        subtitle: detail?.isNotEmpty == true
            ? detail!
            : 'Distribuição atualizada com sucesso.',
        type: NotificationStatus.success,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _notifySavedLite({String? detail}) async {
    _notify(
      title: 'Planejamento físico-financeiro',
      subtitle:
      detail?.isNotEmpty == true ? detail! : 'Distribuição atualizada.',
      type: NotificationStatus.success,
    );
  }

  String _titleCase(String value) {
    final String text = value.trim();

    if (text.isEmpty) return text;

    return text
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
    )
        .join(' ');
  }

  int _toIntFromText(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return 0;

    return int.tryParse(
      text.replaceAll(RegExp(r'[^\d-]'), ''),
    ) ??
        0;
  }

  int _sumExtraExecutionDays(List<AdditivesData> orderedAdds) {
    int sum = 0;

    for (final additive in orderedAdds) {
      final int days = additive.additiveValidityExecutionDays ?? 0;

      if (days > 0) {
        sum += days;
      }
    }

    return sum;
  }

  List<int> _extendPeriods(List<int> base, int extraDays) {
    if (extraDays <= 0 || base.isEmpty) return base;

    final List<int> output = List<int>.from(base);

    final int step =
    base.length >= 2 ? (base.last - base[base.length - 2]).abs() : 30;

    int acc = 0;
    int last = base.last;

    while (acc < extraDays) {
      last += step;
      output.add(last);
      acc += step;
    }

    return output;
  }

  List<int> _daysFromTr(TrData? tr) {
    final int maxDays = _toIntFromText(tr?.prazoExecucaoDias);

    if (maxDays <= 0) {
      return List<int>.generate(12, (index) => (index + 1) * 30);
    }

    final int count = (maxDays / 30).ceil();

    final List<int> base = List<int>.generate(
      count,
          (index) => (index + 1) * 30,
    );

    if (base.last != maxDays) {
      if (base.last > maxDays) {
        base[base.length - 1] = maxDays;
      } else {
        base.add(maxDays);
      }
    }

    return base;
  }

  void _syncLocalGrid({
    required Map<String, List<double>> stateGrid,
    required List<dynamic> services,
    required int periods,
    required Map<String, List<double>> localGrid,
  }) {
    for (final service in services) {
      final String key = _serviceKey(service);

      final List<double> saved = (stateGrid[key] ?? const <double>[])
          .map((value) => value.toDouble())
          .toList();

      final List<double> normalized = saved.length == periods
          ? List<double>.from(saved)
          : saved.length > periods
          ? List<double>.from(saved.take(periods))
          : <double>[
        ...saved,
        ...List<double>.filled(periods - saved.length, 0.0),
      ];

      if (!localGrid.containsKey(key)) {
        localGrid[key] = List<double>.from(normalized);
      } else if (localGrid[key]!.length != periods) {
        localGrid[key] = List<double>.from(normalized);
      }
    }
  }

  List<PhysFinRow> _buildRows({
    required List<dynamic> services,
    required Map<String, double> serviceTotals,
    required Map<String, List<double>> localGrid,
    required int periods,
  }) {
    final List<PhysFinRow> rows = <PhysFinRow>[];

    for (int index = 0; index < services.length; index++) {
      final dynamic service = services[index];

      final String key = _serviceKey(service);
      final String label = _serviceLabel(service);

      final double value = (serviceTotals[key] ?? 0.0).toDouble();

      final List<double> percents =
          localGrid[key] ?? List<double>.filled(periods, 0.0);

      rows.add(
        PhysFinRow(
          key: key,
          item: index + 1,
          descricao: label.toUpperCase(),
          valor: value,
          percent: percents,
        ),
      );
    }

    return rows;
  }

  PhysFinTotals _computeTotals({
    required List<PhysFinRow> rows,
    required int periods,
  }) {
    final List<double> parciais = List<double>.filled(periods, 0.0);

    double totalGeral = 0.0;

    for (final row in rows) {
      totalGeral += row.valor;

      for (int index = 0; index < periods; index++) {
        final double percent =
        index < row.percent.length ? row.percent[index] : 0.0;

        parciais[index] += row.valor * (percent / 100.0);
      }
    }

    final List<double> acumulados = List<double>.filled(periods, 0.0);

    double acc = 0.0;

    for (int index = 0; index < periods; index++) {
      acc += parciais[index];
      acumulados[index] = acc;
    }

    return PhysFinTotals(
      parciais: parciais,
      acumulados: acumulados,
      totalGeral: totalGeral,
    );
  }

  PhysFinTotals _computeTotalsChrono({
    required List<PhysFinRow> rows,
    required int periods,
    required List<int?> termOrders,
    required List<double> Function(
        String serviceKey, {
        int? termOrder,
        }) getPercentFor,
  }) {
    final List<double> parciais = List<double>.filled(periods, 0.0);

    double totalGeral = 0.0;

    for (final row in rows) {
      totalGeral += row.valor;

      for (int colIndex = 0; colIndex < periods; colIndex++) {
        double somaPct = 0.0;

        for (final termOrder in termOrders) {
          final List<double> percents = getPercentFor(
            row.key,
            termOrder: termOrder,
          );

          final double percent =
          colIndex < percents.length ? percents[colIndex] : 0.0;

          somaPct += percent;
        }

        parciais[colIndex] += row.valor * (somaPct / 100.0);
      }
    }

    final List<double> acumulados = List<double>.filled(periods, 0.0);

    double acc = 0.0;

    for (int index = 0; index < periods; index++) {
      acc += parciais[index];
      acumulados[index] = acc;
    }

    return PhysFinTotals(
      parciais: parciais,
      acumulados: acumulados,
      totalGeral: totalGeral,
    );
  }

  PhysFinMeasured _measureWidths({
    required BuildContext context,
    required List<PhysFinRow> rows,
    required double totalGeral,
  }) {
    final NumberFormat money = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final double measuredValueColWidth = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: <String>[
        ...rows.map((row) => money.format(row.valor)),
        money.format(totalGeral),
      ],
      style: const TextStyle(fontSize: 14),
      padding: 8 + 18,
      safety: 14,
    );

    final double measuredDescWidth = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: rows.map((row) => row.descricao).toList(),
      style: const TextStyle(fontSize: 14),
      padding: 24,
      safety: 4,
    );

    return PhysFinMeasured(
      descColWidth: math.min(400.0, measuredDescWidth),
      valueColWidth: measuredValueColWidth,
    );
  }

  PhysFinWidths _resolveColumnWidths({
    required BuildContext context,
    required bool preferFit,
    required int nCols,
    required double viewportWidth,
    required double paddingsHorizontal,
    required double measuredDescWidth,
    required double measuredValueWidth,
    double? extraColWidth,
  }) {
    const double kItemColWidth = 72.0;
    const double kPercentBarVisualWidth = 88.0;

    final String longestMoney = NumberFormat.simpleCurrency(locale: 'pt_BR')
        .format(999999999999.99);

    final double moneyCellNeeded = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: <String>[longestMoney],
      style: const TextStyle(fontSize: 12),
      padding: 20.0,
      safety: 12.0,
    );

    final double minPercentColWidthDefault =
    math.max(138.0, moneyCellNeeded + 18.0);

    final double valueColWidth = math.max(
      measuredValueWidth,
      moneyCellNeeded + 20.0,
    );

    final double extraWidth =
    extraColWidth != null && extraColWidth > 0.0 ? extraColWidth : 0.0;

    double percentCol;
    double barVisual = kPercentBarVisualWidth;

    if (preferFit) {
      final double baseWidth = viewportWidth -
          (measuredDescWidth +
              extraWidth +
              kItemColWidth +
              valueColWidth +
              paddingsHorizontal);

      final double candidate =
      nCols == 0 ? minPercentColWidthDefault : baseWidth / nCols;

      percentCol = math.max(candidate, minPercentColWidthDefault);
      barVisual = math.min(kPercentBarVisualWidth, percentCol - 18.0);
    } else {
      percentCol = minPercentColWidthDefault;
      barVisual = kPercentBarVisualWidth;
    }

    return PhysFinWidths(
      itemCol: kItemColWidth,
      descCol: measuredDescWidth,
      extraCol: extraWidth > 0.0 ? extraWidth : null,
      percentCol: percentCol,
      valueCol: valueColWidth,
      barVisual: barVisual,
    );
  }

  Future<double?> _pickPercentDialog({
    required BuildContext context,
    required double current,
    required double alreadyAllocatedPercent,
    required double serviceTotalReais,
  }) {
    return showPhysFinPercentDialog(
      context: context,
      current: current,
      alreadyAllocatedPercent: alreadyAllocatedPercent,
      serviceTotalReais: serviceTotalReais,
    );
  }

  Future<void> _bootstrapTerms({
    required String contractId,
    required int periods,
  }) async {
    if (!widget.chronogramMode) return;
    if (contractId.trim().isEmpty) return;

    _requireTenantId(contextName: 'PhysFinWidget._bootstrapTerms');

    final cubit = _physicsFinanceCubit;

    if (cubit == null) return;

    await cubit.loadTerms(
      contractId: contractId.trim(),
      periods: periods,
    );
  }

  List<double> _getPercentsForItem(
      PhysicsFinanceState financeState,
      String itemId, {
        required int termOrder,
      }) {
    return financeState.gridByTerm[termOrder]?[itemId] ?? const <double>[];
  }

  void _ensureTermGridByRows({
    required int termOrder,
    required List<PhysFinRow> rows,
    required int periods,
  }) {
    final cubit = _physicsFinanceCubit;

    if (cubit == null) return;

    cubit.ensureTermGridRows(
      termOrder: termOrder,
      itemIds: rows.map((row) => row.key),
      periods: periods,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionCubit, PermissionState>(
      listenWhen: (previous, current) {
        return previous.activeTenantId != current.activeTenantId;
      },
      listener: (context, permissionState) {
        _handleTenantChanged(permissionState.activeTenantId);
      },
      child: _buildWithTenantCubit(context),
    );
  }

  Widget _buildWithTenantCubit(BuildContext context) {
    final cubit = _physicsFinanceCubit;

    if (cubit == null || _tenantId == null || _tenantId!.trim().isEmpty) {
      return Scaffold(
        body: Stack(
          children: const [
            BackgroundChange(),
            Center(
              child: Text(
                'Empresa ativa não selecionada.\n'
                    'Selecione uma empresa para carregar o planejamento físico-financeiro.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return BlocProvider<PhysicsFinanceCubit>.value(
      value: cubit,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    const double kCardMarginH = 40.0;

    const EdgeInsets kTablePadding = EdgeInsets.only(
      left: 10,
      right: 10,
      top: 10,
      bottom: 10,
    );

    final ScheduleRoadCubit scheduleRoadCubit = context.read<ScheduleRoadCubit>();

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundChange(),
          BlocBuilder<ScheduleRoadCubit, ScheduleRoadState>(
            buildWhen: (previous, current) {
              return previous.services != current.services ||
                  previous.serviceTotals != current.serviceTotals ||
                  previous.loadingServices != current.loadingServices ||
                  previous.physfinGrid != current.physfinGrid ||
                  previous.physfinPeriods != current.physfinPeriods;
            },
            builder: (context, roadState) {
              return BlocConsumer<PhysicsFinanceCubit, PhysicsFinanceState>(
                listenWhen: (previous, current) {
                  return previous.errorMessage != current.errorMessage &&
                      current.errorMessage != null &&
                      current.errorMessage!.isNotEmpty;
                },
                listener: (context, financeState) {
                  _notify(
                    title: 'Erro no físico-financeiro',
                    subtitle: financeState.errorMessage,
                    type: NotificationStatus.error,
                    duration: const Duration(seconds: 6),
                  );
                },
                builder: (context, financeState) {
                  final List<AdditivesData> orderedAdds =
                      financeState.additives;

                  final int termosQt = orderedAdds.length;

                  final List<String> termLabels = <String>[
                    'Contratado',
                    ...List<String>.generate(
                      termosQt,
                          (index) => '${index + 1}º Termo',
                    ),
                  ];

                  final List<String?> termSubLabels = <String?>[
                    '',
                    ...orderedAdds.map(
                          (additive) => _titleCase(
                        additive.typeOfAdditive ?? '',
                      ),
                    ),
                  ];

                  final List<int> baseDays = roadState.physfinPeriods.isNotEmpty
                      ? List<int>.from(roadState.physfinPeriods)
                      : _daysFromTr(_trData);

                  final int extraDays = widget.chronogramMode
                      ? _sumExtraExecutionDays(orderedAdds)
                      : 0;

                  final List<int> dias = widget.chronogramMode
                      ? _extendPeriods(baseDays, extraDays)
                      : baseDays;

                  final List<dynamic> services = roadState.services
                      .where((service) => _serviceKey(service) != 'geral')
                      .toList();

                  if (!roadState.loadingServices && services.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum serviço encontrado no orçamento.\n'
                            'Verifique a aba Orçamento (grupos/itens).',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  _syncLocalGrid(
                    stateGrid: roadState.physfinGrid,
                    services: services,
                    periods: dias.length,
                    localGrid: _percentGrid,
                  );

                  _unawaited(
                    _bootstrapTerms(
                      contractId: _contractId,
                      periods: dias.length,
                    ),
                  );

                  final bool waitingTerms = widget.chronogramMode &&
                      (_contractId.isEmpty ||
                          _loadingTr ||
                          !financeState.termsLoaded ||
                          financeState.isLoading);

                  if (waitingTerms) {
                    return const Center(
                      child: LoadingTreeDots(size: 110),
                    );
                  }

                  final List<PhysFinRow> dados = _buildRows(
                    services: services,
                    serviceTotals: roadState.serviceTotals,
                    localGrid: _percentGrid,
                    periods: dias.length,
                  );

                  if (widget.chronogramMode) {
                    for (final int termOrder
                    in financeState.termAdditiveId.keys) {
                      _ensureTermGridByRows(
                        termOrder: termOrder,
                        rows: dados,
                        periods: dias.length,
                      );
                    }
                  }

                  final PhysFinTotals totals = widget.chronogramMode
                      ? _computeTotalsChrono(
                    rows: dados,
                    periods: dias.length,
                    termOrders: List<int?>.generate(
                      termLabels.length,
                          (index) => index == 0 ? null : index,
                    ),
                    getPercentFor: (
                        serviceKeyOrItemId, {
                          int? termOrder,
                        }) {
                      if (termOrder == null) {
                        return _percentGrid[serviceKeyOrItemId] ??
                            const <double>[];
                      }

                      return _getPercentsForItem(
                        financeState,
                        serviceKeyOrItemId,
                        termOrder: termOrder,
                      );
                    },
                  )
                      : _computeTotals(
                    rows: dados,
                    periods: dias.length,
                  );

                  final PhysFinMeasured measured = _measureWidths(
                    context: context,
                    rows: dados,
                    totalGeral: totals.totalGeral,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      const double kExtraCol = 120.0;

                      final double contentViewport =
                          constraints.maxWidth - kCardMarginH;

                      final bool preferFit = !widget.chronogramMode &&
                          constraints.maxWidth >= 1280 &&
                          (dias.isEmpty || dias.last <= 365);

                      final PhysFinWidths widths = _resolveColumnWidths(
                        context: context,
                        preferFit: preferFit,
                        nCols: dias.length,
                        viewportWidth: contentViewport,
                        paddingsHorizontal: kTablePadding.horizontal,
                        measuredDescWidth: measured.descColWidth,
                        measuredValueWidth: measured.valueColWidth,
                        extraColWidth:
                        widget.chronogramMode ? kExtraCol : null,
                      );

                      final double tableWidth = widths.itemCol +
                          widths.descCol +
                          (widths.extraCol ?? 0.0) +
                          dias.length * widths.percentCol +
                          widths.valueCol;

                      final Widget table = PhysFinTable(
                        chronogramMode: widget.chronogramMode,
                        termLabels: termLabels,
                        termSubLabels: termSubLabels,
                        additives: orderedAdds,
                        days: dias,
                        rows: dados,
                        totals: totals,
                        widths: widths,
                        money: _brl,
                        localGrid: _percentGrid,
                        getPercentFor: (
                            key, {
                              int? termOrder,
                            }) {
                          if (termOrder == null) {
                            return _percentGrid[key] ?? const <double>[];
                          }

                          return _getPercentsForItem(
                            financeState,
                            key,
                            termOrder: termOrder,
                          );
                        },
                        onPickPercent: (
                            serviceKey,
                            colIndex,
                            current,
                            alreadyAllocated,
                            serviceTotal,
                            ) async {
                          final double? picked = await _pickPercentDialog(
                            context: context,
                            current: current,
                            alreadyAllocatedPercent: alreadyAllocated,
                            serviceTotalReais: serviceTotal,
                          );

                          if (picked == null) return;

                          if (mounted) {
                            setState(() {
                              _percentGrid[serviceKey]![colIndex] = picked;
                            });
                          }

                          await scheduleRoadCubit.updatePhysFinGrid(
                            periods: dias,
                            grid: _percentGrid,
                          );

                          await _notifySaved(
                            detail: 'Período atualizado: ${colIndex + 1}',
                          );
                        },
                        onPickPercentForTerm: (
                            itemId,
                            colIndex,
                            current,
                            alreadyAllocated,
                            serviceTotal, {
                              required int termOrder,
                            }) async {
                          final double? picked = await _pickPercentDialog(
                            context: context,
                            current: current,
                            alreadyAllocatedPercent: alreadyAllocated,
                            serviceTotalReais: serviceTotal,
                          );

                          if (picked == null) return;

                          final cubit = _physicsFinanceCubit;

                          if (cubit == null) {
                            throw Exception(
                              'PhysicsFinanceCubit não inicializado.',
                            );
                          }

                          await cubit.updatePercentForTerm(
                            contractId: _contractId,
                            termOrder: termOrder,
                            itemId: itemId,
                            colIndex: colIndex,
                            value: picked,
                            periods: dias,
                          );

                          await _notifySavedLite(
                            detail:
                            'Período atualizado (Termo $termOrder): ${colIndex + 1}',
                          );
                        },
                        pickBarColors: ({int? termOrder}) {
                          if (!widget.chronogramMode) {
                            return (
                            fill: AdditivesData.contractedColor,
                            track: AdditivesData.trackColor,
                            disabled: false,
                            );
                          }

                          if (termOrder == null) {
                            return (
                            fill: const Color(0xFFBDBDBD),
                            track: AdditivesData.trackColor,
                            disabled: true,
                            );
                          }

                          final Color color =
                          AdditivesData.colorForOrder(termOrder);

                          return (
                          fill: color,
                          track: AdditivesData.trackColor,
                          disabled: false,
                          );
                        },
                      );

                      final Widget tableRegion = Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kCardMarginH / 2,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: kTablePadding,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: math.max(
                                  tableWidth,
                                  constraints.maxWidth -
                                      kCardMarginH -
                                      kTablePadding.horizontal,
                                ),
                              ),
                              child: table,
                            ),
                          ),
                        ),
                      );

                      final Widget banner = PhysFinBannerTip(
                        text: widget.chronogramMode
                            ? 'Edite os percentuais nas linhas dos Termos. “Contratado” está desativado.'
                            : 'Clique nas barras para alterar os percentuais de cada período.',
                      );

                      final Widget verticalScroll = SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 18),
                            banner,
                            const SizedBox(height: 6),
                            tableRegion,
                          ],
                        ),
                      );

                      final bool isBusy =
                          (roadState.loadingServices && services.isEmpty) ||
                              _loadingTr ||
                              _saving ||
                              financeState.isSaving;

                      return Stack(
                        children: [
                          verticalScroll,
                          if (isBusy)
                            PhysFinBusyOverlay(
                              saving: _saving || financeState.isSaving,
                              textWhenBusy: 'Carregando planejamento...',
                              textWhenSaving: 'Salvando planejamento...',
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}