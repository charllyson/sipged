// lib/_widgets/paint/paint_tool_dock.dart
import 'package:flutter/material.dart';

enum DockSide { left, right }

class ToolGroup {
  final String id;
  final IconData icon;
  final String tooltip;
  final Widget Function(VoidCallback close) panelBuilder;

  /// Largura-alvo MÁXIMA do painel (não é largura fixa).
  final double preferredPanelWidth;

  /// Se true, a largura tenta se ajustar ao conteúdo (até preferredPanelWidth).
  final bool useIntrinsicWidth;

  /// Espaço interno do painel.
  final EdgeInsets? panelPadding;

  /// Cores opcionais para destacar o botão do grupo no dock.
  final Color? iconColor;
  final Color? borderColor;
  final double? sizeborder;
  final Color? menuBackground;

  const ToolGroup({
    required this.id,
    required this.icon,
    required this.tooltip,
    required this.panelBuilder,
    this.preferredPanelWidth = 260,
    this.useIntrinsicWidth = false,
    this.panelPadding,
    this.iconColor,
    this.borderColor,
    this.sizeborder,
    this.menuBackground,
  });
}

class _BuiltPanel {
  final Widget widget;
  final double maxWidth;
  const _BuiltPanel(this.widget, this.maxWidth);
}

class PaintToolDock extends StatefulWidget {
  const PaintToolDock({
    super.key,
    required this.groups,
    this.side = DockSide.right,
    this.panelWidth = 260,
    this.panelMaxHeight = 420,
    this.panelRepaint,
    this.cascadeGap = 8,
    this.radius = 10,
  });

  final List<ToolGroup> groups;
  final DockSide side;
  final double panelWidth;
  final double panelMaxHeight;
  final Listenable? panelRepaint;
  final double cascadeGap;
  final double radius;

  @override
  State<PaintToolDock> createState() => _PaintToolDockState();
}

class _PaintToolDockState extends State<PaintToolDock> {
  String? _openGroupId;
  int _panelEpoch = 0;

  static const double _dockButton = 40.0;
  static const double _dockHPad = 6.0;

  void _toggle(String id) {
    setState(() {
      _openGroupId = (_openGroupId == id) ? null : id;
    });
  }

  void _close() => setState(() => _openGroupId = null);

  void _onExternalRepaint() {
    if (!mounted) return;
    setState(() => _panelEpoch++);
  }

  @override
  void initState() {
    super.initState();
    widget.panelRepaint?.addListener(_onExternalRepaint);
  }

  @override
  void didUpdateWidget(covariant PaintToolDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panelRepaint != widget.panelRepaint) {
      oldWidget.panelRepaint?.removeListener(_onExternalRepaint);
      widget.panelRepaint?.addListener(_onExternalRepaint);
    }
  }

  @override
  void dispose() {
    widget.panelRepaint?.removeListener(_onExternalRepaint);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRight = widget.side == DockSide.right;

    final dock = Material(
      color: Colors.black26,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.radius),
        side: const BorderSide(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: _dockHPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final g in widget.groups)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Tooltip(
                  message: g.tooltip,
                  child: InkResponse(
                    radius: 28,
                    onTap: () => _toggle(g.id),
                    child: Container(
                      width: _dockButton,
                      height: _dockButton,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:  _openGroupId == g.id ? Colors.white54 : g.menuBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: g.borderColor ??
                              (_openGroupId == g.id
                                  ? Colors.blueAccent.shade200
                                  : Colors.white30),
                          width: g.sizeborder ?? 1,
                        ),
                      ),
                      child: Icon(
                        g.icon,
                        size: 20,
                        color: g.iconColor ??
                            (_openGroupId == g.id
                                ? Colors.blueAccent.shade200
                                : Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final built = _buildPanel(context);
    final double panelW = built?.maxWidth ?? 0;
    final double totalWidth =
        _dockButton + _dockHPad + (built != null ? widget.cascadeGap + panelW : 0);

    return SizedBox(
      width: totalWidth,
      child: Stack(
        alignment: isRight ? Alignment.topRight : Alignment.topLeft,
        clipBehavior: Clip.none,
        children: [
          dock,
          if (built != null)
            Positioned(
              top: 0,
              right: isRight ? (_dockButton + _dockHPad + widget.cascadeGap) : null,
              left: isRight ? null : (_dockButton + _dockHPad + widget.cascadeGap),
              child: built.widget,
            ),
        ],
      ),
    );
  }

  _BuiltPanel? _buildPanel(BuildContext context) {
    if (_openGroupId == null) return null;
    final g = widget.groups.firstWhere((e) => e.id == _openGroupId);

    final maxW =
    g.preferredPanelWidth > 0 ? g.preferredPanelWidth : widget.panelWidth;

    final body = ClipRRect(
      key: ValueKey('${g.id}#$_panelEpoch'),
      borderRadius: BorderRadius.circular(widget.radius),
      child: Material(
        color: Colors.black26,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          side: const BorderSide(color: Colors.white24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxW,
            maxHeight: widget.panelMaxHeight,
          ),
          child: SingleChildScrollView(
            padding: g.panelPadding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: g.panelBuilder(_close),
              ),
            ),
          ),
        ),
      ),
    );

    if (g.useIntrinsicWidth) {
      return _BuiltPanel(IntrinsicWidth(child: body), maxW);
    } else {
      return _BuiltPanel(SizedBox(width: maxW, child: body), maxW);
    }
  }
}
