import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_canvas.dart';
import 'package:sipged/_widgets/resize/resize_data.dart';

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

  final List<ResizeData> items;
  final Map<String, List<GeoFeatureData>> featuresByLayer;

  final void Function(
      TabWidgetsCatalog item,
      Offset localOffset,
      ) onCatalogItemDropped;

  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  final ValueChanged<String?>? onSelectedCatalogItemChanged;
  final ValueChanged<ResizeData?>? onSelectedWorkspaceItemChanged;

  @override
  State<GeoWorkspacePanel> createState() => _GeoWorkspacePanelState();
}

class _GeoWorkspacePanelState extends State<GeoWorkspacePanel> {
  late final GeoWorkspaceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GeoWorkspaceCubit(
      initialItems: widget.items,
      initialFeaturesByLayer: widget.featuresByLayer,
      repository: const GeoWorkspaceRepository(),
    );
  }

  @override
  void didUpdateWidget(covariant GeoWorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sempre sincroniza.
    // O próprio cubit já evita emissão desnecessária.
    _cubit.syncExternalItems(widget.items);
    _cubit.syncExternalFeatures(widget.featuresByLayer);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _notifySelection(GeoWorkspaceState state) {
    final selectedItem = state.selectedItem;
    widget.onSelectedCatalogItemChanged?.call(selectedItem?.catalogItemId);
    widget.onSelectedWorkspaceItemChanged?.call(selectedItem);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeoWorkspaceCubit>.value(
      value: _cubit,
      child: BlocListener<GeoWorkspaceCubit, GeoWorkspaceState>(
        listenWhen: (previous, current) {
          final prevSelected = previous.selectedItem;
          final currSelected = current.selectedItem;

          return previous.selectedItemId != current.selectedItemId ||
              prevSelected != currSelected;
        },
        listener: (context, state) => _notifySelection(state),
        child: GeoWorkspaceCanvas(
          onCatalogItemDropped: widget.onCatalogItemDropped,
          onItemChanged: widget.onItemChanged,
          onItemRemoved: widget.onItemRemoved,
        ),
      ),
    );
  }
}