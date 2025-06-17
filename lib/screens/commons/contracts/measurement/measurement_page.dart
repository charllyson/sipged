import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_blocs/measurement/measurement_bloc.dart';
import '../../../../_blocs/user/user_bloc.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/measurement/measurement_data.dart';
import '../../../../_datas/user/user_data.dart';
import '../../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/buttons/deleteButtonPermission.dart';
import '../../../../_widgets/charts/line_chart_sample_class.dart';
import '../../../../_widgets/charts/pie_chart_sample.dart';
import '../../../../_widgets/formats/input_formatters.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> with FormValidationMixin{
  late MeasurementBloc _measurementBloc;
  late UserBloc _userBloc;
  late ContractsBloc _contractsBloc;
  late UserData _currentUser;

  late Future<List<MeasurementData>> _futureMeasurements;

  int? _selectedLine;
  String? _currentMeasurementId;
  bool _formValidated = false;
  bool _isEditable = false;

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
    _userBloc = UserBloc();
    setupValidation([
      _dateController,
      _initialValueController,
      _adjustmentValueController,
      _revisionValueController,
      _processNumberController,
      _adjustmentDateController,
      _orderController
    ], _validateForm);

    final user = Provider.of<UserProvider>(context, listen: false).userData;
    if (user != null) {
      _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
    }
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

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _dateController,
      _initialValueController,
      _adjustmentValueController,
      _revisionValueController,
      _processNumberController,
      _adjustmentDateController,
      _orderController
    ], minLength: 5);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }


  void _fillFields(MeasurementData data) {
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

  void _createNewMeasurement(List<MeasurementData> list) {
    final lastMeasurement = list.map((e) => e.measurementorder ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _selectedLine = null;
      _orderController.text = (lastMeasurement + 1).toString();
      _dateController.clear();
      _initialValueController.clear();
      _adjustmentValueController.clear();
      _revisionValueController.clear();
      _processNumberController.clear();
      _adjustmentDateController.clear();
    });
  }

  void _saveOrUpdateMeasurement() async {
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

    final newMeasurement = MeasurementData(
      uidMeasurement: widget.contractData!.id,
      measurementorder: int.tryParse(_orderController.text),
      measurementnumberprocess: _processNumberController.text,
      measurementinitialvalue: parseCurrencyToDouble(_initialValueController.text),
      measurementdata: convertDDMMYYYYToDateTime(_dateController.text),
      measurementadjustmentvalue: parseCurrencyToDouble(_adjustmentValueController.text),
      measurementadjustmentdate: convertDDMMYYYYToDateTime(_adjustmentDateController.text),
      measurementvaluerevisionsadjustments: parseCurrencyToDouble(_revisionValueController.text),
    );

    await _measurementBloc.saveOrUpdateMeasurement(newMeasurement);

    setState(() {
      _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        _createNewMeasurement(list);
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

  void _deleteMeasurement(String idMeasurement) async {
    if (widget.contractData?.id == null || idMeasurement == null) return;
    await _measurementBloc.deletarMedicao(widget.contractData!.id!, idMeasurement);
    setState(() {
      _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
        uidContract: widget.contractData!.id!,
      );
      _selectedLine = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medição apagada com sucesso.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildFormCampos(),
            FutureBuilder<List<MeasurementData>>(
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                  selectedIndex: _selectedLine,
                                  larguraGrafico: larguraGraficoPizza,
                                  onTouch: (index) {
                                    setState(() {
                                      _selectedLine = index;
                                      if (index != null && index >= 0 && index < measurements.length) {
                                        _fillFields(measurements[index]);
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                LineChartSample(
                                  measurements: measurements,
                                  selectedIndex: _selectedLine,
                                  larguraGraficoLinha: larguraGraficoLinha,
                                  onPointTap: (index) {
                                    setState(() {
                                      _selectedLine = index;
                                      if (index >= 0 && index < measurements.length) {
                                        _fillFields(measurements[index]);
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
                    _buildTable(measurements),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCampos() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nova medição', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: Tooltip(
                    message: 'Este campo é calculado automaticamente e não pode ser editado.',
                    child: CustomTextField(
                        labelText: 'Ordem da medição',
                        controller: _orderController,
                        enabled: false,
                    ),
                  )),
              SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
                      labelText: 'Nº processo',
                      controller: _processNumberController,
                    inputFormatters: [processoMaskFormatter],
                    keyboardType: TextInputType.number,
                  )),
              SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
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
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
                      labelText: 'Data da medição',
                      controller: _dateController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.datetime,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Revisão de medições', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
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
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
                      labelText: 'Data do reajuste',
                      controller: _adjustmentDateController,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.datetime,
                  )),
              SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: CustomTextField(
                    enabled: _isEditable,
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
                    _createNewMeasurement(list);
                  },
                ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_currentMeasurementId != null ? 'Atualizar' : 'Salvar'),
                onPressed: _formValidated ? _isEditable ? _saveOrUpdateMeasurement : null : null,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTable(List<MeasurementData> measurements) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(100),
                1: FixedColumnWidth(180),
                2: FixedColumnWidth(160),
                3: FixedColumnWidth(140),
                4: FixedColumnWidth(160),
                5: FixedColumnWidth(140),
                6: FixedColumnWidth(160),
                7: FixedColumnWidth(80),
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
    final isSelected = data.measurementorder == (_selectedLine != null ? _selectedLine! + 1 : -1);
    final currentUser = Provider.of<UserProvider>(context).userData;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.measurementorder.toString(), () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(data.measurementnumberprocess ?? '', () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementinitialvalue), () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementdata!), () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementadjustmentvalue), () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementadjustmentdate!), () => _fillFields(data), index: index, measurements: measurements),
        _buildEditableCell(priceToString(data.measurementvaluerevisionsadjustments), () => _fillFields(data), index: index, measurements: measurements),
        TableCell(
          child: Stack(
            children: [
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else
                PermissionIconDeleteButton(
                  tooltip: 'Apagar medição?',
                  currentUser: currentUser,
                  showConfirmDialog: true,
                  confirmTitle: 'Confirmar exclusão',
                  confirmContent: 'Deseja apagar esta medição?',
                  hasPermission: (user) => _contractsBloc.knowUserPermissionProfileAdm(
                    userData: user,
                    contract: widget.contractData!,
                  ),
                  onConfirmed: () async {
                    if (widget.contractData!.id != null) {
                      _deleteMeasurement(data.uidMeasurement!);
                    }
                  },
                ),
            ],
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
              _selectedLine = index;
              _fillFields(measurements[index]);
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

  @override
  void dispose() {
    removeValidation([
      _dateController,
      _initialValueController,
      _adjustmentValueController,
      _revisionValueController,
      _processNumberController,
      _adjustmentDateController,
      _orderController
    ], _validateForm);
    super.dispose();
  }

}
