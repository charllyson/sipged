import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guide_lines_data.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guides_line_drawer.dart';

class GeoWorkspaceGuide extends StatelessWidget {
  const GeoWorkspaceGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, GuideLinesData?>(
          selector: (state) => state.guides,
          builder: (context, guides) {
            return CustomPaint(
              painter: GuidesLinesDrawer(guides: guides),
            );
          },
        ),
      ),
    );
  }
}
