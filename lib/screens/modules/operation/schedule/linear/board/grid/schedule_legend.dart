// lib/screens/modules/operation/schedule/linear/board/grid/schedule_legend.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/board/grid/schedule_grid.dart';

class ScheduleLegend extends StatelessWidget {
  const ScheduleLegend({
    super.key,
    required this.faixas,
    required this.legendWidth,
    required this.headerHeight,
    required this.columnHeight,
  });

  final List<ScheduleLinearLaneData> faixas;
  final double legendWidth;
  final double headerHeight;
  final double columnHeight;

  double _laneHeight(ScheduleLinearLaneData lane) {
    return lane.altura;
  }

  String _laneText(ScheduleLinearLaneData lane) {
    final nome = lane.nome.trim();

    if (nome.isNotEmpty) {
      return nome;
    }

    return lane.laneLabel;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: legendWidth,
      height: columnHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: headerHeight),
          ...faixas.map(
                (lane) => SizedBox(
              height: _laneHeight(lane) + ScheduleGrid.kCellVPad * 2,
              width: legendWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ScheduleGrid.kCellVPad,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _laneText(lane),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}