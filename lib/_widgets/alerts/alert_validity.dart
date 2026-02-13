// ==============================
// lib/screens/commons/alerts/alert_validity.dart
// ==============================
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// NOVO: ler DfdData completo
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

// Aditivos via Repository (novo padrão)
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';

class AlertValidity extends StatelessWidget {
  final ProcessData contract;

  const AlertValidity({
    super.key,
    required this.contract,
  });

  Future<DfdData?> _loadDfdStatus(String contractId) async {
    final repo = DfdRepository();
    final dfdData = await repo.readDataForContract(contractId);
    return dfdData;
  }

  /// Calcula a data final do contrato (vigência) com base:
  /// - publicationDate do contrato
  /// - initialValidityContract
  /// - soma de additiveValidityContractDays dos aditivos
  Future<DateTime?> _loadDataFinalContrato(ProcessData contract) async {
    final contractId = contract.id;
    if (contractId == null || contractId.isEmpty) return null;
    if (contract.publicationDate == null) return null;

    // 🔁 Novo padrão: usar AdditivesRepository, não mais AdditivesBloc
    final additivesRepo = AdditivesRepository();
    final List<AdditivesData> aditivos =
    await additivesRepo.ensureForContract(contractId);

    final int diasValidadeInicial = contract.initialValidityContract ?? 0;
    final int diasAditivos = aditivos.fold<int>(
      0,
          (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final int totalDias = diasValidadeInicial + diasAditivos;
    return contract.publicationDate!.add(Duration(days: totalDias));
  }

  @override
  Widget build(BuildContext context) {
    final contractId = contract.id;
    if (contractId == null || contractId.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1) Primeiro buscamos o STATUS do DFD (ex.: EM ANDAMENTO / A INICIAR / CONCLUÍDO)
    return FutureBuilder<DfdData?>(
      future: _loadDfdStatus(contractId),
      builder: (context, snapStatus) {
        if (!snapStatus.hasData) return const SizedBox.shrink();

        final status = snapStatus.data?.statusDemanda;

        // Mostra ícone só para contratos em andamento ou a iniciar (status do DFD)
        final elegivel =
            status == 'EM ANDAMENTO' || status == 'A INICIAR';
        if (!elegivel) return const SizedBox.shrink();

        // 2) Se elegível, calcula a data final do contrato
        return FutureBuilder<DateTime?>(
          future: _loadDataFinalContrato(contract),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();

            final dataFinal = snapshot.data;
            if (dataFinal == null) return const SizedBox.shrink();

            final dias = dataFinal.difference(DateTime.now()).inDays;

            if (dias < 0) {
              return Tooltip(
                message: 'Contrato vencido há ${-dias} dias',
                child: const Icon(
                  Icons.access_alarm,
                  color: Colors.redAccent,
                ),
              );
            } else if (dias <= 60) {
              return Tooltip(
                message: 'Faltam $dias dias',
                child: const Icon(
                  Icons.access_alarm,
                  color: Colors.orange,
                ),
              );
            } else {
              return Tooltip(
                message: '$dias dias para o vencimento',
                child: const Icon(
                  Icons.access_alarm,
                  color: Colors.grey,
                ),
              );
            }
          },
        );
      },
    );
  }
}
