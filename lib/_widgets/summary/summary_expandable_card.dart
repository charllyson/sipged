import 'package:flutter/material.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/shimmer/shimmer_w60_h14.dart';

class SummaryExpandableCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color colorIcon;

  /// [valoresIndividuais] na ordem: [Inicial, Aditivo, Apostila]
  /// Pode ficar vazio quando você só quer mostrar o total.
  final List<double?> valoresIndividuais;

  /// Se informado, sobrepõe qualquer cálculo.
  final double? totalOverride;

  /// Alternativa assíncrona: quando quiser buscar só o total via Future.
  final Future<double?>? valorTotal;

  /// Força shimmer manual (ex: enquanto recalc no controller).
  final bool loading;

  /// true = moeda; false = número inteiro (bom para contagens).
  final bool formatAsCurrency;

  const SummaryExpandableCard({
    super.key,
    required this.title,
    this.icon,
    this.colorIcon = Colors.blueAccent,
    this.valoresIndividuais = const [],
    this.totalOverride,
    this.valorTotal,
    this.loading = false,
    this.formatAsCurrency = true,
  });

  String _format(double? value) {
    final v = (value ?? 0);
    return formatAsCurrency ? priceToString(v) : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final width = responsiveInputWidth(
      context: context,
      itemsPerLine: 6,
      margin: 12,
      spacing: 12,
    );

    final labels = const ['Inicial', 'Aditivo', 'Apostila'];
    final hasBreakdown = valoresIndividuais.isNotEmpty;

    Widget _totalText(double? v) => Text(
      _format(v),
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );

    Widget _totalWidget() {
      if (loading) return ShimmerW60H14();
      if (totalOverride != null) return _totalText(totalOverride);
      if (valorTotal != null) {
        return FutureBuilder<double?>(
          future: valorTotal,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ShimmerW60H14();
            }
            return _totalText(snap.data ?? 0);
          },
        );
      }
      // fallback: soma dos individuais
      final soma = valoresIndividuais.fold<double>(
        0.0, (sum, v) => sum + (v ?? 0.0),
      );
      return _totalText(soma);
    }

    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: icon != null ? Icon(icon, color: colorIcon) : null,
          trailing: hasBreakdown ? null : const SizedBox.shrink(), // some a setinha se não tiver filhos
          title: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Wrap(
            children: [
              const Text('Total:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              _totalWidget(),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
          children: hasBreakdown
              ? List.generate(valoresIndividuais.length, (i) {
            final label = i < labels.length ? labels[i] : 'Valor ${i + 1}';
            final valor = valoresIndividuais[i] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                children: [
                  Text('$label:', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const Spacer(),
                  loading ? ShimmerW60H14() : Text(
                    _format(valor),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          })
              : const <Widget>[],
        ),
      ),
    );
  }
}
