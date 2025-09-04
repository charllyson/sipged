import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

enum TipoCampoGeoJson {
  string,
  integer,
  double_,
  boolean,
  datetime,
}

class GeoJsonPreviewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> features;
  final Future<void> Function(
      List<Map<String, dynamic>> linhas,
      Map<String, TipoCampoGeoJson> tipos,
      List<Map<String, dynamic>> subcolecoes,
      ) onSalvar;

  const GeoJsonPreviewDialog({
    super.key,
    required this.features,
    required this.onSalvar,
  });

  @override
  State<GeoJsonPreviewDialog> createState() => _GeoJsonPreviewDialogState();
}

class _GeoJsonPreviewDialogState extends State<GeoJsonPreviewDialog> {
  bool _carregandoSalvamento = false;

  List<String> _colunas = [];
  List<Map<String, dynamic>> _linhas = [];
  Map<String, bool> _colunaSelecionada = {};
  Map<String, TipoCampoGeoJson> _tipoPorColuna = {};
  Map<int, bool> _linhaSelecionada = {};
  final Map<int, bool> _salvarGeometry = {};
  final Map<int, TextEditingController> _nomeCampoCoordenadas = {};

  double _progressoAtual = 0.0;

  @override
  void initState() {
    super.initState();
    _processarFeatures();
  }

  void _processarFeatures() {
    _linhas = widget.features.map((f) => Map<String, dynamic>.from(f['properties'])).toList();

    if (_linhas.isNotEmpty) {
      _colunas = _linhas.first.keys.toList();
      for (final col in _colunas) {
        _colunaSelecionada[col] = true;
        _tipoPorColuna[col] = TipoCampoGeoJson.string;
      }
      for (int i = 0; i < _linhas.length; i++) {
        _linhaSelecionada[i] = true;
        _salvarGeometry[i] = true;
        _nomeCampoCoordenadas[i] = TextEditingController(text: 'coordinates');
      }
    }
  }

  Future<void> _salvarDados() async {

    setState(() => _carregandoSalvamento = true);
    final total = _linhas.asMap().entries.where((entry) {
      final i = entry.key;
      return _linhaSelecionada[i] == true;
    }).length;
    int salvas = 0;

    final dadosSelecionados = <Map<String, dynamic>>[];
    final subcolecoes = <Map<String, dynamic>>[];

    for (int i = 0; i < _linhas.length; i++) {
      if (_linhaSelecionada[i] != true) continue;

      final linha = _linhas[i];
      final novaLinha = <String, dynamic>{};

      for (final col in _colunas) {
        if (_colunaSelecionada[col] == true) {
          novaLinha[col] = _converterValor(linha[col], _tipoPorColuna[col]!);
        }
      }

      if (_salvarGeometry[i] == true) {
        final nomeCampo = _nomeCampoCoordenadas[i]?.text.trim() ?? 'coordinates';
        final geometry = widget.features[i]['geometry'];
        final coords = geometry['coordinates'];

        List<List<dynamic>> pontos = [];

        try {
          if (coords is List && coords.isNotEmpty) {
            if (coords.first is List && coords.first.isNotEmpty && coords.first.first is List) {
              pontos = (coords)
                  .cast<List<dynamic>>()
                  .expand((sublist) => sublist.cast<List<dynamic>>())
                  .toList();
            } else if (coords.first is List) {
              pontos = coords.cast<List<dynamic>>();
            }
          }
        } catch (e) {
          debugPrint('Erro ao processar coordenadas: $e');
          pontos = [];
        }

        // 1. Converte para LatLng
        final latLngs = pontos.map((p) => LatLng(p[1], p[0])).toList();

        // 2. Ordena os pontos por sequência mais próxima
        final ordenados = ordenarPontosPorSequenciaLinear(latLngs);

        // 3. Converte para mapa de latitude/longitude
        final pontosConvertidos = ordenados.map((p) => {
          'latitude': p.latitude,
          'longitude': p.longitude,
        }).toList();

        subcolecoes.add({
          'parent': novaLinha,
          'subCollection': nomeCampo,
          'points': pontosConvertidos,
        });
      }


      dadosSelecionados.add(novaLinha);
      salvas++;
      setState(() {
        _progressoAtual = salvas / total;
      });
    }

    await widget.onSalvar(dadosSelecionados, _tipoPorColuna, subcolecoes);

    if (mounted) Navigator.of(context).pop(true);
  }

  dynamic _converterValor(dynamic valor, TipoCampoGeoJson tipo) {
    try {
      switch (tipo) {
        case TipoCampoGeoJson.string:
          return valor?.toString();
        case TipoCampoGeoJson.integer:
          return int.tryParse(valor.toString());
        case TipoCampoGeoJson.double_:
          return double.tryParse(valor.toString());
        case TipoCampoGeoJson.boolean:
          final v = valor.toString().toLowerCase();
          return v == 'true' || v == '1';
        case TipoCampoGeoJson.datetime:
          return DateFormat("yyyy-MM-ddTHH:mm:ss").parse(valor);
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          AlertDialog(

            title: const Text('Pré-visualização do GeoJSON'),
            backgroundColor: Colors.white70,
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumoGeoJson(),
                  const Divider(),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Checkbox(
                            value: _todasSelecionadas,
                            onChanged: _alternarTodasLinhas,
                          ),
                        ),
                        _buildCabecalho(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTabela()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _carregandoSalvamento ? null : _salvarDados,
                child: const Text('Salvar'),
              ),
            ],
          ),
          if (_carregandoSalvamento) _buildOverlay('Salvando no Firebase...'),
        ],
      ),
    );
  }

  Widget _buildResumoGeoJson() {
    final tipo = widget.features.first['geometry']?['type'] ?? 'Desconhecido';
    final totalLinhas = _linhas.length;
    final totalColunas = _colunas.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipo de geometria: $tipo', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Linhas: $totalLinhas | Colunas: $totalColunas'),
        ],
      ),
    );
  }

  Widget _buildOverlay(String texto) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _progressoAtual,
                backgroundColor: Colors.grey.shade300,
                color: Colors.blueAccent,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text('${(_progressoAtual * 100).toStringAsFixed(1)}% concluído', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }


  Widget _buildCabecalho() {
    return Row(
      children: _colunas.map((col) {
        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Checkbox(
                    value: _colunaSelecionada[col],
                    onChanged: (val) => setState(() => _colunaSelecionada[col] = val!),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      initialValue: col,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (novoNome) => _renomearColuna(col, novoNome),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTipoDropdown(col),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTipoDropdown(String coluna) {
    return DropdownButton<TipoCampoGeoJson>(
      dropdownColor: Colors.white,
      underline: Container(),
      value: _tipoPorColuna[coluna],
      onChanged: (val) => setState(() => _tipoPorColuna[coluna] = val!),
      items: TipoCampoGeoJson.values.map((tipo) => DropdownMenuItem(
        value: tipo,
        child: Text(tipo.name),
      )).toList(),
    );
  }

  bool get _todasSelecionadas =>
      _linhaSelecionada.values.every((v) => v == true);

  void _alternarTodasLinhas(bool? selecionado) {
    setState(() {
      for (final key in _linhaSelecionada.keys) {
        _linhaSelecionada[key] = selecionado ?? false;
      }
    });
  }

  void _renomearColuna(String antigo, String novo) {
    if (novo.trim().isEmpty || _colunas.contains(novo)) return;

    final index = _colunas.indexOf(antigo);
    if (index != -1) {
      setState(() {
        _colunas[index] = novo;
        for (final linha in _linhas) {
          linha[novo] = linha.remove(antigo);
        }
        _colunaSelecionada[novo] = _colunaSelecionada.remove(antigo) ?? true;
        _tipoPorColuna[novo] = _tipoPorColuna.remove(antigo) ?? TipoCampoGeoJson.string;
      });
    }
  }

  List<LatLng> ordenarPontosPorSequenciaLinear(List<LatLng> pontos) {
    if (pontos.length <= 2) return pontos;

    final visitados = <int>{};
    final resultado = <LatLng>[];

    int atual = 0;
    visitados.add(atual);
    resultado.add(pontos[atual]);

    while (visitados.length < pontos.length) {
      double menorDistancia = double.infinity;
      int proximo = -1;

      for (int i = 0; i < pontos.length; i++) {
        if (visitados.contains(i)) continue;
        final distancia = Distance().as(LengthUnit.Meter, pontos[atual], pontos[i]);
        if (distancia < menorDistancia) {
          menorDistancia = distancia;
          proximo = i;
        }
      }

      if (proximo == -1) break;

      visitados.add(proximo);
      resultado.add(pontos[proximo]);
      atual = proximo;
    }

    return resultado;
  }


  Widget _buildTabela() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _linhas.length,
            itemBuilder: (context, index) {
              final linha = _linhas[index];
              final geometry = widget.features[index]['geometry'];
              final coords = geometry['coordinates'] as List;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: Checkbox(
                      value: _linhaSelecionada[index] ?? true,
                      onChanged: (val) {
                        setState(() {
                          _linhaSelecionada[index] = val ?? true;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: ExpansionTile(
                      title: Text('Linha ${index + 1}'),
                      subtitle: Text(
                        _colunas.map((c) => '$c: ${linha[c]}').join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _salvarGeometry[index] ?? true,
                                onChanged: (val) {
                                  setState(() {
                                    _salvarGeometry[index] = val ?? true;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _nomeCampoCoordenadas[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Nome do campo para salvar coordenadas',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (geometry != null && geometry['coordinates'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Coordenadas:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: coords.expand<Widget>((sublist) {
                                      return sublist.map<Widget>((point) {
                                        return Text('[${point[0]}, ${point[1]}]', style: const TextStyle(fontFamily: 'monospace', fontSize: 12));
                                      }).toList();
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}