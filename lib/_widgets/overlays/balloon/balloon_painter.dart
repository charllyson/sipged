import 'package:flutter/material.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class BalloonPosition {
  const BalloonPosition({
    required this.left,
    required this.top,
    required this.tipCenterX,
    required this.tipCenterY,
    required this.popupWidth,
  });

  final double left;
  final double top;

  /// Usado quando a ponta está em cima ou embaixo.
  final double tipCenterX;

  /// Usado quando a ponta está na esquerda ou direita.
  final double tipCenterY;

  /// Largura real do overlay.
  /// Em top/bottom é igual ao width.
  /// Em left/right é width + tipHeight.
  final double popupWidth;
}

class BalloonPopup extends StatelessWidget {
  const BalloonPopup({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.child,
    this.tipSide = BalloonTipSide.top,
    this.tipCenterX,
    this.tipCenterY,
    this.backgroundColor = Colors.white,
    this.borderRadius = 12,
    this.borderColor = const Color(0x11000000),
    this.tipWidth = 18,
    this.tipHeight = 10,
    this.tipHorizontalMargin = 20,
    this.tipVerticalMargin = 20,
    this.clipBehavior = Clip.antiAlias,
    this.padding = EdgeInsets.zero,
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x22000000),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 28,
        offset: Offset(0, 18),
      ),
    ],
  });

  final double width;
  final double maxHeight;

  final BalloonTipSide tipSide;

  /// Usado para top/bottom.
  final double? tipCenterX;

  /// Usado para left/right.
  final double? tipCenterY;

  final Widget child;

  final Color backgroundColor;
  final double borderRadius;
  final Color borderColor;

  final double tipWidth;
  final double tipHeight;

  final double tipHorizontalMargin;
  final double tipVerticalMargin;

  final Clip clipBehavior;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> boxShadow;

  static double _safeClamp(
      double value,
      double min,
      double max,
      ) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  /// Calcula posição usando um widget como âncora.
  /// Ideal para sino, avatar, botão, ícone etc.
  static BalloonPosition calculatePosition({
    required RenderBox targetBox,
    required RenderBox overlayBox,
    required double balloonWidth,
    required double maxHeight,
    BalloonTipSide tipSide = BalloonTipSide.top,
    double topGap = 0,
    double screenMargin = 8,
    double tipWidth = 18,
    double tipHeight = 10,
    double tipHorizontalMargin = 20,
    double tipVerticalMargin = 20,
  }) {
    final targetOffset = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final targetSize = targetBox.size;
    final overlaySize = overlayBox.size;

    final targetCenterX = targetOffset.dx + (targetSize.width / 2);
    final targetCenterY = targetOffset.dy + (targetSize.height / 2);

    return calculatePositionFromLocalPoint(
      anchor: Offset(targetCenterX, targetCenterY),
      overlaySize: overlaySize,
      balloonWidth: balloonWidth,
      maxHeight: maxHeight,
      tipSide: tipSide,
      topGap: topGap,
      screenMargin: screenMargin,
      tipWidth: tipWidth,
      tipHeight: tipHeight,
      tipHorizontalMargin: tipHorizontalMargin,
      tipVerticalMargin: tipVerticalMargin,
      targetSize: targetSize,
      targetOffset: targetOffset,
    );
  }

  /// Calcula posição usando um ponto local dentro do overlay.
  ///
  /// Ideal para mapa, gráfico, polygon center, marker, canvas etc.
  static BalloonPosition calculatePositionFromLocalPoint({
    required Offset anchor,
    required Size overlaySize,
    required double balloonWidth,
    required double maxHeight,
    BalloonTipSide tipSide = BalloonTipSide.top,
    double topGap = 0,
    double screenMargin = 8,
    double tipWidth = 18,
    double tipHeight = 10,
    double tipHorizontalMargin = 20,
    double tipVerticalMargin = 20,

    /// Opcional.
    /// Quando vier de um RenderBox, ajuda a posicionar abaixo/acima do widget.
    Size? targetSize,

    /// Opcional.
    /// Quando vier de um RenderBox, ajuda a posicionar com base no canto do widget.
    Offset? targetOffset,
  }) {
    final resolvedTargetSize = targetSize ?? Size.zero;
    final resolvedTargetOffset = targetOffset ?? anchor;

    double safeLeft;
    double safeTop;
    double safeTipCenterX = balloonWidth / 2;
    double safeTipCenterY = maxHeight / 2;
    double popupWidth = balloonWidth;

    switch (tipSide) {
      case BalloonTipSide.top:
        popupWidth = balloonWidth;

        final rawLeft = anchor.dx - (balloonWidth / 2);
        final maxLeft = overlaySize.width - balloonWidth - screenMargin;

        safeLeft = _safeClamp(
          rawLeft,
          screenMargin,
          maxLeft,
        );

        final hasTargetBox = targetSize != null && targetOffset != null;

        safeTop = hasTargetBox
            ? resolvedTargetOffset.dy + resolvedTargetSize.height + topGap
            : anchor.dy + topGap;

        final rawTipCenterX = anchor.dx - safeLeft;

        safeTipCenterX = _safeClamp(
          rawTipCenterX,
          tipHorizontalMargin,
          balloonWidth - tipHorizontalMargin,
        );

        break;

      case BalloonTipSide.bottom:
        popupWidth = balloonWidth;

        final rawLeft = anchor.dx - (balloonWidth / 2);
        final maxLeft = overlaySize.width - balloonWidth - screenMargin;

        safeLeft = _safeClamp(
          rawLeft,
          screenMargin,
          maxLeft,
        );

        final hasTargetBox = targetSize != null && targetOffset != null;

        final rawTop = hasTargetBox
            ? resolvedTargetOffset.dy - maxHeight - tipHeight - topGap
            : anchor.dy - maxHeight - tipHeight - topGap;

        final maxTop = overlaySize.height - maxHeight - tipHeight - screenMargin;

        safeTop = _safeClamp(
          rawTop,
          screenMargin,
          maxTop,
        );

        final rawTipCenterX = anchor.dx - safeLeft;

        safeTipCenterX = _safeClamp(
          rawTipCenterX,
          tipHorizontalMargin,
          balloonWidth - tipHorizontalMargin,
        );

        break;

      case BalloonTipSide.left:
        popupWidth = balloonWidth + tipHeight;

        final hasTargetBox = targetSize != null && targetOffset != null;

        final rawLeft = hasTargetBox
            ? resolvedTargetOffset.dx + resolvedTargetSize.width + topGap
            : anchor.dx + topGap;

        final rawTop = anchor.dy - (maxHeight / 2);

        final maxTop = overlaySize.height - maxHeight - screenMargin;
        final maxLeft = overlaySize.width - popupWidth - screenMargin;

        safeLeft = _safeClamp(
          rawLeft,
          screenMargin,
          maxLeft,
        );

        safeTop = _safeClamp(
          rawTop,
          screenMargin,
          maxTop,
        );

        final rawTipCenterY = anchor.dy - safeTop;

        safeTipCenterY = _safeClamp(
          rawTipCenterY,
          tipVerticalMargin,
          maxHeight - tipVerticalMargin,
        );

        break;

      case BalloonTipSide.right:
        popupWidth = balloonWidth + tipHeight;

        final hasTargetBox = targetSize != null && targetOffset != null;

        final rawLeft = hasTargetBox
            ? resolvedTargetOffset.dx - popupWidth - topGap
            : anchor.dx - popupWidth - topGap;

        final rawTop = anchor.dy - (maxHeight / 2);

        final maxTop = overlaySize.height - maxHeight - screenMargin;
        final maxLeft = overlaySize.width - popupWidth - screenMargin;

        safeLeft = _safeClamp(
          rawLeft,
          screenMargin,
          maxLeft,
        );

        safeTop = _safeClamp(
          rawTop,
          screenMargin,
          maxTop,
        );

        final rawTipCenterY = anchor.dy - safeTop;

        safeTipCenterY = _safeClamp(
          rawTipCenterY,
          tipVerticalMargin,
          maxHeight - tipVerticalMargin,
        );

        break;
    }

    return BalloonPosition(
      left: safeLeft,
      top: safeTop,
      tipCenterX: safeTipCenterX,
      tipCenterY: safeTipCenterY,
      popupWidth: popupWidth,
    );
  }

  double get _resolvedTipCenterX {
    final value = tipCenterX ?? (width / 2);

    return _safeClamp(
      value,
      tipHorizontalMargin,
      width - tipHorizontalMargin,
    );
  }

  double get _resolvedTipCenterY {
    final value = tipCenterY ?? (maxHeight / 2);

    return _safeClamp(
      value,
      tipVerticalMargin,
      maxHeight - tipVerticalMargin,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (tipSide) {
      case BalloonTipSide.top:
        return _buildTopTip();

      case BalloonTipSide.bottom:
        return _buildBottomTip();

      case BalloonTipSide.left:
        return _buildLeftTip();

      case BalloonTipSide.right:
        return _buildRightTip();
    }
  }

  Widget _buildTopTip() {
    final resolvedTipCenterX = _resolvedTipCenterX;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: tipHeight,
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: resolvedTipCenterX - (tipWidth / 2),
                  top: 1,
                  child: CustomPaint(
                    size: Size(tipWidth, tipHeight),
                    painter: BalloonTip(
                      color: backgroundColor,
                      shadowColor: const Color(0x22000000),
                      side: BalloonTipSide.top,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildContainer(),
        ],
      ),
    );
  }

  Widget _buildBottomTip() {
    final resolvedTipCenterX = _resolvedTipCenterX;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContainer(),
          SizedBox(
            height: tipHeight,
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: resolvedTipCenterX - (tipWidth / 2),
                  top: -1,
                  child: CustomPaint(
                    size: Size(tipWidth, tipHeight),
                    painter: BalloonTip(
                      color: backgroundColor,
                      shadowColor: const Color(0x22000000),
                      side: BalloonTipSide.bottom,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTip() {
    final resolvedTipCenterY = _resolvedTipCenterY;

    return SizedBox(
      width: width + tipHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: tipHeight,
            height: maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 1,
                  top: resolvedTipCenterY - (tipWidth / 2),
                  child: CustomPaint(
                    size: Size(tipHeight, tipWidth),
                    painter: BalloonTip(
                      color: backgroundColor,
                      shadowColor: const Color(0x22000000),
                      side: BalloonTipSide.left,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildContainer(),
        ],
      ),
    );
  }

  Widget _buildRightTip() {
    final resolvedTipCenterY = _resolvedTipCenterY;

    return SizedBox(
      width: width + tipHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContainer(),
          SizedBox(
            width: tipHeight,
            height: maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -1,
                  top: resolvedTipCenterY - (tipWidth / 2),
                  child: CustomPaint(
                    size: Size(tipHeight, tipWidth),
                    painter: BalloonTip(
                      color: backgroundColor,
                      shadowColor: const Color(0x22000000),
                      side: BalloonTipSide.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer() {
    return Container(
      width: width,
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: boxShadow,
      ),
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}