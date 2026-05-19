import 'package:flutter/material.dart';

class ScheduleHeaderSection extends StatelessWidget {
  const ScheduleHeaderSection({
    super.key,
    required this.title,
    required this.icon,
    required this.compact,
    this.description,
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  final String title;
  final IconData icon;
  final bool compact;

  final String? description;

  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  bool get _hasPrimaryAction {
    return primaryLabel != null && primaryIcon != null;
  }

  bool get _hasSecondaryAction {
    return secondaryLabel != null && secondaryIcon != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleRow = Row(
      children: [
        Icon(
          icon,
          size: compact ? 18 : 19,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (_hasPrimaryAction)
          FilledButton.icon(
            onPressed: onPrimary,
            icon: Icon(
              primaryIcon,
              size: 18,
            ),
            label: Text(primaryLabel!),
            style: FilledButton.styleFrom(
              visualDensity:
              compact ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 8 : 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        if (_hasSecondaryAction)
          OutlinedButton.icon(
            onPressed: onSecondary,
            icon: Icon(
              secondaryIcon,
              size: 18,
            ),
            label: Text(secondaryLabel!),
            style: OutlinedButton.styleFrom(
              visualDensity:
              compact ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 8 : 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );

    final descriptionWidget = description == null || description!.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          description!,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          descriptionWidget,
          if (_hasPrimaryAction || _hasSecondaryAction) ...[
            const SizedBox(height: 8),
            actions,
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: titleRow),
            if (_hasPrimaryAction || _hasSecondaryAction) actions,
          ],
        ),
        descriptionWidget,
      ],
    );
  }
}