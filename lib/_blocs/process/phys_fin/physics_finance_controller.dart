// lib/screens/process/hiring/physical_financial/physics_finance_controller.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';
import 'package:siged/_widgets/schedule/physical_financial/percent_dialog.dart';

import '../../../_widgets/schedule/physical_financial/measure_text.dart';
import '../../../_widgets/schedule/physical_financial/physfin_models.dart';

class PhysicsFinanceController {
  /// Constrói a lista de dias a partir do contrato: múltiplos de 30 até o limite.
  static List<int> daysFromContract(ProcessData c) {
    final int maxDays = (c.initialValidityExecution ?? 0);
    if (maxDays <= 0) {
      // fallback: 12 períodos mensais (30 dias)
      return List<int>.generate(12, (i) => (i + 1) * 30);
    }
    final int n = (maxDays / 30).ceil();
    final List<int> base = List<int>.generate(n, (i) => (i + 1) * 30);
    if (base.last != maxDays) {
      // se não for múltiplo exato de 30, garante o último igual ao maxDays
      if (base.last > maxDays) {
        base[base.length - 1] = maxDays;
      } else {
        base.add(maxDays);
      }
    }
    return base;
  }

  static PhysFinTotals computeTotalsChrono({
    required List<PhysFinRow> rows,
    required int periods,
    required List<int?> termOrders, // ex.: [null, 1, 2, 3]
    required List<double> Function(String serviceKey, {int? termOrder}) getPercentFor,
  }) {
    final List<double> parciais = List<double>.filled(periods, 0.0);
    double totalGeral = 0.0;

    for (final r in rows) {
      totalGeral += r.valor; // total do serviço
      for (int j = 0; j < periods; j++) {
        double somaPct = 0.0;
        for (final ord in termOrders) {
          final percents = getPercentFor(r.key, termOrder: ord);
          final p = (j < percents.length) ? percents[j] : 0.0;
          somaPct += p;
        }
        parciais[j] += r.valor * (somaPct / 100.0);
      }
    }

    final List<double> acumulados = List<double>.filled(periods, 0.0);
    double acc = 0.0;
    for (int j = 0; j < periods; j++) {
      acc += parciais[j];
      acumulados[j] = acc;
    }

    return PhysFinTotals(
      parciais: parciais,
      acumulados: acumulados,
      totalGeral: totalGeral,
    );
  }

  /// Sincroniza o grid local com o state do Bloc.
  static void syncLocalGrid({
    required Map<String, List<double>> stateGrid,
    required List<dynamic> services, // state.services
    required int periods,
    required Map<String, List<double>> localGrid,
  }) {
    for (final s in services) {
      // tolerante a dynamic
      final String key = s.key as String;
      final List<double> saved = (stateGrid[key] ?? const <double>[])
          .map((e) => (e as num).toDouble())
          .toList();

      final List<double> normalized = (saved.length == periods)
          ? saved
          : (saved.length > periods
          ? saved.sublist(0, periods)
          : [...saved, ...List<double>.filled(periods - saved.length, 0.0)]);

      localGrid.putIfAbsent(key, () => List<double>.from(normalized));
    }
  }

  /// Monta as linhas da tabela a partir de services/totais/grid.
  static List<PhysFinRow> buildRows({
    required List<dynamic> services,
    required Map<String, double> serviceTotals,
    required Map<String, List<double>> localGrid,
    required int periods,
  }) {
    final List<PhysFinRow> rows = <PhysFinRow>[];
    for (int i = 0; i < services.length; i++) {
      final s = services[i];
      final String key = s.key as String;
      final String labelRaw = (s.label as String?) ?? '';
      final String label = labelRaw.isNotEmpty ? labelRaw : key;

      final double valor = (serviceTotals[key] ?? 0.0).toDouble();
      final List<double> percents =
      (localGrid[key] ?? List<double>.filled(periods, 0.0));

      rows.add(
        PhysFinRow(
          key: key,
          item: i + 1,
          descricao: label.toUpperCase(),
          valor: valor,
          percent: percents,
        ),
      );
    }
    return rows;
  }

  /// Calcula totais parciais e acumulados por período e o total geral.
  static PhysFinTotals computeTotals({
    required List<PhysFinRow> rows,
    required int periods,
  }) {
    final List<double> parciais = List<double>.filled(periods, 0.0);
    double totalGeral = 0.0;

    for (final r in rows) {
      totalGeral += r.valor;
      for (int j = 0; j < periods; j++) {
        final double p = (j < r.percent.length) ? r.percent[j] : 0.0;
        parciais[j] += r.valor * (p / 100.0);
      }
    }

    final List<double> acumulados = List<double>.filled(periods, 0.0);
    double acc = 0.0;
    for (int j = 0; j < periods; j++) {
      acc += parciais[j];
      acumulados[j] = acc;
    }

    return PhysFinTotals(
      parciais: parciais,
      acumulados: acumulados,
      totalGeral: totalGeral,
    );
  }

  /// Mede larguras dinâmicas de DESCRIÇÃO e VALOR com base no conteúdo.
  static PhysFinMeasured measureWidths({
    required BuildContext context,
    required List<PhysFinRow> rows,
    required double totalGeral,
  }) {
    final NumberFormat money = NumberFormat.simpleCurrency(locale: 'pt_BR');

    final double measuredValueColWidth = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: [
        ...rows.map((e) => money.format(e.valor)),
        money.format(totalGeral),
      ],
      style: const TextStyle(fontSize: 14),
      padding: 8 + 18, // left + right dentro da célula de valor
      safety: 14,
    );

    final double measuredDescWidth = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: rows.map((e) => e.descricao).toList(),
      style: const TextStyle(fontSize: 14),
      padding: 24,
      safety: 4,
    );

    final double descColWidth = math.min(400.0, measuredDescWidth);

    return PhysFinMeasured(
      descColWidth: descColWidth,
      valueColWidth: measuredValueColWidth,
    );
  }

  /// Resolve larguras das colunas e largura visual da barra de %.
  ///
  /// Use [extraColWidth] para reservar a coluna extra (ex.: "CRONOGRAMA").
  /// Deixe `null` para não incluir essa coluna.
  static PhysFinWidths resolveColumnWidths({
    required BuildContext context,
    required bool preferFit,
    required int nCols,
    required double viewportWidth,
    required double paddingsHorizontal,
    required double measuredDescWidth,
    required double measuredValueWidth,
    double? extraColWidth, // largura fixa da coluna extra (opcional)
  }) {
    const double kItemColWidth = 72.0;
    const double kPercentBarVisualWidth = 72.0;

    // dinheiro mais longo p/ estimar célula mínima
    final String longestMoney =
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(999999999.99);

    final double moneyCellNeeded = PhysFinMeasure.measureMaxTextWidth(
      context: context,
      strings: [longestMoney],
      style: const TextStyle(fontSize: 12),
      padding: 12.0,
      safety: 0.0,
    );

    final double minPercentColWidthDefault =
        math.max(72.0, moneyCellNeeded) + 16.0;

    // largura da coluna extra (se houver)
    final double extraW =
    (extraColWidth != null && extraColWidth > 0.0) ? extraColWidth : 0.0;

    double percentCol;
    double barVisual = kPercentBarVisualWidth;

    if (preferFit) {
      final double baseWidth = viewportWidth -
          (measuredDescWidth +
              extraW +
              kItemColWidth +
              measuredValueWidth +
              paddingsHorizontal);

      final double candidate = nCols == 0 ? 100.0 : baseWidth / nCols;
      percentCol = candidate.clamp(56.0, 220.0).toDouble();
      barVisual = math.min(kPercentBarVisualWidth, percentCol - 12.0);
    } else {
      percentCol = math.max(110.0, minPercentColWidthDefault);
      barVisual = kPercentBarVisualWidth;
    }

    return PhysFinWidths(
      itemCol: kItemColWidth,
      descCol: measuredDescWidth,
      extraCol: extraW > 0.0 ? extraW : null,
      percentCol: percentCol,
      valueCol: measuredValueWidth,
      barVisual: barVisual,
    );
  }

  /// Fachada do diálogo de %.
  static Future<double?> pickPercentDialog({
    required BuildContext context,
    required double current,
    required double alreadyAllocatedPercent,
    required double serviceTotalReais,
  }) {
    return showPhysFinPercentDialog(
      context: context,
      current: current,
      alreadyAllocatedPercent: alreadyAllocatedPercent,
      serviceTotalReais: serviceTotalReais,
    );
  }

  /// Notificação de sucesso padrão.
  static void toastSuccess({required String title, required String subtitle}) {
    NotificationCenter.instance.show(
      AppNotification(
        title: Text(title),
        subtitle: Text(subtitle),
        type: AppNotificationType.success,
      ),
    );
  }
}
