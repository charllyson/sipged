import 'package:flutter/material.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

// Domain / Budget
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_blocs/process/budget/magic_budget_adapter.dart';
import 'package:siged/_blocs/process/budget/budget_bloc.dart';
import 'package:siged/_blocs/process/budget/budget_data.dart';

// MagicTable
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';
import 'package:siged/screens/process/measurement/create/measurement_report_header.dart';

import 'package:siged/_blocs/process/report/report_measurement_bloc.dart';

class CreateDetailedReportPage extends StatefulWidget {
  const CreateDetailedReportPage({
    super.key,
    required this.titulo,
    required this.contractData,
    this.measurement,
  });

  final String titulo;
  final ContractData contractData;
  final ReportMeasurementData? measurement;

  @override
  State<CreateDetailedReportPage> createState() =>
      _CreateDetailedReportPageState();
}

class _CreateDetailedReportPageState extends State<CreateDetailedReportPage> {
  final bc.MagicTableController _ctrl = bc.MagicTableController(
    cellPadHorizontal: const EdgeInsets.symmetric(horizontal: 12).horizontal,
  );

  final ReportMeasurementBloc _reportBloc = ReportMeasurementBloc();

  bool _loading = true;
  String? _error;

  final Map<String, TextEditingController> _prevCtrl = {};
  final Map<String, TextEditingController> _periodCtrl = {};
  Map<String, Map<String, dynamic>> _items = {};
  List<String> _budgetItemIds = const [];

  bool get _hasBreakdown {
    final b = widget.measurement?.breakdown;
    if (b == null || b.isEmpty) return false;
    return (b['headers'] is List) &&
        (b['colTypes'] is List) &&
        (b['colWidths'] is List) &&
        (b['rows'] is List);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    for (final c in _prevCtrl.values) c.dispose();
    for (final c in _periodCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_hasBreakdown) {
        final b = widget.measurement!.breakdown!;
        final headers =
        (b['headers'] as List).map((e) => e.toString()).toList();
        final colTypes =
        (b['colTypes'] as List).map((e) => e.toString()).toList();
        final colW = (b['colWidths'] as List)
            .map((e) =>
        (e is num) ? e.toDouble() : double.tryParse('$e') ?? 120.0)
            .toList();
        final rows = (b['rows'] as List)
            .map((r) => (r as List).map((e) => '$e').toList())
            .toList();

        _ctrl.loadFromSnapshot(
          table: [headers, ...rows],
          colTypesAsString: colTypes,
          widths: colW,
        );
      } else {
        final BudgetData budget =
        await BudgetBloc().load(widget.contractData.id!);
        if (budget.isEmpty) {
          _ctrl.loadFromSnapshot(
            table: const <List<String>>[<String>[]],
            colTypesAsString: const <String>[],
            widths: const <double>[],
          );
        } else {
          MagicBudgetAdapter.loadControllerFromDomain(
            controller: _ctrl,
            data: budget,
          );
        }
      }

      _budgetItemIds = _extractBudgetItemIdsFromController();

      if (widget.contractData.id != null && widget.measurement?.id != null) {
        _items = await _reportBloc.loadItemsMap(
          contractId: widget.contractData.id!,
          measurementId: widget.measurement!.id!,
        );
      }

      for (final id in _budgetItemIds) {
        final saved = _items[id];
        _prevCtrl[id] =
            TextEditingController(text: _numToStr(saved?['qtyPrev']));
        _periodCtrl[id] =
            TextEditingController(text: _numToStr(saved?['qtyPeriod']));
      }
    } catch (e) {
      _error = 'Falha ao carregar dados: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _numToStr(dynamic v) {
    final d = (v is num)
        ? v.toDouble()
        : (v is String ? double.tryParse(v.replaceAll(',', '.')) : null);
    if (d == null) return '';
    return d.toStringAsFixed(2);
  }

  double _parseQty(String s) => _ctrl.parseBR(s) ?? 0.0;

  List<String> _extractBudgetItemIdsFromController() {
    final rows = _ctrl.tableData;
    if (rows.isEmpty || rows.first.isEmpty) return const <String>[];
    final out = <String>[];
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;
      final key = (row.first).toString().trim();
      if (key.isNotEmpty) out.add(key);
    }
    return out;
  }

  Future<void> _onEditItem(String budgetItemId) async {
    if (widget.contractData.id == null || widget.measurement?.id == null) {
      return;
    }

    final prev = _parseQty(_prevCtrl[budgetItemId]?.text ?? '0');
    final period = _parseQty(_periodCtrl[budgetItemId]?.text ?? '0');
    final accum = prev + period;

    final payload = {
      'qtyPrev': prev,
      'qtyPeriod': period,
      'qtyAccum': accum,
    };

    await _reportBloc.upsertMeasurementItem(
      contractId: widget.contractData.id!,
      measurementId: widget.measurement!.id!,
      budgetItemId: budgetItemId,
      payload: payload,
    );

    _items[budgetItemId] = {...(_items[budgetItemId] ?? {}), ...payload};
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final table = _loading
        ? const Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Carregando boletim de medição...'),
          SizedBox(height: 12),
          CircularProgressIndicator(),
        ],
      ),
    )
        : (_error != null
        ? Center(child: Text(_error!, textAlign: TextAlign.center))
        : MagicTableChanged(
      controller: _ctrl,
      onInit: (_) async {},
      selectAllOnEdit: false,
      bottomScrollGap: 0,
      rightScrollGap: 0,

      // remove botões de +/remover
      allowAddColumn: false,
      allowRemoveColumn: false,
      allowAddRow: false,

      // 🔹 chave: desligar scroll vertical interno e usar da página
      useExternalVScroll: true,

      // ===== painel direito colado =====
      trailingCols: const [
        TrailingColMeta(
            title: 'Acumulado Anterior',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.number,
            decimals: 2
        ),
        TrailingColMeta(
            title: 'Medido no Período',
            width: 140,
            align: TextAlign.right,
            type: TrailingValueType.number,
            decimals: 2
        ),
        TrailingColMeta(
            title: 'Acumulado Atual',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.number,
            decimals: 2
        ),
        TrailingColMeta(
            title: 'Saldo do Contrato',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.number,
            decimals: 2
        ),
        TrailingColMeta(
            title: 'Acumulado Anterior',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.number,
            decimals: 2
        ),
        TrailingColMeta(
            title: 'Medido no Período',
            width: 140,
            align: TextAlign.right,
            type: TrailingValueType.money,
            moneyPrefix: 'R\$ '
        ),
        TrailingColMeta(
            title: 'Acumulado Atual',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.money,
            moneyPrefix: 'R\$ '
        ),
        TrailingColMeta(
            title: 'Saldo do Contrato',
            width: 140,
            align: TextAlign.right,
            editable: false,
            type: TrailingValueType.money,
            moneyPrefix: 'R\$ '
        ),
      ],
      trailingRowBuilder: (ctx, r) {
        final itemId =
        (r < _ctrl.tableData.length && _ctrl.tableData[r].isNotEmpty)
            ? _ctrl.tableData[r][0]
            : '';

        final saved = _items[itemId];
        final prev = saved?['qtyPrev'] ?? 0.0;
        final period = saved?['qtyPeriod'] ?? 0.0;
        final accum = (saved?['qtyAccum'] ?? (prev + period)) as num;
        final saldo = 0.0; // TODO: calcule o saldo por item

        InputDecoration _dec() => const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        );

        // campos editáveis (prev/period)
        final prevField = TextField(
          controller: _prevCtrl[itemId],
          textAlign: TextAlign.right,
          decoration: _dec(),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          onSubmitted: (_) => _onEditItem(itemId),
          onTapOutside: (_) => _onEditItem(itemId),
        );

        final periodField = TextField(
          controller: _periodCtrl[itemId],
          textAlign: TextAlign.right,
          decoration: _dec(),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          onSubmitted: (_) => _onEditItem(itemId),
          onTapOutside: (_) => _onEditItem(itemId),
        );

        Text _ro(num v) => Text(
          _ctrl.formatNumberBR(v.toDouble(), decimals: 2),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
        );

        return <Widget>[
          prevField,
          periodField,
          _ro(accum),
          _ro(saldo),
        ];
      },
    ));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: UpBar(
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: BackCircleButton(icon: Icons.close),
          ),
          titleWidgets: [Text(widget.titulo)],
        ),
      ),
      body: Stack(
        children: [
          const BackgroundClean(),
          // 🔹 Toda a página rola verticalmente
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
