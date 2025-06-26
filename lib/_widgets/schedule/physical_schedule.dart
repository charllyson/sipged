import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisgeo/_datas/calculationMemory/calculation_memory_data.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import '../../_class/highway/highway_class.dart';
import '../buttons/button_flutuante_hover.dart';

class PhysicalSchedule extends StatefulWidget {
  const PhysicalSchedule({super.key, this.contractData});
  final ContractData? contractData;

  static const List<String> nomesFaixas = [
    'MARGEM LE',
    'PISTA NOVA LE',
    'PISTA ANTIGA LE',
    'CANTEIRO CENTRAL',
    'PISTA ANTIGA LD',
    'PISTA NOVA LD',
    'MARGEM LD',
  ];

  static List<HighwayClass> faixas = [
    HighwayClass(nomesFaixas[0], Colors.black12, 20),
    HighwayClass(nomesFaixas[1], Colors.black87, 20),
    HighwayClass(nomesFaixas[2], Colors.grey, 20),
    HighwayClass(nomesFaixas[3], Colors.yellow, 10),
    HighwayClass(nomesFaixas[4], Colors.grey, 20),
    HighwayClass(nomesFaixas[5], Colors.black87, 20),
    HighwayClass(nomesFaixas[6], Colors.black12, 20),
  ];

  @override
  State<PhysicalSchedule> createState() => _PhysicalScheduleState();
}



class _PhysicalScheduleState extends State<PhysicalSchedule> {
  late final int totalEstacas;
  List<CalculationMemoryData> _execucoes = [];
  String _servicoSelecionado = "GERAL";
  Future<Map<String, Map<String, double>>>? _futurePercentuaisPorServico;
  CalculationMemoryData calculationMemoryData = CalculationMemoryData();
  int get totalEsperado => totalEstacas * PhysicalSchedule.faixas.length;
  int get concluidos => _execucoes.where((e) => e.status == 'concluido').length;
  int get emAndamento => _execucoes.where((e) => e.status == 'em andamento').length;
  int get iniciados => concluidos + emAndamento;
  int get aIniciar => totalEsperado - iniciados;

  double get percentualConcluido => totalEsperado == 0 ? 0 : concluidos / totalEsperado * 100;
  double get percentualEmAndamento => totalEsperado == 0 ? 0 : emAndamento / totalEsperado * 100;
  double get percentualAIniciar => totalEsperado == 0 ? 0 : aIniciar / totalEsperado * 100;

  @override
  void initState() {
    super.initState();
    final km = widget.contractData?.contractExtKm ?? 0;
    totalEstacas = ((km * 1000) / 20).ceil();
    carregarExecucao();
    if (_servicoSelecionado == "GERAL") {
      _futurePercentuaisPorServico = calcularPercentuaisPorServico();
    }
  }

  String get nomeSubcolecao {
    switch (_servicoSelecionado.toUpperCase()) {
      case 'ASFALTO':
        return 'schedules_asfalto';
      case 'BASE | SUB-BASE':
        return 'schedules_base';
      case 'TERRAPLENAGEM':
        return 'schedules_terraplenagem';
      default:
        return 'schedules_geral';
    }
  }

  CollectionReference<Map<String, dynamic>> getSubcollectionRef(String contractId, [String? customCollection]) {
    return FirebaseFirestore.instance
        .collection('temContracts')
        .doc(contractId)
        .collection(customCollection ?? nomeSubcolecao);
  }

  Future<void> carregarExecucao() async {
    final contractId = widget.contractData?.id;
    if (contractId == null) return;

    List<QuerySnapshot<Map<String, dynamic>>> snapshots;

    if (_servicoSelecionado.toUpperCase() == "GERAL") {
      snapshots = await Future.wait([
        getSubcollectionRef(contractId, 'schedules_asfalto').get(),
        getSubcollectionRef(contractId, 'schedules_base').get(),
        getSubcollectionRef(contractId, 'schedules_terraplenagem').get(),
      ]);
    } else {
      final snap = await getSubcollectionRef(contractId).get();
      snapshots = [snap];
    }

    final execucoes = snapshots.expand((snap) {
      return snap.docs.map((doc) => CalculationMemoryData.fromMap(doc.data()));
    }).toList();

    final mapUnico = <String, CalculationMemoryData>{};
    for (final e in execucoes) {
      final key = '${e.numero}_${e.faixaIndex}';
      if (!mapUnico.containsKey(key) || (e.timestamp?.isAfter(mapUnico[key]!.timestamp ?? DateTime(2000)) ?? false)) {
        mapUnico[key] = e;
      }
    }

    setState(() {
      _execucoes = mapUnico.values.toList();
    });
  }

  Future<void> _atualizarQuadrado(int estaca, int faixaIndex, String tipo, String status, [String? comentario]) async {
    final contractId = widget.contractData?.id;
    if (contractId == null) return;
    if (_servicoSelecionado == "GERAL") return;

    final ref = getSubcollectionRef(contractId);
    final query = await ref
        .where('numero', isEqualTo: estaca)
        .where('faixa_index', isEqualTo: faixaIndex)
        .get();

    final dados = {
      'numero': estaca,
      'faixa_index': faixaIndex,
      'tipo': tipo,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      if (comentario != null) 'comentario': comentario,
    };

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      if (status == 'a iniciar') {
        await doc.reference.delete();
      } else {
        await doc.reference.update(dados);
      }
    } else {
      if (status != 'a iniciar') {
        await ref.add(dados);
      }
    }

    await carregarExecucao();
  }

  void _mostrarPopupServico(int estaca, int faixaIndex, String tipoServico) async {
    final execucao = _execucoes.firstWhere(
          (e) => e.numero == estaca && e.faixaIndex == faixaIndex,
      orElse: () => CalculationMemoryData(numero: estaca, faixaIndex: faixaIndex, tipo: tipoServico, status: '', comentario: ''),
    );
    final comentarioCtrl = TextEditingController(text: execucao.comentario ?? '');

    String? escolha = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Atualizar "$tipoServico" - Estaca $estaca'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: comentarioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'concluido'),
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text("Concluído"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'em andamento'),
                    icon: const Icon(Icons.build, color: Colors.orange),
                    label: const Text("Andamento"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'a iniciar'),
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    label: const Text("A iniciar"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );

    if (escolha != null) {
      await _atualizarQuadrado(estaca, faixaIndex, tipoServico, escolha, comentarioCtrl.text.trim().isEmpty ? null : comentarioCtrl.text.trim());
    }
  }



  ///toast
  void mostrarToastSuperior(String mensagem) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 70,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              mensagem,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
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
        ...List.generate(PhysicalSchedule.faixas.length, (i) {
          final faixa = PhysicalSchedule.faixas[i];
          final execucao = _execucoes.firstWhere(
                (e) => e.numero == index && e.faixaIndex == i,
            orElse: () => CalculationMemoryData(numero: index, faixaIndex: i, tipo: '', status: ''),
          );

          return _buildBlocoRodovia(execucao, faixa.altura);

        }),
      ],
    );
  }

  Future<Map<String, Map<String, double>>> calcularPercentuaisPorServico() async {
    final contractId = widget.contractData?.id;
    if (contractId == null) return {};

    final servicos = {
      'ASFALTO': 'schedules_asfalto',
      'BASE | SUB-BASE': 'schedules_base',
      'TERRAPLENAGEM': 'schedules_terraplenagem',
    };

    final Map<String, Map<String, double>> resultado = {};

    for (final entry in servicos.entries) {
      final snap = await getSubcollectionRef(contractId, entry.value).get();

      final execucoes = snap.docs.map((doc) => CalculationMemoryData.fromMap(doc.data())).toList();
      final total = totalEstacas * PhysicalSchedule.faixas.length;
      final concluidos = execucoes.where((e) => e.status == 'concluido').length;
      final andamento = execucoes.where((e) => e.status == 'em andamento').length;
      final iniciados = concluidos + andamento;
      final aIniciar = total - iniciados;

      resultado[entry.key] = {
        'concluido': total == 0 ? 0 : concluidos / total * 100,
        'em andamento': total == 0 ? 0 : andamento / total * 100,
        'a iniciar': total == 0 ? 0 : aIniciar / total * 100,
      };
    }

    return resultado;
  }

  Widget legendaLateral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 20),
        ...PhysicalSchedule.faixas.map(
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

  Future<void> selecionarServico(String servico) async {
    setState(() {
      _servicoSelecionado = servico;
      if (servico == "GERAL") {
        _futurePercentuaisPorServico = calcularPercentuaisPorServico();
      } else {
        _futurePercentuaisPorServico = null;
      }
    });
    await carregarExecucao();
  }

  Widget _buildBlocoRodovia(CalculationMemoryData execucao, double altura) {
    final hasComment = execucao.comentario != null && execucao.comentario!.trim().isNotEmpty;
    final cor = corQuadrado(execucao.numero!, execucao.faixaIndex!);

    final container = GestureDetector(
      onTap: _servicoSelecionado == "GERAL"
          ? () => mostrarToastSuperior("Para editar, selecione um serviço específico.")
          : () => _mostrarPopupServico(execucao.numero!, execucao.faixaIndex!, execucao.tipo!),
      child: Container(
        width: 20,
        height: altura,
        margin: const EdgeInsets.symmetric(vertical: 0.1),
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: cor)),
            if (hasComment)
              const Positioned(
                child: Center(child: Icon(Icons.info_outline_rounded, size: 15, color: Colors.black38)),
              ),
          ],
        ),
      ),
    );

    if (execucao.status!.isEmpty || execucao.status == 'a iniciar') {
      return container; // Sem tooltip
    } else {
      return Tooltip(
        message: _buildTooltip(execucao),
        child: container,
      );
    }
  }

  String _buildTooltip(CalculationMemoryData execucao) {
    final data = execucao.timestamp;
    final comentario = execucao.comentario;
    final buffer = StringBuffer();
    buffer.writeln("Status: ${execucao.status}");
    if (data != null) {
      buffer.writeln("Data: ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}");
    }
    if (comentario != null && comentario.trim().isNotEmpty) {
      buffer.writeln("Comentário: $comentario");
    }
    return buffer.toString().trim();
  }


  Color _corDoServico(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'ASFALTO':
        return Colors.blue;
      case 'BASE | SUB-BASE':
        return Colors.green;
      case 'TERRAPLENAGEM':
        return Colors.red;
      default:
        return Colors.black26;
    }
  }


  Color corQuadrado(int estaca, int faixaIndex) {
    final execucao = _execucoes.firstWhere(
          (e) => e.numero == estaca && e.faixaIndex == faixaIndex,
      orElse: () => CalculationMemoryData(numero: estaca, faixaIndex: faixaIndex, tipo: '', status: ''),
    );

    if (_servicoSelecionado == "GERAL") {
      if (execucao.status == 'concluido' || execucao.status == 'em andamento') {
        return _corDoServico(execucao.tipo!);
      } else {
        return Colors.grey.shade300;
      }
    } else {
      switch (execucao.status) {
        case 'concluido':
          return Colors.green;
        case 'em andamento':
          return Colors.orange;
        default:
          return Colors.grey.shade300;
      }
    }
  }

  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth - 32; // tela pequena: 1 campo por linha
    } else if (screenWidth < 1000) {
      return (screenWidth - 64) / 2; // tela média: 2 por linha
    } else {
      return (screenWidth - 96) / 4; // tela grande: 3 por linha
    }
  }

  Widget _cabecalhoPorServico(Map<String, Map<String, double>> dados, String servicoSelecionado) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("CRONOGRAMA - $servicoSelecionado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...dados.entries.map((entry) {
                final nome = entry.key;
                final valores = entry.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            margin: const EdgeInsets.only(right:
                            6),
                            decoration: BoxDecoration(
                              color: _corDoServico(nome),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.square, color: Colors.green, size: 12),
                          Text("${valores['concluido']!.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.square, color: Colors.orange, size: 12),
                          const SizedBox(width: 4),
                          Text("${valores['em andamento']!.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.square, color: Colors.grey, size: 12),
                          const SizedBox(width: 4),
                          Text("${valores['a iniciar']!.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                );
              }),
            ]
          )

        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width - 32;
    const larguraLegenda = 100.0;
    const larguraEstaca = 22.5;
    final estacasPorLinha = ((largura - larguraLegenda) / larguraEstaca).floor();
    final linhas = (totalEstacas / estacasPorLinha).ceil();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<Map<String, Map<String, double>>>(
            future: _futurePercentuaisPorServico,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Text("Carregando..."));
              }

              final data = snapshot.data!;
              final largura = MediaQuery.of(context).size.width - 32;
              const larguraLegenda = 100.0;
              const larguraEstaca = 22.5;
              final estacasPorLinha = ((largura - larguraLegenda) / larguraEstaca).floor();
              final linhas = (totalEstacas / estacasPorLinha).ceil();

              return ListView.builder(
                itemCount: linhas + 1, // +1 para o cabeçalho
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _cabecalhoPorServico(data, _servicoSelecionado);
                  }
                  final linhaIndex = index - 1;
                  final start = linhaIndex * estacasPorLinha;
                  final end = (start + estacasPorLinha).clamp(0, totalEstacas);
                  final blocos = List.generate(end - start, (i) {
                    final estacaIndex = start + i + 1;
                    return SizedBox(width: 20.5, child: blocoRodoviaVertical(estacaIndex));
                  });

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        legendaLateral(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 0,
                            runSpacing: 0,
                            children: blocos,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                BotaoFlutuanteHover(
                  icon: Icons.clear_all,
                  label: "GERAL",
                  color: Colors.black54,
                  onPressed: () => selecionarServico("GERAL"),
                ),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(
                  icon: Icons.directions_car,
                  label: "ASFALTO",
                  color: Colors.blue,
                  onPressed: () => selecionarServico("ASFALTO"),
                ),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(
                  icon: Icons.recycling,
                  label: "BASE | SUB-BASE",
                  color: Colors.green,
                  onPressed: () => selecionarServico("BASE | SUB-BASE"),
                ),
                const SizedBox(height: 12),
                BotaoFlutuanteHover(
                  icon: Icons.terrain,
                  label: "TERRAPLENAGEM",
                  color: Colors.red,
                  onPressed: () => selecionarServico("TERRAPLENAGEM"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}