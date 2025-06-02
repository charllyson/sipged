import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../_widgets/input/custom_text_field.dart';

class ValidityPage extends StatefulWidget {
  const ValidityPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ValidityPage> createState() => _ValidityPageState();
}

class _ValidityPageState extends State<ValidityPage> {
  late ContractsBloc _contractsBloc;
  late Future<List<ValidityData>> _futureValidity;

  final _ordemCtrl = TextEditingController();
  final _tipoOrdemCtrl = TextEditingController();
  final _dataOrdemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    if (widget.contractData?.uid != null) {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.uid!,
      );
    } else {
      _futureValidity = Future.value([]);
    }
  }

  void preencherCampos(ValidityData data) {
    setState(() {
      _ordemCtrl.text = data.ordernumber.toString();
      _tipoOrdemCtrl.text = data.ordertype ?? '';
      _dataOrdemCtrl.text = convertDateTimeToDDMMYYYY(data.orderdate!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<ValidityData>>(
          future: _futureValidity,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados: \${snapshot.error}'));
            }
            final list = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCamposFormulario(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Ordens cadastradas no sistema', style: TextStyle(fontSize: 20)),
                ),
                _buildTabela(list),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCamposFormulario() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                CustomTextField(labelText: 'Ordem', controller: _ordemCtrl),
                CustomTextField(labelText: 'Tipo da ordem', controller: _tipoOrdemCtrl),
                CustomTextField(labelText: 'Data da ordem', controller: _dataOrdemCtrl),
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
      ),
    );
  }

  Widget _buildTabela(List<ValidityData> list) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(100),
          1: FixedColumnWidth(250),
          2: FixedColumnWidth(200),
          3: FixedColumnWidth(100),
        },
        border: TableBorder.all(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade300,
        ),
        children: [
          _buildHeaderRow(),
          ...list.map((data) => _buildDataRow(data)),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    const headers = ['ORDEM', 'TIPO DA ORDEM', 'DATA DA ORDEM', 'APAGAR'];
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

  TableRow _buildDataRow(ValidityData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildCell(data.ordernumber.toString(), () => preencherCampos(data)),
        _buildCell(data.ordertype ?? '', () => preencherCampos(data)),
        _buildCell(convertDateTimeToDDMMYYYY(data.orderdate!), () => preencherCampos(data)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(String? text, VoidCallback onTap) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }
}


