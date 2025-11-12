// ==============================
// lib/screens/contracts/apostilles/apostilles_page.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_controller.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'apostilles_form_section.dart';
import 'apostilles_graph_section.dart';
import 'apostilles_table_section.dart';

class ApostillesPage extends StatelessWidget {
  final ProcessData contractData;
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

                                      // controllers
                                      orderController: ctrl.orderController,
                                      processController: ctrl.processController,
                                      dateController: ctrl.dateController,
                                      valueController: ctrl.valueController,

                                      onSave: () => ctrl.saveOrUpdate(context),
                                      onClear: ctrl.createNew,

                                      // Dropdown de Ordem (novo)
                                      orderNumberOptions: ctrl.orderNumberOptions,
                                      greyOrderItems: ctrl.greyOrderItems,
                                      onChangedOrderNumber: ctrl.onChangeOrderNumber,

                                      // SideListBox (com rótulos)
                                      sideItems: ctrl.sideItems,
                                      selectedSideIndex: ctrl.selectedSideIndex,
                                      onAddSideItem: ctrl.canAddFile ? () => ctrl.handleAddFile(context) : null,
                                      onTapSideItem: (i) => ctrl.handleOpenFile(context, i), // ⬅️ abre modal
                                      onDeleteSideItem: (i) => ctrl.handleDeleteFile(i, context),
                                      onEditLabelSideItem: (i) => ctrl.handleEditLabelFile(i, context),
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: ApostilleTableSection(
                                      futureApostilles: ctrl.futureApostilles,
                                      onTapItem: ctrl.handleApostilleSelection,
                                      onDelete: (id) => ctrl.deleteApostille(context, id),
                                      selectedItem: ctrl.selectedApostille,
                                    ),
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
