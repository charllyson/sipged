import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guide_lines_data.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guides_line_drawer.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_background.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_item.dart';

class WorkspaceCanvas extends StatefulWidget {
  const WorkspaceCanvas({
    super.key,
    required this.onCatalogItemDropped,
    required this.onCatalogItemPlacedByClick,
    this.pendingCatalogItem,
    this.onPanelSizeChanged,
    this.canvasMinSize = const Size(1400, 900),
  });

  final void Function(CatalogData item, Offset localOffset) onCatalogItemDropped;
  final void Function(CatalogData item, Offset localOffset)
  onCatalogItemPlacedByClick;
  final CatalogData? pendingCatalogItem;
  final ValueChanged<Size>? onPanelSizeChanged;

  /// Tamanho virtual mínimo da área de trabalho.
  /// Quando o painel visível for menor que isso, o canvas continua maior
  /// e o usuário pode navegar com scroll horizontal/vertical.
  final Size canvasMinSize;

  @override
  State<WorkspaceCanvas> createState() => _WorkspaceCanvasState();
}

class _WorkspaceCanvasState extends State<WorkspaceCanvas> {
  final GlobalKey _stackKey = GlobalKey();
  Size _lastReportedPanelSize = Size.zero;

  void _syncPanelSize(WorkspaceCubit cubit, Size panelSize) {
    if (cubit.state.panelSize == panelSize) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cubit.setPanelSize(panelSize);
    });
  }

  void _reportPanelSize(Size panelSize) {
    if (_lastReportedPanelSize == panelSize) return;
    _lastReportedPanelSize = panelSize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPanelSizeChanged?.call(panelSize);
    });
  }

  void _handleBackgroundTapDown(TapDownDetails details) {
    final cubit = context.read<WorkspaceCubit>();
    final pendingItem = widget.pendingCatalogItem;

    if (pendingItem == null) {
      cubit.clearSelection();
      return;
    }

    widget.onCatalogItemPlacedByClick(
      pendingItem,
      details.localPosition,
    );

    cubit.clearSelection();
  }

  Widget _buildCanvas({
    required Size canvasSize,
    required CatalogData? pending,
  }) {
    return DragTarget<CatalogData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data.id.trim().isNotEmpty;
      },
      onAcceptWithDetails: (details) {
        final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return;

        final local = renderBox.globalToLocal(details.offset);
        widget.onCatalogItemDropped(details.data, local);
      },
      builder: (context, candidateData, rejectedData) {
        final receiving = candidateData.isNotEmpty;

        return SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            key: _stackKey,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: WorkspaceBackground(
                  receiving: receiving,
                  pendingPlacementTitle: pending?.title,
                  onTapBackground: _handleBackgroundTapDown,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: BlocSelector<WorkspaceCubit, WorkspaceState,
                        GuideLinesData?>(
                      selector: (state) => state.guides,
                      builder: (context, guides) {
                        return CustomPaint(
                          painter: GuidesLinesDrawer(guides: guides),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: WorkspaceItem(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pendingCatalogItem;
    final isPlacementMode = pending != null;

    return MouseRegion(
      cursor: isPlacementMode
          ? SystemMouseCursors.precise
          : SystemMouseCursors.basic,
      child: ColoredBox(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
            final viewportHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;

            final canvasWidth = math.max(
              viewportWidth,
              widget.canvasMinSize.width,
            );
            final canvasHeight = math.max(
              viewportHeight,
              widget.canvasMinSize.height,
            );

            final canvasSize = Size(canvasWidth, canvasHeight);

            final cubit = context.read<WorkspaceCubit>();
            _syncPanelSize(cubit, canvasSize);
            _reportPanelSize(canvasSize);

            return ClipRect(
              child: ScrollConfiguration(
                behavior: const _WorkspaceScrollBehavior(),
                child: Scrollbar(
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      thumbVisibility: true,
                      notificationPredicate: (notification) =>
                      notification.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildCanvas(
                          canvasSize: canvasSize,
                          pending: pending,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkspaceScrollBehavior extends MaterialScrollBehavior {
  const _WorkspaceScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return child;
  }
}