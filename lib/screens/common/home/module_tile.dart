import 'package:flutter/material.dart';
import 'package:sipged/screens/common/home/module_data_item.dart';

class ModuleTile<T> extends StatefulWidget {
  const ModuleTile({
    super.key,
    required this.item,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  final ModuleDataItem<T> item;
  final bool isDark;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<ModuleTile<T>> createState() => _ModuleTileState<T>();
}

class _ModuleTileState<T> extends State<ModuleTile<T>> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final iconSize = widget.compact ? 66.0 : 74.0;
    final iconRadius = widget.compact ? 19.0 : 22.0;
    final innerIconSize = widget.compact ? 30.0 : 34.0;

    final labelFontSize = widget.compact ? 12.5 : null;
    final subtitleFontSize = widget.compact ? 10.5 : 11.0;

    final labelColor = widget.isDark ? Colors.white : Colors.blueGrey.shade900;

    final subtitleColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.blueGrey.shade600;

    final borderColor = _hovering
        ? item.color.withValues(alpha: 0.45)
        : widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    final scale = _pressed
        ? 0.96
        : _hovering
        ? 1.035
        : 1.0;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(iconRadius),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: innerIconSize,
                    color: item.color,
                  ),
                ),
              ),
              SizedBox(height: widget.compact ? 8 : 10),
              Text(
                item.title,
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
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}