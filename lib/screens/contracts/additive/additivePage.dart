import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _futureAdditives = widget.contractData?.uid != null
        ? _contractsBloc.getAllAdditivesOfContract(uidContract: widget.contractData!.uid!)
        : Future.value([]);
  }

  void preencherCampos(AdditiveData data) {
    _orderController.text = data.additiveorder?.toString() ?? '';
    _dateController.text = data.additivedata != null ? convertDateTimeToDDMMYYYY(data.additivedata!) : '';
    _valueController.text = priceToString(data.additivevalue)!;
    _processController.text = data.additivenumberprocess ?? '';
    _validityContractController.text =
    data.additivevaliditycontractdata != null ? convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata!) : '';
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomTextField(labelText: 'Ordem do aditivo', controller: _orderController),
              CustomTextField(labelText: 'Data do aditivo', controller: _dateController),
              CustomTextField(labelText: 'Valor do aditivo', controller: _valueController),
              CustomTextField(labelText: 'Valor do reajuste', controller: _processController),
              CustomTextField(labelText: 'Valor da revisão', controller: _validityContractController),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // salvar
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar aditivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela(List<AdditiveData> additives) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FixedColumnWidth(180),
            2: FixedColumnWidth(180),
            3: FixedColumnWidth(150),
            4: FixedColumnWidth(150),
            5: FixedColumnWidth(130),
            6: FixedColumnWidth(130),
            7: FixedColumnWidth(80),
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

