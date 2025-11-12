import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import '../../../../_blocs/process/adjustment/adjustment_measurement_controller.dart';
import 'adjustment_measurement_form_section.dart';
import 'adjustment_measurement_graph_section.dart';
import 'adjustment_measurement_table_section.dart';

class AdjustmentMeasurement extends StatelessWidget {
  const AdjustmentMeasurement({super.key, required this.contractData});
  final ProcessData contractData;

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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdjustmentMeasurementController(contract: contractData),
      builder: (context, _) {
        final c = context.read<AdjustmentMeasurementController>();
        c.attachBuildContext(context);
        WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Consumer<AdjustmentMeasurementController>(
                    builder: (context, ctrl, __) {
                      final labels = ctrl.labels;
                      final values = ctrl.values;
                      final total = ctrl.totalAdjustments;
                      final totalDisponivel = ctrl.valorTotalDisponivel;
                      final saldo = ctrl.saldo;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const DividerText(title: 'Gráfico dos reajustes'),
                            const SizedBox(height: 12),
                            AdjustmentMeasurementGraphSection(
                              labels: labels,
                              values: values,
                              valorTotal: totalDisponivel,
                              totalMedicoes: total,
                              selectedIndex: ctrl.selectedLine,
                              onSelectIndex: ctrl.onSelectGraphIndex,
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Cadastrar reajuste no sistema'),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: AdjustmentMeasurementFormSection(
                                isEditable: ctrl.isEditable,
                                formValidated: ctrl.formValidated,
                                selectedAdjustmentMeasurement: ctrl.selectedAdjustment,
                                currentAdjustmentMeasurementId: ctrl.currentAdjustmentId,
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
                                // SideListBox
                                sideItems: ctrl.sideItems,
                                selectedSideIndex: ctrl.selectedSideIndex,
                                onAddSideItem: (!ctrl.isSaving && ctrl.canAddFile) ? ctrl.handleAddFile : null,
                                onTapSideItem: (i) => ctrl.handleOpenFile(context, i), // ⬅️ abre viewer interno
                                onDeleteSideItem: (i) async => ctrl.handleDeleteFile(i),
                                onEditLabelSideItem: (i) async => ctrl.handleEditLabelFile(i),

                                // =========================
                                // NOVAS PROPRIEDADES (DROPDOWN ORDEM)
                                // =========================
                                orderOptions: ctrl.orderOptions,
                                greyOrderItems: ctrl.greyOrderItems,
                                onChangedOrder: ctrl.onChangeOrderDropdown,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Reajustes cadastrados no sistema'),
                            const SizedBox(height: 12),
                            AdjustmentMeasurementTableSection(
                              onTapItem: ctrl.handleSelect,
                              onDelete: (id) async {
                                final ok = await _confirm(context, 'Deseja realmente apagar esta medição?');
                                if (ok) await ctrl.deleteAdjustment(context, id);
                              },
                              adjustmentMeasurementsData: ctrl.adjustments,
                              valueApostilles: ctrl.totalApostilles,
                              valueRevisions: ctrl.totalAdditives,
                              valorTotal: totalDisponivel,
                              balance: saldo,
                              contractData: ctrl.contract,
                              selectedAdjustmentMeasurement: ctrl.selectedAdjustment,
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
            Consumer<AdjustmentMeasurementController>(
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
