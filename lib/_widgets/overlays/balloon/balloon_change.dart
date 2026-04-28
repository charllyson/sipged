import 'package:flutter/material.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_body.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_painter.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class BalloonChange extends StatelessWidget {
  const BalloonChange({
    super.key,
    this.targetBox,
    required this.overlayBox,
    this.localAnchor,
    this.globalAnchor,
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
  targetBox != null || localAnchor != null || globalAnchor != null,
  'Informe targetBox, localAnchor ou globalAnchor para posicionar o BalloonChange.',
  );

  final RenderBox? targetBox;
  final RenderBox overlayBox;

  final Offset? localAnchor;
  final Offset? globalAnchor;

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
  Widget build(BuildContext context) {
    final position = _calculatePosition();

    return Positioned(
      left: position.left,
      top: position.top,
      width: position.popupWidth,
      child: Material(
        type: MaterialType.transparency,
        child: BalloonBody(
          width: width,
          maxHeight: maxHeight,
          tipSide: tipSide,
          tipCenterX: position.tipCenterX,
          tipCenterY: position.tipCenterY,
          title: title,
          headerIcon: headerIcon,
          actionLabel: actionLabel,
          showAction: showAction,
          onAction: onAction,
          loading: loading,
          error: error,
          emptyIcon: emptyIcon,
          emptyMessage: emptyMessage,
          items: items,
        ),
      ),
    );
  }

  BalloonPosition _calculatePosition() {
    final target = targetBox;

    if (target != null) {
      return BalloonPopup.calculatePosition(
        targetBox: target,
        overlayBox: overlayBox,
        balloonWidth: width,
        maxHeight: maxHeight,
        tipSide: tipSide,
        topGap: topGap,
        screenMargin: screenMargin,
        tipWidth: tipWidth,
        tipHeight: tipHeight,
        tipHorizontalMargin: tipHorizontalMargin,
        tipVerticalMargin: tipVerticalMargin,
      );
    }

    final overlaySize = overlayBox.size;

    final Offset anchor = localAnchor ??
        overlayBox.globalToLocal(
          globalAnchor!,
        );

    return BalloonPopup.calculatePositionFromLocalPoint(
      anchor: anchor,
      overlaySize: overlaySize,
      balloonWidth: width,
      maxHeight: maxHeight,
      tipSide: tipSide,
      topGap: topGap,
      screenMargin: screenMargin,
      tipWidth: tipWidth,
      tipHeight: tipHeight,
      tipHorizontalMargin: tipHorizontalMargin,
      tipVerticalMargin: tipVerticalMargin,
    );
  }
}