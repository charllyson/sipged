// lib/screens/modules/operation/schedule/grid/schedule_grid.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_utils/debug/sipged_perf_log.dart';

import 'package:sipged/screens/modules/operation/schedule/grid/schedule_ghost.dart';
import 'package:sipged/screens/modules/operation/schedule/grid/schedule_legend.dart';

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
    this.selectedByEstaca = const <int, Set<int>>{},
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.highlightColor = const Color(0xFF1E88E5),
    this.headerHeight = 25,
    this.rightGutter = 0,
  });

  final int totalEstacas;
  final List<ScheduleRoadData> faixas;
  final Map<int, Map<int, ScheduleRoadData>> execIndex;
  final String servicoSelecionado;
  final double legendWidth;
  final double estacaWidth;

  final Color Function(ScheduleRoadData e) getSquareColor;
  final void Function(ScheduleRoadData e) onTapSquare;
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

    _enabledLanesCache = List<bool>.generate(
      widget.faixas.length,
          (index) => widget.faixas[index].isAllowed(widget.servicoSelecionado),
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
            return acc + (f.altura ?? 20.0) + ScheduleGrid.kCellVPad * 2;
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
      final seg =
          (widget.faixas[i].altura ?? 20.0) + ScheduleGrid.kCellVPad * 2;

      acc += seg;

      if (dy < acc) return i;
    }

    return widget.faixas.length - 1;
  }

  ScheduleRoadData _defaultExec({
    required int estaca,
    required int faixaIndex,
  }) {
    return ScheduleRoadData(
      numero: estaca,
      faixaIndex: faixaIndex,
      tipo: widget.servicoSelecionado,
      status: 'a_iniciar',
      createdAt: null,
      comentario: null,
      key: widget.servicoSelecionado,
      label: widget.servicoSelecionado,
      icon: Icons.layers_outlined,
      color: Colors.grey,
    );
  }

  ScheduleRoadData _execFor({
    required int estaca,
    required int faixaIndex,
  }) {
    return widget.execIndex[estaca]?[faixaIndex] ??
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
        return SipGedPerfLog.measure(
          'ScheduleGrid.LayoutBuilder totalEstacas=${widget.totalEstacas} faixas=${widget.faixas.length}',
              () {
            final double larguraTotal = constraints.maxWidth;

            final double larguraInterna =
            (larguraTotal - itemHPad * 2).clamp(0.0, double.infinity);

            final double larguraUtilGrid = (larguraInterna -
                widget.legendWidth -
                gapLegendGrid -
                widget.rightGutter)
                .clamp(0.0, double.infinity);

            final int colsTotal =
            (larguraUtilGrid / widget.estacaWidth).floor().clamp(2, 100000);

            final int reaisPorLinha = (colsTotal - 1).clamp(1, 100000);

            final double cellWidth =
            colsTotal > 0 ? larguraUtilGrid / colsTotal : widget.estacaWidth;

            final int linhas = widget.totalEstacas <= 0
                ? 0
                : (widget.totalEstacas / reaisPorLinha).ceil();

            SipGedPerfLog.event(
              'ScheduleGrid metrics',
              data: <String, Object?>{
                'larguraTotal': larguraTotal,
                'larguraUtilGrid': larguraUtilGrid,
                'colsTotal': colsTotal,
                'reaisPorLinha': reaisPorLinha,
                'linhas': linhas,
                'cellWidth': cellWidth,
                'columnHeight': columnHeight,
                'itemExtent': itemExtent,
                'mode': 'custom_painter',
              },
            );

            if (linhas <= 0) {
              return const Center(
                child: Text(
                  'Nenhuma estaca calculada para este cronograma.',
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
              cacheExtent: itemExtent,
              itemCount: linhas,
              itemExtent: itemExtent,
              itemBuilder: (context, linhaIndex) {
                return SipGedPerfLog.measure(
                  'ScheduleGrid.itemBuilder linha=$linhaIndex painter',
                  warnAboveMs: 8,
                      () {
                    final start = linhaIndex * reaisPorLinha;

                    final endExclusive = math.min(
                      start + reaisPorLinha,
                      widget.totalEstacas,
                    );

                    final count = endExclusive - start;

                    final realGridWidth = cellWidth * count;

                    final rowExecSignature = Object.hashAll(
                      List<int>.generate(count, (i) {
                        final estaca = start + i + 1;
                        final row = widget.execIndex[estaca];

                        if (row == null || row.isEmpty) return 0;

                        return Object.hash(
                          estaca,
                          row.length,
                          Object.hashAll(
                            row.entries.map(
                                  (entry) => Object.hash(
                                entry.key,
                                entry.value.status,
                                entry.value.comentario,
                                entry.value.fotos.length,
                                entry.value.updatedAt?.millisecondsSinceEpoch,
                                entry.value.takenAtMs,
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
                            w: cellWidth,
                            columnHeight: columnHeight,
                            headerHeight: widget.headerHeight,
                            kCellVPad: ScheduleGrid.kCellVPad,
                            faixas: widget.faixas,
                          ),
                          gridPaint,
                        ],
                      ),
                    );

                    final gridWithInput = Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (ev) {
                        if (widget.onDragStart == null) return;

                        final p = ev.localPosition;
                        final realDx = p.dx - cellWidth;

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
                        if (widget.onDragStart == null ||
                            widget.onDragUpdate == null) {
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
                        final realDx = p.dx - cellWidth;

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

                        if (_lastSentEstaca == estaca &&
                            _lastSentFaixa == faixa) {
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

                        if (_dragStarted &&
                            _pointerIntent == _PointerIntent.selecting) {
                          widget.onDragEnd?.call();
                          _resetPointerTracking();
                          return;
                        }

                        final p = ev.localPosition;
                        final delta = startPosition == null
                            ? Offset.zero
                            : p - startPosition;

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
                        if (_dragStarted &&
                            _pointerIntent == _PointerIntent.selecting) {
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
                            gridWithInput,
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          warnAboveMs: 16,
        );
      },
    );
  }
}

typedef _DefaultExecBuilder = ScheduleRoadData Function({
required int estaca,
required int faixaIndex,
});

class _ScheduleGridLinePainter extends CustomPainter {
  const _ScheduleGridLinePainter({
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

  final int startEstaca;
  final int count;
  final double cellWidth;
  final double headerHeight;
  final List<ScheduleRoadData> faixas;
  final List<bool> enabledLanes;
  final Map<int, Map<int, ScheduleRoadData>> execIndex;
  final Map<int, Set<int>> selectedByEstaca;
  final Color highlightColor;
  final Color Function(ScheduleRoadData e) getSquareColor;
  final _DefaultExecBuilder defaultExecBuilder;
  final int rowExecSignature;
  final int selectedSignature;

  bool _isLaneEnabled(int faixaIndex) {
    if (faixaIndex < 0 || faixaIndex >= enabledLanes.length) {
      return true;
    }

    return enabledLanes[faixaIndex];
  }

  ScheduleRoadData _execFor({
    required int estaca,
    required int faixaIndex,
  }) {
    return execIndex[estaca]?[faixaIndex] ??
        defaultExecBuilder(
          estaca: estaca,
          faixaIndex: faixaIndex,
        );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = highlightColor;

    _paintHeader(canvas);

    double y = headerHeight;

    for (int faixaIndex = 0; faixaIndex < faixas.length; faixaIndex++) {
      final lane = faixas[faixaIndex];
      final laneHeight = lane.altura ?? 20.0;
      final enabled = _isLaneEnabled(faixaIndex);

      final cellTop = y + ScheduleGrid.kCellVPad;

      for (int i = 0; i < count; i++) {
        final estaca = startEstaca + i;
        final x = i * cellWidth;

        final exec = _execFor(
          estaca: estaca,
          faixaIndex: faixaIndex,
        );

        final rect = Rect.fromLTWH(
          x + 0.5,
          cellTop,
          math.max(0, cellWidth - 1),
          laneHeight,
        );

        if (enabled) {
          paint.color = getSquareColor(exec);
          canvas.drawRect(rect, paint);

          final selected =
              selectedByEstaca[estaca]?.contains(faixaIndex) == true;

          if (selected) {
            canvas.drawRect(rect.deflate(1), borderPaint);
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
    for (int i = 0; i < count; i++) {
      final estaca = startEstaca + i;
      final x = i * cellWidth;
      final isMultiploDe10 = estaca % 10 == 0;

      if (!isMultiploDe10 && cellWidth < 18) {
        continue;
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$estaca',
          style: TextStyle(
            fontSize: isMultiploDe10 ? 10 : 7,
            height: 1.0,
            color: isMultiploDe10 ? Colors.red : Colors.grey.shade600,
            fontWeight: isMultiploDe10 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: cellWidth);

      if (isMultiploDe10) {
        canvas.save();

        final cx = x + cellWidth / 2;
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
        textPainter.paint(
          canvas,
          Offset(
            x + (cellWidth - textPainter.width) / 2,
            (headerHeight - textPainter.height) / 2,
          ),
        );
      }
    }
  }

  void _paintCellMarkers({
    required Canvas canvas,
    required Rect rect,
    required ScheduleRoadData data,
  }) {
    final hasPhotos = data.fotos.any((url) => url.trim().isNotEmpty);
    final hasComment = data.comentario?.trim().isNotEmpty ?? false;

    if (!hasPhotos && !hasComment) return;

    final markerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.34);

    final center = rect.center;

    if (hasPhotos) {
      final cameraRect = Rect.fromCenter(
        center: center,
        width: 9,
        height: 7,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          cameraRect,
          const Radius.circular(1.5),
        ),
        markerPaint,
      );

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

      return;
    }

    canvas.drawCircle(center, 3.2, markerPaint);
  }

  void _paintDisabledCell({
    required Canvas canvas,
    required Rect rect,
  }) {
    final bg = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey.shade200;

    canvas.drawRect(rect, bg);

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
    return oldDelegate.startEstaca != startEstaca ||
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