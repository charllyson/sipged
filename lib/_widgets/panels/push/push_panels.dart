import 'package:flutter/material.dart';
import 'package:sipged/_widgets/panels/push/push_panel_data.dart';
import 'package:sipged/_widgets/panels/push/push_panel_shell.dart';
import 'package:sipged/_widgets/panels/push/push_panels_controller.dart';

class PushPanels extends StatefulWidget {
  final Widget child;
  final List<PushPanelData> panels;
  final PushPanelsController controller;
  final Duration duration;
  final Curve curve;

  const PushPanels({
    super.key,
    required this.child,
    required this.panels,
    required this.controller,
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<PushPanels> createState() => _PushPanelsState();
}

class _PushPanelsState extends State<PushPanels> {
  final Map<String, double> _panelWidths = <String, double>{};

  String? _resizingPanelId;
  double? _resizeStartGlobalX;
  double? _resizeStartWidth;

  static const double _resizeHandleWidth = 8;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _syncPanelWidthsFromConfig();
  }

  @override
  void didUpdateWidget(covariant PushPanels oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }

    _syncPanelWidthsFromConfig();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncPanelWidthsFromConfig() {
    for (final panel in widget.panels) {
      _panelWidths.putIfAbsent(panel.id, () => panel.initialWidth);
    }
  }

  PushPanelData? _findPanel(String id) {
    for (final panel in widget.panels) {
      if (panel.id == id) return panel;
    }
    return null;
  }

  double _panelWidth(PushPanelData panel) {
    final value = _panelWidths[panel.id] ?? panel.initialWidth;
    return value.clamp(panel.minWidth, panel.maxWidth).toDouble();
  }

  double get _totalOpenWidth {
    double total = 0;

    for (final id in widget.controller.openIds) {
      final panel = _findPanel(id);
      if (panel != null) {
        total += _panelWidth(panel);
      }
    }

    return total;
  }

  void _startResize(String panelId, DragStartDetails details) {
    final panel = _findPanel(panelId);
    if (panel == null) return;

    setState(() {
      _resizingPanelId = panelId;
      _resizeStartGlobalX = details.globalPosition.dx;
      _resizeStartWidth = _panelWidth(panel);
    });
  }

  void _updateResize(String panelId, DragUpdateDetails details) {
    if (_resizingPanelId != panelId) return;

    final panel = _findPanel(panelId);
    if (panel == null) return;
    if (_resizeStartGlobalX == null || _resizeStartWidth == null) return;

    final delta = _resizeStartGlobalX! - details.globalPosition.dx;
    final nextWidth =
    (_resizeStartWidth! + delta).clamp(panel.minWidth, panel.maxWidth);

    setState(() {
      _panelWidths[panelId] = nextWidth.toDouble();
    });
  }

  void _endResize(String panelId) {
    if (_resizingPanelId != panelId) return;

    setState(() {
      _resizingPanelId = null;
      _resizeStartGlobalX = null;
      _resizeStartWidth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final pushedWidth = _totalOpenWidth.clamp(0.0, maxWidth).toDouble();

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPositioned(
              duration: _resizingPanelId == null
                  ? widget.duration
                  : Duration.zero,
              curve: widget.curve,
              left: 0,
              top: 0,
              bottom: 0,
              right: pushedWidth,
              child: ClipRect(
                child: ColoredBox(
                  color: Colors.white,
                  child: widget.child,
                ),
              ),
            ),
            ..._buildOpenedPanels(),
          ],
        );
      },
    );
  }

  List<Widget> _buildOpenedPanels() {
    final widgets = <Widget>[];
    double accumulatedRight = 0;

    final openedPanels = widget.controller.openIds
        .map(_findPanel)
        .whereType<PushPanelData>()
        .toList(growable: false);

    for (int i = 0; i < openedPanels.length; i++) {
      final panel = openedPanels[openedPanels.length - 1 - i];
      final panelWidth = _panelWidth(panel);
      final isResizing = _resizingPanelId == panel.id;

      widgets.add(
        AnimatedPositioned(
          duration: isResizing ? Duration.zero : widget.duration,
          curve: widget.curve,
          top: 0,
          bottom: 0,
          right: accumulatedRight,
          width: panelWidth,
          child: Stack(
            children: [
              Positioned.fill(
                child: PushPanelShell(
                  title: panel.title,
                  icon: panel.icon,
                  onClose: () => widget.controller.close(panel.id),
                  highlightResizeEdge: isResizing,
                  child: panel.child,
                ),
              ),

              // Linha separadora visível entre painéis
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: isResizing ? 2.0 : 1.0,
                    color: isResizing
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFFD1D5DB),
                  ),
                ),
              ),

              // Área de resize
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _resizeHandleWidth,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (details) =>
                        _startResize(panel.id, details),
                    onHorizontalDragUpdate: (details) =>
                        _updateResize(panel.id, details),
                    onHorizontalDragEnd: (_) => _endResize(panel.id),
                    onHorizontalDragCancel: () => _endResize(panel.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      color: isResizing
                          ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      accumulatedRight += panelWidth;
    }

    return widgets;
  }
}