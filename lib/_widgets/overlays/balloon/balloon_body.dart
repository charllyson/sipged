// lib/_widgets/overlays/balloon/balloon_body.dart

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_empty.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_header.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_painter.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class BalloonBody extends StatelessWidget {
  const BalloonBody({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.items,
    this.title,
    this.showHeader = true,
    this.tipSide = BalloonTipSide.top,
    this.tipCenterX,
    this.tipCenterY,
    this.headerIcon,
    this.actionLabel,
    this.showAction = false,
    this.onAction,
    this.loading = false,
    this.error,
    this.emptyIcon = Icons.notifications_off_outlined,
    this.emptyMessage = 'Nenhum item encontrado.',
  });

  final double width;
  final double maxHeight;

  final BalloonTipSide tipSide;

  final double? tipCenterX;
  final double? tipCenterY;

  /// Se false, oculta totalmente o header,
  /// mesmo que title, headerIcon ou action estejam preenchidos.
  final bool showHeader;

  /// Opcional. Se null ou vazio, não renderiza texto no header.
  final String? title;

  /// Opcional. Se null, não renderiza ícone no header.
  final IconData? headerIcon;

  final String? actionLabel;
  final bool showAction;
  final VoidCallback? onAction;

  final bool loading;
  final String? error;

  final IconData? emptyIcon;
  final String emptyMessage;

  final List<BalloonTileData> items;

  bool get _hasAction {
    final label = (actionLabel ?? '').trim();

    return showAction && label.isNotEmpty && onAction != null;
  }

  bool get _hasHeader {
    if (!showHeader) {
      return false;
    }

    final cleanTitle = (title ?? '').trim();

    return cleanTitle.isNotEmpty || headerIcon != null || _hasAction;
  }

  @override
  Widget build(BuildContext context) {
    final cleanError = (error ?? '').trim();

    return BalloonPopup(
      width: width,
      maxHeight: maxHeight,
      tipSide: tipSide,
      tipCenterX: tipCenterX,
      tipCenterY: tipCenterY,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasHeader) ...[
            BalloonHeader(
              title: title,
              icon: headerIcon,
              actionLabel: actionLabel,
              showAction: showAction,
              onAction: onAction,
            ),
            const Divider(height: 1),
          ],
          if (cleanError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                cleanError,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            )
          else if (loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            )
          else if (items.isEmpty)
              BalloonEmpty(
                icon: emptyIcon,
                message: emptyMessage,
              )
            else
              Flexible(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, _) {
                      return const Divider(height: 1);
                    },
                    itemBuilder: (context, index) {
                      return BalloonTile(
                        data: items[index],
                      );
                    },
                  ),
                ),
              ),
        ],
      ),
    );
  }
}