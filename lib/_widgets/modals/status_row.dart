import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_modal_controller.dart';
import 'package:siged/_widgets/modals/status_chip.dart';

class ScheduleStatusRow extends StatelessWidget {
  final bool showSlider; // NOVO (retrocompat: default true)
  const ScheduleStatusRow({super.key, this.showSlider = true});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusChip(
                selected: c.status,
                onSelect: (c.picking || c.saving) ? null : c.setStatus,
              ),
            ],
          ),
        ),
        if (showSlider) // << só mostra se quiser
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: c.progress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${c.progress.round()}%',
                    onChanged: (c.picking || c.saving) ? null : c.onSliderChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${c.progress.round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
