import 'package:flutter/material.dart';
import 'package:sipged/_widgets/schedule/linear/schedule_lane_class.dart';
import 'schedule_grid.dart';

class ScheduleLegend extends StatelessWidget {
  const ScheduleLegend({
    super.key,
    required this.faixas,
    required this.legendWidth,
    required this.headerHeight,
    required this.columnHeight,
  });

  final List<ScheduleLaneClass> faixas;
  final double legendWidth;
  final double headerHeight;
  final double columnHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: columnHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: headerHeight),
          ...faixas.map(
                (f) => SizedBox(
              height: f.altura + ScheduleGrid.kCellVPad * 2,
              width: legendWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ScheduleGrid.kCellVPad,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    f.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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