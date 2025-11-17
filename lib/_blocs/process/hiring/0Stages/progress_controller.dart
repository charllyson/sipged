import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'progress_bloc.dart';
import 'progress_event.dart';

class ProgressController {
  final BuildContext context;
  ProgressController(this.context);

  /// Vincula o ProgressBloc a um doc de etapa:
  /// contracts/{contractId}/{collectionName}/{stageId}
  void bind({
    required String contractId,
    required String collectionName,
    required String stageId,
  }) {
    final bloc = context.read<ProgressBloc>();
    bloc.add(ProgressBindRequested(
      contractId: contractId,
      collectionName: collectionName,
      stageId: stageId,
    ));
  }

// As operações de escrita (approve/setCompleted) devem ser chamadas
// diretamente no ProgressRepository (ou nos repos das páginas específicas),
// pois exigem IDs explícitos. O Controller aqui é apenas façcade para bind.
}
