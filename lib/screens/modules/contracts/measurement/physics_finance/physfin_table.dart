// lib/screens/modules/contracts/measurement/physics_finance/physfin_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/physics_finance/physics_finance_data.dart';

import 'percent_bar.dart';

class PhysFinTable extends StatelessWidget {
  final bool chronogramMode;
  final List<String> termLabels;
  final List<int?>? termOrders;
  final List<String?>? termSubLabels;

  final List<int> days;
  final List<PhysFinRow> rows;
  final PhysFinTotals totals;
  final PhysFinWidths widths;
  final NumberFormat money;

  final Map<String, List<double>> localGrid;
  final List<AdditivesData>? additives;

  final List<double> Function(String key, {int? termOrder})? getPercentFor;

  final Future<void> Function(
      String serviceKey,
      int colIndex,
      double current,
      double alreadyAllocated,
      double serviceTotal,
      ) onPickPercent;

  final Future<void> Function(
      String itemId,
      int colIndex,
      double current,
      double alreadyAllocated,
      double serviceTotal, {
      required int termOrder,
      })? onPickPercentForTerm;

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

  static const double _rowHeight = 56.0;
  static const double _subRowHeight = 52.0;

  List<int?> _resolveTermOrders() {
    if (!chronogramMode) return const <int?>[null];

    if (termOrders != null && termOrders!.length == termLabels.length) {
      return termOrders!;
    }

    return List<int?>.generate(
      termLabels.length,
          (index) => index == 0 ? null : index,
    );
  }

  ({Color fill, Color track, bool disabled}) _defaultColors({
    int? termOrder,
  }) {
    if (!chronogramMode) {
      return (
      fill: Colors.blue,
      track: const Color(0xFFE0E0E0),
      disabled: false,
      );
    }

    if (termOrder == null) {
      return (
      fill: const Color(0xFF9E9E9E),
      track: const Color(0xFFE0E0E0),
      disabled: true,
      );
    }

    return (
    fill: Colors.blue,
    track: const Color(0xFFE0E0E0),
    disabled: false,
    );
  }

  Widget _headerCell(
      String text,
      double width, {
        Color color = const Color(0xFFD1D5DB),
        Color textColor = Colors.black87,
      }) {
    return Container(
      width: width,
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
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
          color: textColor,
        ),
      ),
    );
  }

  Widget _gridCell({
    required double width,
    required double height,
    Widget? child,
    Alignment alignment = Alignment.centerLeft,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8),
    Color color = Colors.white,
  }) {
    return Container(
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
  }

  Widget _cronPill(
      String text, {
        bool disabled = false,
        String? sub,
      }) {
    final bool hasSub = sub != null && sub.trim().isNotEmpty;

    return Container(
      height: _subRowHeight - 10,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF3F4F6) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
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
            sub,
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

  List<double> _computePerPeriodTotalsForSource({
    required int nCols,
    required List<PhysFinRow> rows,
    required Map<String, List<double>> localGrid,
    required List<double> Function(String key, {int? termOrder})? getPercentFor,
    int? termOrder,
  }) {
    final List<double> output = List<double>.filled(nCols, 0.0);

    for (final row in rows) {
      final String lookupKey =
      termOrder == null ? row.key : row.item.toString();

      final List<double> percents = termOrder == null
          ? localGrid[lookupKey] ?? const <double>[]
          : getPercentFor?.call(lookupKey, termOrder: termOrder) ??
          const <double>[];

      for (int index = 0; index < nCols; index++) {
        final double percent =
        index < percents.length ? percents[index] : 0.0;

        output[index] += row.valor * (percent / 100.0);
      }
    }

    return output;
  }

  List<double> _cumulative(List<double> values) {
    double acc = 0.0;

    return <double>[
      for (final value in values) acc += value,
    ];
  }

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
    final double leftWidth = widths.itemCol +
        widths.descCol +
        (chronogramMode ? (widths.extraCol ?? 120) : 0);

    final leftCell = Container(
      width: leftWidth,
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

    final midCells = <Widget>[
      for (final value in cells)
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
            money.format(value),
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

    return Row(
      children: [
        leftCell,
        ...midCells,
        rightCell,
      ],
    );
  }

  Map<int, Color> _buildHeaderColorMap(
      List<int> days,
      List<AdditivesData>? adds,
      ) {
    final Map<int, Color> map = <int, Color>{};

    for (final day in days) {
      map[day] = const Color(0xFFD1D5DB);
    }

    if (adds == null || adds.isEmpty || days.isEmpty) {
      return map;
    }

    final orderedAdds = List<AdditivesData>.from(adds)
      ..sort(
            (a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0),
      );

    int paintedUntil = days
        .where((day) => day <= days.first + 359)
        .fold<int>(days.first, (previous, current) => current);

    for (final additive in orderedAdds) {
      final int order = additive.additiveOrder ?? 0;
      final int extraDays = additive.additiveValidityExecutionDays ?? 0;

      if (order <= 0 || extraDays <= 0) continue;

      final Color color =
      AdditivesData.colorForOrder(order).withValues(alpha: 0.25);

      final int start = paintedUntil + 1;
      final int end = paintedUntil + extraDays;

      for (final day in days) {
        if (day >= start && day <= end) {
          map[day] = color;
        }
      }

      paintedUntil = end;
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChrono = chronogramMode;
    final List<int?> resolvedOrders = _resolveTermOrders();
    final int subCount = hasChrono ? termLabels.length : 1;

    final Map<int, Color> headerColorMap = _buildHeaderColorMap(
      days,
      additives,
    );

    final Widget header = Row(
      children: [
        _headerCell('ITEM', widths.itemCol),
        _headerCell('DESCRIÇÃO', widths.descCol),
        if (hasChrono) _headerCell('CRONOGRAMA', widths.extraCol ?? 120),
        for (final day in days)
          _headerCell(
            '$day',
            widths.percentCol,
            color: headerColorMap[day] ?? const Color(0xFFD1D5DB),
            textColor: (headerColorMap[day]?.computeLuminance() ?? 1.0) < 0.5
                ? Colors.white
                : Colors.black87,
          ),
        _headerCell('VALOR (R\$)', widths.valueCol),
      ],
    );

    final Widget body = Column(
      children: rows.map((row) {
        final double verticalBlockHeight =
        hasChrono ? _subRowHeight * subCount : _rowHeight;

        final Widget itemCell = _gridCell(
          width: widths.itemCol,
          height: verticalBlockHeight,
          alignment: Alignment.center,
          child: Text(
            '${row.item}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );

        final Widget descCell = _gridCell(
          width: widths.descCol,
          height: verticalBlockHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            row.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        );

        final Widget? chronoCell = hasChrono
            ? _gridCell(
          width: widths.extraCol ?? 120,
          height: verticalBlockHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int index = 0; index < termLabels.length; index++)
                _cronPill(
                  termLabels[index],
                  disabled: resolvedOrders[index] == null,
                  sub: termSubLabels != null &&
                      index < termSubLabels!.length
                      ? termSubLabels![index]
                      : null,
                ),
            ],
          ),
        )
            : null;

        final List<Widget> periodCells = <Widget>[];

        for (int col = 0; col < days.length; col++) {
          final List<Widget> subRows = <Widget>[];

          if (!hasChrono) {
            final List<double> basePercents =
                localGrid[row.key] ?? const <double>[];

            final double current =
            col < basePercents.length ? basePercents[col] : 0.0;

            final double alreadyAllocated = basePercents.asMap().entries
                .where((entry) => entry.key != col)
                .fold<double>(0.0, (sum, entry) => sum + entry.value);

            final String currency = money.format(row.valor * (current / 100));

            final colors = (pickBarColors ?? _defaultColors)(termOrder: null);

            subRows.add(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhysFinPercentBar(
                    percent: current,
                    width: widths.barVisual,
                    height: 24,
                    fillColor: colors.fill,
                    trackColor: colors.track,
                    disabled: colors.disabled,
                    onTap: colors.disabled
                        ? null
                        : () => onPickPercent(
                      row.key,
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
              ),
            );
          } else {
            for (int index = 0; index < subCount; index++) {
              final int? termOrder = resolvedOrders[index];
              final String itemId = row.item.toString();
              final String lookupKey = termOrder == null ? row.key : itemId;

              final List<double> percents =
                  getPercentFor?.call(lookupKey, termOrder: termOrder) ??
                      const <double>[];

              final double current =
              col < percents.length ? percents[col] : 0.0;

              final double alreadyAllocated = percents.asMap().entries
                  .where((entry) => entry.key != col)
                  .fold<double>(0.0, (sum, entry) => sum + entry.value);

              final String currency = money.format(row.valor * (current / 100));

              final colors =
              (pickBarColors ?? _defaultColors)(termOrder: termOrder);

              final VoidCallback? onTap = colors.disabled
                  ? null
                  : () {
                if (termOrder == null || onPickPercentForTerm == null) {
                  onPickPercent(
                    row.key,
                    col,
                    current,
                    alreadyAllocated,
                    row.valor,
                  );
                  return;
                }

                onPickPercentForTerm!(
                  itemId,
                  col,
                  current,
                  alreadyAllocated,
                  row.valor,
                  termOrder: termOrder,
                );
              };

              subRows.add(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhysFinPercentBar(
                      percent: current,
                      width: widths.barVisual,
                      height: 24,
                      fillColor: colors.fill,
                      trackColor: colors.track,
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
                ),
              );
            }
          }

          periodCells.add(
            _gridCell(
              width: widths.percentCol,
              height: verticalBlockHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              child: Column(
                mainAxisAlignment:
                hasChrono ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
                children: subRows,
              ),
            ),
          );
        }

        final Widget valueCell = !hasChrono
            ? _gridCell(
          width: widths.valueCol,
          height: verticalBlockHeight,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 10),
          child: Text(
            money.format(row.valor),
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        )
            : _gridCell(
          width: widths.valueCol,
          height: verticalBlockHeight,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(
            right: 10,
            top: 8,
            bottom: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int index = 0; index < subCount; index++)
                Builder(
                  builder: (_) {
                    final int? termOrder = resolvedOrders[index];

                    final colors = (pickBarColors ?? _defaultColors)(
                      termOrder: termOrder,
                    );

                    return Opacity(
                      opacity: colors.disabled ? 0.65 : 1.0,
                      child: SizedBox(
                        height: _subRowHeight - 10,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            money.format(row.valor),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            itemCell,
            descCell,
            ?chronoCell,
            ...periodCells,
            valueCell,
          ],
        );
      }).toList(),
    );

    final int nCols = days.length;

    final List<double> contratadoParciais =
    _computePerPeriodTotalsForSource(
      nCols: nCols,
      rows: rows,
      localGrid: localGrid,
      getPercentFor: getPercentFor,
      termOrder: null,
    );

    final List<double> contratadoAcum = _cumulative(contratadoParciais);

    const Color mutedBg = Color(0xFFF5F6F7);
    const Color mutedText = Color(0xFF6B7280);

    final double totalContratado = contratadoParciais.fold<double>(
      0.0,
          (sum, value) => sum + value,
    );

    final Widget footerContratadoTotais = _footerRow(
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
      leftStripeColor: const Color(0xFFE5E7EB),
      labelFontSize: 12.5,
      valueFontSize: 12,
    );

    final Widget footerContratadoAcum = _footerRow(
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

    final List<Widget> termFooters = <Widget>[];

    if (chronogramMode && resolvedOrders.length > 1) {
      for (int index = 1; index < resolvedOrders.length; index++) {
        final int? order = resolvedOrders[index];

        if (order == null) continue;

        final List<double> termoParciais =
        _computePerPeriodTotalsForSource(
          nCols: nCols,
          rows: rows,
          localGrid: localGrid,
          getPercentFor: getPercentFor,
          termOrder: order,
        );

        final List<double> termoAcum = _cumulative(termoParciais);

        final double totalTermo = termoParciais.fold<double>(
          0.0,
              (sum, value) => sum + value,
        );

        final Color tone = AdditivesData.colorForOrder(order);
        final Color tinted = AdditivesData.tintForOrder(order);
        final Color tintedStrong = AdditivesData.strongTintForOrder(order);

        termFooters.addAll([
          _footerRow(
            label: 'Total $orderº termo',
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
            label: 'Acumulado $orderº termo',
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