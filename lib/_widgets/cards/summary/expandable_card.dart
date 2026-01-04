import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/overlays/shimmer_w60_h14.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Color colorIcon;

  final List<double?> valoresIndividuais;
  final double? totalOverride;
  final Future<double?>? valorTotal;
  final bool loading;
  final bool formatAsCurrency;
  final List<String>? subTitles;

  const ExpandableCard({
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

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBreakdown = widget.valoresIndividuais.isNotEmpty;

    Widget _totalText(double? v) => Text(
      widget.formatAsCurrency ? priceToString(v ?? 0) : '${v ?? 0}',
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );

    Widget _totalWidget() {
      if (widget.loading) return const ShimmerW60H14();

      if (widget.totalOverride != null) {
        return _totalText(widget.totalOverride);
      }

      if (widget.valorTotal != null) {
        return FutureBuilder<double?>(
          future: widget.valorTotal,
          builder: (_, snap) {
            if (!snap.hasData) return const ShimmerW60H14();
            return _totalText(snap.data);
          },
        );
      }

      final soma = widget.valoresIndividuais.fold<double>(
        0,
            (acc, v) => acc + (v ?? 0),
      );

      return _totalText(soma);
    }

    return IntrinsicWidth(
      child: BasicCard(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 12,
        // width: null -> deixa encolher conforme conteúdo (mantém o comportamento anterior)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CABEÇALHO (seta sempre no fim) ===
            GestureDetector(
              onTap: hasBreakdown
                  ? () => setState(() => expanded = !expanded)
                  : null,
              child: Row(
                children: [
                  if (widget.icon != null)
                    Icon(widget.icon, color: widget.colorIcon),

                  if (widget.icon != null) const SizedBox(width: 8),

                  // ✅ TÍTULO ocupa o espaço e empurra a seta para o fim
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ✅ Seta alinhada ao fim do card
                  if (hasBreakdown)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: expanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // === TOTAL — 1 linha ===
            Row(

              children: [
                const Text("Total:", style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Flexible(child: _totalWidget()),
              ],
            ),

            // === CONTEÚDO EXPANSÍVEL ===
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildBreakdown(),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown() {
    return Column(
      children: List.generate(widget.valoresIndividuais.length, (i) {
        final label = widget.subTitles != null && i < widget.subTitles!.length
            ? widget.subTitles![i]
            : "Valor ${i + 1}";
        final valor = widget.valoresIndividuais[i] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "$label:",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
              Text(
                widget.formatAsCurrency ? priceToString(valor) : valor.toString(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        );
      }),
    );
  }
}
