import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';

class FaixaRodovia {
  final String label;
  final Color cor;
  final double altura;
  const FaixaRodovia(this.label, this.cor, this.altura);
}

class RodoviaEmBlocos extends StatefulWidget {
  const RodoviaEmBlocos({super.key, this.contractData});
  final ContractData? contractData;

  static const List<FaixaRodovia> faixas = [
    FaixaRodovia("Margem", Colors.black12, 20),
    FaixaRodovia("Pista Nova", Colors.black87, 20),
    FaixaRodovia("Pista Antiga", Colors.grey, 20),
    FaixaRodovia("Canteiro Central", Colors.yellow, 10),
    FaixaRodovia("Pista Antiga", Colors.grey, 20),
    FaixaRodovia("Pista Nova", Colors.black87, 20),
    FaixaRodovia("Margem", Colors.black12, 20),
  ];

  @override
  State<RodoviaEmBlocos> createState() => _RodoviaEmBlocosState();
}

class _RodoviaEmBlocosState extends State<RodoviaEmBlocos> {

  late final int totalEstacas;

  @override
  void initState() {
    super.initState();
    final km = widget.contractData?.contractextkm ?? 0;
    totalEstacas = ((km * 1000) / 20).ceil(); // ou .round()
  }

  Widget blocoRodoviaVertical(int index) {
    final bool isMultiploDe10 = index % 10 == 0;
    final TextStyle numeroStyle = TextStyle(
      fontSize: isMultiploDe10 ? 10 : 7,
      height: 1.0,
      color: isMultiploDe10 ? Colors.red : Colors.grey[600],
      fontWeight: isMultiploDe10 ? FontWeight.bold : FontWeight.normal,
    );

    return Column(
      children: [
        SizedBox(
          height: 25,
          child: Center(
            child: isMultiploDe10
                ? RotatedBox(quarterTurns: 3, child: Text('$index', style: numeroStyle))
                : Text('$index', style: numeroStyle),
          ),
        ),
        ...RodoviaEmBlocos.faixas.map(
              (faixa) => Container(
            width: 20,
            height: faixa.altura,
            color: faixa.cor,
            margin: const EdgeInsets.symmetric(vertical: 0.1),
          ),
        ),
      ],
    );
  }

  Widget legendaLateral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 20),
        ...RodoviaEmBlocos.faixas.map(
              (faixa) => Container(
            height: faixa.altura,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 100,
                  child: Text(
                    faixa.label,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    const larguraLegenda = 108.0; // legenda + espaço
    const larguraEstaca = 22.5;
    final estacasPorLinha = ((largura - larguraLegenda) / larguraEstaca).floor();
    final linhas = (totalEstacas / estacasPorLinha).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F4F9),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(32),
            itemCount: linhas,
            itemBuilder: (context, linhaIndex) {
              final start = linhaIndex * estacasPorLinha;
              final end = (start + estacasPorLinha).clamp(0, totalEstacas);
              final blocos = List.generate(end - start, (i) {
                final index = start + i + 1; // 👈 pula a estaca 0
                return SizedBox(width: 20.5, child: blocoRodoviaVertical(index));
              });

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    legendaLateral(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 0.05,
                        runSpacing: 8,
                        children: blocos,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Botões flutuantes
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BotaoFlutuanteHover(icon: Icons.clear_all, label: "GERAL", color: Colors.black.withOpacity(0.7)),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(icon: Icons.directions_car, label: "ASFALTO", color:Colors.blue),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(icon: Icons.recycling, label: "BASE | SUB-BASE", color:  Colors.green),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(icon: Icons.terrain, label: "TERRAPLENAGEM", color:Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class BotaoFlutuanteHover extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const BotaoFlutuanteHover({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<BotaoFlutuanteHover> createState() => _BotaoFlutuanteHoverState();
}

class _BotaoFlutuanteHoverState extends State<BotaoFlutuanteHover> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 20),
            if (_hovering) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovering ? 1 : 0,
                child: Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}