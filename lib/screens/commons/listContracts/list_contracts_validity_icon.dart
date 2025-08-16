import 'package:flutter/material.dart';
import '../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';

class ContractValidityIcon extends StatelessWidget {
  final ContractData contract;
  final ValidityBloc validityBloc;

  const ContractValidityIcon({
    super.key,
    required this.contract,
    required this.validityBloc,
  });

  @override
  Widget build(BuildContext context) {
    final status = contract.contractStatus?.toUpperCase();
    if (status != 'EM ANDAMENTO' && status != 'A INICIAR') {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DateTime?>(
      future: validityBloc.calcularDataFinalContrato(contract: contract),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final dias = snapshot.data!.difference(DateTime.now()).inDays;

        if (dias < 15) {
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
