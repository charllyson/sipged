import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_lane_data.dart';

class ScheduleGhost extends StatelessWidget {
  const ScheduleGhost({
    super.key,
    required this.w,
    required this.columnHeight,
    required this.headerHeight,
    required this.kCellVPad,
    required this.faixas,
  });

  final double w;
  final double columnHeight;
  final double headerHeight;
  final double kCellVPad;
  final List<ScheduleLinearLaneData> faixas;

  String _posLabelForIndex(int i) {
    const pattern = ['LE', 'LE', 'CE', 'LD', 'LD'];
    return pattern[i % pattern.length];
  }

  String _resolvedPos(ScheduleLinearLaneData faixa, int index) {
    final fromData = (faixa.pos).trim();

    if (fromData.isNotEmpty) {
      return fromData;
    }

    final fromController = (faixa.posCtrl?.text ?? '').trim();

    if (fromController.isNotEmpty) {
      return fromController;
    }

    return _posLabelForIndex(index);
  }

  Color _resolvedLaneColor(ScheduleLinearLaneData faixa) {
    return faixa.color;
  }

  double _resolvedLaneHeight(ScheduleLinearLaneData faixa) {
    return faixa.altura;
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
                      height: _resolvedLaneHeight(faixas[i]),
                      decoration: BoxDecoration(
                        color: _resolvedLaneColor(faixas[i]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        _resolvedPos(faixas[i], i),
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