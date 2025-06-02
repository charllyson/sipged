import 'package:flutter/material.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../_blocs/measurement/measurement_bloc.dart';
import '../../../_datas/contracts/contracts_data.dart';
import '../../../_datas/measurement/measurement_data.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../contractDetails.dart';

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
    _initialValueController.text = priceToString(data.measurementinitialvalue)!;
    _adjustmentValueController.text = priceToString(data.measurementadjustmentvalue)!;
    _revisionValueController.text = priceToString(data.measurementvaluerevisionsadjustments)!;
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
        }

        final measurements = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCampos(),
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              CustomTextField(labelText: 'Ordem da medição', controller: _orderController),
              CustomTextField(labelText: 'Data da medição', controller: _dateController),
              CustomTextField(labelText: 'Valor da medição', controller: _initialValueController),
              CustomTextField(labelText: 'Valor do reajuste', controller: _adjustmentValueController),
              CustomTextField(labelText: 'Valor da revisão', controller: _revisionValueController),
              CustomTextField(labelText: 'Data do reajuste', controller: _adjustmentDateController),
              CustomTextField(labelText: 'Nº processo', controller: _processNumberController),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // salvar
            },
            icon: const Icon(Icons.save),
            label: const Text('Salvar medição'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela(List<MeasurementData> measurements) {
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
            4: FixedColumnWidth(180),
            5: FixedColumnWidth(180),
            6: FixedColumnWidth(180),
            7: FixedColumnWidth(80),
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
          padding: const EdgeInsets.all(8),
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        );
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
