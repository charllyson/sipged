import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/highway_property_controller.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/highway_property_data.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/right_way_properties_store.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';

import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';
import 'package:siged/screens/sectors/planning/rightWay/highway_property_form_section.dart';

class RightWayPropertyPage extends StatelessWidget {
  final ContractData contract;
  const RightWayPropertyPage({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RightWayPropertiesStore()),
        ChangeNotifierProvider(
          create: (ctx) => RightWayPropertyController(
            contract: contract,
            store: ctx.read<RightWayPropertiesStore>(),
          ),
        ),
      ],
      child: _RightWayPropertyView(contract: contract),
    );
  }
}

class _RightWayPropertyView extends StatelessWidget {
  final ContractData contract;
  const _RightWayPropertyView({required this.contract});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<RightWayPropertyController>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: UpBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: BackCircleButton(),
          ),
          actions: [
            IconButton(
              tooltip: 'Limpar formulário',
              icon: const Icon(Icons.restore, color: Colors.white),
              onPressed: ctrl.editingMode ? ctrl.clearForm : null,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          BackgroundClean(),

          Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DividerText(title: 'Cadastrar imóvel afetado pelo domínio'),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: RightWayPropertyFormSection(
                                isEditable: ctrl.isEditable,
                                editingMode: ctrl.editingMode,
                                formValidated: ctrl.formValidated,
                                selected: ctrl.selected,
                                currentId: ctrl.currentId,
                                ownerCtrl: ctrl.ownerCtrl,
                                cpfCnpjCtrl: ctrl.cpfCnpjCtrl,
                                typeCtrl: ctrl.typeCtrl,
                                statusCtrl: ctrl.statusCtrl,
                                registryCtrl: ctrl.registryCtrl,
                                officeCtrl: ctrl.officeCtrl,
                                addressCtrl: ctrl.addressCtrl,
                                cityCtrl: ctrl.cityCtrl,
                                ufCtrl: ctrl.ufCtrl,
                                processCtrl: ctrl.processCtrl,
                                notifDateCtrl: ctrl.notifDateCtrl,
                                inspDateCtrl: ctrl.inspDateCtrl,
                                agreeDateCtrl: ctrl.agreeDateCtrl,
                                totalAreaCtrl: ctrl.totalAreaCtrl,
                                affectedAreaCtrl: ctrl.affectedAreaCtrl,
                                indemnityCtrl: ctrl.indemnityCtrl,
                                phoneCtrl: ctrl.phoneCtrl,
                                emailCtrl: ctrl.emailCtrl,
                                notesCtrl: ctrl.notesCtrl,
                                onSave: () => ctrl.saveOrUpdate(context),
                                onClear: ctrl.clearForm,
                              ),
                            ),

                            const DividerText(title: 'Imóveis cadastrados'),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: FutureBuilder<List<RightWayPropertyData>>(
                                future: ctrl.futureProps,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const LoadingProgress();
                                  } else if (snapshot.hasError) {
                                    return Text('Erro: ${snapshot.error}');
                                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Nenhum imóvel encontrado.'),
                                    );
                                  }
                                  final data = snapshot.data!;
                                  ctrl.applySnapshot(data);

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                      child: SimpleTableChanged<RightWayPropertyData>(
                                        constraints: constraints,
                                        listData: data,
                                        columnTitles: const [
                                          'PROPRIETÁRIO',
                                          'CPF/CNPJ',
                                          'TIPO',
                                          'STATUS',
                                          'MUNICÍPIO',
                                          'UF',
                                          'ÁREA ATINGIDA (m²)',
                                          'INDENIZAÇÃO (R\$)',
                                          'VISTORIA',
                                        ],
                                        columnGetters: [
                                              (p) => p.ownerName ?? '-',
                                              (p) => p.cpfCnpj ?? '-',
                                              (p) => p.propertyType ?? '-',
                                              (p) => p.status ?? '-',
                                              (p) => p.city ?? '-',
                                              (p) => p.state ?? '-',
                                              (p) => doubleToString(p.affectedArea),
                                              (p) => priceToString(p.indemnityValue),
                                              (p) => p.inspectionDate != null
                                              ? dateTimeToDDMMYYYY(p.inspectionDate!)
                                              : '-',
                                        ],
                                        onTapItem: ctrl.fillFields,
                                        onDelete: (p) {
                                          if (p.id != null) {
                                            ctrl.delete(context, p.id!);
                                          }
                                        },
                                        columnWidths: const [220, 140, 100, 140, 160, 60, 160, 160, 120],
                                        columnTextAligns: const [
                                          TextAlign.left,  // proprietário
                                          TextAlign.center,// cpf/cnpj
                                          TextAlign.center,// tipo
                                          TextAlign.center,// status
                                          TextAlign.center,// município
                                          TextAlign.center,// uf
                                          TextAlign.right, // área atingida
                                          TextAlign.right, // indenização
                                          TextAlign.center,// vistoria
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const FootBar(),
            ],
          ),
        ],
      ),

      // Overlay de salvamento
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ctrl.isSaving
          ? FloatingActionButton(
        onPressed: () {},
        tooltip: 'Salvando...',
        child: const SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      )
          : null,
    );
  }
}
