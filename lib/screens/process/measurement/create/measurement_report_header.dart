import 'package:flutter/material.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_utils/formats/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/screens/process/measurement/create/create_detailed_reports_page.dart';
import 'package:siged/screens/process/measurement/create/info_grid.dart';
import 'package:siged/screens/process/measurement/create/label_value.dart';

/// =================== Cabeçalho – Boletim de Medição ===================
class MeasurementReportHeader extends StatelessWidget {
  const MeasurementReportHeader({
    super.key,
    required this.contract,
    this.measurement,

    /// 🔹 Resumo da obra (DFD.descricaoObjeto)
    this.descricaoObjeto,

    /// 🔹 Número do contrato (PublicacaoExtratoData.numeroContrato)
    this.numeroContrato,
  });

  final ProcessData contract;
  final ReportMeasurementData? measurement;

  /// 🔹 Campo vindo de DfdData.descricaoObjeto
  final String? descricaoObjeto;

  /// 🔹 Campo vindo de PublicacaoExtratoData.numeroContrato
  final String? numeroContrato;

  String _dashIfEmpty(String? s) {
    final v = (s ?? '').trim();
    return v.isEmpty ? '–' : v;
  }

  String _money(num? v) => v == null ? '–' : priceToString(v.toDouble());
  String _date(DateTime? d) => d == null ? '–' : dateTimeToDDMMYYYY(d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 900;

    // ==== Mapeamento para os campos ====
    // 🔹 OBRA agora vem somente da descricaoObjeto (DFD)
    final obra = _dashIfEmpty(descricaoObjeto);

    // 🔹 LOCAL / CONSTRUTORA ficam em branco até termos fonte correta
    final local = _dashIfEmpty('' /* ex.: region / município, quando existir */);
    final construtora =
    _dashIfEmpty('' /* ex.: companyLeader, quando existir no novo modelo */);

    // 🔹 CONTRATO Nº vem da PublicacaoExtratoData.numeroContrato
    final contratoNum = _dashIfEmpty(numeroContrato);

    final valorContrato = _money(contract.initialValueContract ?? 0);

    final prazoExecStr = (contract.initialValidityExecution == null)
        ? '–'
        : '${contract.initialValidityExecution}';

    final assinatura = _date(
      contract.publicationDate,
    ); // data pública mais próxima que temos
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
          // Título
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

          // Blocos
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
                    _row('VALOR DO CONTRATO:', valorContrato,
                        alignRight: true),
                    _row('ASSINATURA DO CONTRATO:', assinatura,
                        alignRight: true),
                    _row('ORDEM DE SERVIÇO:', ordemServico,
                        alignRight: true),
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
                    _row('PRAZO DE EXECUÇÃO (dias):', prazoExecStr,
                        alignRight: true),
                    _row('ADITIVOS E PARALISAÇÕES (dias):',
                        aditivosParalisacoesDias,
                        alignRight: true),
                    _row('DATA DE CONCLUSÃO:', conclusao,
                        alignRight: true),
                    _row('SALDO DE PRAZO:', saldoPrazo,
                        alignRight: true),
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
                    _row('Nº DE FOLHAS:', numFolhas,
                        alignRight: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LabelValue _row(String label, String value, {bool alignRight = false}) =>
      LabelValue(label: label, value: value, alignRight: alignRight);
}
