// lib/screens/common/modules/module_tile.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';

class ModuleTile extends StatefulWidget {
  const ModuleTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.compact = false,
  });

  final ModuleData item;
  final bool isDark;
  final VoidCallback? onTap;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final bool compact;

  @override
  State<ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<ModuleTile> {
  bool _hovering = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  IconData get _icon {
    return widget.item.homeModuleIcon ?? widget.fallbackIcon;
  }

  Color get _color {
    return widget.item.homeModuleColor ?? widget.fallbackColor;
  }

  String get _title {
    final text = widget.item.labelModule.trim();

    if (text.isEmpty) {
      return 'Módulo';
    }

    return text;
  }

  void _setHovering(bool value) {
    if (_hovering == value) return;

    setState(() {
      _hovering = value;

      if (!value) {
        _pressed = false;
      }
    });
  }

  void _setPressed(bool value) {
    if (!_enabled) return;
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    final iconSize = widget.compact ? 66.0 : 74.0;
    final iconRadius = widget.compact ? 19.0 : 22.0;
    final innerIconSize = widget.compact ? 30.0 : 34.0;

    final labelFontSize = widget.compact ? 12.5 : null;

    final labelColor = widget.isDark ? Colors.white : Colors.blueGrey.shade900;

    final borderColor = _hovering
        ? color.withValues(alpha: 0.45)
        : widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    final cardColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.98)
        : Colors.white;

    final scale = _pressed
        ? 0.96
        : _hovering
        ? 1.035
        : 1.0;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => _setHovering(true),
        onExit: (_) => _setHovering(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: iconSize,
                  width: iconSize,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(iconRadius),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      if (_hovering)
                        BoxShadow(
                          color: color.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _icon,
                      size: innerIconSize,
                      color: color,
                    ),
                  ),
                ),
                SizedBox(height: widget.compact ? 8 : 10),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}