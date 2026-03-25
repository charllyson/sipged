import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_widgets/geo/visualizations/itens/geo_visualizations_panel.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_guide_painter.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_snap_controller.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';

import 'geo_workspace_dashboard_item.dart';

class GeoWorkspaceCanvas extends StatelessWidget {
  const GeoWorkspaceCanvas({
    super.key,
    required this.stackKey,
    required this.itemNotifiers,
    required this.selectedItemIdListenable,
    required this.guidesListenable,
    required this.snapController,
    required this.featuresByLayer,
    required this.onBackgroundTap,
    required this.onCatalogItemDropped,
    required this.onItemSelected,
    required this.onItemLiveChanged,
    required this.onItemCommitChanged,
    required this.onItemRemoved,
    required this.onGuidesChanged,
  });

  final GlobalKey stackKey;
  final List<ValueNotifier<GeoWorkspaceItemData>> itemNotifiers;
  final ValueListenable<String?> selectedItemIdListenable;
  final ValueListenable<GeoWorkspaceGuideLines?> guidesListenable;
  final GeoWorkspaceSnapController snapController;
  final Map<String, List<GeoFeatureData>> featuresByLayer;

  final VoidCallback onBackgroundTap;
  final void Function(
      GeoVisualizationCatalogItem item,
      Offset localOffset,
      ) onCatalogItemDropped;
  final ValueChanged<String> onItemSelected;
  final void Function(String itemId, Offset offset, Size size) onItemLiveChanged;
  final void Function(String itemId, Offset offset, Size size)
  onItemCommitChanged;
  final void Function(String itemId) onItemRemoved;
  final ValueChanged<GeoWorkspaceGuideLines?> onGuidesChanged;

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

          return DragTarget<GeoVisualizationCatalogItem>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              final renderBox =
              stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox == null) return;

              final local = renderBox.globalToLocal(details.offset);
              onCatalogItemDropped(details.data, local);
            },
            builder: (context, candidateData, rejectedData) {
              final receiving = candidateData.isNotEmpty;

              return Stack(
                key: stackKey,
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBackgroundTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: receiving
                                ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: itemNotifiers.isEmpty
                            ? Center(
                          child: Text(
                            receiving
                                ? 'Solte aqui para adicionar ao dashboard'
                                : 'Arraste visualizações para esta área',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                              Colors.black.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<GeoWorkspaceGuideLines?>(
                          valueListenable: guidesListenable,
                          builder: (context, guides, _) {
                            return CustomPaint(
                              painter: GeoWorkspaceGuidePainter(
                                guides: guides,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  ...itemNotifiers.map((itemNotifier) {
                    return ValueListenableBuilder<GeoWorkspaceItemData>(
                      key: ValueKey(itemNotifier.value.id),
                      valueListenable: itemNotifier,
                      builder: (context, item, _) {
                        final initialRect = snapController.clampRect(
                          rect: Rect.fromLTWH(
                            item.offset.dx,
                            item.offset.dy,
                            item.size.width,
                            item.size.height,
                          ),
                          panelSize: panelSize,
                        );

                        final normalizedItem = item.copyWith(
                          offset: initialRect.topLeft,
                          size: initialRect.size,
                        );

                        return Positioned(
                          left: initialRect.left,
                          top: initialRect.top,
                          width: initialRect.width,
                          height: initialRect.height,
                          child: RepaintBoundary(
                            child: ValueListenableBuilder<String?>(
                              valueListenable: selectedItemIdListenable,
                              builder: (context, selectedItemId, _) {
                                return GeoWorkspaceDashboardItem(
                                  item: normalizedItem,
                                  featuresByLayer: featuresByLayer,
                                  selected: selectedItemId == item.id,
                                  onSelected: () => onItemSelected(item.id),
                                  onMoveLive: (desiredRect) {
                                    final items = itemNotifiers
                                        .map((e) => e.value)
                                        .toList(growable: false);

                                    final resolved =
                                    snapController.resolveMoveSnap(
                                      itemId: item.id,
                                      desiredRect: desiredRect,
                                      panelSize: panelSize,
                                      items: items,
                                    );

                                    onItemLiveChanged(
                                      item.id,
                                      resolved.rect.topLeft,
                                      resolved.rect.size,
                                    );
                                    onGuidesChanged(resolved.guides);
                                  },
                                  onMoveEnd: (finalRect) {
                                    final items = itemNotifiers
                                        .map((e) => e.value)
                                        .toList(growable: false);

                                    final resolved =
                                    snapController.resolveMoveSnap(
                                      itemId: item.id,
                                      desiredRect: finalRect,
                                      panelSize: panelSize,
                                      items: items,
                                    );

                                    onItemCommitChanged(
                                      item.id,
                                      resolved.rect.topLeft,
                                      resolved.rect.size,
                                    );
                                    onGuidesChanged(null);
                                  },
                                  onResizeLive: (handle, desiredRect) {
                                    final items = itemNotifiers
                                        .map((e) => e.value)
                                        .toList(growable: false);

                                    final resolved =
                                    snapController.resolveResizeSnap(
                                      itemId: item.id,
                                      desiredRect: desiredRect,
                                      handle: handle,
                                      panelSize: panelSize,
                                      items: items,
                                    );

                                    onItemLiveChanged(
                                      item.id,
                                      resolved.rect.topLeft,
                                      resolved.rect.size,
                                    );
                                    onGuidesChanged(resolved.guides);
                                  },
                                  onResizeEnd: (handle, finalRect) {
                                    final items = itemNotifiers
                                        .map((e) => e.value)
                                        .toList(growable: false);

                                    final resolved =
                                    snapController.resolveResizeSnap(
                                      itemId: item.id,
                                      desiredRect: finalRect,
                                      handle: handle,
                                      panelSize: panelSize,
                                      items: items,
                                    );

                                    onItemCommitChanged(
                                      item.id,
                                      resolved.rect.topLeft,
                                      resolved.rect.size,
                                    );
                                    onGuidesChanged(null);
                                  },
                                  onRemove: () => onItemRemoved(item.id),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}