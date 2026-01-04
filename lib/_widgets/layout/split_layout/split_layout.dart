// lib/_widgets/layout/split_layout.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/split_layout/horizontal_drag_divider.dart';
import 'package:siged/_widgets/layout/split_layout/vertical_drag_divider.dart';

class SplitLayout extends StatefulWidget {
  const SplitLayout({
    super.key,
    required this.left,
    required this.right,
    required this.showRightPanel,
    this.breakpoint = 1280.0,
    this.rightPanelWidth = 600.0,
    this.bottomPanelHeight = 420.0,
    this.showDividers = true,
    this.dividerThickness = 12.0,
    this.dividerBackgroundColor = Colors.white,
    this.dividerBorderColor = const Color(0xFFE5E5E5),
    this.gripColor = const Color(0xFFB0B0B0),
    this.stackedRightOnTop = false,
  });

  final Widget left;
  final Widget right;
  final bool showRightPanel;

  /// Largura a partir da qual vira layout lado a lado
  final double breakpoint;
  final double rightPanelWidth; // alvo no wide
  final double bottomPanelHeight; // alvo no stacked

  final bool showDividers;
  final double dividerThickness;
  final Color dividerBackgroundColor;
  final Color? dividerBorderColor;
  final Color gripColor;

  /// Quando true, no modo stacked (mobile/tablet),
  /// o painel RIGHT fica em cima e o LEFT embaixo.
  /// No modo wide, continua LEFT | RIGHT normal.
  final bool stackedRightOnTop;

  @override
  State<SplitLayout> createState() => _SplitLayoutState();
}

class _SplitLayoutState extends State<SplitLayout> {
  // proporções internas (0..1)
  double _splitWide = 0.5; // parte do espaço para o painel LEFT
  double _splitStacked = 0.5; // parte do espaço para o painel TOP
  bool _wideCalibrated = false;
  bool _stackedCalibrated = false;

  // valores padrão usados no construtor
  static const double _defaultRightPanelWidth = 600.0;
  static const double _defaultBottomPanelHeight = 420.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= widget.breakpoint;

        if (!widget.showRightPanel) {
          // Sem painel: nada de split, nada de divisor
          return SizedBox(
            width: c.maxWidth,
            height: c.maxHeight,
            child: widget.left,
          );
        }

        // ================== LAYOUT WIDE (DESKTOP) ==================
        if (wide) {
          final dividerW = widget.showDividers ? widget.dividerThickness : 0.0;
          final usable = c.maxWidth - dividerW;

          // calibra split APENAS NA PRIMEIRA VEZ
          if (!_wideCalibrated && usable > 0) {
            if (widget.rightPanelWidth == _defaultRightPanelWidth) {
              // 👉 nenhum valor customizado: começa 50/50
              _splitWide = 0.5;
            } else {
              // 👉 valor customizado: respeita o rightPanelWidth informado
              final targetRight =
              widget.rightPanelWidth.clamp(200.0, usable * 0.95);
              final targetLeft = usable - targetRight;
              _splitWide = (targetLeft / usable).clamp(0.02, 0.98);
            }
            _wideCalibrated = true;
          }

          // Larguras a partir do split
          double leftW = usable * _splitWide;
          double rightW = usable - leftW;

          // mínimos bem pequenos para dar LIBERDADE
          const double kMinLeft = 80.0;
          const double kMinRight = 80.0;

          // Se estourar para algum lado, corrige mantendo fluidez
          if (leftW < kMinLeft) {
            leftW = kMinLeft;
            rightW = usable - leftW;
          } else if (rightW < kMinRight) {
            rightW = kMinRight;
            leftW = usable - rightW;
          }

          _splitWide = (leftW / usable).clamp(0.02, 0.98);

          return Row(
            children: [
              SizedBox(width: leftW, child: widget.left),

              if (widget.showDividers)
                VerticalDragDivider(
                  thickness: widget.dividerThickness,
                  background: widget.dividerBackgroundColor,
                  borderColor: widget.dividerBorderColor,
                  gripColor: widget.gripColor,
                  onDrag: (dx) {
                    final currentLeft = usable * _splitWide;
                    final newLeft =
                    (currentLeft + dx).clamp(kMinLeft, usable - kMinRight);
                    setState(() {
                      _splitWide = (newLeft / usable).clamp(0.02, 0.98);
                    });
                  },
                ),

              SizedBox(width: rightW, child: widget.right),
            ],
          );
        }

        // ================== LAYOUT STACKED (MOBILE / TABLET) ==================
        final dividerH = widget.showDividers ? widget.dividerThickness : 0.0;
        final usable = c.maxHeight - dividerH;

        if (!_stackedCalibrated && usable > 0) {
          if (widget.bottomPanelHeight == _defaultBottomPanelHeight) {
            // 👉 nenhum valor customizado: começa 50/50
            _splitStacked = 0.5;
          } else {
            // 👉 valor customizado: respeita o bottomPanelHeight informado
            final targetBottom =
            widget.bottomPanelHeight.clamp(200.0, usable * 0.95);
            final targetTop = usable - targetBottom;
            _splitStacked = (targetTop / usable).clamp(0.05, 0.95);
          }
          _stackedCalibrated = true;
        }

        double topH = usable * _splitStacked;
        double bottomH = usable - topH;

        // mínimos menores para dar mais liberdade
        const double kMinTop = 80.0;
        const double kMinBottom = 80.0;

        if (topH < kMinTop) {
          topH = kMinTop;
          bottomH = usable - topH;
        } else if (bottomH < kMinBottom) {
          bottomH = kMinBottom;
          topH = usable - bottomH;
        }

        _splitStacked = (topH / usable).clamp(0.05, 0.95);

        // qual painel vai em cima/baixo no stacked
        final Widget topChild =
        widget.stackedRightOnTop ? widget.right : widget.left;
        final Widget bottomChild =
        widget.stackedRightOnTop ? widget.left : widget.right;

        return Column(
          children: [
            SizedBox(height: topH, child: topChild),

            if (widget.showDividers)
              HorizontalDragDivider(
                thickness: widget.dividerThickness,
                background: widget.dividerBackgroundColor,
                borderColor: widget.dividerBorderColor,
                gripColor: widget.gripColor,
                onDrag: (dy) {
                  final currentTop = usable * _splitStacked;
                  final newTop =
                  (currentTop + dy).clamp(kMinTop, usable - kMinBottom);
                  setState(() {
                    _splitStacked = (newTop / usable).clamp(0.05, 0.95);
                  });
                },
              ),

            SizedBox(height: bottomH, child: bottomChild),
          ],
        );
      },
    );
  }
}
