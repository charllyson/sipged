import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/texts/divider_text.dart';import 'package:sisged/_widgets/footBar/foot_bar.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_data.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_store.dart';
import 'apostilles_controller.dart';
import 'apostilles_form_section.dart';
import 'apostilles_graph_section.dart';
import 'apostilles_table_section.dart';

class ApostillesPage extends StatelessWidget {
  final ContractData contractData;
  const ApostillesPage({super.key, required this.contractData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ApostillesController(
        store: ctx.read<ApostillesStore>(),
        contract: contractData,
      ),
      builder: (context, _) {
        final c = context.read<ApostillesController>();
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
                          child: Consumer<ApostillesController>(
                            builder: (context, ctrl, __) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const DividerText(title: 'Cadastrar apostilamentos no sistema'),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: ApostilleFormSection(
                                      isEditable: ctrl.isEditable,
                                      editingMode: ctrl.editingMode,
                                      formValidated: ctrl.formValidated,
                                      selectedApostille: ctrl.selectedApostille,
                                      currentApostilleId: ctrl.currentApostilleId,
                                      contractData: ctrl.contract,
                                      apostillesStorageBloc: ctrl.apostillesStorageBloc,
                                      orderController: ctrl.orderCtrl,
                                      processController: ctrl.processCtrl,
                                      dateController: ctrl.dateCtrl,
                                      valueController: ctrl.valueCtrl,
                                      onSave: () => ctrl.saveOrUpdate(context),
                                      onClear: ctrl.createNew,
                                    ),
                                  ),
                                  const DividerText(title: 'Gráfico dos apostilamentos'),
                                  FutureBuilder<List<ApostillesData>>(
                                    future: ctrl.futureApostilles,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final list = snapshot.data!;
                                      ctrl.applySnapshot(list);

                                      final values = list.map((e) => e.apostilleValue ?? 0.0).toList();
                                      final labels = list.map((e) => (e.apostilleOrder ?? '').toString()).toList();

                                      return ApostilleGraphSection(
                                        labels: labels,
                                        values: values,
                                        selectedIndex: ctrl.selectedLine,
                                        onSelectIndex: ctrl.onSelectGraphIndex,
                                      );
                                    },
                                  ),
                                  const DividerText(title: 'Apostilamentos cadastrados no sistema'),
                                  ApostilleTableSection(
                                    futureApostilles: context.read<ApostillesController>().futureApostilles,
                                    onTapItem: (a) => context.read<ApostillesController>().handleApostilleSelection(a),
                                    onDelete: (id) => context.read<ApostillesController>().deleteApostille(context, id),
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
            Consumer<ApostillesController>(
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
