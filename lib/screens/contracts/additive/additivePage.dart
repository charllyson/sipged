import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:flutter_multi_formatter/formatters/money_input_formatter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../_blocs/measurement/measurement_bloc.dart';
import '../../../_datas/contracts/contracts_data.dart';
import '../../../_datas/measurement/measurement_data.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../contractDetails.dart';

class AdditivePage extends StatefulWidget {
  const AdditivePage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> {
  late ContractsBloc _contractsBloc;
  late Future<List<AdditiveData>> _futureAdditives;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();
  final _validityContractController = TextEditingController();
  String? _currentAdditiveId;
  bool _modoEdicao = false;
  bool _formValido = false;
  final _dateFormatter = MaskTextInputFormatter(mask: '##/##/####');

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _futureAdditives = widget.contractData?.uid != null
        ? _contractsBloc.getAllAdditivesOfContract(uidContract: widget.contractData!.uid!)
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

      _orderController.text = data.additiveorder?.toString() ?? '';
      _dateController.text = data.additivedata != null ? convertDateTimeToDDMMYYYY(data.additivedata!) : '';
      _valueController.text = priceToString(data.additivevalue)!;
      _processController.text = data.additivenumberprocess ?? '';
      _validityContractController.text = data.additivevaliditycontractdata != null
          ? convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata!)
          : '';
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdditiveData>>(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCampos(),
              const SizedBox(height: 24),
              const Text('Aditivos cadastrados no sistema', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 12),
              _buildTabela(additives),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Este campo é calculado automaticamente e não pode ser editado.',
                  child: CustomTextField(
                    labelText: 'Ordem do aditivo',
                    controller: _orderController,
                    enabled: false,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      labelText: 'Data do aditivo',
                      controller: _dateController,
                    inputFormatters: [_dateFormatter],
                    keyboardType: TextInputType.datetime,
                  )),
              SizedBox(width: 12),
              Expanded(child:
              CustomTextField(
                  labelText: 'Data da vigência do aditivo',
                  controller: _validityContractController,
                inputFormatters: [_dateFormatter],
                keyboardType: TextInputType.datetime,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CustomTextField(labelText: 'Processo do Aditivo', controller: _processController)),
              SizedBox(width: 12),
              Expanded(child: CustomTextField(
                labelText: 'Valor do aditivo',
                controller: _valueController,
                inputFormatters: [MoneyInputFormatter(
                  leadingSymbol: 'R\$',
                  thousandSeparator: ThousandSeparator.Period,
                  useSymbolPadding: true,
                )],
                keyboardType: TextInputType.number,
              )),

            ]
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _formValido ? _salvarOuAtualizarAditivo : null,
                icon: const Icon(Icons.save),
                label: Text(_modoEdicao ? 'Atualizar aditivo' : 'Salvar aditivo'),
              ),
              const SizedBox(width: 12),
              if (_modoEdicao)
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar novo aditivo'),
                  onPressed: _criarNovoAditivo,
                ),
            ],
          )

        ],
      ),
    );
  }

  Future<void> _definirProximaOrdem() async {
    if (widget.contractData?.uid == null) return;

    final lista = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.uid!,
    );

    final ultimaOrdem = lista.map((e) => e.additiveorder ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _orderController.text = (ultimaOrdem + 1).toString();
    });
  }

  void _criarNovoAditivo() async {
    if (widget.contractData?.uid == null) return;

    final lista = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.uid!,
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
    });
  }



  Future<void> _salvarOuAtualizarAditivo() async {
    if (widget.contractData?.uid == null) return;

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

    final novo = AdditiveData(
      uid: _currentAdditiveId, // null = novo, preenchido = edição
      additivenumberprocess: _processController.text,
      additiveorder: int.tryParse(_orderController.text),
      additivevaliditycontractdata: convertDDMMYYYYToDateTime(_validityContractController.text),
      additivedata: convertDDMMYYYYToDateTime(_dateController.text),
      additivevalue: stringToDouble(_valueController.text),
    );

    await _contractsBloc.salvarOuAtualizarAditivo(novo, widget.contractData!.uid!);

    setState(() {
      _futureAdditives = _contractsBloc.getAllAdditivesOfContract(
        uidContract: widget.contractData!.uid!,
      );
      _currentAdditiveId = null;
      _modoEdicao = false;
      _orderController.clear();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
      _validityContractController.clear();
    });

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
        final larguraTotal = constraints.maxWidth;
        final col0 = larguraTotal * 0.1;
        final col1 = larguraTotal * 0.195;
        final col2 = larguraTotal * 0.195;
        final col3 = larguraTotal * 0.1;
        final col4 = larguraTotal * 0.1;
        final col5 = larguraTotal * 0.1;
        final col6 = larguraTotal * 0.1;
        final col7 = larguraTotal * 0.1;
        return SingleChildScrollView(
          child: Center(
            child: Table(
              columnWidths: {
                0: FixedColumnWidth(col0),
                1: FixedColumnWidth(col1),
                2: FixedColumnWidth(col2),
                3: FixedColumnWidth(col3),
                4: FixedColumnWidth(col4),
                5: FixedColumnWidth(col5),
                6: FixedColumnWidth(col6),
                7: FixedColumnWidth(col7),
              },
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                _buildHeaderRow(),
                ...additives.map((data) => _buildDataRow(data)),
              ],
            ),
          ),
        );
      }
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
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(AdditiveData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildEditableCell(data.additiveorder.toString(), () => preencherCampos(data)),
        _buildEditableCell(data.additivenumberprocess ?? '', () => preencherCampos(data)),
        _buildEditableCell(priceToString(data.additivevalue), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivedata!), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata!), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevalidityexecutiondata!), () => preencherCampos(data)),
        _buildEditableCell(data.additivevalidityexecutiondays.toString(), () => preencherCampos(data)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // ação de deletar
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
          ),
        ),
      ),
    );
  }
}

