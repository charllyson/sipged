import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/chip/chip_card.dart';

class ScheduleHeaderDialog extends StatelessWidget {
  const ScheduleHeaderDialog({
    super.key,
    required this.activeServiceLabel,
    required this.activeServiceColor,
    required this.activeServiceIcon,
    required this.lanesCount,
    required this.servicesCount,
    required this.compact,
  });

  final String activeServiceLabel;
  final Color activeServiceColor;
  final IconData activeServiceIcon;
  final int lanesCount;
  final int servicesCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final iconBox = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: activeServiceColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        activeServiceIcon,
        color: activeServiceColor,
      ),
    );

    final title = Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: 'Serviço em edição: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: activeServiceLabel,
            style: TextStyle(
              color: activeServiceColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      maxLines: compact ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );

    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChipCard(
          '',
          null,
          Icons.view_stream_outlined,
          textValue: '$lanesCount faixa(s)',
          showTitle: false,
          backgroundColor: primary.withValues(alpha: 0.07),
          foregroundColor: primary,
          borderColor: Colors.transparent,
          borderWidth: 0,
          iconSize: 16,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        ChipCard(
          '',
          null,
          Icons.layers_outlined,
          textValue: '$servicesCount serviço(s)',
          showTitle: false,
          backgroundColor: primary.withValues(alpha: 0.07),
          foregroundColor: primary,
          borderColor: Colors.transparent,
          borderWidth: 0,
          iconSize: 16,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconBox,
              const SizedBox(width: 12),
              Expanded(child: title),
            ],
          ),
          const SizedBox(height: 12),
          pills,
        ],
      )
          : Row(
        children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(child: title),
          const SizedBox(width: 12),
          pills,
        ],
      ),
    );
  }
}