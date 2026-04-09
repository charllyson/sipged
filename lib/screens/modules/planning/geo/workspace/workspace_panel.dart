import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_canvas.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({
    super.key,
    required this.items,
    required this.featuresByLayer,
    required this.onCatalogItemDropped,
    required this.onCatalogItemPlacedByClick,
    required this.onItemChanged,
    required this.onItemRemoved,
    this.pendingCatalogItem,
    this.selectedWorkspaceItemId,
    this.onSelectedCatalogItemChanged,
    this.onSelectedWorkspaceItemChanged,
    this.onPanelSizeChanged,
  });

  final List<WorkspaceData> items;
  final Map<String, List<FeatureData>> featuresByLayer;

  final void Function(CatalogData item, Offset localOffset) onCatalogItemDropped;
  final void Function(CatalogData item, Offset localOffset)
  onCatalogItemPlacedByClick;
  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;

  final CatalogData? pendingCatalogItem;
  final String? selectedWorkspaceItemId;

  final ValueChanged<String?>? onSelectedCatalogItemChanged;
  final ValueChanged<WorkspaceData?>? onSelectedWorkspaceItemChanged;
  final ValueChanged<Size>? onPanelSizeChanged;

  @override
  State<WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<WorkspacePanel> {
  late final WorkspaceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = WorkspaceCubit(
      initialItems: widget.items,
      initialFeaturesByLayer: widget.featuresByLayer,
      repository: const WorkspaceRepository(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectionFromParent();
      _notifySelection(_cubit.state);
    });
  }

  @override
  void didUpdateWidget(covariant WorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.items, widget.items)) {
      _cubit.syncExternalItems(widget.items);
    }

    if (!identical(oldWidget.featuresByLayer, widget.featuresByLayer)) {
      _cubit.syncExternalFeatures(widget.featuresByLayer);
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceCubit>.value(
      value: _cubit,
      child: BlocListener<WorkspaceCubit, WorkspaceState>(
        listenWhen: (previous, current) {
          return previous.selectedItemId != current.selectedItemId ||
              previous.selectedItem != current.selectedItem;
        },
        listener: (context, state) => _notifySelection(state),
        child: WorkspaceCanvas(
          pendingCatalogItem: widget.pendingCatalogItem,
          onCatalogItemDropped: widget.onCatalogItemDropped,
          onCatalogItemPlacedByClick: widget.onCatalogItemPlacedByClick,
          onItemChanged: widget.onItemChanged,
          onItemRemoved: widget.onItemRemoved,
          onPanelSizeChanged: widget.onPanelSizeChanged,
        ),
      ),
    );
  }
}