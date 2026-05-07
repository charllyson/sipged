import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_executed_data.dart';
import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_utils/formatters/sipged_format_money.dart';
import 'package:sipged/screens/modules/contracts/measurement/create/info_grid.dart';
import 'package:sipged/screens/modules/contracts/measurement/create/label_value.dart';

class MeasurementReportHeader extends StatelessWidget {
  const MeasurementReportHeader({
    super.key,
    required this.contract,
    this.measurement,
    this.descricaoObjeto,
    this.numeroContrato,
    this.valorDemandaContrato,

    /// PublicacaoExtratoData.dataPublicacao
    this.dataPublicacao,

    /// TrData.prazoExecucaoDias
    this.prazoExecucaoDias,
  });

  final ProcessData contract;
  final ReportExecutedData? measurement;

  final String? descricaoObjeto;
  final String? numeroContrato;
  final num? valorDemandaContrato;

  final DateTime? dataPublicacao;
  final String? prazoExecucaoDias;

  String _dashIfEmpty(String? s) {
    final v = (s ?? '').trim();
    return v.isEmpty ? '–' : v;
  }

  String _money(num? v) {
    return v == null ? '–' : SipGedFormatMoney.doubleToText(v.toDouble());
  }

  String _date(DateTime? d) {
    return d == null ? '–' : SipGedFormatDates.dateToDdMMyyyy(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 900;

    final obra = _dashIfEmpty(descricaoObjeto);
    final local = _dashIfEmpty('');
    final construtora = _dashIfEmpty('');
    final contratoNum = _dashIfEmpty(numeroContrato);
    final valorContrato = _money(valorDemandaContrato);

    final prazoExecStr = _dashIfEmpty(prazoExecucaoDias);
    final assinatura = _date(dataPublicacao);

    final aditivosParalisacoesDias = '–';
    final ordemServico = '–';
    final conclusao = '–';
    final saldoPrazo = '–';

    final medicaoNumero = measurement?.order?.toString() ?? '–';
    final dataBoletim = _date(measurement?.date);
    final periodo = '–';
    final numFolhas = '–';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'BOLETIM DE MEDIÇÃO',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Flex(
            direction: isSmall ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isSmall ? 0 : 3,
                child: InfoGrid(
                  rows: [
                    _row('OBRA:', obra),
                    _row('LOCAL:', local),
                    _row('CONSTRUTORA:', construtora),
                    _row('CONTRATO Nº:', contratoNum),
                  ],
                ),
              ),
              if (!isSmall)
                const SizedBox(width: 8)
              else
                const SizedBox(height: 8),
              Expanded(
                flex: isSmall ? 0 : 2,
                child: InfoGrid(
                  rows: [
                    _row(
                      'VALOR DO CONTRATO:',
                      valorContrato,
                      alignRight: true,
                    ),
                    _row(
                      'ASSINATURA DO CONTRATO:',
                      assinatura,
                      alignRight: true,
                    ),
                    _row(
                      'ORDEM DE SERVIÇO:',
                      ordemServico,
                      alignRight: true,
                    ),
                    _row('', '', alignRight: true),
                  ],
                ),
              ),
              if (!isSmall)
                const SizedBox(width: 8)
              else
                const SizedBox(height: 8),
              Expanded(
                flex: isSmall ? 0 : 2,
                child: InfoGrid(
                  rows: [
                    _row(
                      'PRAZO DE EXECUÇÃO (dias):',
                      prazoExecStr,
                      alignRight: true,
                    ),
                    _row(
                      'ADITIVOS E PARALISAÇÕES (dias):',
                      aditivosParalisacoesDias,
                      alignRight: true,
                    ),
                    _row(
                      'DATA DE CONCLUSÃO:',
                      conclusao,
                      alignRight: true,
                    ),
                    _row(
                      'SALDO DE PRAZO:',
                      saldoPrazo,
                      alignRight: true,
                    ),
                  ],
                ),
              ),
              if (!isSmall)
                const SizedBox(width: 8)
              else
                const SizedBox(height: 8),
              Expanded(
                flex: isSmall ? 0 : 2,
                child: InfoGrid(
                  rows: [
                    _row('MEDIÇÃO Nº:', medicaoNumero),
                    _row('PERÍODO:', periodo),
                    _row('DATA DO BOLETIM:', dataBoletim),
                    _row(
                      'Nº DE FOLHAS:',
                      numFolhas,
                      alignRight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LabelValue _row(
      String label,
      String value, {
        bool alignRight = false,
      }) {
    return LabelValue(
      label: label,
      value: value,
      alignRight: alignRight,
    );
  }
}