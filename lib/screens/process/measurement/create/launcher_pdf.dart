import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:printing/printing.dart' show PdfGoogleFonts;
import 'package:siged/_widgets/table/magic/magic_table_controller.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_data.dart';

Future<Uint8List> buildPdfBytes({
  required MagicTableController ctrl,
  required ContractData contractData,
  required ReportMeasurementData? measurement,
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
  const double kCellFontSize   = 7; // corpo

  final doc = pw.Document();

  // ===== Dados da tabela do controller =====
  final headers = List<String>.from(ctrl.headers);
  final data = List<List<String>>.from(
    ctrl.rowsWithoutHeader.map((r) => List<String>.from(r)),
  );

  // Alinhamento base por coluna (numéricos à direita por padrão)
  final alignFor = <int, pw.Alignment>{
    for (int i = 0; i < ctrl.colCount; i++)
      i: ctrl.isNumericEffective(i)
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft
  };

  // Helpers
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return out;
  }

  // ==== CONFIGURÁVEL: limites para caber em A4 paisagem ====
  const int maxColsPerPage = 14;
  const int rowsPerPage = 28;

  // ==== CONFIGURÁVEL: larguras por coluna global (0..N-1) ====
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

  // Heurística padrão quando a coluna NÃO está no mapa global:
  pw.TableColumnWidth _defaultWidthFor(int globalIndex) {
    if (globalIndex == 0) {
      return const pw.FlexColumnWidth(2);
    }
    if (ctrl.isNumericEffective(globalIndex)) {
      return const pw.FixedColumnWidth(56);
    }
    return const pw.FlexColumnWidth(1);
  }

  // Converte mapeamento GLOBAL (0..N-1) para o SUB-BLOCO (0..k-1)
  Map<int, pw.TableColumnWidth> _subColumnWidthsFromGlobal(
      List<int> colIdxs,
      Map<int, pw.TableColumnWidth> globalWidths,
      ) {
    final map = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < colIdxs.length; i++) {
      final gi = colIdxs[i]; // índice global da coluna
      map[i] = globalWidths[gi] ?? _defaultWidthFor(gi);
    }
    return map;
  }

  final allColIdx = List<int>.generate(headers.length, (i) => i);
  final colChunks = _chunk<int>(allColIdx, maxColsPerPage);

  // Larguras definidas pelo usuário (globais)
  final globalColumnWidths = _globalColumnWidths(headers);

  // Colunas (índices globais) que devem ter conteúdo CENTRALIZADO nas CÉLULAS
  const Set<int> _centerColsGlobal = {0, 2, 3, 4, 6, 7, 8, 9};

  // ===== Páginas =====
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),

      // Cabeçalho em TODAS as páginas
      header: (ctx) => _pdfHeader(
        contractData: contractData,
        measurement: measurement,
        emittedAt: DateTime.now(),
      ),

      // Rodapé com numeração
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
          final colIdxs = colChunks[blk]; // índices globais do bloco
          final subHeaders = [for (final c in colIdxs) headers[c]];

          // === Alinhamentos por coluna do SUB-BLOCO ===
          final subAligns = <int, pw.Alignment>{};
          for (int i = 0; i < colIdxs.length; i++) {
            final global = colIdxs[i];
            if (_centerColsGlobal.contains(global)) {
              subAligns[i] = pw.Alignment.center; // células centralizadas
            } else {
              subAligns[i] = alignFor[global] ?? pw.Alignment.centerLeft;
            }
          }

          // Larguras só para esse sub-bloco (0..k-1)
          final subColumnWidths =
          _subColumnWidthsFromGlobal(colIdxs, globalColumnWidths);

          if (colChunks.length > 1) {
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 4, top: 8),
                child: pw.Text(
                  'Seção ${blk + 1}/${colChunks.length}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            );
          }

          // Mapeia índices locais do sub-bloco para centralizar o CABEÇALHO também
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

                // === CENTRALIZAÇÃO DO CABEÇALHO (horizontal + vertical se houver altura) ===
                headerAlignment: pw.Alignment.center,
                headerAlignments: headerAlignments,

                // === LARGURAS MANUAIS POR COLUNA ===
                columnWidths: subColumnWidths,

                // === BORDAS E LINHAS VERTICAIS/HORIZONTAIS ===
                border: pw.TableBorder(
                  left: const pw.BorderSide(color: PdfColors.grey300, width: 0.25),
                  right: const pw.BorderSide(color: PdfColors.grey300, width: 0.25),
                  top: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  verticalInside:
                  const pw.BorderSide(color: PdfColors.grey400, width: 0.5), // linhas verticais
                  horizontalInside:
                  const pw.BorderSide(color: PdfColors.grey300, width: 0.3),
                ),

                // === TAMANHO DA FONTE (cabeçalho e células) ===
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: kHeaderFontSize,
                ),
                cellStyle: const pw.TextStyle().copyWith(fontSize: kCellFontSize),

                // padding (um pouco mais no header para "simular" altura e melhorar o centramento)
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),

                // === ALINHAMENTO POR COLUNA (células) ===
                cellAlignments: subAligns,

                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
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

/// ======== Cabeçalho PDF (repetido em todas as páginas) ========
pw.Widget _pdfHeader({
  required ContractData contractData,
  required ReportMeasurementData? measurement,
  required DateTime emittedAt,
}) {
  String dash(String? s) => (s == null || s.trim().isEmpty) ? '–' : s.trim();

  String money(num? v) {
    if (v == null) return '–';
    final n = v.toDouble();
    final s = n.toStringAsFixed(2).replaceAll('.', ',');
    final parts = s.split(',');
    final intPart =
    parts[0].replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'R\$ $intPart,${parts[1]}';
  }

  String dateStr(DateTime? d) {
    if (d == null) return '–';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  final obra = dash(contractData.summarySubjectContract ??
      contractData.contractObjectDescription);
  final local = dash(contractData.regionOfState);
  final construtora = dash(contractData.companyLeader);
  final contratoNum = dash(contractData.contractNumber);
  final valorContrato = money(contractData.initialValueContract ?? 0);
  final prazoExec =
      contractData.initialValidityExecutionDays?.toString() ?? '–';
  final assinatura = dateStr(contractData.publicationDateDoe);
  final ordemServ = '–';
  final aditPar = '–';
  final conclusao = '–';
  final saldoPrazo = '–';

  final medicaoNum = measurement?.order?.toString() ?? '–';
  final periodo = '–';
  final dataBoletim = dateStr(measurement?.date);
  final folhas = '–';

  pw.Widget cell(String label, String value, {bool right = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Align(
            alignment: right
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ),
      ],
    ),
  );

  pw.Widget box(List<pw.Widget> children) => pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey500, width: 0.6),
      borderRadius: pw.BorderRadius.circular(4),
      color: PdfColors.white,
    ),
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Column(children: children),
  );

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      // Título
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text('BOLETIM DE MEDIÇÃO',
              style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
      pw.SizedBox(height: 6),

      // 4 caixas
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
              cell('ADITIVOS E PARALISAÇÕES (dias):', aditPar, right: true),
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
//