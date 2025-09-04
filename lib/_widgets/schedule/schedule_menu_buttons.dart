// lib/_widgets/schedule/schedule_menu_buttons.dart
import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/operation/schedule_data.dart';
import 'package:siged/_widgets/buttons/button_flutuante_hover.dart';

class ScheduleMenuButtons extends StatefulWidget {
  const ScheduleMenuButtons({
    super.key,
    required this.options,
    required this.current,
    required this.onSelect,
    this.spacing = 12,
    this.initiallyExpanded = true,
  });

  final List<ScheduleData> options;
  final String current;
  final void Function(String key) onSelect;
  final double spacing;
  final bool initiallyExpanded;

  @override
  State<ScheduleMenuButtons> createState() => _ScheduleMenuButtonsState();
}

class _ScheduleMenuButtonsState extends State<ScheduleMenuButtons>
    with TickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  ScheduleData? _currentOption() {
    if (widget.options.isEmpty) return null;
    final i = widget.options.indexWhere((o) => o.key == widget.current);
    return i >= 0 ? widget.options[i] : widget.options.first;
  }

  @override
  Widget build(BuildContext context) {
    final childrenExpanded = widget.options.map((o) {
      final isSelected = o.key == widget.current;
      final bg = isSelected ? o.color : o.color.withOpacity(0.18);
      return _ServiceButton(
        option: o,
        isSelected: isSelected,
        background: bg,
        onTap: () => widget.onSelect(o.key),
      );
    }).toList();

    final toggle = _ToggleButton(expanded: _expanded, onTap: _toggle);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _expanded
        // EXPANDIDO: todos os serviços + toggle sempre embaixo
            ? [
          ..._withSpacing(childrenExpanded, widget.spacing),
          SizedBox(height: widget.spacing),
          toggle,
        ]
        // CONTRAÍDO: serviço selecionado no topo + toggle SEMPRE embaixo
            : [
          _CollapsedSelectedButton(
            option: _currentOption(),
            onTap: _toggle, // tocar no selecionado também expande
          ),
          SizedBox(height: widget.spacing),
          toggle,
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(items[i]);
    }
    return out;
  }
}

class _CollapsedSelectedButton extends StatelessWidget {
  const _CollapsedSelectedButton({required this.option, required this.onTap});
  final ScheduleData? option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (option == null) return const SizedBox.shrink();
    return _ServiceButton(
      option: option!,
      isSelected: true,
      background: option!.color,
      onTap: onTap, // no contraído, serve para EXPANDIR
    );
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
    final borderColor = isSelected ? option.color : Colors.transparent;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: isSelected ? 1.05 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: option.color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: BotaoFlutuanteHover(
          icon: option.icon,
          label: option.label,
          color: background,
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BotaoFlutuanteHover(
      icon: expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
      label: expanded ? 'Recolher' : 'Serviços',
      color: Colors.black.withOpacity(0.12),
      onPressed: onTap,
    );
  }
}
