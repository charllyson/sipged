import 'package:flutter/material.dart';
import 'tipo_dado_enum.dart';

class HeaderTipoDropdown extends StatelessWidget {
  final String coluna;
  final TipoDado tipoAtual;
  final ValueChanged<TipoDado?>? onChanged;
  final bool isSelecionado;
  final void Function(bool?) onCheckboxChanged;

  const HeaderTipoDropdown({
    super.key,
    required this.coluna,
    required this.tipoAtual,
    required this.onChanged,
    required this.isSelecionado,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: isSelecionado,
          onChanged: onCheckboxChanged,
        ),
        SizedBox(
          width: 80,
          child: DropdownButton<TipoDado>(
            isExpanded: true,
            value: tipoAtual,
            underline: const SizedBox(),
            items: TipoDado.values.map((tipo) {
              return DropdownMenuItem<TipoDado>(
                value: tipo,
                child: Text(tipo.name, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Text(coluna, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
