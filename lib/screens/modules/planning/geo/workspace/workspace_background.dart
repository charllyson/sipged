import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';

class WorkspaceBackground extends StatelessWidget {
  const WorkspaceBackground({
    super.key,
    required this.receiving,
    required this.onTapBackground,
    this.pendingPlacementTitle,
  });

  final bool receiving;
  final ValueChanged<TapDownDetails> onTapBackground;
  final String? pendingPlacementTitle;

  bool get _isPlacementMode =>
      pendingPlacementTitle != null && pendingPlacementTitle!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, bool>(
      selector: (state) => state.hasItems,
      builder: (context, hasItems) {
        final theme = Theme.of(context);

        String message;
        if (receiving) {
          message = 'Solte aqui para adicionar ao dashboard';
        } else if (_isPlacementMode) {
          message = 'Clique para posicionar "${pendingPlacementTitle!}"';
        } else {
          message = 'Arraste visualizações para esta área';
        }

        final highlight = receiving || _isPlacementMode;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onTapBackground,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: highlight
                  ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                width: 2,
              )
                  : null,
            ),
            child: hasItems
                ? (_isPlacementMode
                ? Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.70) ??
                          Colors.black.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
                : null)
                : Center(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.55) ??
                      Colors.black.withValues(alpha: 0.55),
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