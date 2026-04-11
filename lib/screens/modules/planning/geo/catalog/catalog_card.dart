import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';

class CatalogCard extends StatefulWidget {
  final CatalogData item;
  final bool selected;
  final bool isDragging;
  final VoidCallback? onTap;

  const CatalogCard({
    super.key,
    required this.item,
    required this.selected,
    this.isDragging = false,
    this.onTap,
  });

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = scheme.primary;
    final hovered = _hovered || widget.selected || widget.isDragging;

    final backgroundColor = widget.selected
        ? (isDark ? const Color(0xFF1A1A22) : const Color(0xFFF8F8FA))
        : (isDark ? const Color(0xFF171717) : Colors.white);

    final borderColor = widget.selected
        ? primary.withValues(alpha: 0.70)
        : hovered
        ? primary.withValues(alpha: 0.28)
        : (isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08));

    final iconColor = widget.selected
        ? primary
        : hovered
        ? primary.withValues(alpha: 0.95)
        : primary.withValues(alpha: 0.82);

    final title = widget.item.title;
    final icon = widget.item.icon ?? Icons.widgets_outlined;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: title,
        waitDuration: const Duration(milliseconds: 250),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: hovered ? 1.015 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.selected ? 1.1 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.selected
                      ? primary.withValues(alpha: isDark ? 0.18 : 0.14)
                      : Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: widget.selected ? 14 : hovered ? 12 : 8,
                  offset: Offset(0, widget.selected ? 4 : 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Center(
                child: Icon(
                  icon,
                  size: 26,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}