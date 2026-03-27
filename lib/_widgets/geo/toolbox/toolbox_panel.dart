import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_action_item.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_icon_button.dart';

class ToolboxPanel extends StatelessWidget {
  final List<ToolboxSectionData> sections;
  final String? selectedToolId;
  final ValueChanged<String?>? onSelected;
  final double? iconSize;
  final double? buttonSize;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;

  const ToolboxPanel({
    super.key,
    required this.sections,
    this.selectedToolId,
    this.onSelected,
    this.iconSize,
    this.buttonSize,
    this.spacing = 6,
    this.runSpacing = 6,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Center(
        child: Text('Nenhuma ferramenta disponível.'),
      );
    }

    final allActions =
    sections.expand((section) => section.actions).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;

        final resolvedButtonSize = _resolveButtonSize(maxWidth);
        final resolvedIconSize = iconSize ?? _resolveIconSize(resolvedButtonSize);

        final effectiveButtonSize = buttonSize ?? resolvedButtonSize;

        final availableWidthForGrid = math.max(
          0.0,
          maxWidth - padding.horizontal,
        );

        final columns = _resolveColumnCount(
          availableWidth: availableWidthForGrid,
          buttonSize: effectiveButtonSize,
          spacing: spacing,
          itemCount: allActions.length,
        );

        final contentWidth = _resolveContentWidth(
          columns: columns,
          buttonSize: effectiveButtonSize,
          spacing: spacing,
        );

        return RepaintBoundary(
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: contentWidth,
                  maxWidth: contentWidth,
                ),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: allActions
                      .map(
                        (action) => ToolboxIconButton(
                      key: ValueKey(action.id),
                      action: action,
                      selectedToolId: selectedToolId,
                      onSelected: onSelected,
                      iconSize: resolvedIconSize,
                      buttonSize: effectiveButtonSize,
                    ),
                  )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _resolveButtonSize(double maxWidth) {
    if (maxWidth <= 180) return 34;
    if (maxWidth <= 240) return 36;
    if (maxWidth <= 320) return 38;
    return 40;
  }

  double _resolveIconSize(double buttonSize) {
    if (buttonSize <= 34) return 18;
    if (buttonSize <= 36) return 19;
    return 20;
  }

  int _resolveColumnCount({
    required double availableWidth,
    required double buttonSize,
    required double spacing,
    required int itemCount,
  }) {
    final footprint = buttonSize + spacing;
    if (footprint <= 0) return 1;

    final rawCount = ((availableWidth + spacing) / footprint).floor();
    final clamped = rawCount.clamp(1, math.max(1, itemCount)).toInt();
    return clamped;
  }

  double _resolveContentWidth({
    required int columns,
    required double buttonSize,
    required double spacing,
  }) {
    if (columns <= 1) return buttonSize;
    return (columns * buttonSize) + ((columns - 1) * spacing);
  }
}