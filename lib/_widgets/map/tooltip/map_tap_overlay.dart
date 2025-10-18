// lib/_widgets/map/tooltip/map_tap_overlay.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_animated_card.dart';
import 'package:siged/_widgets/map/tooltip/tooltip_balloon_tip.dart';

/// Overlay de tooltip ancorado num ponto na tela (Offset global).
/// Use para polylines/markers quando quiser um overlay fora do FlutterMap.
class MapTapOverlayTooltip {
  static OverlayEntry? _entry;
  static void Function(Offset)? _repositionHook; // fornece reposicionamento dinâmico

  /// Mostra o tooltip em [position] (coordenada GLOBAL).
  static void show({
    required OverlayState overlayState,
    required Offset position,
    required String title,
    String? subtitle,
    double maxWidth = 280,
    VoidCallback? onDetails,
    VoidCallback? onClose,
    bool forceDownArrow = true, // seta sempre para baixo
  }) {
    hide();

    _entry = OverlayEntry(
      builder: (ctx) {
        return _AnchoredTooltipOverlay(
          globalPosition: position,
          title: title,
          subtitle: subtitle,
          maxWidth: maxWidth,
          onDetails: onDetails,
          onClose: () {
            onClose?.call();
            hide();
          },
          forceDownArrow: forceDownArrow,
          onRepositionHookReady: (fn) => _repositionHook = fn,
        );
      },
    );

    overlayState.insert(_entry!);
  }

  /// Atualiza a posição global do tooltip (ex.: em pan/zoom).
  static void updatePosition(Offset globalPosition) {
    _repositionHook?.call(globalPosition);
  }

  /// Esconde/limpa.
  static void hide() {
    _entry?.remove();
    _entry = null;
    _repositionHook = null;
  }
}

class _AnchoredTooltipOverlay extends StatefulWidget {
  const _AnchoredTooltipOverlay({
    required this.globalPosition,
    required this.title,
    required this.subtitle,
    required this.maxWidth,
    required this.onDetails,
    required this.onClose,
    required this.forceDownArrow,
    required this.onRepositionHookReady,
  });

  final Offset globalPosition;
  final String title;
  final String? subtitle;
  final double maxWidth;
  final VoidCallback? onDetails;
  final VoidCallback? onClose;
  final bool forceDownArrow;
  final void Function(void Function(Offset)) onRepositionHookReady;

  @override
  State<_AnchoredTooltipOverlay> createState() => _AnchoredTooltipOverlayState();
}

class _AnchoredTooltipOverlayState extends State<_AnchoredTooltipOverlay> {
  late Offset _pos = widget.globalPosition;

  @override
  void initState() {
    super.initState();
    // Exponha um hook para reposicionamento dinâmico
    widget.onRepositionHookReady((newPos) {
      if (!mounted) return;
      setState(() => _pos = newPos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    const safeLeft = 8.0;
    const safeRight = 8.0;
    final safeTop = padding.top + 8.0;

    final estimatedCardHeight = _estimateHeight(widget.title, widget.subtitle, widget.maxWidth);

// deixa a seta um pouco maior/visível
    const double arrowH = 9.0;
    const double arrowW = 14.0;

// espaço entre card e a base da seta
    const double verticalGap = 6.0;
// sobreposição mínima da base da seta com o card (evita “vazamento” de fundo)
    const double baseOverlap = 2.0;

    final left = math.max(
      safeLeft,
      math.min(_pos.dx - (widget.maxWidth / 2), size.width - widget.maxWidth - safeRight),
    );

// card acima do ponto do clique
    final cardTop = (_pos.dy - (estimatedCardHeight + arrowH + verticalGap))
        .clamp(safeTop, double.infinity);

// bordo inferior do card
    final cardBottom = cardTop + estimatedCardHeight;

// seta “cola” no card (base encosta no card e desce)
    final balloonTop = cardBottom - baseOverlap;

// centraliza seta perto do clique, limitado às bordas do card
    final balloonLeft = math.max(
      left + 10,
      math.min(_pos.dx - (arrowW / 2), left + widget.maxWidth - 10 - arrowW),
    );

    return Stack(
      children: [
        // Clicar fora fecha
        Positioned.fill(
          child: GestureDetector(onTap: widget.onClose),
        ),

        // Card
        Positioned(
          left: left,
          top: cardTop,
          width: widget.maxWidth,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                TooltipAnimatedCard(
                  title: widget.title,
                  subtitle: (widget.subtitle ?? '').trim().isEmpty ? null : widget.subtitle,
                  maxWidth: widget.maxWidth,
                  onDetails: widget.onDetails,
                  onClose: widget.onClose,
                ),
                TooltipBalloonTip(
                  color: Colors.black87,
                  width: 14,
                  height: arrowH,
                  direction: BalloonDirection.down,
                  shadow: true,
                )
              ],
            ),
          ),
        ),

      ],
    );
  }

  double _estimateHeight(String title, String? subtitle, double maxWidth) {
    // aproximação para 2 linhas título + (opcional) 2 linhas subtítulo + padding + ações
    const base = 14 + 8 + 36; // paddings/linha de ações
    final hasSub = (subtitle ?? '').trim().isNotEmpty;
    final titleLines = _estimateLines(title, maxWidth, 15, 2);
    final subLines   = hasSub ? _estimateLines(subtitle!, maxWidth, 13, 2) : 0;
    return (titleLines * 18.0) + (subLines * 16.0) + base;
  }

  int _estimateLines(String text, double maxWidth, double fontSize, int maxLines) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth - 28); // padding horizontal ~ 14 + 14
    final lineHeight = fontSize * 1.2;
    final lines = (tp.size.height / lineHeight).ceil();
    return lines.clamp(1, maxLines);
  }
}
