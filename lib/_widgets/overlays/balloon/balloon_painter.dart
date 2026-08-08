import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class BalloonPosition {
  const BalloonPosition({
    required this.left,
    required this.top,
    required this.tipCenterX,
    required this.tipCenterY,
    required this.popupWidth,
    required this.popupMaxHeight,
    required this.tipSide,
  });

  final double left;
  final double top;
  final double tipCenterX;
  final double tipCenterY;
  final double popupWidth;
  final double popupMaxHeight;
  final BalloonTipSide tipSide;
}

class BalloonPopup extends StatelessWidget {
  const BalloonPopup({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.child,
    this.minHeight,
    this.forceMaxHeight = false,
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
  final double? minHeight;
  final bool forceMaxHeight;

  final BalloonTipSide tipSide;
  final double? tipCenterX;
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

  static const double _minUsableHeight = 120;

  static double _safeClamp(
      double value,
      double min,
      double max,
      ) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  static double _resolveMaxHeight({
    required double requestedMaxHeight,
    required double availableHeight,
  }) {
    if (requestedMaxHeight <= 0) {
      return _minUsableHeight;
    }

    if (availableHeight <= 0) {
      return math.min(requestedMaxHeight, _minUsableHeight);
    }

    if (availableHeight < _minUsableHeight) {
      return math.max(availableHeight, 72);
    }

    return math.min(requestedMaxHeight, availableHeight);
  }

  static BalloonTipSide _resolveAutoTipSide({
    required BalloonTipSide preferredSide,
    required bool autoFlip,
    required Offset anchor,
    required Size overlaySize,
    required double balloonWidth,
    required double maxHeight,
    required double topGap,
    required double screenMargin,
    required double tipHeight,
    Size? targetSize,
    Offset? targetOffset,
  }) {
    if (!autoFlip) {
      return preferredSide;
    }

    final hasTargetBox = targetSize != null && targetOffset != null;

    final targetTop = hasTargetBox ? targetOffset.dy : anchor.dy;
    final targetBottom = hasTargetBox
        ? targetOffset.dy + targetSize.height
        : anchor.dy;

    final targetLeft = hasTargetBox ? targetOffset.dx : anchor.dx;
    final targetRight = hasTargetBox
        ? targetOffset.dx + targetSize.width
        : anchor.dx;

    final availableBelow = overlaySize.height -
        targetBottom -
        topGap -
        tipHeight -
        screenMargin;

    final availableAbove = targetTop - topGap - tipHeight - screenMargin;

    final availableRight = overlaySize.width -
        targetRight -
        topGap -
        tipHeight -
        screenMargin;

    final availableLeft = targetLeft - topGap - tipHeight - screenMargin;

    switch (preferredSide) {
      case BalloonTipSide.top:
        if (availableBelow < maxHeight && availableAbove > availableBelow) {
          return BalloonTipSide.bottom;
        }
        return BalloonTipSide.top;

      case BalloonTipSide.bottom:
        if (availableAbove < maxHeight && availableBelow > availableAbove) {
          return BalloonTipSide.top;
        }
        return BalloonTipSide.bottom;

      case BalloonTipSide.left:
        if (availableRight < balloonWidth && availableLeft > availableRight) {
          return BalloonTipSide.right;
        }
        return BalloonTipSide.left;

      case BalloonTipSide.right:
        if (availableLeft < balloonWidth && availableRight > availableLeft) {
          return BalloonTipSide.left;
        }
        return BalloonTipSide.right;
    }
  }

  static BalloonPosition calculatePosition({
    required RenderBox targetBox,
    required RenderBox overlayBox,
    required double balloonWidth,
    required double maxHeight,
    BalloonTipSide tipSide = BalloonTipSide.top,
    bool autoFlip = true,
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
      autoFlip: autoFlip,
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

  static BalloonPosition calculatePositionFromLocalPoint({
    required Offset anchor,
    required Size overlaySize,
    required double balloonWidth,
    required double maxHeight,
    BalloonTipSide tipSide = BalloonTipSide.top,
    bool autoFlip = true,
    double topGap = 0,
    double screenMargin = 8,
    double tipWidth = 18,
    double tipHeight = 10,
    double tipHorizontalMargin = 20,
    double tipVerticalMargin = 20,
    Size? targetSize,
    Offset? targetOffset,
  }) {
    final resolvedTargetSize = targetSize ?? Size.zero;
    final resolvedTargetOffset = targetOffset ?? anchor;

    final resolvedTipSide = _resolveAutoTipSide(
      preferredSide: tipSide,
      autoFlip: autoFlip,
      anchor: anchor,
      overlaySize: overlaySize,
      balloonWidth: balloonWidth,
      maxHeight: maxHeight,
      topGap: topGap,
      screenMargin: screenMargin,
      tipHeight: tipHeight,
      targetSize: targetSize,
      targetOffset: targetOffset,
    );

    double safeLeft;
    double safeTop;
    double safeTipCenterX = balloonWidth / 2;
    double safeTipCenterY = maxHeight / 2;
    double popupWidth = balloonWidth;
    double popupMaxHeight = maxHeight;

    final hasTargetBox = targetSize != null && targetOffset != null;

    switch (resolvedTipSide) {
      case BalloonTipSide.top:
        popupWidth = balloonWidth;

        final rawLeft = anchor.dx - (balloonWidth / 2);
        final maxLeft = overlaySize.width - balloonWidth - screenMargin;

        safeLeft = _safeClamp(
          rawLeft,
          screenMargin,
          maxLeft,
        );

        safeTop = hasTargetBox
            ? resolvedTargetOffset.dy + resolvedTargetSize.height + topGap
            : anchor.dy + topGap;

        final availableHeight = overlaySize.height -
            safeTop -
            tipHeight -
            screenMargin;

        popupMaxHeight = _resolveMaxHeight(
          requestedMaxHeight: maxHeight,
          availableHeight: availableHeight,
        );

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

        final targetTop = hasTargetBox ? resolvedTargetOffset.dy : anchor.dy;

        final availableHeight = targetTop -
            topGap -
            tipHeight -
            screenMargin;

        popupMaxHeight = _resolveMaxHeight(
          requestedMaxHeight: maxHeight,
          availableHeight: availableHeight,
        );

        final rawTop = targetTop - popupMaxHeight - tipHeight - topGap;
        final maxTop =
            overlaySize.height - popupMaxHeight - tipHeight - screenMargin;

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

        final rawLeft = hasTargetBox
            ? resolvedTargetOffset.dx + resolvedTargetSize.width + topGap
            : anchor.dx + topGap;

        final availableHeight = overlaySize.height -
            (screenMargin * 2);

        popupMaxHeight = _resolveMaxHeight(
          requestedMaxHeight: maxHeight,
          availableHeight: availableHeight,
        );

        final rawTop = anchor.dy - (popupMaxHeight / 2);

        final maxTop = overlaySize.height - popupMaxHeight - screenMargin;
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
          popupMaxHeight - tipVerticalMargin,
        );

        break;

      case BalloonTipSide.right:
        popupWidth = balloonWidth + tipHeight;

        final rawLeft = hasTargetBox
            ? resolvedTargetOffset.dx - popupWidth - topGap
            : anchor.dx - popupWidth - topGap;

        final availableHeight = overlaySize.height -
            (screenMargin * 2);

        popupMaxHeight = _resolveMaxHeight(
          requestedMaxHeight: maxHeight,
          availableHeight: availableHeight,
        );

        final rawTop = anchor.dy - (popupMaxHeight / 2);

        final maxTop = overlaySize.height - popupMaxHeight - screenMargin;
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
          popupMaxHeight - tipVerticalMargin,
        );

        break;
    }

    return BalloonPosition(
      left: safeLeft,
      top: safeTop,
      tipCenterX: safeTipCenterX,
      tipCenterY: safeTipCenterY,
      popupWidth: popupWidth,
      popupMaxHeight: popupMaxHeight,
      tipSide: resolvedTipSide,
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

  double get _resolvedMinHeight {
    if (forceMaxHeight) return maxHeight;

    final value = minHeight ?? 0;

    if (value <= 0) return 0;
    if (value > maxHeight) return maxHeight;

    return value;
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
        minHeight: _resolvedMinHeight,
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