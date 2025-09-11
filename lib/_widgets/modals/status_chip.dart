// lib/_widgets/modals/status_chip.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/schedule/linear/schedule_status.dart';

class StatusChip extends StatelessWidget {
  final ScheduleStatus selected;
  final ValueChanged<ScheduleStatus>? onSelect;

  const StatusChip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  Widget _chip(BuildContext _, ScheduleStatus s) {
    final sel = s == selected;
    return Material(
      color: sel ? s.color : Colors.grey.shade200,
      shape: StadiumBorder(
        side: BorderSide(color: sel ? s.color : Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelect == null ? null : () => onSelect!(s),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(s.icon, size: 18, color: sel ? Colors.white : s.color),
              const SizedBox(width: 8),
              Text(
                s.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ordem: concluído | em andamento | a iniciar
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _chip(context, ScheduleStatus.aIniciar),
            const SizedBox(width: 8),
            _chip(context, ScheduleStatus.emAndamento),
            const SizedBox(width: 8),
            _chip(context, ScheduleStatus.concluido),
          ],
        ),
      ),
    );
  }
}
