import 'package:flutter/material.dart';

import '../../../_blocs/process/contracts/contracts_controller.dart';

class OverviewDashboardTypeFiltered extends StatelessWidget {
  final ContractsController controller;

  const OverviewDashboardTypeFiltered({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        const Text('Filtrar por: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          dropdownColor: Colors.white,
          isDense: true,
          underline: Container(),
          value: controller.tipoDeValorSelecionado,
          items: ['Somatório total', 'Valor contratado', 'Total em aditivos', 'Total em apostilas']
              .map((tipo) => DropdownMenuItem(
            value: tipo,
            child: Text(tipo),
          ))
              .toList(),
          onChanged: (val) {
            controller.tipoDeValorSelecionado = val ?? 'Somatório total';
            controller.notifyListeners();
          },
        ),
      ],
    );
  }
}
