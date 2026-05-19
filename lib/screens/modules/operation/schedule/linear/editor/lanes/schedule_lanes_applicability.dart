import 'package:flutter/material.dart';

class ScheduleLanesApplicability extends StatelessWidget {
  const ScheduleLanesApplicability({super.key,
    required this.isGeral,
    required this.serviceLabel,
    required this.value,
    required this.onChanged,
    required this.compact,
  });

  final bool isGeral;
  final String serviceLabel;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textColor = isGeral
        ? theme.colorScheme.onSurface.withValues(alpha: 0.42)
        : theme.colorScheme.onSurface.withValues(alpha: 0.86);

    return Row(
      crossAxisAlignment:
      compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: compact ? VisualDensity.compact : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: compact ? 10 : 0),
            child: Text(
              isGeral
                  ? 'Selecione um serviço para configurar a faixa.'
                  : 'Aplicável ao serviço atual ($serviceLabel)',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
