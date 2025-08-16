import 'package:flutter/material.dart';

import 'highway_class.dart';

class Legend extends StatelessWidget {
  final List<HighwayClass> faixas;

  const Legend({super.key, required this.faixas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 20),
        ...faixas.map(
              (faixa) => Container(
            height: faixa.altura,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 100,
              child: Text(
                faixa.label,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
