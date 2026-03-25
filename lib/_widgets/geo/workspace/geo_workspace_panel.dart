import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_widgets/geo/visualizations/itens/geo_visualizations_panel.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_canvas.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_snap_controller.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';

class GeoWorkspacePanel extends StatefulWidget {
  const GeoWorkspacePanel({
    super.key,
    required this.items,
    required this.featuresByLayer,
    required this.onCatalogItemDropped,
    required this.onItemChanged,
    required this.onItemRemoved,
    this.onSelectedCatalogItemChanged,
    this.onSelectedWorkspaceItemChanged,
  });

  final List<GeoWorkspaceItemData> items;
  final Map<String, List<GeoFeatureData>> featuresByLayer;

  final void Function(
      GeoVisualizationCatalogItem item,
      Offset localOffset,
      ) onCatalogItemDropped;

  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;

  final void Function(String itemId) onItemRemoved;

  final ValueChanged<String?>? onSelectedCatalogItemChanged;
  final ValueChanged<GeoWorkspaceItemData?>? onSelectedWorkspaceItemChanged;

  @override
  State<GeoWorkspacePanel> createState() => _GeoWorkspacePanelState();
}

class _GeoWorkspacePanelState extends State<GeoWorkspacePanel> {
  final GlobalKey _stackKey = GlobalKey();
  final GeoWorkspaceSnapController _snapController =
  const GeoWorkspaceSnapController();

  final Map<String, ValueNotifier<GeoWorkspaceItemData>> _itemNotifiersById = {};
  final ValueNotifier<GeoWorkspaceGuideLines?> _guidesNotifier =
  ValueNotifier<GeoWorkspaceGuideLines?>(null);
  final ValueNotifier<String?> _selectedItemIdNotifier =
  ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _syncNotifiersFromItems(widget.items);
  }

  @override
  void didUpdateWidget(covariant GeoWorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNotifiersFromItems(widget.items);
  }

  @override
  void dispose() {
    for (final notifier in _itemNotifiersById.values) {
      notifier.dispose();
    }
    _guidesNotifier.dispose();
    _selectedItemIdNotifier.dispose();
    super.dispose();
  }

  List<ValueNotifier<GeoWorkspaceItemData>> get _itemNotifiersInOrder {
    return widget.items
        .map((item) => _itemNotifiersById[item.id])
        .whereType<ValueNotifier<GeoWorkspaceItemData>>()
        .toList(growable: false);
  }

  void _syncNotifiersFromItems(List<GeoWorkspaceItemData> items) {
    final incomingIds = items.map((e) => e.id).toSet();

    final idsToRemove = _itemNotifiersById.keys
        .where((id) => !incomingIds.contains(id))
        .toList(growable: false);

    for (final id in idsToRemove) {
      _itemNotifiersById.remove(id)?.dispose();

      if (_selectedItemIdNotifier.value == id) {
        _selectedItemIdNotifier.value = null;
      }
    }

    for (final item in items) {
      final existing = _itemNotifiersById[item.id];
      if (existing == null) {
        _itemNotifiersById[item.id] = ValueNotifier<GeoWorkspaceItemData>(item);
      } else if (existing.value != item) {
        existing.value = item;
      }
    }

    final selectedId = _selectedItemIdNotifier.value;
    if (selectedId != null && !_itemNotifiersById.containsKey(selectedId)) {
      _selectedItemIdNotifier.value = null;
    }
  }

  void _updateLocalItem(String itemId, Offset offset, Size size) {
    final notifier = _itemNotifiersById[itemId];
    if (notifier == null) return;

    final current = notifier.value;
    final next = current.copyWith(
      offset: offset,
      size: size,
    );

    if (next == current) return;
    notifier.value = next;
  }

  void _commitItem(String itemId, Offset offset, Size size) {
    final notifier = _itemNotifiersById[itemId];
    if (notifier == null) return;

    final current = notifier.value;
    final next = current.copyWith(
      offset: offset,
      size: size,
    );

    if (next != current) {
      notifier.value = next;
    }

    widget.onItemChanged(itemId, offset, size);
    widget.onSelectedWorkspaceItemChanged?.call(notifier.value);
  }

  void _removeLocalItem(String itemId) {
    final wasSelected = _selectedItemIdNotifier.value == itemId;

    _itemNotifiersById.remove(itemId)?.dispose();

    if (wasSelected) {
      _selectedItemIdNotifier.value = null;
      widget.onSelectedCatalogItemChanged?.call(null);
      widget.onSelectedWorkspaceItemChanged?.call(null);
    }

    _guidesNotifier.value = null;
    widget.onItemRemoved(itemId);
  }

  void _setGuides(GeoWorkspaceGuideLines? guides) {
    if (_guidesNotifier.value == guides) return;
    _guidesNotifier.value = guides;
  }

  void _selectItem(String itemId) {
    if (_selectedItemIdNotifier.value != itemId) {
      _selectedItemIdNotifier.value = itemId;
    }

    final selectedItem = _itemNotifiersById[itemId]?.value;
    widget.onSelectedCatalogItemChanged?.call(selectedItem?.catalogItemId);
    widget.onSelectedWorkspaceItemChanged?.call(selectedItem);
  }

  void _clearSelection() {
    if (_selectedItemIdNotifier.value != null) {
      _selectedItemIdNotifier.value = null;
    }
    if (_guidesNotifier.value != null) {
      _guidesNotifier.value = null;
    }

    widget.onSelectedCatalogItemChanged?.call(null);
    widget.onSelectedWorkspaceItemChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return GeoWorkspaceCanvas(
      stackKey: _stackKey,
      itemNotifiers: _itemNotifiersInOrder,
      selectedItemIdListenable: _selectedItemIdNotifier,
      guidesListenable: _guidesNotifier,
      snapController: _snapController,
      featuresByLayer: widget.featuresByLayer,
      onBackgroundTap: _clearSelection,
      onCatalogItemDropped: widget.onCatalogItemDropped,
      onItemSelected: _selectItem,
      onItemLiveChanged: _updateLocalItem,
      onItemCommitChanged: _commitItem,
      onItemRemoved: _removeLocalItem,
      onGuidesChanged: _setGuides,
    );
  }
}