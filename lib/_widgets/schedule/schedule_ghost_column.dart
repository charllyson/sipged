import 'package:flutter/material.dart';
import 'package:sisged/_widgets/schedule/schedule_lane_class.dart';

import 'package:sisged/_blocs/sectors/operation/schedule_style.dart';

class ScheduleGhostColumn extends StatelessWidget {

  final double w;
  final double columnHeight;
  final double headerHeight;
  final double kCellVPad;
  final List<ScheduleLaneClass> faixas;


  String _posLabelForIndex(int i) {
    const pattern = ['LE', 'LE', 'CE', 'LD', 'LD'];
    return pattern[i % pattern.length];
  }

  const ScheduleGhostColumn({
    super.key,
    required this.w,
    required this.columnHeight,
    required this.headerHeight,
    required this.kCellVPad,
    required this.faixas,

  });

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
                  // bloco colorido com o MESMO padding das células reais
                  Padding(
                    padding:
                    EdgeInsets.symmetric(vertical: kCellVPad),
                    child: Container(
                      height: faixas[i].altura,
                      decoration: BoxDecoration(
                        color:
                        ScheduleStyle.colorForFaixa(faixas[i].label),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // rótulo central (opcional, puramente visual)
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        _posLabelForIndex(i),
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
