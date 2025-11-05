// lib/_widgets/layout/responsive_split_view.dart
import 'package:flutter/material.dart';

class ResponsiveSplitView extends StatefulWidget {
  const ResponsiveSplitView({
    super.key,
    required this.left,
    required this.right,
    required this.showRightPanel,
    this.breakpoint = 980.0,
    this.rightPanelWidth = 600.0,
    this.bottomPanelHeight = 420.0,
    this.showDividers = true,
    this.dividerThickness = 12.0,
    this.dividerBackgroundColor = Colors.white,
    this.dividerBorderColor,
    this.gripColor = const Color(0xFFB0B0B0),
  });

  final Widget left;
  final Widget right;
  final bool showRightPanel;

  final double breakpoint;
  final double rightPanelWidth;     // alvo no wide
  final double bottomPanelHeight;   // alvo no stacked

  final bool showDividers;
  final double dividerThickness;
  final Color dividerBackgroundColor;
  final Color? dividerBorderColor;
  final Color gripColor;

  @override
  State<ResponsiveSplitView> createState() => _ResponsiveSplitViewState();
}

class _ResponsiveSplitViewState extends State<ResponsiveSplitView> {
  // proporções internas
  double _splitWide = 0.66; // será recalibrado para bater com rightPanelWidth
  double _splitStacked = 0.55; // será recalibrado para bater com bottomPanelHeight
  bool _wideCalibrated = false;
  bool _stackedCalibrated = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= widget.breakpoint;

      if (!widget.showRightPanel) {
        // Sem painel: nada de split, nada de divisor
        return SizedBox(width: c.maxWidth, height: c.maxHeight, child: widget.left);
      }

      if (wide) {
        final dividerW = widget.showDividers ? widget.dividerThickness : 0.0;
        final usable = c.maxWidth - dividerW;

        // calibra split para iniciar com painel = rightPanelWidth
        if (!_wideCalibrated && usable > 0) {
          final targetRight = widget.rightPanelWidth.clamp(300.0, usable * 0.8);
          _splitWide = (usable - targetRight) / usable;
          _wideCalibrated = true;
        }

        // calcula larguras a partir do split
        double leftW = (usable * _splitWide);
        double rightW = usable - leftW;

        // limites
        const double kMinLeft = 220.0;
        final double kMinRight = 300.0;
        final double kMaxRight = usable * 0.85;

        // corrige para respeitar limites
        rightW = rightW.clamp(kMinRight, kMaxRight);
        leftW = usable - rightW;
        _splitWide = (leftW / usable).clamp(0.05, 0.95);

        return Row(
          children: [
            SizedBox(width: leftW, child: widget.left),

            if (widget.showDividers)
              _VerticalDragDivider(
                thickness: widget.dividerThickness,
                background: widget.dividerBackgroundColor,
                borderColor: widget.dividerBorderColor,
                gripColor: widget.gripColor,
                onDrag: (dx) {
                  final newLeft = (leftW + dx).clamp(kMinLeft, usable - kMinRight);
                  setState(() => _splitWide = (newLeft / usable).clamp(0.05, 0.95));
                },
              ),

            SizedBox(width: rightW, child: widget.right),
          ],
        );
      }

      // ===== Stacked (mobile/tablet) =====
      final dividerH = widget.showDividers ? widget.dividerThickness : 0.0;
      final usable = c.maxHeight - dividerH;

      if (!_stackedCalibrated && usable > 0) {
        final targetBottom = widget.bottomPanelHeight.clamp(300.0, usable * 0.9);
        final targetTop = usable - targetBottom;
        _splitStacked = (targetTop / usable).clamp(0.2, 0.9);
        _stackedCalibrated = true;
      }

      double topH = usable * _splitStacked;
      double bottomH = usable - topH;

      const double kMinTop = 220.0;
      final double kMinBottom = 300.0;
      final double kMaxBottom = usable * 0.9;

      bottomH = bottomH.clamp(kMinBottom, kMaxBottom);
      topH = usable - bottomH;
      _splitStacked = (topH / usable).clamp(0.2, 0.9);

      return Column(
        children: [
          SizedBox(height: topH, child: widget.left),

          if (widget.showDividers)
            _HorizontalDragDivider(
              thickness: widget.dividerThickness,
              background: widget.dividerBackgroundColor,
              borderColor: widget.dividerBorderColor,
              gripColor: widget.gripColor,
              onDrag: (dy) {
                final newTop = (topH + dy).clamp(kMinTop, usable - kMinBottom);
                setState(() => _splitStacked = (newTop / usable).clamp(0.2, 0.9));
              },
            ),

          SizedBox(height: bottomH, child: widget.right),
        ],
      );
    });
  }
}

// ===== Divisores com "grip" =====
class _VerticalDragDivider extends StatelessWidget {
  const _VerticalDragDivider({
    required this.thickness,
    required this.background,
    required this.gripColor,
    this.borderColor,
    required this.onDrag,
  });

  final double thickness;
  final Color background;
  final Color gripColor;
  final Color? borderColor;
  final void Function(double dx) onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: thickness,
          color: background,
          child: Stack(
            children: [
              if (borderColor != null)
                Align(alignment: Alignment.centerLeft, child: Container(width: 1, color: borderColor)),
              if (borderColor != null)
                Align(alignment: Alignment.centerRight, child: Container(width: 1, color: borderColor)),
              Center(
                child: Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: gripColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalDragDivider extends StatelessWidget {
  const _HorizontalDragDivider({
    required this.thickness,
    required this.background,
    required this.gripColor,
    this.borderColor,
    required this.onDrag,
  });

  final double thickness;
  final Color background;
  final Color gripColor;
  final Color? borderColor;
  final void Function(double dy) onDrag;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        child: Container(
          height: thickness,
          color: background,
          child: Stack(
            children: [
              if (borderColor != null)
                Align(alignment: Alignment.topCenter, child: Container(height: 1, color: borderColor)),
              if (borderColor != null)
                Align(alignment: Alignment.bottomCenter, child: Container(height: 1, color: borderColor)),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: gripColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
