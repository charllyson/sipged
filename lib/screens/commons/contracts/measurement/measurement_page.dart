import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/measurement/measurement_bloc.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/measurement/measurement_data.dart';
import '../../../../_widgets/charts/line_chart_sample_class.dart';
import '../../../../_widgets/charts/pie_chart_sample.dart';
import '../../../../_widgets/input/custom_text_field.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  late MeasurementBloc _measurementBloc;
  late Future<List<MeasurementData>> _futureMeasurements;
  int? _linhaSelecionada;
  String? _currentMeasurementId;
  final _dateFormatter = MaskTextInputFormatter(mask: '##/##/####');

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _initialValueController = TextEditingController();
  final _adjustmentValueController = TextEditingController();
  final _revisionValueController = TextEditingController();
  final _processNumberController = TextEditingController();
  final _adjustmentDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _measurementBloc = MeasurementBloc();
    if (widget.contractData?.id != null) {
      _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        if (list.isNotEmpty) {
          final ultimaOrdem = list.map((e) => e.measurementorder ?? 0).reduce((a, b) => a > b ? a : b);
          _orderController.text = (ultimaOrdem + 1).toString();
        } else {
          _orderController.text = '1';
        }
        return list;
      });
    } else {
      _futureMeasurements = Future.value([]);
    }
  }

  void preencherCampos(MeasurementData data) {
    setState(() {
      _currentMeasurementId = data.uidMeasurement;
      _orderController.text = data.measurementorder.toString();
      _dateController.text = convertDateTimeToDDMMYYYY(data.measurementdata!);
      _initialValueController.text = priceToString(data.measurementinitialvalue);
      _adjustmentValueController.text = priceToString(data.measurementadjustmentvalue);
      _revisionValueController.text = priceToString(data.measurementvaluerevisionsadjustments);
      _processNumberController.text = data.measurementnumberprocess ?? '';
      _adjustmentDateController.text = convertDateTimeToDDMMYYYY(data.measurementadjustmentdate!);
    });
  }

  bool get _formularioValido {
    return _orderController.text.isNotEmpty &&
        _dateController.text.length == 10 &&
        _initialValueController.text.isNotEmpty &&
        _adjustmentValueController.text.isNotEmpty &&
        _revisionValueController.text.isNotEmpty &&
        _adjustmentDateController.text.length == 10;
  }

  void _criarNovaMedicao(List<MeasurementData> list) {
    final ultimaOrdem = list.map((e) => e.measurementorder ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _linhaSelecionada = null;
      _orderController.text = (ultimaOrdem + 1).toString();
      _dateController.clear();
      _initialValueController.clear();
      _adjustmentValueController.clear();
      _revisionValueController.clear();
      _processNumberController.clear();
      _adjustmentDateController.clear();
    });
  }

  void _salvarMedicao() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja salvar esta medição?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    final novaMedicao = MeasurementData(
      uidMeasurement: widget.contractData!.id,
      measurementorder: int.tryParse(_orderController.text),
      measurementnumberprocess: _processNumberController.text,
      measurementinitialvalue: parseCurrencyToDouble(_initialValueController.text),
      measurementdata: convertDDMMYYYYToDateTime(_dateController.text),
      measurementadjustmentvalue: parseCurrencyToDouble(_adjustmentValueController.text),
      measurementadjustmentdate: convertDDMMYYYYToDateTime(_adjustmentDateController.text),
      measurementvaluerevisionsadjustments: parseCurrencyToDouble(_revisionValueController.text),
    );

    await _measurementBloc.salvarOuAtualizarMedicao(novaMedicao);

    setState(() {
      _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        _criarNovaMedicao(list);
        return list;
      });
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medição salva com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }


  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 18;
    const margin = 12;
    const horizontalPadding = 32.0; // somando os dois lados (Padding 16 + 16)

    if (screenWidth < 600) {
      return screenWidth - margin * 2 - horizontalPadding; // 1 por linha
    } else if (screenWidth < 900) {
      return (screenWidth - margin * 2 - spacing * 1 - horizontalPadding) / 2; // 2 por linha
    } else if (screenWidth < 1300) {
      return (screenWidth - margin * 2 - spacing * 2 - horizontalPadding) / 3; // 3 por linha
    } else {
      return (screenWidth - margin * 2 - spacing * 3 - horizontalPadding) / 4; // 4 por linha
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MeasurementData>>(
      future: _futureMeasurements,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: \${snapshot.error}'));
        }else if(!snapshot.hasData || snapshot.data!.isEmpty){
          return Center(child: Text('Nenhuma medição encontrada'));
        }

        final measurements = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCampos(),
              SizedBox(height: 12),
              const Text('Gráfico das medições cadastradas no sistema', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              LayoutBuilder(
                  builder: (context, constraints) {
                    final double larguraDisponivel = constraints.maxWidth;
                    const double larguraGraficoPizza = 300;
                    const double espacamento = 26;

                    final double larguraGraficoLinha = math.max(
                      larguraDisponivel - larguraGraficoPizza - espacamento - espacamento, 300, // largura mínima segura
                    );
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          PieChartSample(
                            measurements: measurements,
                            selectedIndex: _linhaSelecionada,
                            larguraGrafico: larguraGraficoPizza,
                            onTouch: (index) {
                              setState(() {
                                _linhaSelecionada = index;
                                if (index != null && index >= 0 && index < measurements.length) {
                                  preencherCampos(measurements[index]);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          LineChartSample(
                            measurements: measurements,
                            selectedIndex: _linhaSelecionada,
                            larguraGraficoLinha: larguraGraficoLinha,
                            onPointTap: (index) {
                              setState(() {
                                _linhaSelecionada = index;
                                if (index >= 0 && index < measurements.length) {
                                  preencherCampos(measurements[index]);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                }
              ),
              const SizedBox(height: 24),
              const Text('Medições cadastradas no sistema', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              _buildTabela(measurements),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormCampos() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
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
                    message: 'Este campo é calculado automaticamente e não pode ser editado.',
                    child: CustomTextField(
                        labelText: 'Ordem da medição',
                        controller: _orderController,
                        enabled: false,
                    ),
                  )),
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Nº processo',
                      controller: _processNumberController,
                    inputFormatters: [processoMaskFormatter],
                    keyboardType: TextInputType.number,
                  )),
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Valor da medição',
                      controller: _initialValueController,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: 'R\$',
                        useSymbolPadding: true,
                        thousandSeparator: ThousandSeparator.Period,
                        mantissaLength: 2,
                      ),
                    ],
                    keyboardType: TextInputType.number,
                  )),
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Data da medição',
                      controller: _dateController,
                    inputFormatters: [_dateFormatter],
                    keyboardType: TextInputType.datetime,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Valor do reajuste',
                      controller: _adjustmentValueController,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: 'R\$',
                        useSymbolPadding: true,
                        thousandSeparator: ThousandSeparator.Period,
                        mantissaLength: 2,
                      ),
                    ],
                    keyboardType: TextInputType.number,
                  )),
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Data do reajuste',
                      controller: _adjustmentDateController,
                    inputFormatters: [_dateFormatter],
                    keyboardType: TextInputType.datetime,
                  )),
              SizedBox(
                  width: getResponsiveWidth(context),
                  child: CustomTextField(
                      labelText: 'Valor da revisão',
                      controller: _revisionValueController,
                    inputFormatters: [
                      CurrencyInputFormatter(
                        leadingSymbol: 'R\$',
                        useSymbolPadding: true,
                        thousandSeparator: ThousandSeparator.Period,
                        mantissaLength: 2,
                      ),
                    ],
                    keyboardType: TextInputType.number,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_currentMeasurementId != null)
                TextButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Limpar'),
                  onPressed: () async {
                    final list = await _futureMeasurements;
                    _criarNovaMedicao(list);
                  },
                ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_currentMeasurementId != null ? 'Atualizar' : 'Salvar'),
                onPressed: _formularioValido ? _salvarMedicao : null,
              ),
            ],
          )
        ],
      ),
    );
  }

  double? parseCurrencyToDouble(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.'));
  }

  Widget _buildTabela(List<MeasurementData> measurements) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(100), // ORDEM
                1: FixedColumnWidth(180), // Nº PROCESSO
                2: FixedColumnWidth(160), // VALOR MEDIÇÃO
                3: FixedColumnWidth(140), // DATA MEDIÇÃO
                4: FixedColumnWidth(160), // VALOR REAJUSTE
                5: FixedColumnWidth(140), // DATA REAJUSTE
                6: FixedColumnWidth(160), // VALOR REVISÃO
                7: FixedColumnWidth(80),  // APAGAR
              },
              children: [
                _buildHeaderRow(),
                ...measurements.map((data) => _buildDataRow(data, measurements)),
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
      'VALOR MEDIÇÃO',
      'DATA MEDIÇÃO',
      'VALOR REAJUSTE',
      'DATA REAJUSTE',
      'VALOR REVISÃO',
      'APAGAR'
    ];
    return TableRow(
      decoration: const BoxDecoration(color: Color.fromRGBO(0, 200, 255, 0.3)),
      children: headers.map((title) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(MeasurementData data, List<MeasurementData> measurements) {
    final index = measurements.indexOf(data);
    final isSelected = data.measurementorder == (_linhaSelecionada != null ? _linhaSelecionada! + 1 : -1);

    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.measurementorder.toString(), () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(data.measurementnumberprocess ?? '', () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementinitialvalue), () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementdata!), () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementadjustmentvalue), () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementadjustmentdate!), () => preencherCampos(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementvaluerevisionsadjustments), () => preencherCampos(data), index: index, measurements: measurements),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (widget.contractData?.id == null || data.uidMeasurement == null) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmação'),
                    content: const Text('Deseja apagar esta medição?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
                    ],
                  ),
                );

                if (confirm != true) return;

                await _measurementBloc.deletarMedicao(widget.contractData!.id!, data.uidMeasurement!);

                setState(() {
                  _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
                    uidContract: widget.contractData!.id!,
                  );
                  _linhaSelecionada = null;
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medição apagada com sucesso.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },

            ),
          ),
        ),
      ],
    );
  }


  Widget _buildEditableCell(String? text, VoidCallback onTap, {int? index, List<MeasurementData>? measurements}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: () {
          if (index != null && measurements != null) {
            setState(() {
              _linhaSelecionada = index;
              preencherCampos(measurements[index]);
            });
          }
          onTap();
        },
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
