import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_action_item.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_icon_button.dart';

class ToolboxPanel extends StatelessWidget {
  final List<ToolboxSectionData> sections;
  final String? selectedToolId;
  final ValueChanged<String?>? onSelected;
  final double iconSize;
  final double buttonSize;
  final double spacing;
  final double runSpacing;
  final EdgeInsets padding;

  const ToolboxPanel({
    super.key,
    required this.sections,
    this.selectedToolId,
    this.onSelected,
    this.iconSize = 20,
    this.buttonSize = 40,
    this.spacing = 3,
    this.runSpacing = 3,
    this.padding = const EdgeInsets.all(4),
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

    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: padding,
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
              iconSize: iconSize,
              buttonSize: buttonSize,
            ),
          )
              .toList(growable: false),
        ),
      ),
    );
  }
}