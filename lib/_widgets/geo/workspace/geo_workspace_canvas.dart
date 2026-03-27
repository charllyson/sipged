import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_data.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_panel.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_dashboard.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_guide.dart';

class GeoWorkspaceCanvas extends StatefulWidget {
  const GeoWorkspaceCanvas({
    super.key,
    required this.onCatalogItemDropped,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final void Function(
      TabWidgetsCatalog item,
      Offset localOffset,
      ) onCatalogItemDropped;

  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  State<GeoWorkspaceCanvas> createState() => _GeoWorkspaceCanvasState();
}

class _GeoWorkspaceCanvasState extends State<GeoWorkspaceCanvas> {
  final GlobalKey _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelSize = Size(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
            constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
          );

          final cubit = context.read<GeoWorkspaceCubit>();
          if (cubit.state.panelSize != panelSize) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              cubit.setPanelSize(panelSize);
            });
          }

          return DragTarget<TabWidgetsCatalog>(
            onWillAcceptWithDetails: (_) => true,
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
                    child: _CanvasBackground(receiving: receiving),
                  ),
                  const Positioned.fill(
                    child: _GuidesOverlay(),
                  ),
                  Positioned.fill(
                    child: _ItemsLayer(
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
    );
  }
}

class _CanvasBackground extends StatelessWidget {
  const _CanvasBackground({
    required this.receiving,
  });

  final bool receiving;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, bool>(
      selector: (state) => state.hasItems,
      builder: (context, hasItems) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<GeoWorkspaceCubit>().clearSelection(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: receiving
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: hasItems
                ? null
                : Center(
              child: Text(
                receiving
                    ? 'Solte aqui para adicionar ao dashboard'
                    : 'Arraste visualizações para esta área',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GuidesOverlay extends StatelessWidget {
  const _GuidesOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState,
            GeoWorkspaceGuideLines?>(
          selector: (state) => state.guides,
          builder: (context, guides) {
            return CustomPaint(
              painter: GeoWorkspaceGuide(guides: guides),
            );
          },
        ),
      ),
    );
  }
}

class _ItemsLayer extends StatelessWidget {
  const _ItemsLayer({
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, List<String>>(
      selector: (state) => state.itemIds,
      builder: (context, itemIds) {
        return Stack(
          children: itemIds
              .map(
                (itemId) => _PositionedWorkspaceItem(
              key: ValueKey(itemId),
              itemId: itemId,
              onItemChanged: onItemChanged,
              onItemRemoved: onItemRemoved,
            ),
          )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PositionedWorkspaceItem extends StatelessWidget {
  const _PositionedWorkspaceItem({
    super.key,
    required this.itemId,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final String itemId;
  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, _WorkspaceItemView?>(
      selector: (state) {
        final item = state.itemByIdOrNull(itemId);
        if (item == null) return null;

        return _WorkspaceItemView(
          item: item,
          selected: state.isSelected(itemId),
          dataVersion: state.dataVersion,
        );
      },
      builder: (context, view) {
        if (view == null) return const SizedBox.shrink();

        final item = view.item;

        return Positioned(
          left: item.offset.dx,
          top: item.offset.dy,
          width: item.size.width,
          height: item.size.height,
          child: RepaintBoundary(
            child: GeoWorkspaceDashboard(
              item: item,
              dataVersion: view.dataVersion,
              selected: view.selected,
              onSelected: () {
                context.read<GeoWorkspaceCubit>().selectItem(item.id);
              },
              onMoveLive: (desiredRect) {
                context.read<GeoWorkspaceCubit>().moveItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                );
              },
              onMoveEnd: (finalRect) {
                final resolved =
                context.read<GeoWorkspaceCubit>().moveItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                );

                onItemChanged(
                  item.id,
                  resolved.rect.topLeft,
                  resolved.rect.size,
                );
              },
              onResizeLive: (handle, desiredRect) {
                context.read<GeoWorkspaceCubit>().resizeItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                  handle: handle,
                );
              },
              onResizeEnd: (handle, finalRect) {
                final resolved =
                context.read<GeoWorkspaceCubit>().resizeItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                  handle: handle,
                );

                onItemChanged(
                  item.id,
                  resolved.rect.topLeft,
                  resolved.rect.size,
                );
              },
              onRemove: () {
                context.read<GeoWorkspaceCubit>().removeItemLocal(item.id);
                onItemRemoved(item.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _WorkspaceItemView {
  final GeoWorkspaceData item;
  final bool selected;
  final int dataVersion;

  const _WorkspaceItemView({
    required this.item,
    required this.selected,
    required this.dataVersion,
  });

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceItemView &&
        other.item == item &&
        other.selected == selected &&
        other.dataVersion == dataVersion;
  }

  @override
  int get hashCode => Object.hash(item, selected, dataVersion);
}