import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:siged/_widgets/table/magic/magic_table_controller.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_data.dart';

Future<Uint8List> buildPdfBytes({
  required MagicTableController ctrl,
  required ProcessData contractData,
  required ReportMeasurementData? measurement,

  /// 🔹 Resumo da obra (DFD.descricaoObjeto)
  String? descricaoObjeto,

  /// 🔹 Número do contrato (PublicacaoExtratoData.numeroContrato)
  String? numeroContrato,

  /// 🔹 Valor do contrato (DFD.valorDemanda)
  num? valorDemandaContrato,
}) async {
  // === Fontes (Unicode) ===
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();
  final fontItalic = await PdfGoogleFonts.notoSansItalic();
  final fontMono = await PdfGoogleFonts.robotoMonoRegular();

  final theme = pw.ThemeData.withFont(
    base: fontRegular,
    bold: fontBold,
    italic: fontItalic,
    boldItalic: fontBold,
    icons: fontMono,
  );

  // >>> tamanhos de fonte fáceis de alterar
  const double kHeaderFontSize = 6; // cabeçalho
  const double kCellFontSize = 7; // corpo

  final doc = pw.Document();

  // ===== Dados da tabela do controller =====
  final headers = List<String>.from(ctrl.headers);
  final data = List<List<String>>.from(
    ctrl.rowsWithoutHeader.map((r) => List<String>.from(r)),
  );

  final alignFor = <int, pw.Alignment>{
    for (int i = 0; i < ctrl.colCount; i++)
      i: ctrl.isNumericEffective(i)
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft
  };

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      out.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return out;
  }

  const int maxColsPerPage = 14;
  const int rowsPerPage = 28;

  Map<int, pw.TableColumnWidth> _globalColumnWidths(List<String> headers) {
    return <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(30),
      1: const pw.FixedColumnWidth(200),
      2: const pw.FixedColumnWidth(30),
      3: const pw.FixedColumnWidth(50),
      4: const pw.FixedColumnWidth(64),
      5: const pw.FixedColumnWidth(64),
      6: const pw.FixedColumnWidth(64),
      7: const pw.FixedColumnWidth(64),
      8: const pw.FixedColumnWidth(64),
      9: const pw.FixedColumnWidth(64),
      10: const pw.FixedColumnWidth(64),
      11: const pw.FixedColumnWidth(64),
      12: const pw.FixedColumnWidth(64),
      13: const pw.FixedColumnWidth(64),
      14: const pw.FixedColumnWidth(100),
    };
  }

  pw.TableColumnWidth _defaultWidthFor(int globalIndex) {
    if (globalIndex == 0) {
      return const pw.FlexColumnWidth(2);
    }
    if (ctrl.isNumericEffective(globalIndex)) {
      return const pw.FixedColumnWidth(56);
    }
    return const pw.FlexColumnWidth(1);
  }

  Map<int, pw.TableColumnWidth> _subColumnWidthsFromGlobal(
      List<int> colIdxs,
      Map<int, pw.TableColumnWidth> globalWidths,
      ) {
    final map = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < colIdxs.length; i++) {
      final gi = colIdxs[i];
      map[i] = globalWidths[gi] ?? _defaultWidthFor(gi);
    }
    return map;
  }

  final allColIdx = List<int>.generate(headers.length, (i) => i);
  final colChunks = _chunk<int>(allColIdx, maxColsPerPage);
  final globalColumnWidths = _globalColumnWidths(headers);

  const Set<int> _centerColsGlobal = {0, 2, 3, 4, 6, 7, 8, 9};

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      header: (ctx) => _pdfHeader(
        contractData: contractData,
        measurement: measurement,
        emittedAt: DateTime.now(),

        /// 🔹 Campos novos pro cabeçalho
        descricaoObjeto: descricaoObjeto,
        numeroContrato: numeroContrato,
        valorDemandaContrato: valorDemandaContrato,
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página ${ctx.pageNumber} / ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (context) {
        final widgets = <pw.Widget>[];

        for (var blk = 0; blk < colChunks.length; blk++) {
          final colIdxs = colChunks[blk];
          final subHeaders = [for (final c in colIdxs) headers[c]];

          final subAligns = <int, pw.Alignment>{};
          for (int i = 0; i < colIdxs.length; i++) {
            final global = colIdxs[i];
            if (_centerColsGlobal.contains(global)) {
              subAligns[i] = pw.Alignment.center;
            } else {
              subAligns[i] = alignFor[global] ?? pw.Alignment.centerLeft;
            }
          }

          final subColumnWidths =
          _subColumnWidthsFromGlobal(colIdxs, globalColumnWidths);

          if (colChunks.length > 1) {
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 4, top: 8),
                child: pw.Text(
                  'Seção ${blk + 1}/${colChunks.length}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            );
          }

          final headerAlignments = <int, pw.Alignment>{
            for (int i = 0; i < colIdxs.length; i++) i: pw.Alignment.center
          };

          final rowChunks = _chunk<List<String>>(data, rowsPerPage);
          for (final rowsSlice in rowChunks) {
            final subData = <List<String>>[
              for (final r in rowsSlice)
                [for (final c in colIdxs) (c < r.length ? r[c] : '')]
            ];

            widgets.add(
              pw.Table.fromTextArray(
                headers: subHeaders,
                data: subData,
                tableWidth: pw.TableWidth.max,
                headerAlignment: pw.Alignment.center,
                headerAlignments: headerAlignments,
                columnWidths: subColumnWidths,
                border: pw.TableBorder(
                  left: const pw.BorderSide(
                      color: PdfColors.grey300, width: 0.25),
                  right: const pw.BorderSide(
                      color: PdfColors.grey300, width: 0.25),
                  top: const pw.BorderSide(
                      color: PdfColors.grey300, width: 0.5),
                  bottom: const pw.BorderSide(
                      color: PdfColors.grey300, width: 0.5),
                  verticalInside: const pw.BorderSide(
                      color: PdfColors.grey400, width: 0.5),
                  horizontalInside: const pw.BorderSide(
                      color: PdfColors.grey300, width: 0.3),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: kHeaderFontSize,
                ),
                cellStyle:
                const pw.TextStyle().copyWith(fontSize: kCellFontSize),
                headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blue800),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 2,
                ),
                cellAlignments: subAligns,
                oddRowDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
              ),
            );

            widgets.add(pw.SizedBox(height: 8));
          }
        }

        return widgets;
      },
    ),
  );

  return doc.save();
}

pw.Widget _pdfHeader({
  required ProcessData contractData,
  required ReportMeasurementData? measurement,
  required DateTime emittedAt,

  /// 🔹 Resumo da obra (DFD.descricaoObjeto)
  String? descricaoObjeto,

  /// 🔹 Número do contrato (PublicacaoExtratoData.numeroContrato)
  String? numeroContrato,

  /// 🔹 Valor do contrato (DFD.valorDemanda)
  num? valorDemandaContrato,
}) {
  String dash(String? s) =>
      (s == null || s.trim().isEmpty) ? '–' : s.trim();

  String money(num? v) {
    if (v == null) return '–';
    final n = v.toDouble();
    final s = n.toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
    return 'R\$ $intPart,${parts[1]}';
  }

  String dateStr(DateTime? d) {
    if (d == null) return '–';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  final local = dash('');        // ajuste quando tiver campo de local/município
  final construtora = dash('');  // ajuste quando tiver campo de empresa

  // 🔹 Agora NÃO usa mais contractData.contractNumber / summarySubject
  final contratoNum = dash(numeroContrato);
  final obra = dash(descricaoObjeto);

  // 🔹 Valor do contrato vem SOMENTE da demanda (DFD.valorDemanda)
  final valorContrato = money(valorDemandaContrato);

  final prazoExec =
      contractData.initialValidityExecution?.toString() ?? '–';
  final assinatura = dateStr(contractData.publicationDate);
  final ordemServ = '–';
  final aditPar = '–';
  final conclusao = '–';
  final saldoPrazo = '–';

  final medicaoNum = measurement?.order?.toString() ?? '–';
  final periodo = '–';
  final dataBoletim = dateStr(measurement?.date);
  final folhas = '–';

  pw.Widget cell(String label, String value, {bool right = false}) =>
      pw.Padding(
        padding:
        const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Align(
                alignment: right
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                child: pw.Text(
                  value,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ),
          ],
        ),
      );

  pw.Widget box(List<pw.Widget> children) => pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(
        color: PdfColors.grey500,
        width: 0.6,
      ),
      borderRadius: pw.BorderRadius.circular(4),
      color: PdfColors.white,
    ),
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Column(children: children),
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'BOLETIM DE MEDIÇÃO',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: box([
              cell('OBRA:', obra),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('LOCAL:', local),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('CONSTRUTORA:', construtora),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('CONTRATO Nº:', contratoNum),
            ]),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: box([
              cell('VALOR DO CONTRATO:', valorContrato, right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('ASSINATURA DO CONTRATO:', assinatura, right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('ORDEM DE SERVIÇO:', ordemServ, right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('', '-', right: true),
            ]),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: box([
              cell('PRAZO DE EXECUÇÃO (dias):', prazoExec, right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('ADITIVOS E PARALISAÇÕES (dias):', aditPar,
                  right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('DATA DE CONCLUSÃO:', conclusao, right: true),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('SALDO DE PRAZO:', saldoPrazo, right: true),
            ]),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: box([
              cell('MEDIÇÃO Nº:', medicaoNum),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('PERÍODO:', periodo),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('DATA DO BOLETIM:', dataBoletim),
              pw.Divider(color: PdfColors.grey400, height: 0.6),
              cell('Nº DE FOLHAS:', folhas, right: true),
            ]),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
    ],
  );
}
