import 'package:flutter/material.dart';

import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_controller.dart';
import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_data.dart';

import 'package:siged/_widgets/loading/loading_progress.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_widgets/texts/divider_text.dart';

import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

/// Tabela de imóveis do Domínio de Faixa (Right Way)
/// - Usa apenas o `PlanningRightWayPropertyController`
/// - Preenche o formulário ao clicar em uma linha (fillFields)
/// - Permite deletar um item (delete)
class PlanningRightWayPropertyTable extends StatelessWidget {
  const PlanningRightWayPropertyTable({
    super.key,
    required this.controller,
    this.headerTitle = 'Imóveis cadastrados',
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
    this.emptyMessage = 'Nenhum imóvel encontrado.',
  });

  final PlanningRightWayPropertyController controller;
  final String headerTitle;
  final EdgeInsetsGeometry padding;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DividerText(title: headerTitle),

        Padding(
          padding: padding,
          // ✅ Ouvimos o controller para rebuildar a FutureBuilder quando ele der notifyListeners()
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return FutureBuilder<List<PlanningRightWayPropertyData>>(
                future: controller.futureProps,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      (snapshot.data == null || snapshot.data!.isEmpty)) {
                    return const LoadingProgress();
                  }
                  if (snapshot.hasError) {
                    return Text('Erro: ${snapshot.error}');
                  }

                  final data = snapshot.data ?? const <PlanningRightWayPropertyData>[];
                  if (data.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(emptyMessage),
                    );
                  }

                  // mantém o snapshot atual no controller (para seleção etc.)
                  controller.applySnapshot(data);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SimpleTableChanged<PlanningRightWayPropertyData>(
                            constraints: constraints,
                            listData: data,

                            // Cabeçalhos
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

                            // Como extrair cada coluna do item
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

                            // Larguras fixas (ajuste se preferir)
                            columnWidths: const [220, 140, 100, 140, 160, 60, 160, 160, 120],

                            // Alinhamentos por coluna
                            columnTextAligns: const [
                              TextAlign.left,   // proprietário
                              TextAlign.center, // cpf/cnpj
                              TextAlign.center, // tipo
                              TextAlign.center, // status
                              TextAlign.center, // município
                              TextAlign.center, // uf
                              TextAlign.right,  // área atingida
                              TextAlign.right,  // indenização
                              TextAlign.center, // vistoria
                            ],

                            // Ações
                            onTapItem: controller.fillFields,
                            onDelete: (p) async {
                              if (p.id != null && controller.contract.id != null) {
                                await controller.delete(context, p.id!);
                              }
                            },

                            // Seleção atual (funciona mesmo após reload por igualdade via id)
                            selectedItem: controller.selected,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
