import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../_blocs/contracts/contracts_bloc.dart';
import '../../../_blocs/measurement/measurement_bloc.dart';
import '../../../_datas/apostilles/apostilles_data.dart';
import '../../../_datas/contracts/contracts_data.dart';
import '../../../_datas/measurement/measurement_data.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../contractDetails.dart';

class ApostillesPage extends StatefulWidget {
  const ApostillesPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> {
  late ContractsBloc _contractsBloc;
  late Future<List<ApostillesData>> _futureApostilles;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    if (widget.contractData?.uid != null) {
      _futureApostilles = _contractsBloc.getAllApostillesOfContract(
        uidContract: widget.contractData!.uid!,
      );
    } else {
      _futureApostilles = Future.value([]);
    }
  }

  void preencherCampos(ApostillesData data) {
    _orderController.text = data.apostilleorder?.toString() ?? '';
    _dateController.text = convertDateTimeToDDMMYYYY(data.apostilledata!);
    _valueController.text = priceToString(data.apostillevalue)!;
    _processController.text = data.apostillenumberprocess ?? '';
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
        }

        final apostilles = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCampos(),
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
              CustomTextField(labelText: 'Ordem do apostilamento', controller: _orderController),
              CustomTextField(labelText: 'Data do apostilamento', controller: _dateController),
              CustomTextField(labelText: 'Valor do apostilamento', controller: _valueController),
              CustomTextField(labelText: 'Nº do processo', controller: _processController),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // salvar
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar apostilamento'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela(List<ApostillesData> apostilles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FixedColumnWidth(200),
            2: FixedColumnWidth(180),
            3: FixedColumnWidth(180),
            4: FixedColumnWidth(80),
          },
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            _buildHeaderRow(),
            ...apostilles.map((data) => _buildDataRow(data)),
          ],
        ),
      ),
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

  TableRow _buildDataRow(ApostillesData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildEditableCell(data.apostilleorder.toString(), () => preencherCampos(data)),
        _buildEditableCell(data.apostillenumberprocess ?? '', () => preencherCampos(data)),
        _buildEditableCell(priceToString(data.apostillevalue), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.apostilledata!), () => preencherCampos(data)),
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
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

