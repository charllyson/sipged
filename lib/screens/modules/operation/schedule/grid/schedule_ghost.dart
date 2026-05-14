import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_style.dart';

class ScheduleGhost extends StatelessWidget {
  final double w;
  final double columnHeight;
  final double headerHeight;
  final double kCellVPad;
  final List<ScheduleRoadData> faixas;

  const ScheduleGhost({
    super.key,
    required this.w,
    required this.columnHeight,
    required this.headerHeight,
    required this.kCellVPad,
    required this.faixas,
  });

  String _posLabelForIndex(int i) {
    const pattern = ['LE', 'LE', 'CE', 'LD', 'LD'];
    return pattern[i % pattern.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: columnHeight,
      child: Column(
        children: [
          SizedBox(height: headerHeight),
          for (int i = 0; i < faixas.length; i++)
            IgnorePointer(
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: kCellVPad),
                    child: Container(
                      height: faixas[i].altura ?? 20.0,
                      decoration: BoxDecoration(
                        color: ScheduleRoadStyle.colorForFaixa(
                          faixas[i].laneLabel,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        (faixas[i].pos ?? '').trim().isNotEmpty
                            ? faixas[i].pos!.trim()
                            : _posLabelForIndex(i),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}