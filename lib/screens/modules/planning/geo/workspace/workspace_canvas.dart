import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/component/component_data_catalog.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_utils/debug/sipged_perf.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_background.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_data_item.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_guides.dart';

class WorkspaceCanvas extends StatefulWidget {
  const WorkspaceCanvas({
    super.key,
    required this.onCatalogItemDropped,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final void Function(
      ComponentDataCatalog item,
      Offset localOffset,
      ) onCatalogItemDropped;

  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  State<WorkspaceCanvas> createState() => _WorkspaceCanvasState();
}

class _WorkspaceCanvasState extends State<WorkspaceCanvas> {
  final GlobalKey _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SipgedPerf.traceSync(
      'WorkspaceCanvas.build',
          () {
        return ColoredBox(
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelSize = Size(
                constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
                constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
              );

              final cubit = context.read<WorkspaceCubit>();
              if (cubit.state.panelSize != panelSize) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  cubit.setPanelSize(panelSize);
                });
              }

              return DragTarget<ComponentDataCatalog>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) {
                  final renderBox =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;

                  final local = renderBox.globalToLocal(details.offset);

                  SipgedPerf.log(
                    'WorkspaceCanvas.onCatalogItemDropped',
                    data: {
                      'catalogItemId': details.data.id,
                      'x': local.dx,
                      'y': local.dy,
                    },
                  );

                  widget.onCatalogItemDropped(details.data, local);
                },
                builder: (context, candidateData, rejectedData) {
                  final receiving = candidateData.isNotEmpty;

                  return Stack(
                    key: _stackKey,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: WorkspaceBackground(receiving: receiving),
                      ),
                      const Positioned.fill(
                        child: WorkspaceGuide(),
                      ),
                      Positioned.fill(
                        child: WorkspaceDataItem(
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
      },
      warnMs: 8,
    );
  }
}