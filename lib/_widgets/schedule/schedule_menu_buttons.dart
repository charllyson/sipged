import 'package:flutter/material.dart';
import 'package:sisged/_blocs/sectors/operation/schedule_data.dart';
import 'package:sisged/_widgets/buttons/button_flutuante_hover.dart';

class ScheduleMenuButtons extends StatelessWidget {
  const ScheduleMenuButtons({
    super.key,
    required this.options,
    required this.current,
    required this.onSelect,
    this.direction = Axis.vertical,
    this.spacing = 12,
  });

  final List<ScheduleData> options;
  final String current;
  final void Function(String key) onSelect;
  final Axis direction;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final children = options.map((o) {
      final isSelected = o.key == current;
      final bg = isSelected ? o.color : o.color.withOpacity(0.2);

      return _ServiceButton(
        option: o,
        isSelected: isSelected,
        background: bg,
        onTap: () => onSelect(o.key),
      );
    }).toList();

    if (direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _withSpacing(children, spacing),
      );
    }
    return Row(children: _withSpacing(children, spacing));
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    final spaced = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) spaced.add(SizedBox(height: direction == Axis.vertical ? gap : 0, width: direction == Axis.horizontal ? gap : 0));
      spaced.add(items[i]);
    }
    return spaced;
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.option,
    required this.isSelected,
    required this.background,
    required this.onTap,
  });

  final ScheduleData option;
  final bool isSelected;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // realce sutil no selecionado: borda + sombra + leve escala
    final borderColor = isSelected ? option.color : Colors.transparent;

    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: isSelected ? 1.05 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: borderColor, width: isSelected ? 2 : 1.0),
        ),
        child: BotaoFlutuanteHover(
          icon: option.icon ?? Icons.check,
          label: option.label,
          color: background,
          onPressed: onTap,
        ),
      ),
    );
  }
}
