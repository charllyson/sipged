import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/_widgets/buttons/expanded_button_change.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';

class ScheduleButtonsServices extends StatefulWidget {
  const ScheduleButtonsServices({
    super.key,
    required this.options,
    required this.current,
    required this.onSelect,
    this.spacing = 12,
    this.initiallyExpanded = true,
    this.enabled = true,
  });

  final List<ScheduleLinearServicesData> options;
  final String current;
  final void Function(String key) onSelect;

  final double spacing;
  final bool initiallyExpanded;
  final bool enabled;

  @override
  State<ScheduleButtonsServices> createState() =>
      _ScheduleButtonsServicesState();
}

class _ScheduleButtonsServicesState extends State<ScheduleButtonsServices>
    with TickerProviderStateMixin {
  late bool _expanded;

  static const Color _selectedBorderColor = SipGedTheme.darkPrimary;
  static const Color _selectedIndicatorColor = SipGedTheme.darkSecondary;

  static const String _defaultServiceIconKey =
      ScheduleLinearServicesData.defaultServiceIconKey;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ScheduleButtonsServices oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }

    final options = _preparedOptions();
    final currentKey = _cleanKey(widget.current);

    if (options.isEmpty) return;

    final currentExists = options.any(
          (option) => _cleanKey(option.key) == currentKey,
    );

    if (!currentExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final fallback = options.firstWhere(
              (option) => _cleanKey(option.key) == ScheduleLinearServicesData.geralKey,
          orElse: () => options.first,
        );

        widget.onSelect(fallback.key);
      });
    }
  }

  String _cleanKey(String value) {
    return value.trim();
  }

  String _resolveServiceIconKey(ScheduleLinearServicesData option) {
    final key = _cleanKey(option.key);

    if (key == ScheduleLinearServicesData.geralKey) {
      return ScheduleLinearServicesData.geralIconKey;
    }

    final iconKey = option.iconKey.trim();

    if (iconKey.isNotEmpty) {
      return iconKey;
    }

    return _defaultServiceIconKey;
  }

  IconData _resolveServiceIcon(ScheduleLinearServicesData option) {
    final key = _cleanKey(option.key);

    if (key == ScheduleLinearServicesData.geralKey) {
      return Icons.clear_all;
    }

    final iconKey = _resolveServiceIconKey(option);

    if (iconKey == _defaultServiceIconKey) {
      return Icons.layers_outlined;
    }

    return IconsCatalog.iconFor(iconKey);
  }

  void _toggle() {
    if (!widget.enabled) return;

    setState(() {
      _expanded = !_expanded;
    });
  }

  ScheduleLinearServicesData? _currentOption() {
    final options = _preparedOptions();

    if (options.isEmpty) return null;

    final currentKey = _cleanKey(widget.current);

    final index = options.indexWhere((option) {
      return _cleanKey(option.key) == currentKey;
    });

    if (index >= 0) {
      return options[index];
    }

    final geralIndex = options.indexWhere((option) {
      return _cleanKey(option.key) == ScheduleLinearServicesData.geralKey;
    });

    if (geralIndex >= 0) {
      return options[geralIndex];
    }

    return options.first;
  }

  List<ScheduleLinearServicesData> _preparedOptions() {
    final seen = <String>{};
    final out = <ScheduleLinearServicesData>[];

    for (final option in widget.options) {
      final key = _cleanKey(option.key);

      if (key.isEmpty) continue;
      if (seen.contains(key)) continue;

      seen.add(key);

      final resolvedIconKey = _resolveServiceIconKey(option);
      final resolvedIcon = key == ScheduleLinearServicesData.geralKey
          ? Icons.clear_all
          : _resolveServiceIcon(option);

      out.add(
        option.copyWith(
          key: key,
          label: option.label.trim().isEmpty ? key : option.label.trim(),
          iconKey: resolvedIconKey,
          icon: resolvedIcon,
        ),
      );
    }

    if (!seen.contains(ScheduleLinearServicesData.geralKey)) {
      out.insert(0, ScheduleLinearServicesData.emptyGeral);
    }

    out.sort(ScheduleLinearServicesData.compareByLayer);

    return List<ScheduleLinearServicesData>.unmodifiable(out);
  }

  @override
  Widget build(BuildContext context) {
    final options = _preparedOptions();
    final currentKey = _cleanKey(widget.current);

    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final childrenExpanded = options.map((option) {
      final optionKey = _cleanKey(option.key);
      final isSelected = optionKey == currentKey;

      return _ServiceButton(
        option: option,
        icon: _resolveServiceIcon(option),
        isSelected: isSelected,
        enabled: widget.enabled,
        background: option.color,
        selectedBorderColor: _selectedBorderColor,
        selectedIndicatorColor: _selectedIndicatorColor,
        onTap: () {
          if (!widget.enabled) return;
          widget.onSelect(option.key);
        },
      );
    }).toList(growable: false);

    final toggle = _ToggleButton(
      expanded: _expanded,
      enabled: widget.enabled,
      onTap: _toggle,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _expanded
            ? <Widget>[
          ..._withSpacing(childrenExpanded, widget.spacing),
          SizedBox(height: widget.spacing),
          toggle,
        ]
            : <Widget>[
          _CollapsedSelectedButton(
            option: _currentOption(),
            iconResolver: _resolveServiceIcon,
            enabled: widget.enabled,
            selectedBorderColor: _selectedBorderColor,
            selectedIndicatorColor: _selectedIndicatorColor,
            onTap: _toggle,
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
      if (i > 0) {
        out.add(SizedBox(height: gap));
      }

      out.add(items[i]);
    }

    return out;
  }
}

class _CollapsedSelectedButton extends StatelessWidget {
  const _CollapsedSelectedButton({
    required this.option,
    required this.iconResolver,
    required this.enabled,
    required this.selectedBorderColor,
    required this.selectedIndicatorColor,
    required this.onTap,
  });

  final ScheduleLinearServicesData? option;
  final IconData Function(ScheduleLinearServicesData option) iconResolver;
  final bool enabled;
  final Color selectedBorderColor;
  final Color selectedIndicatorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentOption = option;

    if (currentOption == null) {
      return const SizedBox.shrink();
    }

    return _ServiceButton(
      option: currentOption,
      icon: iconResolver(currentOption),
      isSelected: true,
      enabled: enabled,
      background: currentOption.color,
      selectedBorderColor: selectedBorderColor,
      selectedIndicatorColor: selectedIndicatorColor,
      onTap: onTap,
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.option,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.background,
    required this.selectedBorderColor,
    required this.selectedIndicatorColor,
    required this.onTap,
  });

  final ScheduleLinearServicesData option;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final Color background;
  final Color selectedBorderColor;
  final Color selectedIndicatorColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
    enabled ? background : background.withValues(alpha: 0.38);

    final label = option.label.trim().isEmpty
        ? option.key.trim()
        : option.label.trim();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: enabled ? 1.0 : 0.58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? selectedBorderColor : Colors.transparent,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ExpandedButtonChange(
                icon: icon,
                label: label,
                color: effectiveColor,
                onPressed: enabled ? onTap : null,
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: -5,
              right: -5,
              child: IgnorePointer(
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: selectedIndicatorColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.expanded,
    required this.enabled,
    required this.onTap,
  });

  final bool expanded;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ExpandedButtonChange(
      icon: expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
      label: expanded ? 'Recolher' : 'Serviços',
      color: enabled ? Colors.black : Colors.black38,
      onPressed: enabled ? onTap : null,
    );
  }
}