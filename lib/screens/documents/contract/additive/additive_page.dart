import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';

import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import 'additive_controller.dart';
import 'additive_form_section.dart';
import 'additive_graph_section.dart';
import 'additive_table_section.dart';
import '../../../../_datas/documents/contracts/additive/additive_data.dart';

class AdditivePage extends StatelessWidget {
  const AdditivePage({super.key, required this.contractData});
  final ContractData contractData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdditiveController(contract: contractData),
      builder: (context, _) {
        final c = context.read<AdditiveController>();
        WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));

        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Consumer<AdditiveController>(
                            builder: (context, ctrl, __) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DividerText(title: 'Cadastrar aditivos no sistema'),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: AdditiveFormSection(
                                      isEditable: ctrl.isEditable,
                                      editingMode: ctrl.editingMode,
                                      formValidated: ctrl.formValidated,
                                      selectedAdditive: ctrl.selectedAdditive,
                                      currentAdditiveId: ctrl.currentAdditiveId,
                                      contractData: ctrl.contract,
                                      orderController: ctrl.orderCtrl,
                                      processController: ctrl.processCtrl,
                                      dateController: ctrl.dateCtrl,
                                      typeOfAdditiveCtrl: ctrl.typeCtrl,
                                      valueController: ctrl.valueCtrl,
                                      additionalDaysExecutionController: ctrl.addDaysExecCtrl,
                                      additionalDaysContractController: ctrl.addDaysContractCtrl,
                                      onSave: () => ctrl.saveOrUpdate(context),
                                      onClear: ctrl.createNew,
                                      onUploadSaveToFirestore: ctrl.savePdfUrl,
                                    ),
                                  ),
                                  const DividerText(title: 'Gráfico dos aditivos'),
                                  FutureBuilder<List<AdditiveData>>(
                                    future: ctrl.futureAdditives,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final additives = snapshot.data!;
                                      ctrl.applySnapshot(additives);

                                      final values = additives.map((e) => e.additiveValue ?? 0.0).toList();
                                      final labels = additives.map((e) => (e.additiveOrder ?? '').toString()).toList();

                                      return AdditiveGraphSection(
                                        labels: labels,
                                        values: values,
                                        selectedIndex: ctrl.selectedLine,
                                        onSelectIndex: ctrl.onSelectGraphIndex,
                                      );
                                    },
                                  ),
                                  const DividerText(title: 'Aditivos cadastrados no sistema'),
                                  AdditiveTableSection(
                                    onTapItem: (a) => context.read<AdditiveController>().handleAdditiveSelection(a),
                                    onDelete: (id) => context.read<AdditiveController>().deleteAdditive(context, id),
                                    futureAdditive: context.read<AdditiveController>().futureAdditives,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const FootBar(),
              ],
            ),
            Consumer<AdditiveController>(
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
