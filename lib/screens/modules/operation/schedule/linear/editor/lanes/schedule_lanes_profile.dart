import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_header_section.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/editor/lanes/schedule_lanes_applicability.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/editor/lanes/schedule_lanes_editor.dart';

class ScheduleLanesProfile extends StatelessWidget {
  const ScheduleLanesProfile({
    super.key,
    required this.rows,
    required this.isActiveGeral,
    required this.activeServiceLabel,
    required this.canRemoveIndex,
    required this.allowedForLane,
    required this.onAdd,
    required this.onRemoveAt,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onPosChanged,
    required this.onNameChanged,
    required this.onLaneColorChanged,
    required this.onAllowedChanged,
    required this.compact,
  });

  final List<ScheduleLinearLaneData> rows;
  final bool isActiveGeral;
  final String activeServiceLabel;

  final bool Function(int index) canRemoveIndex;
  final bool Function(int index) allowedForLane;

  final VoidCallback onAdd;

  final ValueChanged<int> onRemoveAt;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  final void Function(int index, String value) onPosChanged;
  final void Function(int index, String value) onNameChanged;
  final void Function(int index, int colorValue) onLaneColorChanged;
  final void Function(int index, bool value) onAllowedChanged;

  final bool compact;

  bool _canMoveUp(int index) {
    return index > 0;
  }

  bool _canMoveDown(int index) {
    return index >= 0 && index < rows.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lanesList = ListView.separated(
      itemCount: rows.length,
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Column(
          children: [
            ScheduleLanesEditor(
              index: index,
              data: rows[index],
              compact: compact,
              canRemove: canRemoveIndex(index),
              canMoveUp: _canMoveUp(index),
              canMoveDown: _canMoveDown(index),
              onRemove: () => onRemoveAt(index),
              onMoveUp: _canMoveUp(index) ? () => onMoveUp(index) : null,
              onMoveDown: _canMoveDown(index) ? () => onMoveDown(index) : null,
              onPosChanged: (value) => onPosChanged(index, value),
              onNameChanged: (value) => onNameChanged(index, value),
              onColorChanged: (value) => onLaneColorChanged(index, value),
            ),
            const SizedBox(height: 6),
            ScheduleLanesApplicability(
              isGeral: isActiveGeral,
              serviceLabel: activeServiceLabel,
              value: allowedForLane(index),
              compact: compact,
              onChanged: isActiveGeral
                  ? null
                  : (value) {
                if (value == null) return;
                onAllowedChanged(index, value);
              },
            ),
          ],
        );
      },
    );

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScheduleHeaderSection(
            title: 'Faixas',
            icon: Icons.view_stream_outlined,
            compact: true,
            description:
            'Use as setas nos serviços para definir a ordem.',
            primaryLabel: 'Adicionar faixa',
            primaryIcon: Icons.add,
            onPrimary: onAdd,
          ),
          const SizedBox(height: 10),
          lanesList,
        ],
      )
          : Column(
        children: [
          ScheduleHeaderSection(
            title: 'Faixas',
            icon: Icons.view_stream_outlined,
            compact: false,
            description:
            'Use as setas nos serviços para definir a ordem.',
            primaryLabel: 'Adicionar faixa',
            primaryIcon: Icons.add,
            onPrimary: onAdd,
          ),
          const SizedBox(height: 10),
          Expanded(child: lanesList),
        ],
      ),
    );
  }
}