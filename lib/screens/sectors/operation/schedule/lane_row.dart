import 'package:flutter/material.dart';

import '../../../../_widgets/input/custom_text_field.dart';
import 'lane_row_data.dart';

class LaneRow extends StatelessWidget {
  const LaneRow({
    required this.index,
    required this.data,
    required this.canRemove,
    required this.onRemove,
    required this.onPosChanged,
    required this.onNameChanged,
  });

  final int index;
  final LaneRowData data;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onPosChanged;
  final ValueChanged<String> onNameChanged;

  static const _rowHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // Tracinho colorido (muda conforme NOME da faixa)
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(width: 12, height: double.infinity, color: data.color),
          ),
          const SizedBox(width: 10),

          // POSIÇÃO (texto livre; regra de remoção não depende dele)
          SizedBox(
            width: 72,
            child: CustomTextField(
              controller: data.posCtrl,
              onChanged: onPosChanged,
              textInputAction: TextInputAction.next,
              labelText: 'Posição',
              hintText: 'ex.: LE, CE, LD…',
            ),
          ),
          const SizedBox(width: 10),

          // NOME DA FAIXA
          Expanded(
            child: CustomTextField(
              controller: data.nameCtrl,
              onChanged: onNameChanged,
              labelText: 'Nome da faixa',
              hintText: 'ex.: PISTA ATUAL, CANTEIRO…',
            ),
          ),

          const SizedBox(width: 4),
          if (canRemove)
            IconButton(
              tooltip: 'Remover faixa',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
        ],
      ),
    );
  }
}
