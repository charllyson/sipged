// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../../_blocs/measurement/measurement_bloc.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/measurement/measurement_data.dart';
import '../../../../_widgets/charts/charts_class.dart';
import '../../../../_widgets/charts/line_chart_sample_class.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../contract_details.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  late MeasurementBloc _measurementBloc;
  late Future<List<MeasurementData>> _futureMeasurements;

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
    if (widget.contractData?.uid != null) {
      _futureMeasurements = _measurementBloc.getAllMeasurementsOfContract(
        uidContract: widget.contractData!.uid!,
      );
    } else {
      _futureMeasurements = Future.value([]);
    }
  }

  void preencherCampos(MeasurementData data) {
    _orderController.text = data.measurementorder.toString();
    _dateController.text = convertDateTimeToDDMMYYYY(data.measurementdata!);
    _initialValueController.text = priceToString(data.measurementinitialvalue);
    _adjustmentValueController.text = priceToString(data.measurementadjustmentvalue);
    _revisionValueController.text = priceToString(data.measurementvaluerevisionsadjustments);
    _processNumberController.text = data.measurementnumberprocess ?? '';
    _adjustmentDateController.text = convertDateTimeToDDMMYYYY(data.measurementadjustmentdate!);
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
              Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 200,
                    child: LineChartSample(measurements: measurements),
                  ),
                ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(child: CustomTextField(labelText: 'Ordem da medição', controller: _orderController)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(labelText: 'Nº processo', controller: _processNumberController)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(labelText: 'Valor da medição', controller: _initialValueController)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(labelText: 'Data da medição', controller: _dateController)),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CustomTextField(labelText: 'Valor do reajuste', controller: _adjustmentValueController)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(labelText: 'Data do reajuste', controller: _adjustmentDateController)),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(labelText: 'Valor da revisão', controller: _revisionValueController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  // salvar
                },
                icon: const Icon(Icons.save),
                label: const Text('Salvar medição'),
              ),
            ]
          )
        ],
      ),
    );
  }

  Widget _buildTabela(List<MeasurementData> measurements) {
    return LayoutBuilder(
      builder: (context, constrains) {
        final larguraTotal = constrains.maxWidth;
        final col0 = larguraTotal * 0.1;
        final col1 = larguraTotal * 0.2;
        final col2 = larguraTotal * 0.19;
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
                ...measurements.map((data) => _buildDataRow(data)),
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
        return Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));
      }).toList(),
    );
  }

  TableRow _buildDataRow(MeasurementData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildEditableCell(data.measurementorder.toString(), () => preencherCampos(data)),
        _buildEditableCell(data.measurementnumberprocess ?? '', () => preencherCampos(data)),
        _buildEditableCell(priceToString(data.measurementinitialvalue), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementdata!), () => preencherCampos(data)),
        _buildEditableCell(priceToString(data.measurementadjustmentvalue), () => preencherCampos(data)),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.measurementadjustmentdate!), () => preencherCampos(data)),
        _buildEditableCell(priceToString(data.measurementvaluerevisionsadjustments), () => preencherCampos(data)),
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
