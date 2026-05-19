import 'package:flutter/material.dart';

class ScheduleActionsButtons extends StatelessWidget {
  const ScheduleActionsButtons({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.compact,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(
                Icons.save,
                size: 18,
              ),
              label: const Text(
                'Salvar configuração',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancelar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 42,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(
              Icons.save,
              size: 18,
            ),
            label: const Text('Salvar configuração'),
          ),
        ),
      ],
    );
  }
}