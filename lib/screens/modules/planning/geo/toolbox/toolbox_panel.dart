import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_action_item.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_icon_button.dart';

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
        final panelWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 220.0;

        final effectivePanelWidth = math.max(120.0, panelWidth);

        final resolvedButtonSize =
            buttonSize ?? _resolveButtonSize(effectivePanelWidth);

        final resolvedIconSize =
            iconSize ?? _resolveIconSize(resolvedButtonSize);

        final availableWidth = math.max(
          0.0,
          effectivePanelWidth - padding.horizontal,
        );

        final columns = _resolveColumnCount(
          availableWidth: availableWidth,
          buttonSize: resolvedButtonSize,
          spacing: spacing,
          itemCount: allActions.length,
        );

        final contentWidth = _resolveContentWidth(
          availableWidth: availableWidth,
          columns: columns,
          buttonSize: resolvedButtonSize,
          spacing: spacing,
        );

        return RepaintBoundary(
          child: Align(
            alignment: Alignment.topLeft,
            child: SingleChildScrollView(
              padding: padding,
              child: SizedBox(
                width: contentWidth,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: spacing,
                  runSpacing: runSpacing,
                  children: allActions
                      .map(
                        (action) => SizedBox(
                      width: resolvedButtonSize,
                      height: resolvedButtonSize,
                      child: ToolboxIconButton(
                        key: ValueKey(action.id),
                        action: action,
                        selectedToolId: selectedToolId,
                        onSelected: onSelected,
                        iconSize: resolvedIconSize,
                        buttonSize: resolvedButtonSize,
                      ),
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
    if (maxWidth <= 160) return 32;
    if (maxWidth <= 200) return 34;
    if (maxWidth <= 260) return 36;
    if (maxWidth <= 320) return 38;
    return 40;
  }

  double _resolveIconSize(double buttonSize) {
    if (buttonSize <= 32) return 17;
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
    if (itemCount <= 0) return 1;

    final footprint = buttonSize + spacing;
    if (footprint <= 0) return 1;

    final rawCount = ((availableWidth + spacing) / footprint).floor();
    return rawCount.clamp(1, itemCount);
  }

  double _resolveContentWidth({
    required double availableWidth,
    required int columns,
    required double buttonSize,
    required double spacing,
  }) {
    final rawWidth =
        (columns * buttonSize) + ((columns > 1 ? columns - 1 : 0) * spacing);

    return rawWidth.clamp(buttonSize, availableWidth);
  }
}