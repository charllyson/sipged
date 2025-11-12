import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/validity/validity_store.dart';

// NOVO: ler status do DFD (identificacao.statusContrato)
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

class AlertValidity extends StatelessWidget {
  final ProcessData contract;

  const AlertValidity({
    super.key,
    required this.contract,
  });

  Future<String?> _loadDfdStatus(String? contractId) async {
    if (contractId == null || contractId.isEmpty) return null;
    try {
      final repo = DfdRepository();
      final r = await repo.readLightFields(contractId);
      return (r.status ?? '').trim();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final validityStore = context.read<ValidityStore>();
    final additivesStore = context.read<AdditivesStore>();

    final contractId = (() {
      final id = contract.id;
      try {
        // suporta objetos com .id ou string direta
        final dyn = id as dynamic;
        final hasIdProp = (() {
          try {
            return (dyn as dynamic).id is String;
          } catch (_) {
            return false;
          }
        })();
        if (hasIdProp) return (dyn as dynamic).id as String;
      } catch (_) {}
      return id?.toString();
    })();

    // 1) Primeiro buscamos o STATUS do DFD
    return FutureBuilder<String?>(
      future: _loadDfdStatus(contractId),
      builder: (context, snapStatus) {
        if (!snapStatus.hasData) return const SizedBox.shrink();

        final status = (snapStatus.data ?? '').toUpperCase();

        // Mostra ícone só para contratos em andamento ou a iniciar (status do DFD)
        final elegivel = status == 'EM ANDAMENTO' || status == 'A INICIAR';
        if (!elegivel) return const SizedBox.shrink();

        // 2) Se elegível, calcula a data final do contrato normalmente
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
      },
    );
  }
}
