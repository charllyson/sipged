import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:siged/_utils/converters/converters_utils.dart';

import 'package:siged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:siged/_widgets/timeline/time_line_item.dart';
import 'package:siged/_widgets/timeline/timeline_shimmer.dart';

class TimelineClass extends StatelessWidget {
  /// Status do DFD do contrato exibido (ex.: "EM ANDAMENTO", "A INICIAR"...)
  final String? dfdStatus;

  /// Altura fixa da timeline (shimmer + conteúdo real)
  static const double _timelineHeight = 90;

  const TimelineClass({
    super.key,
    this.dfdStatus,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValidityCubit, ValidityState>(

      builder: (context, state) {
        final contract = state.contract;
        final validities = state.validities;
        final additives = state.additives;

        if (contract == null || validities.isEmpty) {
          return const TimelineShimmer(
            height: _timelineHeight,
            itemCount: 4,
          );
        }

        final cubit = context.read<ValidityCubit>();
        final DateTime? dataFinalContrato = cubit.dataFinalContrato;
        final DateTime? dataFinalExecucao = cubit.dataFinalExecucao;

        final items = _gerarTimelineItems(
          contract: contract,
          additives: additives,
          validities: validities,
          dataFinalContrato: dataFinalContrato,
          dataFinalExecucao: dataFinalExecucao,
        );

        return _buildTimeline(items, dfdStatus?.toUpperCase().trim());
      },
    );
  }

  List<TimelineItem> _gerarTimelineItems({
    required ProcessData contract,
    required List<AdditivesData> additives,
    required List<ValidityData> validities,
    required DateTime? dataFinalContrato,
    required DateTime? dataFinalExecucao,
  }) {
    final List<TimelineItem> items = [];

    for (int i = 0; i < validities.length; i++) {
      final v = validities[i];
      int? diasParalisados;

      if ((v.ordertype?.toUpperCase() ?? '').contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        if ((anterior.ordertype?.toUpperCase() ?? '').contains('PARALISA') &&
            v.orderdate != null &&
            anterior.orderdate != null) {
          diasParalisados =
              v.orderdate!.difference(anterior.orderdate!).inDays;
        }
      }

      items.add(
        TimelineItem(
          title: v.ordertype ?? 'ORDEM',
          date: v.orderdate,
          source: 'validity',
          original: v,
          diasParalisados: diasParalisados,
        ),
      );
    }

    if (contract.publicationDate != null) {
      items.add(
        TimelineItem(
          title: 'PUBLICAÇÃO',
          date: contract.publicationDate,
          source: '0.resume',
          original: contract,
        ),
      );
    }

    for (final a in additives) {
      if (a.additiveDate != null &&
          ((a.additiveValidityContractDays ?? 0) > 0 ||
              (a.additiveValidityExecutionDays ?? 0) > 0)) {
        items.add(
          TimelineItem(
            title: 'ASSINATURA ADITIVO DE PRAZO',
            date: a.additiveDate,
            source: 'assinatura_prazo',
            original: a,
          ),
        );
      }
    }

    if (dataFinalContrato != null) {
      items.add(
        TimelineItem(
          title: 'FINAL DO CONTRATO',
          date: dataFinalContrato,
          source: 'prazo',
        ),
      );
    }

    if (dataFinalExecucao != null) {
      items.add(
        TimelineItem(
          title: 'FINAL DA EXECUÇÃO',
          date: dataFinalExecucao,
          source: 'prazo',
        ),
      );
    }

    return items
      ..removeWhere((e) => e.date == null)
      ..sort((a, b) => a.date!.compareTo(b.date!));
  }

  Widget _buildTimeline(List<TimelineItem> items, String? dfdStatusUp) {
    final status = dfdStatusUp ?? '';
    return Center(
      child: SizedBox(
        height: _timelineHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final (color, icon) = _getIconAndColor(item);
              final dateStr = dateTimeToDDMMYYYY(item.date!);

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
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (item.source == 'prazo') ...[
                          if (status == 'EM ANDAMENTO')
                            item.date!.isAfter(DateTime.now())
                                ? Text(
                              'Faltam: ${item.date!.difference(DateTime.now()).inDays} dias',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            )
                                : Text(
                              'Vencido: ${DateTime.now().difference(item.date!).inDays} dias',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else if (status.isNotEmpty)
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.indigo,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    Container(
                      width: 40,
                      height: 2,
                      color: Colors.grey.shade400,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  (Color, IconData) _getIconAndColor(TimelineItem item) {
    switch (item.source) {
      case 'validity':
        final type = item.title.toUpperCase();
        if (type.contains('REINÍCIO')) {
          return (Colors.blue, Icons.refresh);
        }
        if (type.contains('INÍCIO')) {
          return (Colors.green, Icons.play_arrow);
        }
        if (type.contains('PARALISA')) {
          return (Colors.orange, Icons.pause);
        }
        if (type.contains('FINALIZA')) {
          return (Colors.green, Icons.check_circle);
        }
        return (Colors.grey, Icons.description);

      case '0.resume':
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
