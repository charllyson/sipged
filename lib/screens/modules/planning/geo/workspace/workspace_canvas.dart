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
    required this.onItemChanged,
    required this.onItemRemoved,
    this.pendingCatalogItem,
    this.onPanelSizeChanged,
  });

  final void Function(CatalogData item, Offset localOffset) onCatalogItemDropped;
  final void Function(CatalogData item, Offset localOffset)
  onCatalogItemPlacedByClick;
  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;
  final CatalogData? pendingCatalogItem;
  final ValueChanged<Size>? onPanelSizeChanged;

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
            final panelSize = Size(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
              constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
            );

            final cubit = context.read<WorkspaceCubit>();
            _syncPanelSize(cubit, panelSize);
            _reportPanelSize(panelSize);

            return DragTarget<CatalogData>(
              onWillAcceptWithDetails: (details) => details.data.id.isNotEmpty,
              onAcceptWithDetails: (details) {
                final renderBox =
                _stackKey.currentContext?.findRenderObject() as RenderBox?;
                if (renderBox == null) return;

                final local = renderBox.globalToLocal(details.offset);
                widget.onCatalogItemDropped(details.data, local);
              },
              builder: (context, candidateData, rejectedData) {
                final receiving = candidateData.isNotEmpty;

                return Stack(
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
                    Positioned.fill(
                      child: WorkspaceItem(
                        onItemChanged: widget.onItemChanged,
                        onItemRemoved: widget.onItemRemoved,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}