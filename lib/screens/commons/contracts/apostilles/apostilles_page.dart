import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_datas/apostilles/apostilles_data.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_widgets/charts/bar_chart_sample.dart';
import '../../../../_widgets/charts/pie_chart_sample.dart';
import '../../../../_widgets/input/custom_text_field.dart';

class ApostillesPage extends StatefulWidget {
  const ApostillesPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> {
  late ContractsBloc _contractsBloc;
  late Future<List<ApostillesData>> _futureApostilles;
  int? _linhaSelecionada;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();
  String? _currentApostillesId;
  bool _modoEdicao = false;
  bool _formValido = false;
  final _dateFormatter = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});



  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _loadApostilles();
    _dateController.addListener(_validarFormulario);
    _valueController.addListener(_validarFormulario);
    _processController.addListener(_validarFormulario);
    _orderController.text = '1'; // valor inicial padrão
  }



  void _deletarApostille(String uid) async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente apagar este apostilamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    await _contractsBloc.deletarApostille(widget.contractData!.id!, uid);

    setState(() => _loadApostilles());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apostilamento apagado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }


  void preencherCampos(ApostillesData data) {
    setState(() {
      _modoEdicao = true;
      _currentApostillesId = data.uid;
      _orderController.text = data.apostilleorder?.toString() ?? '';
      _dateController.text = convertDateTimeToDDMMYYYY(data.apostilledata);
      _valueController.text = priceToString(data.apostillevalue);
      _processController.text = data.apostillenumberprocess ?? '';
    });
  }

  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 12;
    const margin = 12;
    const horizontalPadding = 32.0; // somando os dois lados (Padding 16 + 16)

    if (screenWidth < 600) {
      return screenWidth - margin - horizontalPadding; // 1 por linha
    } else if (screenWidth < 900) {
      return (screenWidth - margin * 2 - spacing * 1 - horizontalPadding) / 2; // 2 por linha
    } else if (screenWidth < 1300) {
      return (screenWidth - margin * 2 - spacing * 2 - horizontalPadding) / 3; // 3 por linha
    } else {
      return (screenWidth - margin * 3 - spacing * 3 - horizontalPadding) / 4; // 4 por linha
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<ApostillesData>>(
      future: _futureApostilles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: \${snapshot.error}'));
        }else if(!snapshot.hasData || snapshot.data!.isEmpty){
          return Center(child: Text('Nenhum apostilamento encontrado'));
        }
        final apostilles = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCampos(),
              SizedBox(height: 12),
              const Text('Gráfico dos apostilamentos cadastradas no sistema', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double larguraDisponivel = constraints.maxWidth;
                  const double larguraGraficoPizza = 300;
                  const double espacamento = 100;

                  final double larguraGraficoBarra = math.max(
                    larguraDisponivel - larguraGraficoPizza - espacamento, 300,
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PieChartSample(
                          apostilles: apostilles,
                          selectedIndex: _linhaSelecionada,
                          larguraGrafico: larguraGraficoPizza,
                          onTouch: (index) {
                            setState(() {
                              _linhaSelecionada = index;
                              if (index != null && index >= 0 && index < apostilles.length) {
                                preencherCampos(apostilles[index]);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        BarChartSample(
                          apostilles: apostilles,
                          selectedIndex: _linhaSelecionada,
                          larguraGrafico: larguraGraficoBarra,
                          onBarTap: (index) {
                            setState(() {
                              _linhaSelecionada = index;
                              if (index >= 0 && index < apostilles.length) {
                                preencherCampos(apostilles[index]);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Apostilamentos cadastrados no sistema', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              _buildTabela(apostilles),
            ],
          ),
        );
      },
    );
  }

  void _criarNewApostilles() async {
    if (widget.contractData?.id == null) return;

    final lista = await _contractsBloc.getAllApostillesOfContract(uidContract: widget.contractData!.id!);
    final ultimaOrdem = lista.map((e) => e.apostilleorder ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _modoEdicao = false;
      _currentApostillesId = null;
      _orderController.text = (ultimaOrdem + 1).toString();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
    });
  }

  void _loadApostilles() {
    if (widget.contractData?.id != null) {
      _futureApostilles = _contractsBloc.getAllApostillesOfContract(uidContract: widget.contractData!.id!)
          .then((list) {
        if (!_modoEdicao) {
          final ultimaOrdem = list.map((e) => e.apostilleorder ?? 0).fold(0, (a, b) => a > b ? a : b);
          _orderController.text = (ultimaOrdem + 1).toString();
        }
        return list;
      });
    } else {
      _futureApostilles = Future.value([]);
    }
  }

  void _validarFormulario() {
    final valido = _dateController.text.isNotEmpty && _valueController.text.isNotEmpty && _processController.text.isNotEmpty;
    setState(() => _formValido = valido);
  }

  Future<void> _saveOrUpdateApostilles() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(_modoEdicao ? 'Deseja atualizar este apostilamento?' : 'Deseja salvar um novo apostilamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    final novo = ApostillesData(
      uid: _currentApostillesId,
      apostillenumberprocess: _processController.text,
      apostilleorder: int.tryParse(_orderController.text),
      apostilledata: convertDDMMYYYYToDateTime(_dateController.text),
      apostillevalue: stringToDouble(_valueController.text),
    );

    await _contractsBloc.saveOrUpdateApostille(novo, widget.contractData!.id!);

    setState(() {
      _loadApostilles();
      _currentApostillesId = null;
      _modoEdicao = false;
      _orderController.clear();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_modoEdicao ? 'Apostilamento atualizado com sucesso!' : 'Apostilamento salvo com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFormCampos() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: getResponsiveWidth(context),
                  child: Tooltip(
                    message: 'Este campo é gerado automaticamente.',
                    child: CustomTextField(
                      labelText: 'Ordem do apostilamento',
                      controller: _orderController,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                      labelText: 'Nº do processo',
                      controller: _processController,
                      inputFormatters: [processoMaskFormatter],
                      keyboardType: TextInputType.number,
                    )),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                        labelText: 'Valor do apostilamento',
                        controller: _valueController,
                      inputFormatters: [
                        CurrencyInputFormatter(
                          leadingSymbol: 'R\$',
                          useSymbolPadding: true,
                          thousandSeparator: ThousandSeparator.Period,
                          mantissaLength: 2,
                        ),
                      ],
                      keyboardType: TextInputType.number,                    )),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                        labelText: 'Data do apostilamento',
                        controller: _dateController,
                      inputFormatters: [_dateFormatter],
                      keyboardType: TextInputType.number,
                    )),

              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _formValido ? _saveOrUpdateApostilles : null,
                  icon: Icon(Icons.save),
                  label: Text(_modoEdicao ? 'Atualizar' : 'Salvar'),
                ),
                const SizedBox(width: 12),
                if (_modoEdicao)
                  TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Adicionar'),
                    onPressed: _criarNewApostilles,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabela(List<ApostillesData> apostilles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(80),  // ORDEM
                1: FixedColumnWidth(200),  // Nº PROCESSO
                2: FixedColumnWidth(140),  // VALOR
                3: FixedColumnWidth(120),  // DATA
                4: FixedColumnWidth(80),   // APAGAR
              },
              children: [
                _buildHeaderRow(),
                ...apostilles.map((data) => _buildDataRow(data, apostilles)),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildHeaderRow() {
    const headers = [
      'ORDEM',
      'Nº PROCESSO',
      'VALOR',
      'DATA',
      'APAGAR'
    ];
    return TableRow(
      decoration: const BoxDecoration(color: Color.fromRGBO(0, 200, 255, 0.3)),
      children: headers.map((title) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(ApostillesData data, List<ApostillesData> apostilles) {
    final index = apostilles.indexOf(data);
    final isSelected = index == _linhaSelecionada;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.apostilleorder.toString(), () {
          setState(() {
            _linhaSelecionada = index;
            preencherCampos(data);
          });
        }),
        _buildEditableCell(data.apostillenumberprocess ?? '', () {
          setState(() {
            _linhaSelecionada = index;
            preencherCampos(data);
          });
        }),
        _buildEditableCell(priceToString(data.apostillevalue), () {
          setState(() {
            _linhaSelecionada = index;
            preencherCampos(data);
          });
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.apostilledata!), () {
          setState(() {
            _linhaSelecionada = index;
            preencherCampos(data);
          });
        }),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // deletar
              },
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildEditableCell(String? text, VoidCallback onTap) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text ?? '',
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

