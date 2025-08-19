import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';

import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RevisionMeasurementController(contract: contractData),
      builder: (context, _) {
        final c = context.read<RevisionMeasurementController>();
        WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));

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
                              selectedIndex: ctrl.selectedLine,
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
                                contractData: ctrl.contract,
                                orderAdjustmentController: ctrl.orderCtrl,
                                processNumberAdjustmentController: ctrl.processCtrl,
                                dateAdjustmentController: ctrl.dateCtrl,
                                valueAdjustmentController: ctrl.valueCtrl,
                                onSave: () async {
                                  final ok = await _confirm(context, 'Deseja salvar esta medição?');
                                  if (ok) await ctrl.saveOrUpdate(context);
                                },
                                onClear: ctrl.createNew,
                                onUploadSaveToFirestore: ctrl.savePdfUrl,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Medições cadastradas no sistema'),
                            const SizedBox(height: 12),
                            RevisionMeasurementTableSection(
                              onTapItem: ctrl.handleSelect,
                              onDelete: (id) async {
                                final ok = await _confirm(context, 'Deseja realmente apagar esta medição?');
                                if (ok) await ctrl.deleteReport(context, id);
                              },
                              measurementsData: ctrl.revision,
                              valorInicial: ctrl.valorInicialContrato,
                              valorAditivos: ctrl.totalAditivos,
                              valorTotal: totalDisponivel,
                              saldo: saldo,
                              contractData: ctrl.contract,
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
                  ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
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
