import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_datas/apostilles/apostilles_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_widgets/charts/bar_chart_sample.dart';
import '../../../../_widgets/charts/pie_chart_sample.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';

class AdditivePage extends StatefulWidget {
  const AdditivePage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> {
  late ContractsBloc _contractsBloc;
  late Future<List<AdditiveData>> _futureAdditives;
  late AdditiveData _additiveData;
  bool _isSaving = false;
  int? _linhaSelecionada;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();
  final _validityContractController = TextEditingController();
  final _typeOfAdditiveCtrl = TextEditingController();

  String? _currentAdditiveId;
  bool _modoEdicao = false;
  bool _formValido = false;
  final _dateFormatter = MaskTextInputFormatter(mask: '##/##/####');
  final AdditiveData additiveData = AdditiveData();

  final List<String> _typeOfAdditive = [
    'VALOR',
    'PRAZO',
    'REEQUILÍBRIO'
  ];

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    //final status = additiveData.typeOfAdditive!.toUpperCase().trim();
    //_typeOfAdditiveCtrl.text = _typeOfAdditive.contains(status) ? status! : '';

    _futureAdditives = widget.contractData?.id != null
        ? _contractsBloc.getAllAdditivesOfContract(uidContract: widget.contractData!.id!)
        : Future.value([]);

    _definirProximaOrdem();

    _dateController.addListener(_validarFormulario);
    _valueController.addListener(_validarFormulario);
    _processController.addListener(_validarFormulario);
    _validityContractController.addListener(_validarFormulario);
  }

  void _validarFormulario() {
    final valido = _dateController.text.isNotEmpty &&
        _valueController.text.isNotEmpty &&
        _processController.text.isNotEmpty &&
        _validityContractController.text.isNotEmpty;

    setState(() => _formValido = valido);
  }

  void preencherCampos(AdditiveData data) {
    setState(() {
      _modoEdicao = true;
      _currentAdditiveId = data.uid;
      _typeOfAdditiveCtrl.text = data.typeOfAdditive ?? '';
      _orderController.text = data.additiveorder?.toString() ?? '';
      _dateController.text = data.additivedata != null ? convertDateTimeToDDMMYYYY(data.additivedata!) : '';
      _valueController.text = priceToString(data.additivevalue);
      _processController.text = data.additivenumberprocess ?? '';
      _validityContractController.text = data.additivevaliditycontractdata != null
          ? convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata!)
          : '';
    });
  }

  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 12; // mesmo valor usado no Wrap
    const margin = 12;

    if (screenWidth < 600) {
      return screenWidth - margin - 32; // 1 por linha
    } else if (screenWidth < 1000) {
      return (screenWidth - spacing - margin * 1 - 32) / 2; // 2 por linha
    } else {
      return (screenWidth - spacing - margin * 2 - 32) / 3; // 3 por linha
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
    children: [
        FutureBuilder<List<AdditiveData>>(
          future: _futureAdditives,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }else if(!snapshot.hasData || snapshot.data!.isEmpty){
              return Center(child: Text('Nenhum aditivo encontrado'));
            }


            final additives = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCampos(),
                  SizedBox(height: 12),
                  const Text('Gráfico dos aditivos', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double larguraDisponivel = constraints.maxWidth;
                      const double larguraGraficoPizza = 300;
                      const double espacamento = 100;

                      final double larguraGraficoBarras = math.max(
                        larguraDisponivel - larguraGraficoPizza - espacamento,
                        300, // largura mínima segura
                      );
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            PieChartSample(
                              additives: additives,
                              selectedIndex: _linhaSelecionada,
                              larguraGrafico: larguraGraficoPizza,
                              onTouch: (index) {
                                setState(() {
                                  _linhaSelecionada = index;
                                  if (index != null && index >= 0 && index < additives.length) {
                                    preencherCampos(additives[index]);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            BarChartSample(
                              additives: additives,
                              selectedIndex: _linhaSelecionada,
                              larguraGrafico: larguraGraficoBarras,
                              onBarTap: (index) {
                                setState(() {
                                  _linhaSelecionada = index;
                                  if (index >= 0 && index < additives.length) {
                                    preencherCampos(additives[index]);
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
                  const Text('Aditivos cadastrados no sistema', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 12),
                  _buildTabela(additives),
                ],
              ),
            );
          },
        ),
      if (_isSaving)
        Stack(
          children: [
            ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ],
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
                    message: 'Este campo é calculado automaticamente e não pode ser editado.',
                    child: CustomTextField(
                      labelText: 'Ordem do aditivo',
                      controller: _orderController,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                        labelText: 'Data do aditivo',
                        controller: _dateController,
                      inputFormatters: [_dateFormatter],
                      keyboardType: TextInputType.datetime,
                    )),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                    labelText: 'Data da vigência do aditivo',
                    controller: _validityContractController,
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
                        labelText: 'Processo do Aditivo',
                        controller: _processController,
                      inputFormatters: [processoMaskFormatter],
                      keyboardType: TextInputType.number,
                    )),
                SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                  labelText: 'Valor do aditivo',
                  controller: _valueController,
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
                  child: DropDownButtonChange(
                    labelText: 'Tipo de Aditivo',
                    items: _typeOfAdditive,
                    controller: _typeOfAdditiveCtrl,
                    onChanged: (value) => _additiveData.typeOfAdditive = value ?? '',
                  ),
                ),
              ]
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _formValido ? _salvarOuAtualizarAditivo : null,
                  icon: Icon(Icons.save),
                  label: Text(_modoEdicao ? 'Atualizar' : 'Salvar'), // Corrigido
                ),
                const SizedBox(width: 12),
                if (_modoEdicao)
                  TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Limpar'),
                    onPressed: _criarNovoAditivo,
                  ),
              ],
            )

          ],
        ),
      ),
    );
  }

  Future<void> _definirProximaOrdem() async {
    if (widget.contractData?.id == null) return;

    final lista = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.id!,
    );

    final ultimaOrdem = lista.map((e) => e.additiveorder ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _orderController.text = (ultimaOrdem + 1).toString();
    });
  }

  void _criarNovoAditivo() async {
    if (widget.contractData?.id == null) return;

    final lista = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.id!,
    );

    final ultimaOrdem = lista.map((e) => e.additiveorder ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _modoEdicao = false;
      _currentAdditiveId = null;
      _orderController.text = (ultimaOrdem + 1).toString();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
      _validityContractController.clear();
      _typeOfAdditiveCtrl.clear(); // <- Adicionado
    });
  }



  Future<void> _salvarOuAtualizarAditivo() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(_modoEdicao
            ? 'Deseja atualizar este aditivo?'
            : 'Deseja salvar um novo aditivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    final novo = AdditiveData(
      uid: _currentAdditiveId,
      additivenumberprocess: _processController.text,
      additiveorder: int.tryParse(_orderController.text),
      additivevaliditycontractdata: convertDDMMYYYYToDateTime(_validityContractController.text),
      additivedata: convertDDMMYYYYToDateTime(_dateController.text),
      additivevalue: stringToDouble(_valueController.text),
      typeOfAdditive: _typeOfAdditiveCtrl.text,
    );

    await _contractsBloc.salvarOuAtualizarAditivo(novo, widget.contractData!.id!);

    setState(() {
      _futureAdditives = _contractsBloc.getAllAdditivesOfContract(
        uidContract: widget.contractData!.id!,
      );
      _currentAdditiveId = null;
      _modoEdicao = false;
      _orderController.clear();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
      _validityContractController.clear();
      _typeOfAdditiveCtrl.clear();
      _isSaving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_modoEdicao ? 'Aditivo atualizado com sucesso!' : 'Aditivo salvo com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTabela(List<AdditiveData> additives) {

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(70), // ORDEM
                1: FixedColumnWidth(200), // Nº PROCESSO
                2: FixedColumnWidth(140), // VALOR
                3: FixedColumnWidth(120), // VIGÊNCIA INICIAL
                4: FixedColumnWidth(120), // VIGÊNCIA PÓS
                5: FixedColumnWidth(120), // DATA EXECUÇÃO
                6: FixedColumnWidth(120), // DIAS EXECUÇÃO
                7: FixedColumnWidth(80),  // APAGAR
              },
              children: [
                _buildHeaderRow(),
                ...additives.map((data) => _buildDataRow(data, additives)),
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
      'VALOR DO ADITIVO',
      'VIGÊNCIA INICIAL',
      'VIGÊNCIA PÓS ADITIVO',
      'DIAS DO ADITIVO',
      'DIAS DE VALIDADE',
      'APAGAR',
    ];
    return TableRow(
      decoration: const BoxDecoration(color: Color.fromRGBO(0, 200, 255, 0.3)),
      children: headers.map((title) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
              textAlign: TextAlign.center, // Alinhamento horizontal
              title, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(AdditiveData data, List<AdditiveData> additives) {
    final index = additives.indexOf(data);
    final isSelected = index == _linhaSelecionada;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.additiveorder.toString(), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(data.additivenumberprocess ?? '', (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(priceToString(data.additivevalue), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivedata), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevalidityexecutiondata), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        _buildEditableCell(data.additivevalidityexecutiondays.toString(), (){
          _linhaSelecionada = index;
          preencherCampos(data);
        }),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletarAditivo(data.uid!),
            ),
          ),
        ),
      ],
    );
  }

  void _deletarAditivo(String uidAditivo) async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente apagar este aditivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _contractsBloc.deletarAditivo(widget.contractData!.id!, uidAditivo);

    setState(() {
      _futureAdditives = _contractsBloc.getAllAdditivesOfContract(
        uidContract: widget.contractData!.id!,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aditivo deletado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
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
          ),
        ),
      ),
    );
  }
}

