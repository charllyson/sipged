import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/validity/validity_store.dart';

class AlertValidity extends StatelessWidget {
  final ContractData contract;

  const AlertValidity({
    super.key,
    required this.contract,
  });

  @override
  Widget build(BuildContext context) {
    final status = contract.contractStatus?.toUpperCase();

    // Mostra ícone só para contratos em andamento ou a iniciar
    if (status != 'EM ANDAMENTO' && status != 'A INICIAR') {
      return const SizedBox.shrink();
    }

    final validityStore = context.read<ValidityStore>();
    final additivesStore = context.read<AdditivesStore>();

    return FutureBuilder<DateTime?>(
      future: validityStore.calcularDataFinalContrato(
        contract: contract,
        additivesStore: additivesStore,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final dataFinal = snapshot.data!;
        final dias = dataFinal.difference(DateTime.now()).inDays;

        if (dias < 0) {
          return Tooltip(
            message: 'Contrato vencido há ${-dias} dias',
            child: const Icon(Icons.access_alarm, color: Colors.redAccent),
          );
        } else if (dias <= 60) {
          return Tooltip(
            message: 'Faltam $dias dias',
            child: const Icon(Icons.access_alarm, color: Colors.orange),
          );
        } else {
          return Tooltip(
            message: '$dias dias para o vencimento',
            child: const Icon(Icons.access_alarm, color: Colors.grey),
          );
        }
      },
    );
  }
}
