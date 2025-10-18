// lib/screens/_pages/physical_financial/physfin_table.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_widgets/schedule/physical_financial/physfin_models.dart';

import 'percent_bar.dart';

class PhysFinTable extends StatelessWidget {
  final bool chronogramMode;
  final List<String> termLabels;
  final List<int?>? termOrders;

  /// Subtítulos por termo (ex.: "Valor", "Prazo", "Reequilíbrio").
  /// Deve ter o mesmo length de [termLabels]. Deixe null/'' para omitir.
  final List<String?>? termSubLabels;

  final List<int> days;
  final List<PhysFinRow> rows;

  /// Mantido apenas para outras métricas; os rodapés são re-calculados por fonte.
  final PhysFinTotals totals;

  final PhysFinWidths widths;
  final NumberFormat money;

  /// Grid base (Contratado) — por serviceKey.
  final Map<String, List<double>> localGrid;

  /// Lista real de aditivos — usada para colorir cabeçalho pelos dias aditivados.
  final List<AdditiveData>? additives;

  /// getPercentFor:
  ///   - termOrder == null  -> recebe **serviceKey** (contratado)
  ///   - termOrder != null  -> recebe **itemId** (string do número do item)
  final List<double> Function(String key, {int? termOrder})? getPercentFor;

  final Future<void> Function(
      String serviceKey,
      int colIndex,
      double current,
      double alreadyAllocated,
      double serviceTotal,
      ) onPickPercent;

  /// onPickPercentForTerm recebe **itemId** quando termOrder != null
  final Future<void> Function(
      String itemId,
      int colIndex,
      double current,
      double alreadyAllocated,
      double serviceTotal, {
      required int termOrder,
      })? onPickPercentForTerm;

  /// Função que devolve as cores das barras por termo.
  final ({Color fill, Color track, bool disabled}) Function({int? termOrder})?
  pickBarColors;

  const PhysFinTable({
    super.key,
    required this.chronogramMode,
    required this.termLabels,
    this.termOrders,
    this.termSubLabels,
    required this.days,
    required this.rows,
    required this.totals,
    required this.widths,
    required this.money,
    required this.localGrid,
    this.additives,
    this.getPercentFor,
    required this.onPickPercent,
    this.onPickPercentForTerm,
    this.pickBarColors,
  });

  // ======== Layout consts
  static const double _rowHeight = 56.0;
  static const double _subRowHeight = 52.0;

  // ======== Helpers

  List<int?> _resolveTermOrders() {
    if (!chronogramMode) return const <int?>[null];
    if (termOrders != null && termOrders!.length == termLabels.length) {
      return termOrders!;
    }
    final out = <int?>[];
    for (int i = 0; i < termLabels.length; i++) {
      out.add(i == 0 ? null : i);
    }
    return out;
  }

  ({Color fill, Color track, bool disabled}) _defaultColors({int? termOrder}) {
    if (!chronogramMode) {
      return (
      fill: Colors.blue,
      track: const Color(0xFFE0E0E0),
      disabled: false,
      );
    }
    if (termOrder == null) {
      // contratado bloqueado na seção de aditivos
      return (
      fill: const Color(0xFF9E9E9E),
      track: const Color(0xFFE0E0E0),
      disabled: true,
      );
    }
    return (fill: Colors.blue, track: const Color(0xFFE0E0E0), disabled: false);
  }

  Widget _headerCell(
      String text,
      double w, {
        Color color = const Color(0xFFD1D5DB),
        Color textColor = Colors.black87,
      }) =>
      Container(
        width: w,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: const Border(
            right: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
            color: textColor,
          ),
        ),
      );

  Widget _gridCell({
    required double width,
    required double height,
    Widget? child,
    Alignment alignment = Alignment.centerLeft,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
    Color color = Colors.white,
  }) =>
      Container(
        width: width,
        height: height,
        alignment: alignment,
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: const Border(
            right: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: child,
      );

  Widget _cronPill(String text, {bool disabled = false, String? sub}) {
    final hasSub = (sub != null && sub.trim().isNotEmpty);
    return Container(
      height: _subRowHeight - 10,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF3F4F6) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: hasSub
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: disabled ? Colors.black38 : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.0,
              fontWeight: FontWeight.w500,
              color: disabled ? Colors.black45 : Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      )
          : Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: disabled ? Colors.black38 : Colors.black87,
        ),
      ),
    );
  }

  /// Somatório por período PARA UMA FONTE específica:
  /// - termOrder == null  -> Contratado (usa localGrid/ serviceKey)
  /// - termOrder != null  -> Termo N (usa getPercentFor(itemId, termOrder:N))
  List<double> _computePerPeriodTotalsForSource({
    required int nCols,
    required List<PhysFinRow> rows,
    required Map<String, List<double>> localGrid, // contratado
    required List<double> Function(String key, {int? termOrder})? getPercentFor,
    int? termOrder, // null => contratado
  }) {
    final out = List<double>.filled(nCols, 0.0);
    if (rows.isEmpty) return out;

    for (final r in rows) {
      if (termOrder == null) {
        // CONTRATADO: chave = serviceKey (r.key)
        final perc = localGrid[r.key] ?? const <double>[];
        for (int j = 0; j < nCols; j++) {
          final p = j < perc.length ? perc[j] : 0.0;
          out[j] += r.valor * (p / 100.0);
        }
      } else {
        // TERMO: chave = itemId
        if (getPercentFor == null) continue;
        final itemId = r.item.toString();
        final perc = getPercentFor(itemId, termOrder: termOrder);
        for (int j = 0; j < nCols; j++) {
          final p = j < perc.length ? perc[j] : 0.0;
          out[j] += r.valor * (p / 100.0);
        }
      }
    }

    return out;
  }

  List<double> _cumulative(List<double> v) {
    double run = 0.0;
    return [for (final x in v) (run += x)];
  }

  // ---------- Footer UI helpers (estilização)
  Widget _footerRow({
    required String label,
    required List<double> cells,
    required double totalRight,
    required PhysFinWidths widths,
    required NumberFormat money,
    required Color bg,
    required Color textColor,
    double height = 48,
    FontWeight labelWeight = FontWeight.w700,
    bool topSeparator = false,
    Color? leftStripeColor,
    double? labelFontSize,
    double valueFontSize = 12.5,
  }) {
    final leftCell = Container(
      width: widths.itemCol +
          widths.descCol +
          (chronogramMode ? (widths.extraCol ?? 120) : 0),
      height: height,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: const BorderSide(color: Color(0xFFE5E7EB)),
          bottom: const BorderSide(color: Color(0xFFE5E7EB)),
          top: topSeparator
              ? const BorderSide(color: Color(0xFFE5E7EB), width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          if (leftStripeColor != null)
            Container(
              width: 6,
              height: height - 12,
              decoration: BoxDecoration(
                color: leftStripeColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          if (leftStripeColor != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: labelWeight,
                fontSize: labelFontSize ?? 13,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final midCells = [
      for (final v in cells)
        Container(
          width: widths.percentCol,
          height: height,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: bg,
            border: const Border(
              right: BorderSide(color: Color(0xFFE5E7EB)),
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(
            money.format(v),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: valueFontSize,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];

    final rightCell = Container(
      width: widths.valueCol,
      height: height,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          right: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Text(
        money.format(totalRight),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: valueFontSize + 0.5,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Row(children: [leftCell, ...midCells, rightCell]);
  }

  // ============================================================
  // 🎨 Cores do cabeçalho (por período), respeitando additiveValidityExecutionDays
  // ============================================================
  Map<int, Color> _buildHeaderColorMap(List<int> days, List<AdditiveData>? adds) {
    final Map<int, Color> map = {};
    // base neutra
    for (final d in days) {
      map[d] = const Color(0xFFD1D5DB);
    }
    if (adds == null || adds.isEmpty) return map;

    final orderedAdds = List<AdditiveData>.from(adds)
      ..sort((a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0));

    // Considera que o contrato base foi planejado até o último 'day' da base
    // e que os aditivos de execução expandem a partir daí em sequência.
    // Para garantir previsibilidade, assume-se que a base é até o maior 'day'
    // NÃO colorido ainda; depois os aditivos empilham.
    int paintedUntil = days.isNotEmpty ? days.first : 0;

    // Primeiro, identifica o que já é "base" (sem cor de aditivo)
    // Vamos considerar a base como o menor segmento contínuo a partir do início.
    // O restante poderá ser colorido por aditivos.
    // Caso prefira fixar 360 como base, troque paintedUntil = 360;
    paintedUntil = (days.isNotEmpty ? days.where((d) => d <= (days.first + 359)).fold(days.first, (a, b) => b) : 0);

    for (final add in orderedAdds) {
      final ord = add.additiveOrder ?? 0;
      final extraDays = add.additiveValidityExecutionDays ?? 0;
      if (ord <= 0 || extraDays <= 0) continue;

      final color = AdditiveData.colorForOrder(ord).withOpacity(0.25);

      final start = paintedUntil + 1;
      final end = paintedUntil + extraDays;

      for (final d in days) {
        if (d >= start && d <= end) {
          map[d] = color;
        }
      }
      paintedUntil = end;
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final hasChrono = chronogramMode;
    final resolvedOrders = _resolveTermOrders(); // [null, 1, 2, ...]
    final subCount = hasChrono ? termLabels.length : 1;

    // Cabeçalho colorido por aditivos (somente aditivos marcam cores extras)
    final headerColorMap = _buildHeaderColorMap(days, additives);

    // HEADER
    final header = Row(
      children: [
        _headerCell('ITEM', widths.itemCol),
        _headerCell('DESCRIÇÃO', widths.descCol),
        if (hasChrono) _headerCell('CRONOGRAMA', widths.extraCol ?? 120),
        for (final d in days)
          _headerCell(
            '$d',
            widths.percentCol,
            color: headerColorMap[d] ?? const Color(0xFFD1D5DB),
            textColor: (headerColorMap[d]?.computeLuminance() ?? 1.0) < 0.5
                ? Colors.white
                : Colors.black87,
          ),
        _headerCell('VALOR (R\$)', widths.valueCol),
      ],
    );

    // BODY
    final body = Column(
      children: rows.map((row) {
        final verticalBlockHeight =
        hasChrono ? _subRowHeight * subCount : _rowHeight;

        final itemCell = _gridCell(
          width: widths.itemCol,
          height: verticalBlockHeight,
          alignment: Alignment.center,
          child: Text(
            '${row.item}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        );

        final descCell = _gridCell(
          width: widths.descCol,
          height: verticalBlockHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            row.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
            const TextStyle(fontWeight: FontWeight.w600, letterSpacing: .2),
          ),
        );

        Widget? chronoCell;
        if (hasChrono) {
          chronoCell = _gridCell(
            width: widths.extraCol ?? 120,
            height: verticalBlockHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < termLabels.length; i++)
                  _cronPill(
                    termLabels[i],
                    disabled: resolvedOrders[i] == null,
                    sub: (termSubLabels != null && i < termSubLabels!.length)
                        ? termSubLabels![i]
                        : null,
                  ),
              ],
            ),
          );
        }

        final periodCells = <Widget>[];
        for (int col = 0; col < days.length; col++) {
          List<Widget> subRows;

          if (!hasChrono) {
            // CONTRATADO — seção "Licitação": editável (se você usar esse componente lá)
            final basePercents = localGrid[row.key] ?? const <double>[];
            final current = col < basePercents.length ? basePercents[col] : 0.0;
            final alreadyAllocated = basePercents.asMap().entries
                .where((e) => e.key != col)
                .fold<double>(0.0, (s, e) => s + (e.value));

            final currency = money.format(row.valor * (current / 100.0));
            final colors = (pickBarColors ?? _defaultColors)(termOrder: null);

            subRows = [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhysFinPercentBar(
                    percent: current,
                    width: widths.barVisual,
                    height: 24,
                    fillColor: colors.fill,
                    disabled: colors.disabled,
                    onTap: () => onPickPercent(
                      row.key, // contratado usa serviceKey
                      col,
                      current,
                      alreadyAllocated,
                      row.valor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: widths.percentCol,
                    child: Text(
                      currency,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            ];
          } else {
            // CRONOGRAMA — usa **ITEM** como chave para termos; serviceKey para contratado
            subRows = [
              for (int i = 0; i < subCount; i++)
                Builder(
                  builder: (_) {
                    final termOrder = resolvedOrders[i];
                    final itemId = row.item.toString();

                    final keyForGet = (termOrder == null) ? row.key : itemId;

                    final percents = (getPercentFor != null)
                        ? getPercentFor!(keyForGet, termOrder: termOrder)
                        : const <double>[];

                    final current = col < percents.length ? percents[col] : 0.0;

                    final alreadyAllocated = percents.asMap().entries
                        .where((e) => e.key != col)
                        .fold<double>(0.0, (s, e) => s + (e.value));

                    final currency =
                    money.format(row.valor * (current / 100.0));
                    final colors =
                    (pickBarColors ?? _defaultColors)(termOrder: termOrder);

                    final onTap = colors.disabled
                        ? null
                        : () {
                      if (termOrder == null ||
                          onPickPercentForTerm == null) {
                        return onPickPercent(
                          row.key, // contratado usa serviceKey
                          col,
                          current,
                          alreadyAllocated,
                          row.valor,
                        );
                      }
                      return onPickPercentForTerm!(
                        itemId, // ITEM como chave para os termos
                        col,
                        current,
                        alreadyAllocated,
                        row.valor,
                        termOrder: termOrder,
                      );
                    };

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhysFinPercentBar(
                          percent: current,
                          width: widths.barVisual,
                          height: 24,
                          fillColor: colors.fill,
                          disabled: colors.disabled,
                          onTap: onTap,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: widths.percentCol,
                          child: Text(
                            currency,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ];
          }

          periodCells.add(
            _gridCell(
              width: widths.percentCol,
              height: verticalBlockHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                mainAxisAlignment:
                hasChrono ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
                children: subRows,
              ),
            ),
          );
        }

        // COLUNA VALOR
        Widget valueCell;
        if (!hasChrono) {
          valueCell = _gridCell(
            width: widths.valueCol,
            height: verticalBlockHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              money.format(row.valor),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        } else {
          final subRowsValues = <Widget>[];
          for (int i = 0; i < subCount; i++) {
            final termOrder = resolvedOrders[i];
            final colors =
            (pickBarColors ?? _defaultColors)(termOrder: termOrder);

            subRowsValues.add(
              Opacity(
                opacity: colors.disabled ? 0.65 : 1.0,
                child: SizedBox(
                  height: _subRowHeight - 10,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      money.format(row.valor), // repete valor base
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            );
          }

          valueCell = _gridCell(
            width: widths.valueCol,
            height: verticalBlockHeight,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: subRowsValues,
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            itemCell,
            descCell,
            if (chronoCell != null) chronoCell,
            ...periodCells,
            valueCell,
          ],
        );
      }).toList(),
    );

    // ===================== FOOTERS (por fonte) ===============================

    final nCols = days.length;

    // 1) CONTRATADO (visual bloqueado/menos poluído na aba aditivos)
    final contratadoParciais = _computePerPeriodTotalsForSource(
      nCols: nCols,
      rows: rows,
      localGrid: localGrid,
      getPercentFor: getPercentFor,
      termOrder: null,
    );
    final contratadoAcum = _cumulative(contratadoParciais);

    const mutedBg = Color(0xFFF5F6F7); // cinza muito claro
    const mutedText = Color(0xFF6B7280); // slate-500
    final totalContratado =
    contratadoParciais.fold<double>(0.0, (a, b) => a + b);

    final footerContratadoTotais = _footerRow(
      label: 'Total contratado',
      cells: contratadoParciais,
      totalRight: totalContratado,
      widths: widths,
      money: money,
      bg: mutedBg,
      textColor: mutedText,
      height: 48,
      labelWeight: FontWeight.w700,
      topSeparator: true,
      // stripe apagada para indicar "bloqueado"
      leftStripeColor: const Color(0xFFE5E7EB),
      labelFontSize: 12.5,
      valueFontSize: 12,
    );

    final footerContratadoAcum = _footerRow(
      label: 'Acumulado contratado',
      cells: contratadoAcum,
      totalRight: contratadoAcum.isEmpty ? 0.0 : contratadoAcum.last,
      widths: widths,
      money: money,
      bg: const Color(0xFFF0F2F4),
      textColor: mutedText,
      height: 44,
      labelWeight: FontWeight.w600,
      leftStripeColor: const Color(0xFFE5E7EB),
      labelFontSize: 12.5,
      valueFontSize: 12,
    );

    // 2) TERMOS — cada um com leve “tinta” da sua cor
    final termFooters = <Widget>[];
    if (chronogramMode && resolvedOrders.length > 1) {
      for (int i = 1; i < resolvedOrders.length; i++) {
        final ord = resolvedOrders[i]; // 1,2,3...
        if (ord == null) continue;

        final termoParciais = _computePerPeriodTotalsForSource(
          nCols: nCols,
          rows: rows,
          localGrid: localGrid,
          getPercentFor: getPercentFor,
          termOrder: ord,
        );
        final termoAcum = _cumulative(termoParciais);
        final totalTermo =
        termoParciais.fold<double>(0.0, (a, b) => a + b);

        final tone = AdditiveData.colorForOrder(ord);
        final tinted = AdditiveData.tintForOrder(ord);
        final tintedStrong = AdditiveData.strongTintForOrder(ord);

        termFooters.addAll([
          _footerRow(
            label: 'Total ${ord}º termo',
            cells: termoParciais,
            totalRight: totalTermo,
            widths: widths,
            money: money,
            bg: tinted,
            textColor: const Color(0xFF111827),
            height: 48,
            labelWeight: FontWeight.w800,
            topSeparator: true,
            leftStripeColor: tone,
            labelFontSize: 13,
            valueFontSize: 12.5,
          ),
          _footerRow(
            label: 'Acumulado ${ord}º termo',
            cells: termoAcum,
            totalRight: termoAcum.isEmpty ? 0.0 : termoAcum.last,
            widths: widths,
            money: money,
            bg: tintedStrong,
            textColor: const Color(0xFF111827),
            height: 44,
            labelWeight: FontWeight.w700,
            leftStripeColor: tone,
            labelFontSize: 12.5,
            valueFontSize: 12.5,
          ),
        ]);
      }
    }

    return Column(
      children: [
        header,
        body,
        footerContratadoTotais,
        footerContratadoAcum,
        ...termFooters,
      ],
    );
  }
}
