// lib/screens/process/revision/revision_measurement.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/additives/additives_bloc.dart';

import 'package:siged/_blocs/process/revision/revision_measurement_bloc.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_controller.dart';

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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RevisionMeasurementController>(
      create: (_) => RevisionMeasurementController(
        contract: contractData,
        measurementBloc: RevisionMeasurementBloc(),
        additivesBloc: AdditivesBloc(),
      ),
      builder: (context, _) {
        final c = context.read<RevisionMeasurementController>();

        // contexto para os diálogos de rótulo do SideListBox
        c.attachBuildContext(context);

        // inicializa dados e permissões
        WidgetsBinding.instance.addPostFrameCallback((_) => c.init(context));

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
                                selectedRevisionMeasurement: ctrl.selectedRevision,
                                currentRevisionMeasurementId: ctrl.currentRevisionId,
                                contractData: ctrl.contract,
                                orderRevisionController: ctrl.orderCtrl,
                                processNumberRevisionController: ctrl.processCtrl,
                                dateRevisionController: ctrl.dateCtrl,
                                valueRevisionController: ctrl.valueCtrl,
                                onSave: () async {
                                  final ok = await _confirm(context, 'Deseja salvar esta medição?');
                                  if (ok) {
                                    await ctrl.saveOrUpdate(
                                      onConfirm: () async => true,
                                    );
                                  }
                                },
                                onClear: ctrl.createNew,
                                // ▶️ SideListBox (abre PDF em modal interno)
                                sideItems: ctrl.sideItems,
                                selectedSideIndex: ctrl.selectedSideIndex,
                                onAddSideItem: ctrl.canAddFile ? ctrl.handleAddFile : null,
                                onTapSideItem: (i) => ctrl.handleOpenFile(context, i),
                                onDeleteSideItem: ctrl.handleDeleteFile,
                                onEditLabelSideItem: ctrl.handleEditLabelFile,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const DividerText(title: 'Medições cadastradas no sistema'),
                            const SizedBox(height: 12),
                            RevisionMeasurementTableSection(
                              onTapItem: ctrl.selectRow,
                              onDelete:  (id) async {
                                final ok = await _confirm(
                                  context,
                                  'Deseja realmente apagar esta medição?',
                                );
                                if (ok) {
                                  await ctrl.deleteById(id);
                                }
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

            // overlay de "salvando"
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
