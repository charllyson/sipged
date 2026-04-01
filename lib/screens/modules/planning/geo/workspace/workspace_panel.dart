import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_utils/debug/sipged_perf.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_canvas.dart';

class WorkspacePanel extends StatefulWidget {
  const WorkspacePanel({
    super.key,
    required this.items,
    required this.featuresByLayer,
    required this.onCatalogItemDropped,
    required this.onItemChanged,
    required this.onItemRemoved,
    this.onSelectedCatalogItemChanged,
    this.onSelectedWorkspaceItemChanged,
  });

  final List<WorkspaceData> items;
  final Map<String, List<GeoFeatureData>> featuresByLayer;

  final void Function(
      ComponentDataCatalog item,
      Offset localOffset,
      ) onCatalogItemDropped;

  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;

  final ValueChanged<String?>? onSelectedCatalogItemChanged;
  final ValueChanged<WorkspaceData?>? onSelectedWorkspaceItemChanged;

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

    SipgedPerf.log(
      'WorkspacePanel.initState',
      data: {
        'items': widget.items.length,
        'layers': widget.featuresByLayer.length,
      },
    );
  }

  @override
  void didUpdateWidget(covariant WorkspacePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    SipgedPerf.traceSync(
      'WorkspacePanel.didUpdateWidget',
          () {
        if (!identical(oldWidget.items, widget.items)) {
          _cubit.syncExternalItems(widget.items);
        }

        if (!identical(oldWidget.featuresByLayer, widget.featuresByLayer)) {
          _cubit.syncExternalFeatures(widget.featuresByLayer);
        }
      },
      warnMs: 8,
      data: {
        'itemsChanged': !identical(oldWidget.items, widget.items),
        'featuresChanged':
        !identical(oldWidget.featuresByLayer, widget.featuresByLayer),
      },
    );
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
    return SipgedPerf.traceSync(
      'WorkspacePanel.build',
          () {
        return BlocProvider<WorkspaceCubit>.value(
          value: _cubit,
          child: BlocListener<WorkspaceCubit, WorkspaceState>(
            listenWhen: (previous, current) {
              return previous.selectedItemId != current.selectedItemId ||
                  previous.selectedItem != current.selectedItem;
            },
            listener: (context, state) => _notifySelection(state),
            child: WorkspaceCanvas(
              onCatalogItemDropped: widget.onCatalogItemDropped,
              onItemChanged: widget.onItemChanged,
              onItemRemoved: widget.onItemRemoved,
            ),
          ),
        );
      },
      warnMs: 8,
      data: {
        'items': widget.items.length,
        'layers': widget.featuresByLayer.length,
      },
    );
  }
}