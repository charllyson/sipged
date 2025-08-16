import 'package:flutter/material.dart';
import 'package:sisged/_utils/date_utils.dart';

import '../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../_datas/documents/contracts/additive/additive_data.dart';
import '../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../_datas/documents/contracts/validity/validity_data.dart';

class TimelineItem {
  final String title;
  final DateTime? date;
  final String source;
  final dynamic original;
  final int? diasParalisados;

  TimelineItem({
    required this.title,
    required this.date,
    required this.source,
    this.original,
    this.diasParalisados,
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

        final contract = contracts.firstOrNull;
        if (contract == null) return const SizedBox.shrink();

        final bloc = ValidityBloc();

        return FutureBuilder(
          future: Future.wait([
            bloc.calcularDataFinalContrato(contract: contract),
            bloc.calcularDataFinalExecucao(contract: contract),
          ]),
          builder: (context, innerSnapshot) {
            if (!innerSnapshot.hasData) return const SizedBox.shrink();

            final dataFinalContrato = innerSnapshot.data![0];
            final dataFinalExecucao = innerSnapshot.data![1];

            final items = _gerarTimelineItems(
              contract: contract,
              additives: additives,
              validities: validities,
              dataFinalContrato: dataFinalContrato,
              dataFinalExecucao: dataFinalExecucao,
              bloc: bloc,
            );

            return _buildTimeline(items, contract);
          },
        );
      },
    );
  }

  List<TimelineItem> _gerarTimelineItems({
    required ContractData contract,
    required List<AdditiveData> additives,
    required List<ValidityData> validities,
    required DateTime? dataFinalContrato,
    required DateTime? dataFinalExecucao,
    required ValidityBloc bloc,
  }) {
    final List<TimelineItem> items = [];

    bloc.calcularDiasParalisados(validities);

    for (int i = 0; i < validities.length; i++) {
      final v = validities[i];
      int? diasParalisados;
      if ((v.ordertype?.toUpperCase() ?? '').contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        if ((anterior.ordertype?.toUpperCase() ?? '').contains('PARALISA') &&
            v.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados = v.orderdate!.difference(anterior.orderdate!).inDays;
        }
      }

      items.add(TimelineItem(
        title: v.ordertype ?? 'ORDEM',
        date: v.orderdate,
        source: 'validity',
        original: v,
        diasParalisados: diasParalisados,
      ));
    }

    if (contract.publicationDateDoe != null) {
      items.add(TimelineItem(
        title: 'PUBLICAÇÃO',
        date: contract.publicationDateDoe,
        source: 'mainInformation',
        original: contract,
      ));
    }

    for (final a in additives) {
      if (a.additiveDate != null &&
          ((a.additiveValidityContractDays ?? 0) > 0 || (a.additiveValidityExecutionDays ?? 0) > 0)) {
        items.add(TimelineItem(
          title: 'ASSINATURA ADITIVO DE PRAZO',
          date: a.additiveDate,
          source: 'assinatura_prazo',
          original: a,
        ));
      }
    }

    if (dataFinalContrato != null) {
      items.add(TimelineItem(
        title: 'FINAL DO CONTRATO',
        date: dataFinalContrato,
        source: 'prazo',
      ));
    }

    if (dataFinalExecucao != null) {
      items.add(TimelineItem(
        title: 'FINAL DA EXECUÇÃO',
        date: dataFinalExecucao,
        source: 'prazo',
      ));
    }

    return items
      ..removeWhere((e) => e.date == null)
      ..sort((a, b) => a.date!.compareTo(b.date!));
  }

  Widget _buildTimeline(List<TimelineItem> items, ContractData contract) {
    final contractStatus = contract.contractStatus?.toUpperCase() ?? '';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final (color, icon) = _getIconAndColor(item);
          final dateStr = convertDateTimeToDDMMYYYY(item.date!);

          return Row(
            children: [
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
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
                    Text(item.title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                    if (item.source == 'prazo') ...[
                      if (contractStatus == 'EM ANDAMENTO')
                        item.date!.isAfter(DateTime.now())
                            ? Text('Faltam: ${item.date!.difference(DateTime.now()).inDays} dias',
                            style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center)
                            : Text('Vencido: ${DateTime.now().difference(item.date!).inDays} dias',
                            style: const TextStyle(fontSize: 11, color: Colors.redAccent), textAlign: TextAlign.center)
                      else
                        Text(contractStatus,
                            style: const TextStyle(fontSize: 11, color: Colors.indigo), textAlign: TextAlign.center),
                    ],
                    // ... demais trechos
                  ],
                ),
              ),
              if (index < items.length - 1)
                Container(width: 40, height: 2, color: Colors.grey.shade400),
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
        if (type.contains('PARALISA')) return (Colors.orange, Icons.pause);
        if (type.contains('FINALIZA')) return (Colors.green, Icons.check_circle);
        return (Colors.grey, Icons.description);
      case 'mainInformation':
        return (Colors.black54, Icons.article);
      case 'assinatura_prazo':
        return (Colors.teal, Icons.edit_note);
      case 'prazo':
        return (Colors.black54, Icons.calendar_today);
      default:
        return (Colors.grey, Icons.help_outline);
    }
  }
}
