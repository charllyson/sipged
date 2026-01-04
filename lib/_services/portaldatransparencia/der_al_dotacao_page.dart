import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// ===============================
/// MODELOS
/// ===============================

class UgItem {
  final String id;
  final String descricao;

  UgItem({required this.id, required this.descricao});

  factory UgItem.fromJson(Map<String, dynamic> json) {
    return UgItem(
      id: (json['id'] ?? '').toString(),
      descricao: (json['descricao'] ?? '').toString(),
    );
  }
}

class DotacaoAnoRow {
  final int ano;
  final String ugCodigo; // exemplo: "010001" (quando vem)
  final String descricaoUg;

  final double totalInicial;
  final double totalSuplementado;
  final double totalReduzido;
  final double totalAtualizado;

  DotacaoAnoRow({
    required this.ano,
    required this.ugCodigo,
    required this.descricaoUg,
    required this.totalInicial,
    required this.totalSuplementado,
    required this.totalReduzido,
    required this.totalAtualizado,
  });
}

/// ===============================
/// SERVICE (API)
/// ===============================

class AlTransparenciaApi {
  // Base do portal (conforme a doc do próprio site)
  static const String _base = 'https://transparencia.al.gov.br';

  final String apiKey;

  AlTransparenciaApi({required this.apiKey});

  Map<String, String> _headers() => <String, String>{
    // Nota do portal: requests AJAX
    'X-Requested-With': 'XMLHttpRequest',
    'Accept': 'application/json',
    // Cabeçalho que você recebeu por e-mail (ajuste se seu portal exigir outro nome)
    // Pelo seu print: chave-api-dados
    'chave-api-dados': apiKey,
  };

  /// Lista UGs disponíveis para o período
  Future<List<UgItem>> listarUgs({
    required String dataIni, // dd/mm/yyyy
    required String dataFim, // dd/mm/yyyy
  }) async {
    final uri = Uri.parse('$_base/orcamento/json-dotacoes-avancada-ug/')
        .replace(queryParameters: {
      'data_registro_dti_': dataIni,
      'data_registro_dtf_': dataFim,
    });

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Erro listarUgs: ${res.statusCode} - ${res.body}');
    }

    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! List) return <UgItem>[];

    return decoded.map((e) => UgItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Consulta Dotações Orçamentárias por UG (totais no período)
  /// Doc: /orcamento/json-dotacoes/ com filtros e datas
  Future<Map<String, dynamic>> dotacoesPorUg({
    required String ugId, // id (combos) ou ug (filtro) conforme retorno do portal
    required String dataIni, // dd/mm/yyyy
    required String dataFim, // dd/mm/yyyy
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_base/orcamento/json-dotacoes/').replace(
      queryParameters: {
        'data_registro_dti_': dataIni,
        'data_registro_dtf_': dataFim,
        'limit': '$limit',
        'offset': '$offset',
        // conforme doc: "ug" é opcional e filtra pela unidade gestora
        'ug': ugId,
      },
    );

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Erro dotacoesPorUg: ${res.statusCode} - ${res.body}');
    }
    return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

/// ===============================
/// UI (PAGE)
/// ===============================

class DerAlDotacaoPage extends StatefulWidget {
  const DerAlDotacaoPage({super.key});

  @override
  State<DerAlDotacaoPage> createState() => _DerAlDotacaoPageState();
}

class _DerAlDotacaoPageState extends State<DerAlDotacaoPage> {
  late final AlTransparenciaApi api;

  final NumberFormat moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat df = DateFormat('dd/MM/yyyy');

  // intervalo por anos
  int anoInicial = DateTime.now().year - 5;
  int anoFinal = DateTime.now().year;

  // controle de loading/erro
  Future<List<DotacaoAnoRow>>? _future;

  // filtro de nome (porque o nome exato pode variar no portal)
  final List<String> _possibleDerNames = const [
    'DEPARTAMENTO ESTADUAL DE ESTRADAS DE RODAGEM',
    'DEPARTAMENTO DE ESTRADAS DE RODAGEM',
    'DER',
  ];

  @override
  void initState() {
    super.initState();
    final key = dotenv.env['AL_TRANSPARENCIA_API_KEY'];
    if (key == null || key.trim().isEmpty) {
      // deixa estourar mais claro no build
      api = AlTransparenciaApi(apiKey: '');
    } else {
      api = AlTransparenciaApi(apiKey: key.trim());
      _future = _load();
    }
  }

  Future<List<DotacaoAnoRow>> _load() async {
    if (api.apiKey.isEmpty) {
      throw Exception('Chave não encontrada. Configure AL_TRANSPARENCIA_API_KEY no .env');
    }
    if (anoFinal < anoInicial) {
      throw Exception('Ano final não pode ser menor que ano inicial.');
    }

    final List<DotacaoAnoRow> out = [];

    for (int ano = anoInicial; ano <= anoFinal; ano++) {
      final dataIni = '01/01/$ano';
      final dataFim = '31/12/$ano';

      // 1) pega UGs do período
      final ugs = await api.listarUgs(dataIni: dataIni, dataFim: dataFim);

      // 2) encontra DER por nome (case-insensitive)
      final UgItem? derUg = _findDerUg(ugs);
      if (derUg == null) {
        // se não achou, segue para o próximo ano (ou lance erro, como preferir)
        continue;
      }

      // 3) consulta dotações filtrando pela UG
      final jsonMap = await api.dotacoesPorUg(
        ugId: derUg.id,
        dataIni: dataIni,
        dataFim: dataFim,
        limit: 50,
        offset: 0,
      );

      final rows = (jsonMap['rows'] as List?) ?? const [];
      if (rows.isEmpty) {
        // sem dados nesse ano
        out.add(
          DotacaoAnoRow(
            ano: ano,
            ugCodigo: '',
            descricaoUg: derUg.descricao,
            totalInicial: 0,
            totalSuplementado: 0,
            totalReduzido: 0,
            totalAtualizado: 0,
          ),
        );
        continue;
      }

      // Normalmente a resposta vem com uma linha para a UG.
      // Pegamos a primeira, mas você pode somar todas se o portal devolver mais de uma.
      final first = rows.first as Map<String, dynamic>;

      out.add(
        DotacaoAnoRow(
          ano: ano,
          ugCodigo: (first['ug'] ?? '').toString(),
          descricaoUg: (first['descricao_ug'] ?? derUg.descricao).toString(),
          totalInicial: _parsePtBrMoney(first['total_inicial']),
          totalSuplementado: _parsePtBrMoney(first['total_suplementado']),
          totalReduzido: _parsePtBrMoney(first['total_reduzido']),
          totalAtualizado: _parsePtBrMoney(first['total_atualizado']),
        ),
      );
    }

    // Ordena por ano
    out.sort((a, b) => a.ano.compareTo(b.ano));
    return out;
  }

  UgItem? _findDerUg(List<UgItem> ugs) {
    final upper = ugs
        .map((e) => UgItem(id: e.id, descricao: e.descricao.toUpperCase()))
        .toList();

    for (final name in _possibleDerNames) {
      final target = name.toUpperCase();
      final found = upper.where((u) => u.descricao.contains(target)).toList();
      if (found.isNotEmpty) {
        // pega o mais "longo" (tende a ser o nome completo)
        found.sort((a, b) => b.descricao.length.compareTo(a.descricao.length));
        // retorna id original (mesmo valor)
        return found.first;
      }
    }
    return null;
  }

  double _parsePtBrMoney(dynamic v) {
    if (v == null) return 0.0;
    final s = v.toString().trim();
    if (s.isEmpty) return 0.0;
    // Exemplo vem como "184.290.122,00"
    final normalized = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (api.apiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dotações DER/AL')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Configure AL_TRANSPARENCIA_API_KEY no arquivo .env e reinicie o app.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dotações Orçamentárias — DER/AL (por ano)'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _FiltersBar(
            anoInicial: anoInicial,
            anoFinal: anoFinal,
            onChanged: (ai, af) {
              setState(() {
                anoInicial = ai;
                anoFinal = af;
                _future = _load();
              });
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<DotacaoAnoRow>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText('Erro: ${snap.error}'),
                  );
                }
                final rows = snap.data ?? const <DotacaoAnoRow>[];
                if (rows.isEmpty) {
                  return const Center(child: Text('Sem dados no intervalo informado.'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Ano')),
                        DataColumn(label: Text('UG')),
                        DataColumn(label: Text('Descrição UG')),
                        DataColumn(label: Text('Dotação inicial')),
                        DataColumn(label: Text('Suplementada')),
                        DataColumn(label: Text('Reduzida')),
                        DataColumn(label: Text('Atualizada')),
                      ],
                      rows: rows.map((r) {
                        return DataRow(
                          cells: [
                            DataCell(Text('${r.ano}')),
                            DataCell(Text(r.ugCodigo.isEmpty ? '-' : r.ugCodigo)),
                            DataCell(SizedBox(width: 420, child: Text(r.descricaoUg))),
                            DataCell(Text(moeda.format(r.totalInicial))),
                            DataCell(Text(moeda.format(r.totalSuplementado))),
                            DataCell(Text(moeda.format(r.totalReduzido))),
                            DataCell(Text(moeda.format(r.totalAtualizado))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final int anoInicial;
  final int anoFinal;
  final void Function(int anoInicial, int anoFinal) onChanged;

  const _FiltersBar({
    required this.anoInicial,
    required this.anoFinal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final years = List<int>.generate(16, (i) => now - i); // últimos 16 anos

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          const Text('Período:'),
          DropdownButton<int>(
            value: anoInicial,
            items: years
                .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              final newIni = v;
              final newFim = anoFinal < newIni ? newIni : anoFinal;
              onChanged(newIni, newFim);
            },
          ),
          const Text('até'),
          DropdownButton<int>(
            value: anoFinal,
            items: years
                .map((y) => DropdownMenuItem<int>(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              final newFim = v;
              final newIni = anoInicial > newFim ? newFim : anoInicial;
              onChanged(newIni, newFim);
            },
          ),
          const SizedBox(width: 12),
          const Text(
            'Obs.: o app busca o DER pela lista de UGs do portal e então consulta as dotações do ano.',
          ),
        ],
      ),
    );
  }
}
