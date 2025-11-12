import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/overlays/shimmer_w60_h14.dart';

class SummaryExpandableCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color colorIcon;

  /// Valores individuais (cada índice corresponde a um rótulo do breakdown).
  final List<double?> valoresIndividuais;

  /// Se informado, sobrepõe qualquer cálculo.
  final double? totalOverride;

  /// Alternativa assíncrona: quando quiser buscar só o total via Future.
  final Future<double?>? valorTotal;

  /// Força shimmer manual (ex: enquanto recalc no controller).
  final bool loading;

  /// true = moeda; false = número inteiro (bom para contagens).
  final bool formatAsCurrency;

  /// Rótulos dos itens do breakdown.
  final List<String>? subTitles;

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
    this.subTitles,
  });

  String _format(double? value) {
    final v = (value ?? 0);
    return formatAsCurrency ? priceToString(v) : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // largura responsiva dos cartões da grade
    final width = responsiveInputWidth(
      context: context,
      itemsPerLine: 6,
      margin: 12,
      spacing: 12,
      // se você aplicou meu patch do responsive_utils, dá pra por minItemWidth > 220
      // minItemWidth: 230,
    );

    final hasBreakdown = valoresIndividuais.isNotEmpty;

    Widget _totalText(double? v) => Text(
      _format(v),
      softWrap: false,
      overflow: TextOverflow.visible,
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
        0.0,
            (sum, v) => sum + (v ?? 0.0),
      );
      return _totalText(soma);
    }

    return SizedBox(
      width: width,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: icon != null ? Icon(icon, color: colorIcon) : null,
            trailing: hasBreakdown ? null : const SizedBox.shrink(),

            // ✅ Título robusto para iPad 12,9": até 2 linhas, sem estourar
            title: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  // deixa espaço para ícones/setas; evita overflow
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth - 40),
                  child: Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                );
              },
            ),

            // ✅ “Total: R$ …” sem quebrar layout; adapta no iPad grande
            subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  _totalWidget(),
                ],
              ),
            ),

            childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: hasBreakdown
                ? [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(valoresIndividuais.length, (i) {
                      final label = (subTitles != null && i < subTitles!.length)
                          ? subTitles![i]
                          : 'Valor ${i + 1}';
                      final valor = valoresIndividuais[i] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            // label do breakdown com quebra controlada
                            Expanded(
                              child: Text(
                                '$label:',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            loading
                                ? ShimmerW60H14()
                                : Text(
                              _format(valor),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ]
                : const <Widget>[],
          ),
        ),
      ),
    );
  }
}
