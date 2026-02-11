// lib/screens/modules/planning/rightWay/property/lane_regularization_table.dart
import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';

import 'package:siged/_widgets/overlays/loading_progress.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

// ✅ NOVO: sem intl
import 'package:siged/_utils/formats/sipged_format_numbers.dart';
import 'package:siged/_utils/formats/sipged_format_money.dart';

import 'package:siged/_blocs/modules/planning/lane_regularization/lane_regularization_controller.dart';
import 'package:siged/_blocs/modules/planning/lane_regularization/lane_regularization_data.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

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

  String _fmtDec(double? v, {int digits = 2, String empty = '-'}) {
    if (v == null) return empty;
    return SipGedFormatNumbers.decimalPtBr(v, fractionDigits: digits);
  }

  String _fmtMoney(double? v, {String empty = '-'}) {
    if (v == null) return empty;
    return SipGedFormatMoney.doubleToText(v);
  }

  String _fmtKmIniFim(LaneRegularizationData p) {
    final a = p.kmStart;
    final b = p.kmEnd;
    if (a != null && b != null) {
      return '${_fmtDec(a, digits: 3)} - ${_fmtDec(b, digits: 3)}';
    } else if (a != null) {
      return _fmtDec(a, digits: 3);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle(text: headerTitle),
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
                          child: SingleChildScrollView(
                            // vertical
                            padding: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              // horizontal
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
                                        (p) => _fmtKmIniFim(p),
                                        (p) => p.laneSide ?? '-',
                                        (p) => p.city ?? '-',
                                        (p) => p.state ?? '-',
                                        (p) => _fmtDec(p.affectedArea, digits: 2),
                                        (p) => _fmtMoney(p.appraisalValue),
                                        (p) => _fmtMoney(p.indemnityValue),
                                        (p) => p.paymentDate != null
                                        ? SipGedFormatDates.dateToDdMMyyyy(p.paymentDate!)
                                        : '-',
                                  ],
                                  columnWidths: const [
                                    130,
                                    250,
                                    140,
                                    120,
                                    140,
                                    140,
                                    120,
                                    160,
                                    80,
                                    160,
                                    60,
                                    180,
                                    160,
                                    160,
                                    120
                                  ],
                                  columnTextAligns: const [
                                    TextAlign.center, // status
                                    TextAlign.left, // proprietário
                                    TextAlign.center, // cpf/cnpj
                                    TextAlign.center, // tipo
                                    TextAlign.center, // etapa
                                    TextAlign.center, // negociação
                                    TextAlign.center, // rodovia
                                    TextAlign.center, // km
                                    TextAlign.center, // lado
                                    TextAlign.center, // município
                                    TextAlign.center, // uf
                                    TextAlign.right, // área
                                    TextAlign.right, // valor avaliado
                                    TextAlign.right, // indenização
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
