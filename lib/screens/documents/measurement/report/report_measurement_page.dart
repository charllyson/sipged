import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_controller.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'report_measurement_form_section.dart';
import 'report_measurement_graph_section.dart';
import 'report_measurement_table_section.dart';

class ReportMeasurement extends StatelessWidget {
  const ReportMeasurement({super.key, required this.contractData});
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
    return ChangeNotifierProvider(
      create: (_) => ReportMeasurementController(contract: contractData),
      builder: (context, _) {
        final c = context.read<ReportMeasurementController>();
        WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));

        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Consumer<ReportMeasurementController>(
                      builder: (context, ctrl, __) {
                        final labels = ctrl.labels;
                        final values = ctrl.values;
                        final totalMedicoes = ctrl.totalMedicoes;
                        final totalDisponivel = ctrl.valorTotalDisponivel;
                        final saldo = ctrl.saldo;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ---------- Gráfico ----------
                            const DividerText(title: 'Gráfico das medições'),
                            const SizedBox(height: 12),
                            ReportMeasurementGraphSection(
                              labels: labels,
                              values: values,
                              valorTotal: totalDisponivel,
                              totalMedicoes: totalMedicoes,
                              selectedIndex: ctrl.selectedLine,
                              onSelectIndex: ctrl.onSelectGraphIndex,
                            ),

                            const SizedBox(height: 12),
                            const DividerText(title: 'Cadastrar medições no sistema'),
                            const SizedBox(height: 12),

                            // ---------- Formulário ----------
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: ReportMeasurementFormSection(
                                isEditable: ctrl.isEditable,
                                formValidated: ctrl.formValidated,
                                selectedReportMeasurement: ctrl.selectedReport,
                                currentReportMeasurementId: ctrl.currentReportId,
                                contractData: ctrl.contract,
                                orderController: ctrl.orderCtrl,
                                processNumberController: ctrl.processCtrl,
                                dateController: ctrl.dateCtrl,
                                valueController: ctrl.valueCtrl,
                                reportMeasurementStorageBloc: ctrl.reportMeasurementStorageBloc,
                                onClear: ctrl.createNew,
                                onSave: () async {
                                  final ok = await _confirm(context, 'Deseja salvar esta medição?');
                                  if (ok) await ctrl.saveOrUpdate(context);
                                },
                              ),
                            ),

                            const SizedBox(height: 12),
                            const DividerText(title: 'Medições cadastradas no sistema'),
                            const SizedBox(height: 12),

                            // ---------- Tabela ----------
                            ReportMeasurementTableSection(
                              onTapItem: ctrl.handleSelect,
                              onDelete: (id) async {
                                final ok = await _confirm(context, 'Deseja realmente apagar esta medição?');
                                if (ok) await ctrl.deleteReport(context, id);
                              },
                              measurementsData: ctrl.reports, // página atual do controller
                              valorInicial: ctrl.valorInicialContrato,
                              valorAditivos: ctrl.totalAditivos,
                              valorTotal: totalDisponivel,
                              saldo: saldo,
                              contractData: ctrl.contract,
                              selectedMeasurement: ctrl.selectedReport,
                            ),

                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),

            // ---------- Overlay de carregamento (padrão do ValidityPage) ----------
            Consumer<ReportMeasurementController>(
              builder: (_, ctrl, __) =>
              ctrl.isSaving ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
