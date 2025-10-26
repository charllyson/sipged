import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:siged/screens/process/measurement/create/launcher_pdf.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/_widgets/pdf/export_pdf_button.dart';
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

import 'package:siged/_services/pdf/pdf_preview_launcher_stub.dart'
if (dart.library.html) 'package:siged/_services/pdf/pdf_preview_launcher_web.dart';

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

  Map<String, Map<String, dynamic>> _items = {};
  final Map<String, double> _lastSavedPeriod = {};

  // keys
  static const String _kItemKey = 'item_key';
  static const String _kQtyPrev = 'qty_prev';
  static const String _kQtyPeriod = 'qty_period';
  static const String _kQtyAccum = 'qty_accum';
  static const String _kQtySaldo = 'qty_saldo';
  static const String _kValPrev = 'val_prev';
  static const String _kValPeriod = 'val_period';
  static const String _kValAccum = 'val_accum';
  static const String _kValSaldo = 'val_saldo';

  int _idxItem = 0;
  int _idxQtdContrato = -1;
  int _idxPU = -1;
  int _idxQtyPrev = -1;
  int _idxQtyPeriod = -1;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {

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

      _applySchemaWithGroups();
      _hydrateQuantitiesFromItems();
      _ctrl.addListener(_onControllerChanged);
    } catch (e) {
      _error = 'Falha ao carregar dados: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _parseBR(String s) => _ctrl.parseBR(s) ?? 0.0;

  // 🔹 detecta cabeçalhos tolerantes
  int _findHeaderIndexLoose(List<String> candidates) {
    String norm(String s) {
      final up = s.toUpperCase().trim();
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

    for (final c in candsNorm) {
      final i = headersNorm.indexOf(c);
      if (i >= 0) return i;
    }
    for (int i = 0; i < headersNorm.length; i++) {
      for (final c in candsNorm) {
        if (headersNorm[i].contains(c)) return i;
      }
    }
    for (int i = 0; i < headersNorm.length; i++) {
      for (final c in candsNorm) {
        if (c.contains(headersNorm[i])) return i;
      }
    }
    return -1;
  }

  // ✅ calcula a quantidade contratual, mesmo se coluna “Quantidade” faltar
  double _qtdContratoRowRobusto(int row) {
    if (_idxQtdContrato >= 0 &&
        row >= 0 &&
        row < _ctrl.tableData.length &&
        _idxQtdContrato < _ctrl.tableData[row].length) {
      final q = _parseBR(_ctrl.tableData[row][_idxQtdContrato]);
      if (q > 0) return q.toDouble();
    }

    final idxTotalContrato =
    _findHeaderIndexLoose(['Total (R\$)', 'Total R\$', 'Total']);
    final idxPUlocal = (_idxPU >= 0)
        ? _idxPU
        : _findHeaderIndexLoose([
      'Unitário (UN)',
      'Unitário',
      'Preço Unitário',
      'Preco Unitario',
      'Preço (R\$)',
      'PU',
      'Unitário (R\$)',
    ]);

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

    if (total > 0 && pu > 0) return (total / pu).toDouble();
    return 0.0;
  }

  // ✅ valida quantidade e recalcula valores monetários
  void _validateAndClampPeriodIfNeeded(int row) {
    if (_idxQtyPeriod < 0) return;

    final qtyStr = _ctrl.tableData[row][_idxQtyPeriod];
    final qty = _parseBR(qtyStr);
    final qtdContrato = _qtdContratoRowRobusto(row);
    final prevStr = _ctrl.tableData[row][_idxQtyPrev];
    final prev = _parseBR(prevStr);

    final saldoDisponivel = (qtdContrato - prev).clamp(0.0, double.infinity);
    if (qty > saldoDisponivel) {
      final novo = saldoDisponivel;
      _ctrl.setCellValue(
        row,
        _idxQtyPeriod,
        _ctrl.formatNumberBR(novo, decimals: 2, trimZeros: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange[700],
          content: Text(
            'A quantidade medida não pode ultrapassar o saldo do contrato (${_ctrl.formatNumberBR(saldoDisponivel, decimals: 2)}).',
          ),
        ),
      );
    }

    // atualiza valores derivados (inclui Medido no Período R$)
    _ctrl.recomputeRow(row);
  }

  void _applySchemaWithGroups() {
    if (!_ctrl.hasData) return;

    final legacyCols = <bc.ColumnMeta>[];
    for (int c = 0; c < _ctrl.colCount; c++) {
      final title =
      (c < _ctrl.headers.length) ? _ctrl.headers[c] : _ctrl.excelColName(c);
      final key = (c == 0) ? _kItemKey : 'legacy_$c';
      legacyCols.add(bc.ColumnMeta(
        key: key,
        title: title,
        type: bc.ColumnType.text,
        editable: false,
        group: 'CONTRATO',
      ));
    }

    _idxQtdContrato = _findHeaderIndexLoose(
        ['Quantidade', 'Quantidade do contrato', 'Qtde Contratada']);
    _idxPU = _findHeaderIndexLoose(
        ['Unitário', 'Preço Unitário', 'PU', 'Unitário (R\$)']);

    double _unitPriceRow(int row) {
      if (_idxPU >= 0 && _idxPU < _ctrl.tableData[row].length) {
        final v = _parseBR(_ctrl.tableData[row][_idxPU]);
        if (v > 0) return v.toDouble();
      }
      return 0.0;
    }

    final metas = <bc.ColumnMeta>[
      ...legacyCols,

      // QUANTIDADE
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
          return _ctrl.formatNumberBR(d, decimals: 2, trimZeros: true);
        },
      ),
      bc.ColumnMeta(
        key: _kQtyAccum,
        title: 'Acumulado Atual',
        type: bc.ColumnType.number,
        editable: false,
        group: 'QUANTIDADE',
        compute: (row, values, ctrl) {
          final prev = ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;
          final period = ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;
          return ctrl.formatNumberBR(prev + period, decimals: 2, trimZeros: true);
        },
      ),
      bc.ColumnMeta(
        key: _kQtySaldo,
        title: 'Saldo do Contrato',
        type: bc.ColumnType.number,
        editable: false,
        group: 'QUANTIDADE',
        compute: (row, values, ctrl) {
          final period =
              ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;
          final qtdC = _qtdContratoRowRobusto(row);
          final saldo = qtdC - period;
          return ctrl.formatNumberBR(saldo, decimals: 2, trimZeros: true);
        },
      ),

      // VALOR (R$)
      bc.ColumnMeta(
        key: _kValPrev,
        title: 'Acumulado Anterior',
        type: bc.ColumnType.money,
        editable: false,
        group: 'VALOR',
        compute: (row, values, ctrl) {//
          final prev = ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;
          final pu = _unitPriceRow(row);
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
              ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;
          final pu = _unitPriceRow(row);
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
          final prev = ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPrev)]) ?? 0.0;
          final period = ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;
          final pu = _unitPriceRow(row);
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
          final pu = _unitPriceRow(row);
          final qtdContrato = _qtdContratoRowRobusto(row);
          final periodQty =
              ctrl.parseBR(values[_ctrl.colIndexByKey(_kQtyPeriod)]) ?? 0.0;
          final saldoVal = (qtdContrato - periodQty) * pu;
          return ctrl.formatMoneyBR(saldoVal);
        },
      ),
    ];

    _ctrl.setSchema(schema: metas, setHeaderFromSchema: true);
    _idxQtyPrev = _ctrl.colIndexByKey(_kQtyPrev);
    _idxQtyPeriod = _ctrl.colIndexByKey(_kQtyPeriod);
  }

  void _hydrateQuantitiesFromItems() {
    if (!_ctrl.hasData || _idxQtyPrev < 0 || _idxQtyPeriod < 0) return;
    for (int r = 1; r < _ctrl.tableData.length; r++) {
      final itemId = _ctrl.tableData[r].isNotEmpty ? _ctrl.tableData[r][0] : null;
      if (itemId == null) continue;
      final saved = _items[itemId];
      if (saved == null) continue;

      final prev = (saved['qtyPrev'] ?? 0).toDouble();
      final period = (saved['qtyPeriod'] ?? 0).toDouble();
      _ctrl.setCellValue(r, _idxQtyPrev,
          _ctrl.formatNumberBR(prev, decimals: 2, trimZeros: true));
      _ctrl.setCellValue(r, _idxQtyPeriod,
          _ctrl.formatNumberBR(period, decimals: 2, trimZeros: true));
      _lastSavedPeriod[itemId] = period;
    }
    _ctrl.recomputeAll();
  }

  void _onControllerChanged() {
    if (!_ctrl.hasData || _idxQtyPeriod < 0) return;

    for (int r = 1; r < _ctrl.tableData.length; r++) {
      final itemId =
      (_ctrl.tableData[r].isNotEmpty) ? _ctrl.tableData[r][0].toString() : null;
      if (itemId == null) continue;

      _validateAndClampPeriodIfNeeded(r);

      final periodTxt = _ctrl.tableData[r][_idxQtyPeriod];
      final period = _parseBR(periodTxt);

      final last = _lastSavedPeriod[itemId];
      if (last == null || (period - last).abs() > 1e-9) {
        _lastSavedPeriod[itemId] = period;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = _loading
        ? const Center(
      child: Column(
        children: [
          Text('Carregando boletim de medição...'),
          SizedBox(height: 12),
          CircularProgressIndicator(),
        ],
      ),
    )
        : (_error != null
        ? Center(child: Text(_error!))
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: BackCircleButton(icon: Icons.close),
            ),
            titleWidgets: [Text(widget.titulo)],
            actions: [
              IconButton(
                tooltip: 'Pré-visualizar PDF',
                onPressed: () async {
                  final bytes = await buildPdfBytes(
                    ctrl: _ctrl,
                    contractData: widget.contractData,
                    measurement: widget.measurement,
                  );
                  await launchPdfPreview(context, bytes, fileName: 'Boletim_Medicao.pdf');
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              ),
            ],
          ),
        ),
        body: Stack(
            children: [
            const BackgroundClean(),
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
                        Padding(//
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

