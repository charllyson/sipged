import 'package:flutter/material.dart';

import 'package:sipged/screens/modules/operation/schedule/common/header/schedule_status.dart';

class ScheduleModalStatus extends StatelessWidget {
  const ScheduleModalStatus({
    super.key,
    this.showSlider = true,
    required this.status,
    required this.progress,
    this.enabled = true,
    this.onStatusChanged,
    this.onProgressChanged,
  });

  final bool showSlider;
  final ScheduleStatus status;
  final double progress;
  final bool enabled;

  final ValueChanged<ScheduleStatus>? onStatusChanged;
  final ValueChanged<double>? onProgressChanged;

  double get _safeProgress => progress.clamp(0.0, 100.0);

  @override
  Widget build(BuildContext context) {
    final sliderEnabled = enabled && onProgressChanged != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScheduleModalChips(
          selected: status,
          onSelect: enabled && onStatusChanged != null
              ? onStatusChanged
              : null,
        ),
        if (showSlider) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _safeProgress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_safeProgress.round()}%',
                    onChanged: sliderEnabled
                        ? (value) => onProgressChanged!(value)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Text(
                    '${_safeProgress.round()}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ScheduleModalChips extends StatelessWidget {
  const ScheduleModalChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ScheduleStatus selected;
  final ValueChanged<ScheduleStatus>? onSelect;

  static const List<ScheduleStatus> _items = <ScheduleStatus>[
    ScheduleStatus.aIniciar,
    ScheduleStatus.emAndamento,
    ScheduleStatus.concluido,
  ];

  Widget _chip(BuildContext context, ScheduleStatus status) {
    final selectedStatus = status == selected;
    final theme = Theme.of(context);

    final selectedColor = status.color;
    final unselectedBackground = theme.colorScheme.surfaceContainerHighest;
    final unselectedBorder = theme.dividerColor.withValues(alpha: 0.35);
    final unselectedText = theme.colorScheme.onSurface.withValues(alpha: 0.88);

    return Material(
      color: selectedStatus ? selectedColor : unselectedBackground,
      shape: StadiumBorder(
        side: BorderSide(
          color: selectedStatus ? selectedColor : unselectedBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelect == null ? null : () => onSelect!(status),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status.icon,
                size: 18,
                color: selectedStatus ? Colors.white : selectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                status.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedStatus ? Colors.white : unselectedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ordem: a iniciar | em andamento | concluído
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _chip(context, _items[i]),
            ],
          ],
        ),
      ),
    );
  }
}