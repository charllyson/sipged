// lib/_widgets/modals/parts/date_row.dart
import 'package:flutter/material.dart';

class ScheduleDateRow extends StatelessWidget {
  final String labelPrefix; // ex: 'Data do serviço:'
  final DateTime selectedDate;
  final bool enabled;
  final ValueChanged<DateTime>? onChanged;

  const ScheduleDateRow({
    super.key,
    this.labelPrefix = 'Data:',
    required this.selectedDate,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final d = selectedDate;
    final label =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(
        children: [
          Expanded(child: Text('$labelPrefix $label')),
          TextButton(
            onPressed: !enabled
                ? null
                : () async {
              final newD = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (newD != null && onChanged != null) {
                onChanged!(newD);
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }
}
