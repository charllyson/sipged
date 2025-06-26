import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import 'package:sisgeo/_utils/date_utils.dart';

class TimelineItem {
  final String title;
  final DateTime? date;
  final String source; // 'validity', 'contract', 'additive', 'prazo'
  final dynamic original;

  TimelineItem({
    required this.title,
    required this.date,
    required this.source,
    this.original,
  });
}

class TimelineClass extends StatelessWidget {
  final Future<List<ValidityData>> futureValidity;
  final Future<List<ContractData>> futureContractList;
  final Future<List<AdditiveData>> futureAdditiveList;

  const TimelineClass({
    super.key,
    required this.futureValidity,
    required this.futureContractList,
    required this.futureAdditiveList,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        futureValidity,
        futureContractList,
        futureAdditiveList,
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final validities = snapshot.data![0] as List<ValidityData>;
        final contracts = snapshot.data![1] as List<ContractData>;
        final additives = snapshot.data![2] as List<AdditiveData>;

        final timelineItems = _mapToTimelineItems(
          validities: validities,
          contracts: contracts,
          additives: additives,
        );

        if (timelineItems.isEmpty) return const SizedBox.shrink();

        return _buildTimeline(timelineItems);
      },
    );
  }

  List<TimelineItem> _mapToTimelineItems({
    required List<ValidityData> validities,
    required List<ContractData> contracts,
    required List<AdditiveData> additives,
  }) {
    final validityItems = validities.map((v) => TimelineItem(
      title: v.ordertype ?? 'ORDEM',
      date: v.orderdate,
      source: 'validity',
      original: v,
    ));

    final contractItems = contracts.map((c) => TimelineItem(
      title: 'PUBLICAÇÃO',
      date: c.publicationDateDoe,
      source: 'contract',
      original: c,
    ));


    final publicationDate = contracts.firstOrNull?.publicationDateDoe;
    final ordemInicio = validities.firstWhere(
          (v) => (v.ordertype?.toUpperCase() ?? '').contains('INÍCIO'),
      orElse: () => ValidityData(orderdate: null),
    ).orderdate;

    final totalDiasContrato = additives
        .where((a) => (a.additionalAdditiveContractDays ?? 0) > 0)
        .fold<int>(0, (sum, a) => sum + (a.additionalAdditiveContractDays ?? 0));

    final totalDiasExecucao = additives
        .where((a) => (a.additionalAdditiveExecutionDays ?? 0) > 0)
        .fold<int>(0, (sum, a) => sum + (a.additionalAdditiveExecutionDays ?? 0));

    final dataFinalContrato = (publicationDate != null && totalDiasContrato > 0)
        ? publicationDate.add(Duration(days: totalDiasContrato))
        : null;

    final dataFinalExecucao = (ordemInicio != null && totalDiasExecucao > 0)
        ? ordemInicio.add(Duration(days: totalDiasExecucao))
        : null;

    final prazoFinalItems = <TimelineItem>[];
    if (dataFinalContrato != null) {
      prazoFinalItems.add(TimelineItem(
        title: 'FINAL DO CONTRATO',
        date: dataFinalContrato,
        source: 'prazo',
      ));
    }

    if (dataFinalExecucao != null) {
      prazoFinalItems.add(TimelineItem(
        title: 'FINAL DA EXECUÇÃO',
        date: dataFinalExecucao,
        source: 'prazo',
      ));
    }

    return [
      ...validityItems,
      ...contractItems,
      ...prazoFinalItems,
    ]
      ..removeWhere((e) => e.date == null)
      ..sort((a, b) => a.date!.compareTo(b.date!));
  }

  Widget _buildTimeline(List<TimelineItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final (color, icon) = _getIconAndColor(item);
          final dateStr = convertDateTimeToDDMMYYYY(item.date!);

          return Row(
            children: [
              SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Tooltip(
                      message: item.title,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: color,
                        child: Icon(icon, size: 14, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Column(
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (item.source == 'prazo') ...[
                          item.date!.isAfter(DateTime.now())
                              ? Text(
                            'Faltam: ${item.date!.difference(DateTime.now()).inDays} dias',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.center,
                          )
                              : Text(
                            'Vencido: ${DateTime.now().difference(item.date!).inDays} dias',
                            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              if (index < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Container(
                    width: 40,
                    height: 2,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  (Color, IconData) _getIconAndColor(TimelineItem item) {
    switch (item.source) {
      case 'validity':
        final type = item.title.toUpperCase();
        if (type.contains('REINÍCIO')) return (Colors.blue, Icons.refresh);
        if (type.contains('INÍCIO')) return (Colors.green, Icons.play_arrow);
        if (type.contains('PARALIZA')) return (Colors.orange, Icons.pause);
        if (type.contains('FINALIZA')) return (Colors.green, Icons.check_circle);
        return (Colors.grey, Icons.description);
      case 'contract':
        return (Colors.black54, Icons.article);
      case 'prazo':
        return (Colors.black54, Icons.calendar_today);
      default:
        return (Colors.grey, Icons.help_outline);
    }
  }
}
