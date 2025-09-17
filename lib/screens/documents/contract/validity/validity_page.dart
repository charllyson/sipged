import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_controller.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_widgets/timeline/timeline_class.dart';
import 'validity_form_section.dart';
import 'validity_table_section.dart';

class ValidityPage extends StatelessWidget {
  const ValidityPage({super.key, required this.contractData});
  final ContractData contractData;

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente salvar ou atualizar esta ordem?'),
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
      create: (_) => ValidityController(contract: contractData),
      builder: (context, _) {
        final c = context.read<ValidityController>();
        WidgetsBinding.instance.addPostFrameCallback((_) => c.postFrameInit(context));

        return Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Consumer<ValidityController>(
                      builder: (context, ctrl, __) {
                        return Column(
                          children: [
                            // Timeline
                            TimelineClass(
                              futureValidity: ctrl.futureValidity,
                              futureContractList: ctrl.futureContractList,
                              futureAdditiveList: ctrl.futureAdditives,
                            ),
                            const SizedBox(height: 12),

                            const DividerText(title: 'Cadastrar validades no sistema'),
                            const SizedBox(height: 12),

                            // Form + SideListBox
                            ValidityFormSection(
                              orderCtrl: ctrl.orderCtrl,
                              orderTypeCtrl: ctrl.orderTypeCtrl,
                              orderDateCtrl: ctrl.orderDateCtrl,
                              availableOrders: ctrl.availableOrders,
                              selectedValidityData: ctrl.selectedValidityData,
                              isEditable: ctrl.isEditable,
                              isSaving: ctrl.isSaving,
                              formValidated: ctrl.formValidated,
                              contractData: ctrl.contract,
                              onChangeDate: ctrl.onChangeDate,
                              onClear: ctrl.createNew,
                              onSaveOrUpdate: () async {
                                final ok = await _confirm(context);
                                if (ok) await ctrl.saveOrUpdate(context);
                              },
                              // SideListBox bindings
                              sideItems: ctrl.fileNames,
                              selectedSideIndex: ctrl.selectedFileIndex,
                              onAddSideItem: () => ctrl.addFile(context),
                              onTapSideItem: (i) => ctrl.openFileAt(i, context),
                              onDeleteSideItem: (i) => ctrl.removeFileAt(i, context),
                            ),

                            const SizedBox(height: 12),
                            const DividerText(title: 'Validades cadastradas no sistema'),
                            const SizedBox(height: 12),

                            // Tabela (com destaque da linha selecionada)
                            ValidityTableSection(
                              futureValidity: ctrl.futureValidity,
                              onTapItem: ctrl.fillFields,
                              onDelete: (id) async {
                                final ok = await _confirm(context);
                                if (ok) await ctrl.deleteValidity(context, id);
                              },
                              selectedItem: ctrl.selectedValidityData,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const FootBar(),
              ],
            ),
            Consumer<ValidityController>(
              builder: (_, ctrl, __) => ctrl.isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
