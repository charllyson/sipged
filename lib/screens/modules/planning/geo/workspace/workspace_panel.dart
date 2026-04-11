import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_scope_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_canvas.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({
    super.key,
    required this.scope,
    required this.featuresByLayer,
    this.pendingCatalogItem,
    this.selectedWorkspaceItemId,
    this.onSelectedCatalogItemChanged,
    this.onSelectedWorkspaceItemChanged,
    this.onPanelSizeChanged,
    this.onItemsChanged,
    this.canvasMinSize = const Size(1400, 900),
  });

  final WorkspaceScopeData scope;
  final Map<String, List<FeatureData>> featuresByLayer;

  final CatalogData? pendingCatalogItem;
  final String? selectedWorkspaceItemId;

  final ValueChanged<String?>? onSelectedCatalogItemChanged;
  final ValueChanged<WorkspaceData?>? onSelectedWorkspaceItemChanged;
  final ValueChanged<Size>? onPanelSizeChanged;
  final ValueChanged<List<WorkspaceData>>? onItemsChanged;

  /// Tamanho virtual mínimo do canvas da área de trabalho.
  final Size canvasMinSize;

  @override
  WorkspacePanelState createState() => WorkspacePanelState();
}

class WorkspacePanelState extends State<WorkspacePanel> {
  static const double _autoEdgePadding = 0;
  static const double _autoGap = 16;

  late final WorkspaceCubit _cubit;
  int _workspaceCounter = 0;

  @override
  void initState() {
    super.initState();

    _cubit = WorkspaceCubit(
      scope: widget.scope,
      initialFeaturesByLayer: widget.featuresByLayer,
      repository: WorkspaceRepository(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await _cubit.loadScope(scope: widget.scope);

      if (!mounted) return;

      _cubit.syncExternalFeatures(widget.featuresByLayer);
      _syncSelectionFromParent();
      _notifySelection(_cubit.state);
      widget.onItemsChanged?.call(_cubit.state.items);
    });
  }

  @override
  void didUpdateWidget(covariant WorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scope != widget.scope) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await _cubit.loadScope(scope: widget.scope);

        if (!mounted) return;

        _cubit.syncExternalFeatures(widget.featuresByLayer);
        _syncSelectionFromParent();
        _notifySelection(_cubit.state);
        widget.onItemsChanged?.call(_cubit.state.items);
      });
      return;
    }

    if (!mapEquals(oldWidget.featuresByLayer, widget.featuresByLayer)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cubit.syncExternalFeatures(widget.featuresByLayer);
      });
    }

    if (oldWidget.selectedWorkspaceItemId != widget.selectedWorkspaceItemId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncSelectionFromParent();
      });
    }
  }

  void _syncSelectionFromParent() {
    final selectedId = widget.selectedWorkspaceItemId?.trim();

    if (selectedId == null || selectedId.isEmpty) {
      _cubit.clearSelection();
      return;
    }

    final exists = _cubit.state.items.any((item) => item.id == selectedId);
    if (!exists) {
      _cubit.clearSelection();
      return;
    }

    _cubit.selectItem(selectedId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _notifySelection(WorkspaceState state) {
    final selectedItem = state.selectedItem;
    widget.onSelectedCatalogItemChanged?.call(selectedItem?.catalogItemId);
    widget.onSelectedWorkspaceItemChanged?.call(selectedItem);
  }

  String _nextItemId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final scopeId =
    widget.scope.documentId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'workspace_item_${scopeId}_${stamp}_${_workspaceCounter++}';
  }

  Offset _findAutomaticPlacementOffset(CatalogData catalogItem) {
    final type = ComponentTypeMapper.fromCatalogItemId(catalogItem.id);
    if (type == null) {
      return const Offset(100, 100);
    }

    final itemSize = type.defaultSize;
    final panelSize = _cubit.state.panelSize;

    final effectivePanel = (panelSize.width > 0 && panelSize.height > 0)
        ? panelSize
        : widget.canvasMinSize;

    final maxLeft = math.max(
      _autoEdgePadding,
      effectivePanel.width - itemSize.width - _autoEdgePadding,
    );

    final maxTop = math.max(
      _autoEdgePadding,
      effectivePanel.height - itemSize.height - _autoEdgePadding,
    );

    final existingRects = _cubit.state.items
        .map(
          (e) => Rect.fromLTWH(
        e.offset.dx,
        e.offset.dy,
        e.size.width,
        e.size.height,
      ),
    )
        .toList(growable: false);

    bool overlaps(Rect candidate) {
      final candidateWithGap = candidate.inflate(_autoGap / 2);
      for (final rect in existingRects) {
        if (rect.overlaps(candidateWithGap)) return true;
      }
      return false;
    }

    for (double top = _autoEdgePadding;
    top <= maxTop;
    top += itemSize.height + _autoGap) {
      for (double left = _autoEdgePadding;
      left <= maxLeft;
      left += itemSize.width + _autoGap) {
        final candidate = Rect.fromLTWH(
          left,
          top,
          itemSize.width,
          itemSize.height,
        );

        if (!overlaps(candidate)) {
          return candidate.center;
        }
      }
    }

    final fallbackLeft = (_autoEdgePadding + (_cubit.state.items.length * 28))
        .clamp(_autoEdgePadding, maxLeft)
        .toDouble();

    final fallbackTop = (_autoEdgePadding + (_cubit.state.items.length * 20))
        .clamp(_autoEdgePadding, maxTop)
        .toDouble();

    return Offset(
      fallbackLeft + (itemSize.width / 2),
      fallbackTop + (itemSize.height / 2),
    );
  }

  WorkspaceData _buildWorkspaceItemFromCatalog({
    required CatalogData catalogItem,
    required Offset localOffset,
  }) {
    final type = ComponentTypeMapper.fromCatalogItemId(catalogItem.id);
    if (type == null) {
      throw Exception('Tipo não implementado: ${catalogItem.id}');
    }

    final size = type.defaultSize;
    final centeredOffset = Offset(
      localOffset.dx - (size.width / 2),
      localOffset.dy - (size.height / 2),
    );

    return WorkspaceData(
      id: _nextItemId(),
      title: catalogItem.title,
      type: type,
      offset: centeredOffset,
      size: size,
      properties: type.defaultProperties,
    );
  }

  void placeCatalogItemAt(CatalogData item, Offset localOffset) {
    final newItem = _buildWorkspaceItemFromCatalog(
      catalogItem: item,
      localOffset: localOffset,
    );

    _cubit.addItem(newItem);
  }

  void placeCatalogItemAutomatically(CatalogData item) {
    final offset = _findAutomaticPlacementOffset(item);
    placeCatalogItemAt(item, offset);
  }

  void updateItemProperty(String itemId, CatalogData property) {
    final propertyKey = property.key;
    if (propertyKey == null || propertyKey.trim().isEmpty) return;

    _cubit.updateItemProperty(
      itemId: itemId,
      propertyKey: propertyKey,
      property: property,
    );
  }

  Future<void> applyBinding(
      String itemId,
      String propertyKey,
      AttributeData data,
      List<LayerData> currentTree,
      ) async {
    final currentItem = _cubit.state.itemByIdOrNull(itemId);
    if (currentItem == null) return;

    final updatedProperties = currentItem.properties.map((property) {
      if (property.key == propertyKey) {
        return property.copyWith(
          bindingValue: AttributeData(
            sourceId: data.sourceId,
            sourceLabel: data.sourceLabel,
            fieldName: data.fieldName,
            aggregation: data.aggregation,
            fieldValue: data.fieldValue,
            fieldValues: data.fieldValues,
          ),
        );
      }

      if (property.key == 'source') {
        final currentBinding = property.bindingValue;
        final currentSourceId = currentBinding?.sourceId?.trim() ?? '';
        final newSourceId = data.sourceId?.trim() ?? '';

        if (newSourceId.isNotEmpty &&
            (currentSourceId.isEmpty || currentSourceId != newSourceId)) {
          return property.copyWith(
            bindingValue: AttributeData(
              sourceId: data.sourceId,
              sourceLabel: data.sourceLabel,
            ),
          );
        }
      }

      return property;
    }).toList(growable: false);

    _cubit.updateItemProperties(
      itemId: itemId,
      properties: updatedProperties,
    );

    final sourceId = data.sourceId?.trim() ?? '';
    if (sourceId.isEmpty) return;

    final layersCubit = context.read<LayerCubit>();
    final featureCubit = context.read<FeatureCubit>();

    final layer = layersCubit.findNodeById(sourceId, tree: currentTree);
    if (layer == null || layer.isGroup) return;

    await featureCubit.ensureLayerFieldNames(layer, force: false);
    await featureCubit.ensureLayerLoaded(layer, force: false);

    if (!mounted) return;

    _cubit.syncExternalFeatures(widget.featuresByLayer);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceCubit>.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<WorkspaceCubit, WorkspaceState>(
            listenWhen: (previous, current) {
              return previous.selectedItemId != current.selectedItemId ||
                  previous.selectedItem != current.selectedItem;
            },
            listener: (context, state) {
              _notifySelection(state);
            },
          ),
          BlocListener<WorkspaceCubit, WorkspaceState>(
            listenWhen: (previous, current) {
              return current.loaded &&
                  !current.isLoading &&
                  (!identical(previous.items, current.items) ||
                      !listEquals(previous.items, current.items));
            },
            listener: (context, state) {
              widget.onItemsChanged?.call(state.items);
            },
          ),
        ],
        child: WorkspaceCanvas(
          pendingCatalogItem: widget.pendingCatalogItem,
          onCatalogItemDropped: placeCatalogItemAt,
          onCatalogItemPlacedByClick: placeCatalogItemAt,
          onPanelSizeChanged: widget.onPanelSizeChanged,
          canvasMinSize: widget.canvasMinSize,
        ),
      ),
    );
  }
}