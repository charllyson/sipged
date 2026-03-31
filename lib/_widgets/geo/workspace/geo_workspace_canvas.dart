import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_widgets/geo/visualizations/catalog/tab_widget_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_background.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_guides.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item.dart';

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
                    child: GeoWorkspaceBackground(receiving: receiving),
                  ),
                  const Positioned.fill(
                    child: GeoWorkspaceGuide(),
                  ),
                  Positioned.fill(
                    child: GeoWorkspaceItem(
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

