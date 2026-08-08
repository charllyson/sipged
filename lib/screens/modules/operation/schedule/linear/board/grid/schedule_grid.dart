// lib/screens/modules/operation/schedule/linear/board/grid/schedule_grid.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';

import 'package:sipged/screens/modules/operation/schedule/linear/board/grid/schedule_ghost.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/board/grid/schedule_legend.dart';

class ScheduleGrid extends StatefulWidget {
  const ScheduleGrid({
    super.key,
    required this.totalEstacas,
    required this.faixas,
    required this.execIndex,
    required this.servicoSelecionado,
    required this.legendWidth,
    required this.estacaWidth,
    required this.getSquareColor,
    required this.onTapSquare,
    required this.userLabelResolver,
    this.services = const <ScheduleLinearServicesData>[],
    this.selectedByEstaca = const <int, Set<int>>{},
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
    this.rightGutter = 0,
    this.ghostWidth = 22.5,
  });

  final int totalEstacas;
  final List<ScheduleLinearLaneData> faixas;

  final Map<String, ScheduleLinearCellData> execIndex;

  final String servicoSelecionado;
  final List<ScheduleLinearServicesData> services;

  final double legendWidth;
  final double estacaWidth;
  final double ghostWidth;

  final Color Function(ScheduleLinearCellData e) getSquareColor;
  final void Function(ScheduleLinearCellData e) onTapSquare;
  final String Function(String? uid) userLabelResolver;

  final Map<int, Set<int>> selectedByEstaca;

  final void Function(int estaca, int faixaIndex)? onDragStart;
  final void Function(int estaca, int faixaIndex)? onDragUpdate;
  final VoidCallback? onDragEnd;

  final Color highlightColor;
  final double headerHeight;
  final double rightGutter;

  static const double kCellVPad = 0.5;

  @override
  State<ScheduleGrid> createState() => _ScheduleGridState();
}

enum _PointerIntent {
  none,
  selecting,
  scrolling,
}

class _ScheduleGridState extends State<ScheduleGrid> {
  static const double _dragStartThreshold = 7.0;
  static const double _tapMoveTolerance = 5.0;
  static const double _verticalScrollDominance = 1.15;
  static const double _horizontalSelectTolerance = 0.65;

  Offset? _pointerDownPosition;
  int? _pointerDownEstaca;
  int? _pointerDownFaixa;

  bool _dragStarted = false;
  _PointerIntent _pointerIntent = _PointerIntent.none;

  int? _lastSentEstaca;
  int? _lastSentFaixa;

  late List<bool> _enabledLanesCache;
  late String _enabledLanesCacheKey;

  @override
  void initState() {
    super.initState();

    _enabledLanesCacheKey = '';
    _enabledLanesCache = const <bool>[];
    _ensureEnabledLanesCache();
  }

  @override
  void didUpdateWidget(covariant ScheduleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureEnabledLanesCache();
  }

  String _cellKey({
    required String serviceKey,
    required int estaca,
    required int faixaIndex,
  }) {
    return '${serviceKey.trim()}_${faixaIndex}_$estaca';
  }

  bool _isGeralService() {
    return widget.servicoSelecionado.trim() ==
        ScheduleLinearServicesData.geralKey;
  }

  ScheduleLinearCellData? _priorityCellForGeral({
    required int estaca,
    required int faixaIndex,
  }) {
    final services = ScheduleLinearServicesData.specificSortedByLayer(
      widget.services,
    );

    for (final service in services) {
      final serviceKey = service.key.trim();

      if (serviceKey.isEmpty ||
          serviceKey == ScheduleLinearServicesData.geralKey) {
        continue;
      }

      final data = widget.execIndex[_cellKey(
        serviceKey: serviceKey,
        estaca: estaca,
        faixaIndex: faixaIndex,
      )];

      if (data == null) continue;

      if (data.isConcluido || data.isEmAndamento) {
        return data;
      }
    }

    return null;
  }

  String _makeEnabledLanesKey() {
    final lanesHash = Object.hashAll(
      widget.faixas.map(
            (lane) => Object.hash(
          lane.faixaIndex,
          lane.allowedByService,
        ),
      ),
    );

    return '${widget.servicoSelecionado}|${widget.faixas.length}|$lanesHash';
  }

  void _ensureEnabledLanesCache() {
    final key = _makeEnabledLanesKey();

    if (_enabledLanesCacheKey == key &&
        _enabledLanesCache.length == widget.faixas.length) {
      return;
    }

    _enabledLanesCacheKey = key;

    final isGeral = _isGeralService();

    _enabledLanesCache = List<bool>.generate(
      widget.faixas.length,
          (index) {
        if (isGeral) return true;

        return widget.faixas[index].isAllowed(widget.servicoSelecionado);
      },
      growable: false,
    );
  }

  bool _laneEnabledFor(int faixaIndex) {
    if (faixaIndex < 0 || faixaIndex >= _enabledLanesCache.length) {
      return true;
    }

    return _enabledLanesCache[faixaIndex];
  }

  void _resetPointerTracking() {
    _pointerDownPosition = null;
    _pointerDownEstaca = null;
    _pointerDownFaixa = null;
    _dragStarted = false;
    _pointerIntent = _PointerIntent.none;
    _lastSentEstaca = null;
    _lastSentFaixa = null;
  }

  bool _isVerticalScrollGesture(Offset delta) {
    final dx = delta.dx.abs();
    final dy = delta.dy.abs();

    if (dy < _dragStartThreshold) return false;

    return dy > dx * _verticalScrollDominance;
  }

  bool _isSelectionGesture(Offset delta) {
    final dx = delta.dx.abs();
    final dy = delta.dy.abs();

    if (delta.distance < _dragStartThreshold) return false;

    return dx >= dy * _horizontalSelectTolerance;
  }

  double _columnHeight() {
    return (widget.headerHeight +
        widget.faixas.fold<double>(
          0,
              (acc, f) {
            return acc + f.altura + ScheduleGrid.kCellVPad * 2;
          },
        ))
        .roundToDouble();
  }

  int _faixaIndexFromDy(double dy) {
    dy -= widget.headerHeight;

    if (dy < 0) return 0;
    if (widget.faixas.isEmpty) return 0;

    double acc = 0;

    for (int i = 0; i < widget.faixas.length; i++) {
      final seg = widget.faixas[i].altura + ScheduleGrid.kCellVPad * 2;

      acc += seg;

      if (dy < acc) return i;
    }

    return widget.faixas.length - 1;
  }

  ScheduleLinearCellData _defaultExec({
    required int estaca,
    required int faixaIndex,
  }) {
    return ScheduleLinearCellData(
      numero: estaca,
      faixaIndex: faixaIndex,
      serviceKey: widget.servicoSelecionado,
      status: ScheduleLinearCellStatus.aIniciar,
      comentario: null,
      createdAt: null,
      createdBy: null,
      updatedAt: null,
      updatedBy: null,
      fotos: const <String>[],
      fotosMeta: const <Map<String, dynamic>>[],
      takenAtMs: null,
    );
  }

  ScheduleLinearCellData _execFor({
    required int estaca,
    required int faixaIndex,
  }) {
    if (_isGeralService()) {
      final priority = _priorityCellForGeral(
        estaca: estaca,
        faixaIndex: faixaIndex,
      );

      if (priority != null) {
        return priority;
      }
    }

    return widget.execIndex[_cellKey(
      serviceKey: widget.servicoSelecionado,
      estaca: estaca,
      faixaIndex: faixaIndex,
    )] ??
        _defaultExec(
          estaca: estaca,
          faixaIndex: faixaIndex,
        );
  }

  @override
  Widget build(BuildContext context) {
    _ensureEnabledLanesCache();

    const double gapLegendGrid = 8.0;
    const double itemHPad = 10.0;
    const double itemVPad = 12.0;

    final double columnHeight = _columnHeight();
    final double itemExtent = columnHeight + (itemVPad * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double larguraTotal = constraints.maxWidth;

        final double larguraInterna =
        (larguraTotal - itemHPad * 2).clamp(0.0, double.infinity);

        final double ghostWidth = widget.ghostWidth;
        final double cellWidth = widget.estacaWidth;

        final double larguraUtilGridPrimeiraLinha = (larguraInterna -
            widget.legendWidth -
            gapLegendGrid -
            widget.rightGutter)
            .clamp(0.0, double.infinity);

        final double larguraRealEstacasPrimeiraLinha =
        (larguraUtilGridPrimeiraLinha - ghostWidth)
            .clamp(0.0, double.infinity);

        final int reaisPrimeiraLinha =
        (larguraRealEstacasPrimeiraLinha / cellWidth)
            .floor()
            .clamp(1, 100000);

        final double larguraUtilGridDemaisLinhas =
        (larguraInterna - widget.rightGutter).clamp(0.0, double.infinity);

        final double larguraRealEstacasDemaisLinhas =
        (larguraUtilGridDemaisLinhas - ghostWidth)
            .clamp(0.0, double.infinity);

        final int reaisDemaisLinhas =
        (larguraRealEstacasDemaisLinhas / cellWidth)
            .floor()
            .clamp(1, 100000);

        final int linhas = widget.totalEstacas <= 0
            ? 0
            : widget.totalEstacas <= reaisPrimeiraLinha
            ? 1
            : 1 +
            ((widget.totalEstacas - reaisPrimeiraLinha) /
                reaisDemaisLinhas)
                .ceil();

        if (linhas <= 0) {
          return const Center(
            child: Text(
              'Nenhuma estaca calculada para este gallery.',
              textAlign: TextAlign.center,
            ),
          );
        }

        int estacaFromRealDx(double dx, int start, int count) {
          final int col = (dx / cellWidth).floor().clamp(0, count - 1);
          final estaca = start + col + 1;

          return estaca.clamp(1, widget.totalEstacas);
        }

        return ListView.builder(
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          scrollCacheExtent: ScrollCacheExtent.pixels(itemExtent),
          itemCount: linhas,
          itemExtent: itemExtent,
          itemBuilder: (context, linhaIndex) {
            final bool showLegend = linhaIndex == 0;

            final int start = showLegend
                ? 0
                : reaisPrimeiraLinha + ((linhaIndex - 1) * reaisDemaisLinhas);

            final int reaisPorLinha =
            showLegend ? reaisPrimeiraLinha : reaisDemaisLinhas;

            final double larguraUtilGrid = showLegend
                ? larguraUtilGridPrimeiraLinha
                : larguraUtilGridDemaisLinhas;

            final double larguraRealEstacas = showLegend
                ? larguraRealEstacasPrimeiraLinha
                : larguraRealEstacasDemaisLinhas;

            final endExclusive = math.min(
              start + reaisPorLinha,
              widget.totalEstacas,
            );

            final count = endExclusive - start;

            if (count <= 0) {
              return const SizedBox.shrink();
            }

            final realGridWidth = cellWidth * count;

            final rowExecSignature = Object.hashAll(
              List<int>.generate(count, (i) {
                final estaca = start + i + 1;

                final rowItems = <ScheduleLinearCellData>[];

                for (int faixa = 0; faixa < widget.faixas.length; faixa++) {
                  final cell = _execFor(
                    estaca: estaca,
                    faixaIndex: faixa,
                  );

                  rowItems.add(cell);
                }

                return Object.hash(
                  estaca,
                  rowItems.length,
                  Object.hashAll(
                    rowItems.map(
                          (cell) => Object.hash(
                        cell.serviceKey,
                        cell.faixaIndex,
                        cell.status,
                        cell.comentario,
                        cell.fotos.length,
                        cell.updatedAt?.millisecondsSinceEpoch,
                        cell.takenAtMs,
                      ),
                    ),
                  ),
                );
              }),
            );

            final selectedSignature = Object.hashAll(
              List<int>.generate(count, (i) {
                final estaca = start + i + 1;
                final selected = widget.selectedByEstaca[estaca];

                if (selected == null || selected.isEmpty) return 0;

                return Object.hash(
                  estaca,
                  Object.hashAllUnordered(selected),
                );
              }),
            );

            final painter = _ScheduleGridLinePainter(
              serviceKey: widget.servicoSelecionado,
              services: widget.services,
              startEstaca: start + 1,
              count: count,
              cellWidth: cellWidth,
              headerHeight: widget.headerHeight,
              faixas: widget.faixas,
              enabledLanes: _enabledLanesCache,
              execIndex: widget.execIndex,
              selectedByEstaca: widget.selectedByEstaca,
              highlightColor: widget.highlightColor,
              getSquareColor: widget.getSquareColor,
              defaultExecBuilder: _defaultExec,
              rowExecSignature: rowExecSignature,
              selectedSignature: selectedSignature,
            );

            final gridPaint = SizedBox(
              width: realGridWidth,
              height: columnHeight,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: painter,
                  size: Size(realGridWidth, columnHeight),
                ),
              ),
            );

            final gridArea = SizedBox(
              width: larguraUtilGrid,
              height: columnHeight,
              child: Row(
                children: [
                  ScheduleGhost(
                    w: ghostWidth,
                    columnHeight: columnHeight,
                    headerHeight: widget.headerHeight,
                    kCellVPad: ScheduleGrid.kCellVPad,
                    faixas: widget.faixas,
                  ),
                  SizedBox(
                    width: larguraRealEstacas,
                    height: columnHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: gridPaint,
                    ),
                  ),
                ],
              ),
            );

            final gridWithInput = Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (ev) {
                if (widget.onDragStart == null) return;

                final p = ev.localPosition;
                final realDx = p.dx - ghostWidth;

                if (realDx < 0) {
                  _resetPointerTracking();
                  return;
                }

                if (p.dy <= widget.headerHeight) {
                  _resetPointerTracking();
                  return;
                }

                final faixa = _faixaIndexFromDy(p.dy);

                if (!_laneEnabledFor(faixa)) {
                  _resetPointerTracking();
                  return;
                }

                final estaca = estacaFromRealDx(realDx, start, count);

                _pointerDownPosition = p;
                _pointerDownEstaca = estaca;
                _pointerDownFaixa = faixa;
                _dragStarted = false;
                _pointerIntent = _PointerIntent.none;
                _lastSentEstaca = null;
                _lastSentFaixa = null;
              },
              onPointerMove: (ev) {
                if (widget.onDragStart == null || widget.onDragUpdate == null) {
                  return;
                }

                final startPosition = _pointerDownPosition;
                final startEstaca = _pointerDownEstaca;
                final startFaixa = _pointerDownFaixa;

                if (startPosition == null ||
                    startEstaca == null ||
                    startFaixa == null) {
                  return;
                }

                final p = ev.localPosition;
                final delta = p - startPosition;
                final realDx = p.dx - ghostWidth;

                if (_pointerIntent == _PointerIntent.scrolling) {
                  return;
                }

                if (_pointerIntent == _PointerIntent.none) {
                  if (_isVerticalScrollGesture(delta)) {
                    _pointerIntent = _PointerIntent.scrolling;
                    _dragStarted = false;
                    return;
                  }

                  if (!_isSelectionGesture(delta)) {
                    return;
                  }

                  _pointerIntent = _PointerIntent.selecting;
                }

                if (_pointerIntent != _PointerIntent.selecting) {
                  return;
                }

                if (realDx < 0) return;
                if (p.dy <= widget.headerHeight) return;

                if (!_dragStarted) {
                  if (!_laneEnabledFor(startFaixa)) return;

                  _dragStarted = true;
                  _lastSentEstaca = startEstaca;
                  _lastSentFaixa = startFaixa;

                  widget.onDragStart!(startEstaca, startFaixa);
                }

                final faixa = _faixaIndexFromDy(p.dy);

                if (!_laneEnabledFor(faixa)) return;

                final estaca = estacaFromRealDx(realDx, start, count);

                if (_lastSentEstaca == estaca && _lastSentFaixa == faixa) {
                  return;
                }

                _lastSentEstaca = estaca;
                _lastSentFaixa = faixa;

                widget.onDragUpdate!(estaca, faixa);
              },
              onPointerUp: (ev) {
                final startPosition = _pointerDownPosition;
                final startEstaca = _pointerDownEstaca;
                final startFaixa = _pointerDownFaixa;

                if (_dragStarted && _pointerIntent == _PointerIntent.selecting) {
                  widget.onDragEnd?.call();
                  _resetPointerTracking();
                  return;
                }

                final p = ev.localPosition;
                final delta =
                startPosition == null ? Offset.zero : p - startPosition;

                final canTap = startPosition != null &&
                    startEstaca != null &&
                    startFaixa != null &&
                    delta.distance <= _tapMoveTolerance &&
                    _pointerIntent != _PointerIntent.scrolling;

                if (canTap && _laneEnabledFor(startFaixa)) {
                  final exec = _execFor(
                    estaca: startEstaca,
                    faixaIndex: startFaixa,
                  );

                  widget.onTapSquare(exec);
                }

                _resetPointerTracking();
              },
              onPointerCancel: (_) {
                if (_dragStarted && _pointerIntent == _PointerIntent.selecting) {
                  widget.onDragEnd?.call();
                }

                _resetPointerTracking();
              },
              child: gridArea,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: itemVPad,
                horizontal: itemHPad,
              ),
              child: SizedBox(
                width: larguraInterna,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showLegend) ...[
                      SizedBox(
                        width: widget.legendWidth,
                        height: columnHeight,
                        child: ScheduleLegend(
                          faixas: widget.faixas,
                          legendWidth: widget.legendWidth,
                          headerHeight: widget.headerHeight,
                          columnHeight: columnHeight,
                        ),
                      ),
                      const SizedBox(width: gapLegendGrid),
                    ],
                    gridWithInput,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

typedef _DefaultExecBuilder = ScheduleLinearCellData Function({
required int estaca,
required int faixaIndex,
});

class _ScheduleGridLinePainter extends CustomPainter {
  const _ScheduleGridLinePainter({
    required this.serviceKey,
    required this.services,
    required this.startEstaca,
    required this.count,
    required this.cellWidth,
    required this.headerHeight,
    required this.faixas,
    required this.enabledLanes,
    required this.execIndex,
    required this.selectedByEstaca,
    required this.highlightColor,
    required this.getSquareColor,
    required this.defaultExecBuilder,
    required this.rowExecSignature,
    required this.selectedSignature,
  });

  final String serviceKey;
  final List<ScheduleLinearServicesData> services;
  final int startEstaca;
  final int count;
  final double cellWidth;
  final double headerHeight;
  final List<ScheduleLinearLaneData> faixas;
  final List<bool> enabledLanes;
  final Map<String, ScheduleLinearCellData> execIndex;
  final Map<int, Set<int>> selectedByEstaca;
  final Color highlightColor;
  final Color Function(ScheduleLinearCellData e) getSquareColor;
  final _DefaultExecBuilder defaultExecBuilder;
  final int rowExecSignature;
  final int selectedSignature;

  static const Color _cellBorderColor = Color(0xFFE8E8E8);
  static const Color _disabledBorderColor = Color(0xFFE0E0E0);

  String _cellKey({
    required int estaca,
    required int faixaIndex,
  }) {
    return '${serviceKey.trim()}_${faixaIndex}_$estaca';
  }

  bool _isGeralService() {
    return serviceKey.trim() == ScheduleLinearServicesData.geralKey;
  }

  ScheduleLinearCellData? _priorityCellForGeral({
    required int estaca,
    required int faixaIndex,
  }) {
    final orderedServices = ScheduleLinearServicesData.specificSortedByLayer(
      services,
    );

    for (final service in orderedServices) {
      final key = service.key.trim();

      if (key.isEmpty || key == ScheduleLinearServicesData.geralKey) continue;

      final data = execIndex['${key}_${faixaIndex}_$estaca'];

      if (data == null) continue;

      if (data.isConcluido || data.isEmAndamento) {
        return data;
      }
    }

    return null;
  }

  bool _isLaneEnabled(int faixaIndex) {
    if (faixaIndex < 0 || faixaIndex >= enabledLanes.length) {
      return true;
    }

    return enabledLanes[faixaIndex];
  }

  ScheduleLinearCellData _execFor({
    required int estaca,
    required int faixaIndex,
  }) {
    if (_isGeralService()) {
      final priority = _priorityCellForGeral(
        estaca: estaca,
        faixaIndex: faixaIndex,
      );

      if (priority != null) {
        return priority;
      }
    }

    return execIndex[_cellKey(
      estaca: estaca,
      faixaIndex: faixaIndex,
    )] ??
        defaultExecBuilder(
          estaca: estaca,
          faixaIndex: faixaIndex,
        );
  }

  double _cellHorizontalInset() {
    if (cellWidth >= 34) return 0.55;
    if (cellWidth >= 26) return 0.50;
    if (cellWidth >= 18) return 0.42;
    if (cellWidth >= 12) return 0.30;
    if (cellWidth >= 8) return 0.18;
    if (cellWidth >= 5) return 0.08;

    return 0.0;
  }

  double _cellBorderWidth() {
    if (cellWidth >= 18) return 0.8;
    if (cellWidth >= 12) return 0.65;
    if (cellWidth >= 8) return 0.45;
    if (cellWidth >= 5) return 0.30;

    return 0.0;
  }

  double _selectionStrokeWidth() {
    if (cellWidth >= 34) return 2.0;
    if (cellWidth >= 26) return 1.8;
    if (cellWidth >= 18) return 1.4;
    if (cellWidth >= 12) return 1.0;
    if (cellWidth >= 8) return 0.65;
    if (cellWidth >= 5) return 0.35;

    return 0.0;
  }

  double _selectionDeflate() {
    if (cellWidth >= 18) return 1.0;
    if (cellWidth >= 12) return 0.6;
    if (cellWidth >= 8) return 0.35;
    if (cellWidth >= 5) return 0.15;

    return 0.0;
  }

  int _headerLabelStep() {
    if (cellWidth >= 34) return 1;
    if (cellWidth >= 26) return 2;
    if (cellWidth >= 18) return 5;
    if (cellWidth >= 12) return 10;
    if (cellWidth >= 8) return 20;
    if (cellWidth >= 5) return 25;
    if (cellWidth >= 3) return 50;

    return 100;
  }

  double _headerFontSize(bool isMajor) {
    if (cellWidth >= 34) return isMajor ? 13 : 11;
    if (cellWidth >= 26) return isMajor ? 12.5 : 10.5;
    if (cellWidth >= 18) return isMajor ? 12 : 10.5;
    if (cellWidth >= 12) return isMajor ? 11.5 : 10;
    if (cellWidth >= 8) return isMajor ? 11 : 9.8;
    if (cellWidth >= 5) return isMajor ? 10.5 : 9.5;

    return isMajor ? 10 : 9;
  }

  bool _shouldRotateHeaderLabel() {
    return cellWidth < 26;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;

    final cellBorderWidth = _cellBorderWidth();

    final cellBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellBorderWidth
      ..color = _cellBorderColor;

    final selectionStrokeWidth = _selectionStrokeWidth();
    final selectionDeflate = _selectionDeflate();

    final selectionBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectionStrokeWidth
      ..color = highlightColor;

    _paintHeader(canvas);

    double y = headerHeight;

    for (int faixaIndex = 0; faixaIndex < faixas.length; faixaIndex++) {
      final lane = faixas[faixaIndex];
      final laneHeight = lane.altura;
      final enabled = _isLaneEnabled(faixaIndex);

      final cellTop = y + ScheduleGrid.kCellVPad;
      final horizontalInset = _cellHorizontalInset();

      for (int i = 0; i < count; i++) {
        final estaca = startEstaca + i;
        final x = i * cellWidth;

        final exec = _execFor(
          estaca: estaca,
          faixaIndex: faixaIndex,
        );

        final rect = Rect.fromLTWH(
          x + horizontalInset,
          cellTop,
          math.max(0, cellWidth - (horizontalInset * 2)),
          laneHeight,
        );

        if (enabled) {
          fillPaint.color = getSquareColor(exec);
          canvas.drawRect(rect, fillPaint);

          if (cellBorderWidth > 0) {
            canvas.drawRect(rect, cellBorderPaint);
          }

          final selected =
              selectedByEstaca[estaca]?.contains(faixaIndex) == true;

          if (selected && selectionStrokeWidth > 0) {
            canvas.drawRect(
              rect.deflate(selectionDeflate),
              selectionBorderPaint,
            );
          }

          _paintCellMarkers(
            canvas: canvas,
            rect: rect,
            data: exec,
          );
        } else {
          _paintDisabledCell(
            canvas: canvas,
            rect: rect,
          );
        }
      }

      y += laneHeight + ScheduleGrid.kCellVPad * 2;
    }
  }

  void _paintHeader(Canvas canvas) {
    final labelStep = _headerLabelStep();
    final rotateLabels = _shouldRotateHeaderLabel();

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;

    for (int i = 0; i < count; i++) {
      final estaca = startEstaca + i;
      final x = i * cellWidth;
      final cx = x + cellWidth / 2;

      final isMajor = estaca % 10 == 0;
      final shouldShowLabel = estaca == startEstaca || estaca % labelStep == 0;

      if (isMajor || shouldShowLabel) {
        final tickHeight = isMajor ? 8.0 : 5.0;

        canvas.drawLine(
          Offset(cx, headerHeight - tickHeight),
          Offset(cx, headerHeight),
          tickPaint,
        );
      }

      if (!shouldShowLabel) {
        continue;
      }

      final fontSize = _headerFontSize(isMajor);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$estaca',
          style: TextStyle(
            fontSize: fontSize,
            height: 1.0,
            color: isMajor ? Colors.red : Colors.grey.shade700,
            fontWeight: isMajor ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      )..layout(
        maxWidth: rotateLabels
            ? math.max(16, headerHeight - 4)
            : math.max(16, cellWidth * 2.4),
      );

      if (rotateLabels) {
        canvas.save();

        final cy = headerHeight / 2;

        canvas.translate(cx, cy);
        canvas.rotate(-math.pi / 2);

        textPainter.paint(
          canvas,
          Offset(
            -textPainter.width / 2,
            -textPainter.height / 2,
          ),
        );

        canvas.restore();
      } else {
        final left = x + (cellWidth - textPainter.width) / 2;

        textPainter.paint(
          canvas,
          Offset(
            left,
            (headerHeight - textPainter.height) / 2,
          ),
        );
      }
    }
  }

  void _paintCellMarkers({
    required Canvas canvas,
    required Rect rect,
    required ScheduleLinearCellData data,
  }) {
    final hasPhotos = data.fotos.any((url) => url.trim().isNotEmpty);
    final hasComment = data.comentario?.trim().isNotEmpty ?? false;

    if (!hasPhotos && !hasComment) return;

    final markerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.34);

    final center = rect.center;

    if (cellWidth < 5) {
      return;
    }

    if (hasPhotos) {
      final cameraWidth = cellWidth < 8 ? 5.0 : 9.0;
      final cameraHeight = cellWidth < 8 ? 4.0 : 7.0;

      final cameraRect = Rect.fromCenter(
        center: center,
        width: cameraWidth,
        height: cameraHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cameraRect,
          const Radius.circular(1.5),
        ),
        markerPaint,
      );

      if (cellWidth >= 8) {
        canvas.drawCircle(
          center,
          2.0,
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.white.withValues(alpha: 0.65),
        );

        canvas.drawRect(
          Rect.fromLTWH(
            cameraRect.left + 2,
            cameraRect.top - 2,
            4,
            2,
          ),
          markerPaint,
        );
      }

      return;
    }

    final radius = cellWidth < 8 ? 2.0 : 3.2;
    canvas.drawCircle(center, radius, markerPaint);
  }

  void _paintDisabledCell({
    required Canvas canvas,
    required Rect rect,
  }) {
    final bg = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade200;

    canvas.drawRect(rect, bg);

    if (cellWidth >= 5) {
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cellBorderWidth()
        ..color = _disabledBorderColor;

      canvas.drawRect(rect, border);
    }

    if (cellWidth < 6) {
      return;
    }

    final stripe = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.38);

    const double w = 8.0;

    for (double x = rect.left - rect.height;
    x < rect.right + rect.height;
    x += w * 2) {
      final path = Path()
        ..moveTo(x, rect.top)
        ..lineTo(x + w, rect.top)
        ..lineTo(x + w - rect.height, rect.bottom)
        ..lineTo(x - rect.height, rect.bottom)
        ..close();

      canvas.drawPath(path, stripe);
    }
  }

  @override
  bool shouldRepaint(covariant _ScheduleGridLinePainter oldDelegate) {
    return oldDelegate.serviceKey != serviceKey ||
        oldDelegate.services != services ||
        oldDelegate.startEstaca != startEstaca ||
        oldDelegate.count != count ||
        oldDelegate.cellWidth != cellWidth ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.faixas != faixas ||
        oldDelegate.enabledLanes != enabledLanes ||
        oldDelegate.execIndex != execIndex ||
        oldDelegate.selectedByEstaca != selectedByEstaca ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.rowExecSignature != rowExecSignature ||
        oldDelegate.selectedSignature != selectedSignature;
  }
}