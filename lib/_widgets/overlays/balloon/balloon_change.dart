// lib/_widgets/overlays/balloon/balloon_change.dart

import 'dart:math' as math;

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
    this.globalAnchorBuilder,
    this.rebuildListenable,
    required this.width,
    required this.maxHeight,
    this.minHeight,
    this.forceMaxHeight = false,
    this.title,
    this.showHeader = true,
    required this.items,
    this.tipSide = BalloonTipSide.top,
    this.autoFlip = true,
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
  final double? minHeight;
  final bool forceMaxHeight;

  final BalloonTipSide tipSide;

  /// Quando true, troca automaticamente o lado do balão
  /// se não houver espaço suficiente na direção preferida.
  final bool autoFlip;

  final bool showHeader;
  final String? title;
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
  final GlobalKey _popupKey = GlobalKey();

  double? _measuredTotalHeight;

  static const double _headerHeight = 41.0;
  static const double _loadingHeight = 58.0;
  static const double _errorMinHeight = 54.0;
  static const double _emptyHeight = 88.0;

  static const double _tileSimpleHeight = 45.0;
  static const double _tileWithSecondaryHeight = 76.0;
  static const double _dividerHeight = 1.0;

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

    if (oldWidget.items.length != widget.items.length ||
        oldWidget.maxHeight != widget.maxHeight ||
        oldWidget.width != widget.width ||
        oldWidget.tipSide != widget.tipSide ||
        oldWidget.forceMaxHeight != widget.forceMaxHeight ||
        oldWidget.title != widget.title ||
        oldWidget.showHeader != widget.showHeader ||
        oldWidget.loading != widget.loading ||
        oldWidget.error != widget.error) {
      _measuredTotalHeight = null;
    }
  }

  @override
  void dispose() {
    widget.rebuildListenable?.removeListener(_handleRebuildRequested);
    super.dispose();
  }

  void _handleRebuildRequested() {
    if (!mounted) return;

    _measuredTotalHeight = null;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final estimatedContainerHeight = _resolveEstimatedContainerHeight();

    final initialPosition = _calculatePosition(
      containerHeightForCalculation: estimatedContainerHeight,
    );

    if (initialPosition == null) {
      return const SizedBox.shrink();
    }


    final measuredContainerHeight = _resolveMeasuredContainerHeight(
      side: initialPosition.tipSide,
      fallback: estimatedContainerHeight,
    );

    final position = _measuredTotalHeight == null
        ? initialPosition
        : _calculatePosition(
      containerHeightForCalculation: measuredContainerHeight,
    ) ??
        initialPosition;

    _scheduleMeasure();

    return Positioned(
      left: position.left,
      top: position.top,
      width: position.popupWidth,
      child: Material(
        key: _popupKey,
        type: MaterialType.transparency,
        child: BalloonBody(
          width: widget.width,
          maxHeight: position.popupMaxHeight,
          minHeight: widget.minHeight,
          forceMaxHeight: widget.forceMaxHeight,
          tipSide: position.tipSide,
          tipCenterX: position.tipCenterX,
          tipCenterY: position.tipCenterY,
          title: widget.title,
          showHeader: widget.showHeader,
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

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final context = _popupKey.currentContext;

      if (context == null) {
        return;
      }

      final renderObject = context.findRenderObject();

      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return;
      }

      final measuredHeight = renderObject.size.height;

      if (measuredHeight <= 0) {
        return;
      }

      final current = _measuredTotalHeight;

      if (current != null && (current - measuredHeight).abs() < 0.5) {
        return;
      }

      setState(() {
        _measuredTotalHeight = measuredHeight;
      });
    });
  }

  double _resolveEstimatedContainerHeight() {
    if (widget.forceMaxHeight) {
      return widget.maxHeight;
    }

    final estimatedHeight = _estimateNaturalContainerHeight();
    final requestedMinHeight = widget.minHeight ?? 0;

    final resolvedHeight = math.max(
      requestedMinHeight,
      estimatedHeight,
    );

    return resolvedHeight.clamp(
      0.0,
      widget.maxHeight,
    );
  }

  double _resolveMeasuredContainerHeight({
    required BalloonTipSide side,
    required double fallback,
  }) {
    final measuredTotalHeight = _measuredTotalHeight;

    if (measuredTotalHeight == null || measuredTotalHeight <= 0) {
      return fallback;
    }

    final rawContainerHeight = switch (side) {
      BalloonTipSide.top || BalloonTipSide.bottom =>
      measuredTotalHeight - widget.tipHeight,
      BalloonTipSide.left || BalloonTipSide.right => measuredTotalHeight,
    };

    return rawContainerHeight.clamp(
      0.0,
      widget.maxHeight,
    );
  }

  double _estimateNaturalContainerHeight() {
    double height = 0;

    if (_hasHeader) {
      height += _headerHeight;
    }

    final cleanError = (widget.error ?? '').trim();

    if (cleanError.isNotEmpty) {
      height += _errorMinHeight;
      return height;
    }

    if (widget.loading) {
      height += _loadingHeight;
      return height;
    }

    if (widget.items.isEmpty) {
      height += _emptyHeight;
      return height;
    }

    for (final item in widget.items) {
      height += item.hasSecondaryContent
          ? _tileWithSecondaryHeight
          : _tileSimpleHeight;
    }

    if (widget.items.length > 1) {
      height += (widget.items.length - 1) * _dividerHeight;
    }

    return height;
  }

  bool get _hasHeader {
    if (!widget.showHeader) {
      return false;
    }

    final cleanTitle = (widget.title ?? '').trim();
    final cleanActionLabel = (widget.actionLabel ?? '').trim();

    final hasAction = widget.showAction &&
        cleanActionLabel.isNotEmpty &&
        widget.onAction != null;

    return cleanTitle.isNotEmpty || widget.headerIcon != null || hasAction;
  }

  BalloonPosition? _calculatePosition({
    required double containerHeightForCalculation,
  }) {
    final target = widget.targetBox;

    if (target != null && target.attached) {
      return BalloonPopup.calculatePosition(
        targetBox: target,
        overlayBox: widget.overlayBox,
        balloonWidth: widget.width,
        maxHeight: containerHeightForCalculation,
        tipSide: widget.tipSide,
        autoFlip: widget.autoFlip,
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
      maxHeight: containerHeightForCalculation,
      tipSide: widget.tipSide,
      autoFlip: widget.autoFlip,
      topGap: widget.topGap,
      screenMargin: widget.screenMargin,
      tipWidth: widget.tipWidth,
      tipHeight: widget.tipHeight,
      tipHorizontalMargin: widget.tipHorizontalMargin,
      tipVerticalMargin: widget.tipVerticalMargin,
    );
  }
}