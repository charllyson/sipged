import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_modal_controller.dart';

class ScheduleDateRow extends StatelessWidget {
  final String labelPrefix; // NOVO (retrocompat: default 'Data:')
  const ScheduleDateRow({super.key, this.labelPrefix = 'Data:'});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();
    final d = c.selectedDate;
    final label = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(
        children: [
          Expanded(child: Text('$labelPrefix $label')),
          TextButton(
            onPressed: (c.picking || c.saving)
                ? null
                : () async {
              final newD = await showDatePicker(
                context: context,
                initialDate: c.selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (newD != null) c.setDate(newD);
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }
}
