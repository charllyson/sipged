// lib/_widgets/overlays/balloon/balloon_change.dart

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_body.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_painter.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class BalloonChange extends StatefulWidget {
  const BalloonChange({
    super.key,
    this.targetBox,
    required this.overlayBox,
    this.localAnchor,
    this.globalAnchor,

    /// Recalcula a posição global da âncora sempre que o balloon rebuildar.
    ///
    /// Ideal para mapa, zoom, pan, scroll manual, gráficos e canvas.
    this.globalAnchorBuilder,

    /// Quando informado, o BalloonChange escuta esse listenable e atualiza
    /// internamente a posição.
    ///
    /// Exemplo:
    /// final ValueNotifier balloonTick = ValueNotifier(0);
    /// balloonTick.value++;
    this.rebuildListenable,

    required this.width,
    required this.maxHeight,
    this.title,
    required this.items,
    this.tipSide = BalloonTipSide.top,
    this.headerIcon,
    this.actionLabel,
    this.showAction = false,
    this.onAction,
    this.loading = false,
    this.error,
    this.emptyIcon = Icons.notifications_off_outlined,
    this.emptyMessage = 'Nenhum item encontrado.',
    this.topGap = 0,
    this.screenMargin = 8,
    this.tipWidth = 18,
    this.tipHeight = 10,
    this.tipHorizontalMargin = 20,
    this.tipVerticalMargin = 20,
  }) : assert(
  targetBox != null ||
      localAnchor != null ||
      globalAnchor != null ||
      globalAnchorBuilder != null,
  'Informe targetBox, localAnchor, globalAnchor ou globalAnchorBuilder para posicionar o BalloonChange.',
  );

  final RenderBox? targetBox;
  final RenderBox overlayBox;

  final Offset? localAnchor;
  final Offset? globalAnchor;

  final Offset? Function()? globalAnchorBuilder;
  final Listenable? rebuildListenable;

  final double width;
  final double maxHeight;

  final BalloonTipSide tipSide;

  /// Opcional. Se null ou vazio, o título não aparece.
  final String? title;

  /// Opcional. Se null, o ícone do header não aparece.
  final IconData? headerIcon;

  final String? actionLabel;
  final bool showAction;
  final VoidCallback? onAction;

  final bool loading;
  final String? error;

  final IconData? emptyIcon;
  final String emptyMessage;

  final List<BalloonTileData> items;

  final double topGap;
  final double screenMargin;

  final double tipWidth;
  final double tipHeight;
  final double tipHorizontalMargin;
  final double tipVerticalMargin;

  @override
  State<BalloonChange> createState() => _BalloonChangeState();
}

class _BalloonChangeState extends State<BalloonChange> {
  @override
  void initState() {
    super.initState();
    widget.rebuildListenable?.addListener(_handleRebuildRequested);
  }

  @override
  void didUpdateWidget(covariant BalloonChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rebuildListenable != widget.rebuildListenable) {
      oldWidget.rebuildListenable?.removeListener(_handleRebuildRequested);
      widget.rebuildListenable?.addListener(_handleRebuildRequested);
    }
  }

  @override
  void dispose() {
    widget.rebuildListenable?.removeListener(_handleRebuildRequested);
    super.dispose();
  }

  void _handleRebuildRequested() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final position = _calculatePosition();

    if (position == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: position.left,
      top: position.top,
      width: position.popupWidth,
      child: Material(
        type: MaterialType.transparency,
        child: BalloonBody(
          width: widget.width,
          maxHeight: widget.maxHeight,
          tipSide: widget.tipSide,
          tipCenterX: position.tipCenterX,
          tipCenterY: position.tipCenterY,
          title: widget.title,
          headerIcon: widget.headerIcon,
          actionLabel: widget.actionLabel,
          showAction: widget.showAction,
          onAction: widget.onAction,
          loading: widget.loading,
          error: widget.error,
          emptyIcon: widget.emptyIcon,
          emptyMessage: widget.emptyMessage,
          items: widget.items,
        ),
      ),
    );
  }

  BalloonPosition? _calculatePosition() {
    final target = widget.targetBox;

    if (target != null && target.attached) {
      return BalloonPopup.calculatePosition(
        targetBox: target,
        overlayBox: widget.overlayBox,
        balloonWidth: widget.width,
        maxHeight: widget.maxHeight,
        tipSide: widget.tipSide,
        topGap: widget.topGap,
        screenMargin: widget.screenMargin,
        tipWidth: widget.tipWidth,
        tipHeight: widget.tipHeight,
        tipHorizontalMargin: widget.tipHorizontalMargin,
        tipVerticalMargin: widget.tipVerticalMargin,
      );
    }

    final overlaySize = widget.overlayBox.size;

    final Offset? resolvedGlobalAnchor =
        widget.globalAnchorBuilder?.call() ?? widget.globalAnchor;

    final Offset? anchor = widget.localAnchor ??
        (resolvedGlobalAnchor == null
            ? null
            : widget.overlayBox.globalToLocal(resolvedGlobalAnchor));

    if (anchor == null) {
      return null;
    }

    return BalloonPopup.calculatePositionFromLocalPoint(
      anchor: anchor,
      overlaySize: overlaySize,
      balloonWidth: widget.width,
      maxHeight: widget.maxHeight,
      tipSide: widget.tipSide,
      topGap: widget.topGap,
      screenMargin: widget.screenMargin,
      tipWidth: widget.tipWidth,
      tipHeight: widget.tipHeight,
      tipHorizontalMargin: widget.tipHorizontalMargin,
      tipVerticalMargin: widget.tipVerticalMargin,
    );
  }
}