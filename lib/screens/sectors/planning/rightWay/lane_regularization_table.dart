// lib/screens/sectors/planning/rightWay/property/lane_regularization_table.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/overlays/loading_progress.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_widgets/texts/divider_text.dart';

import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/process/laneRegularization/lane_regularization_controller.dart';
import 'package:siged/_blocs/process/laneRegularization/lane_regularization_data.dart';

class LaneRegularizationTable extends StatelessWidget {
  const LaneRegularizationTable({
    super.key,
    required this.controller,
    this.headerTitle = 'Imóveis cadastrados',
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
    this.emptyMessage = 'Nenhum imóvel encontrado.',
  });

  final LaneRegularizationController controller;
  final String headerTitle;
  final EdgeInsetsGeometry padding;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DividerText(title: headerTitle),

        // 🔧 Dá altura elástica para a área da tabela
        Expanded(
          child: Padding(
            padding: padding,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return FutureBuilder<List<LaneRegularizationData>>(
                  future: controller.futureProps,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        (snapshot.data == null || snapshot.data!.isEmpty)) {
                      return const LoadingProgress();
                    }
                    if (snapshot.hasError) {
                      return Text('Erro: ${snapshot.error}');
                    }

                    final data = snapshot.data ?? const <LaneRegularizationData>[];
                    if (data.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(emptyMessage),
                      );
                    }

                    controller.applySnapshot(data);

                    // 🔧 Rolagem vertical + horizontal
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Scrollbar(
                          interactive: true,
                          child: SingleChildScrollView( // vertical
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView( // horizontal
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: SimpleTableChanged<LaneRegularizationData>(
                                  constraints: constraints,
                                  listData: data,
                                  columnTitles: const [
                                    'STATUS',
                                    'PROPRIETÁRIO',
                                    'CPF/CNPJ',
                                    'TIPO',
                                    'ETAPA',
                                    'NEGOCIAÇÃO',
                                    'RODOVIA',
                                    'KM (INI-FIM)',
                                    'LADO',
                                    'MUNICÍPIO',
                                    'UF',
                                    'ÁREA ATINGIDA (m²)',
                                    'VALOR AVAL. (R\$)',
                                    'INDENIZAÇÃO (R\$)',
                                    'PAGAMENTO',
                                  ],
                                  columnGetters: [
                                        (p) => p.status ?? '-',
                                        (p) => p.ownerName ?? '-',
                                        (p) => p.cpfCnpj ?? '-',
                                        (p) => p.propertyType ?? '-',
                                        (p) => p.currentStage ?? '-',
                                        (p) => p.negotiationStatus ?? '-',
                                        (p) => p.roadName ?? '-',
                                        (p) {
                                      final a = p.kmStart; final b = p.kmEnd;
                                      if (a != null && b != null) {
                                        return '${a.toStringAsFixed(3)} - ${b.toStringAsFixed(3)}';
                                      } else if (a != null) {
                                        return a.toStringAsFixed(3);
                                      }
                                      return '-';
                                    },
                                        (p) => p.laneSide ?? '-',
                                        (p) => p.city ?? '-',
                                        (p) => p.state ?? '-',
                                        (p) => doubleToString(p.affectedArea),
                                        (p) => priceToString(p.appraisalValue),
                                        (p) => priceToString(p.indemnityValue),
                                        (p) => p.paymentDate != null ? dateTimeToDDMMYYYY(p.paymentDate!) : '-',
                                  ],
                                  columnWidths: const [
                                    130, 250, 140, 120, 140, 140, 120, 160, 80, 160, 60, 180, 160, 160, 120
                                  ],
                                  columnTextAligns: const [
                                    TextAlign.center, // status
                                    TextAlign.left,   // proprietário
                                    TextAlign.center, // cpf/cnpj
                                    TextAlign.center, // tipo
                                    TextAlign.center, // etapa
                                    TextAlign.center, // negociação
                                    TextAlign.center, // rodovia
                                    TextAlign.center, // km
                                    TextAlign.center, // lado
                                    TextAlign.center, // município
                                    TextAlign.center, // uf
                                    TextAlign.right,  // área
                                    TextAlign.right,  // valor avaliado
                                    TextAlign.right,  // indenização
                                    TextAlign.center, // pagamento
                                  ],
                                  onTapItem: controller.fillFields,
                                  onDelete: (p) async {
                                    if (p.id != null && controller.contract.id != null) {
                                      await controller.delete(context, p.id!);
                                    }
                                  },
                                  selectedItem: controller.selected,
                                ),
                              ),
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
        ),
      ],
    );
  }
}
