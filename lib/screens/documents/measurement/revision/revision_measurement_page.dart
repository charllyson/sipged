import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/_widgets/footBar/foot_bar.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';

// ⬇️ blocos injetados no controller
import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart';

// controller + seções
import 'revision_measurement_controller.dart';
import 'revision_measurement_form_section.dart';
import 'revision_measurement_graph_section.dart';
import 'revision_measurement_table_section.dart';

class RevisionMeasurement extends StatelessWidget {
  const RevisionMeasurement({super.key, required this.contractData});
  final ContractData contractData;

  Future<bool> _confirm(BuildContext context, String msg) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RevisionMeasurementController>(
      create: (_) => RevisionMeasurementController(
        measurementBloc: ReportMeasurementBloc(),
        additivesBloc: AdditivesBloc(),
      ),
      builder: (context, _) {
        final c = context.read<RevisionMeasurementController>();
        // Inicializa com o contrato atual (controller usa `late ContractData contract`)
        WidgetsBinding.instance.addPostFrameCallback(
              (_) => c.init(context, contractData: contractData),
        );

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Consumer<RevisionMeasurementController>(
                    builder: (context, ctrl, __) {
                      final labels = ctrl.labels;
                      final values = ctrl.values;
                      final total = ctrl.totalMedicoes;
                      final totalDisponivel = ctrl.valorTotalDisponivel;
                      final saldo = ctrl.saldo;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const DividerText(title: 'Gráfico das medições'),
                            const SizedBox(height: 12),
                            RevisionMeasurementGraphSection(
                              labels: labels,
                              values: values,
                              valorTotal: totalDisponivel,
                              totalMedicoes: total,
                              selectedIndex: ctrl.selectedIndex,
                              onSelectIndex: ctrl.onSelectGraphIndex,
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Cadastrar medições no sistema'),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: RevisionMeasurementFormSection(
                                isEditable: ctrl.isEditable,
                                formValidated: ctrl.formValidated,
                                selectedAdjustmentMeasurement: ctrl.selectedRevision,
                                currentAdjustmentMeasurementId: ctrl.currentRevisionId,
                                contractData: ctrl.contract, // não-nulo (late) no controller
                                orderAdjustmentController: ctrl.orderCtrl,
                                processNumberAdjustmentController: ctrl.processCtrl,
                                dateAdjustmentController: ctrl.dateCtrl,
                                valueAdjustmentController: ctrl.valueCtrl,
                                onSave: () async {
                                  await ctrl.saveOrUpdate(
                                    onConfirm: () => _confirm(context, 'Deseja salvar esta medição?'),
                                    onSuccessSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Medição salva com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    onErrorSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Erro ao salvar a medição.'),
                                      ),
                                    ),
                                  );
                                },
                                onClear: ctrl.createNew, // ✅ passa a função, não o resultado
                                onUploadSaveToFirestore: ctrl.savePdfUrl,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Medições cadastradas no sistema'),
                            const SizedBox(height: 12),
                            RevisionMeasurementTableSection(
                              onTapItem: ctrl.selectRow,
                              onDelete: (id) async {
                                final ok = await _confirm(
                                  context,
                                  'Deseja realmente apagar esta medição?',
                                );
                                if (ok) {
                                  await ctrl.deleteById(
                                    id,
                                    onSuccessSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Medição apagada com sucesso.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                    onErrorSnack: () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Erro ao remover a medição.'),
                                      ),
                                    ),
                                  );
                                }
                              },
                              measurementsData: ctrl.revision,
                              valorInicial: ctrl.valorInicialContrato,
                              valorAditivos: ctrl.totalAditivos,
                              valorTotal: totalDisponivel,
                              saldo: saldo,
                              contractData: ctrl.contract, // não-nulo
                              selectedMeasurement: ctrl.selectedRevision,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const FootBar(),
              ],
            ),
            Consumer<RevisionMeasurementController>(
              builder: (_, ctrl, __) => ctrl.isSaving
                  ? Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: Colors.black.withOpacity(0.4),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
