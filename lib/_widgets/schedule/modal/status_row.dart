// lib/_widgets/modals/parts/status_row.dart
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/schedule/modal/status_chip.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_status.dart';

class ScheduleStatusRow extends StatelessWidget {
  final bool showSlider; // default true
  final ScheduleStatus status;
  final double progress; // 0–100
  final bool enabled;

  final ValueChanged<ScheduleStatus>? onStatusChanged;
  final ValueChanged<double>? onProgressChanged;

  const ScheduleStatusRow({
    super.key,
    this.showSlider = true,
    required this.status,
    required this.progress,
    this.enabled = true,
    this.onStatusChanged,
    this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sliderEnabled = enabled && onProgressChanged != null;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusChip(
                selected: status,
                onSelect: enabled && onStatusChanged != null
                    ? onStatusChanged
                    : null,
              ),
            ],
          ),
        ),
        if (showSlider)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: progress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${progress.round()}%',
                    onChanged: sliderEnabled
                        ? (v) => onProgressChanged!(v)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${progress.round()}%',
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
