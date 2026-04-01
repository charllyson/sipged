import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';

class WorkspaceBackground extends StatelessWidget {
  const WorkspaceBackground({
    super.key,
    required this.receiving,
  });

  final bool receiving;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, bool>(
      selector: (state) => state.hasItems,
      builder: (context, hasItems) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<WorkspaceCubit>().clearSelection(),
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