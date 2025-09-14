import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';
import 'package:siged/_services/pdf/web_pdf_controller.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';

import 'package:siged/_services/pdf/web_pdf_widget.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';

import 'measurement_budget_page.dart';

class ReportMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;

  // 👇 agora com nomes de REPORT
  final ReportMeasurementData? selectedReportMeasurement;
  final String? currentReportMeasurementId;

  final ContractData contractData;
  final ReportMeasurementStorageBloc reportMeasurementStorageBloc;

  final TextEditingController orderController;
  final TextEditingController processNumberController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  const ReportMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedReportMeasurement,
    required this.currentReportMeasurementId,
    required this.contractData,
    required this.reportMeasurementStorageBloc,
    required this.orderController,
    required this.processNumberController,
    required this.dateController,
    required this.valueController,
    required this.onSave,
    required this.onClear,
  });

  // helper p/ formato BR (sua lib exige String)
  String currencyBR(num v) => toCurrencyString(
    v.toString(),
    leadingSymbol: 'R\$ ',
    useSymbolPadding: true,
    thousandSeparator: ThousandSeparator.Period,
    mantissaLength: 2,
  );

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(
      BuildContext context,
      TextEditingController controller,
      String label, {
        bool enabled = true,
        bool tooltip = false,
        bool money = false,
        bool date = false,
        List<TextInputFormatter>? mask,
      }) {
    List<TextInputFormatter> formatters = [];

    if (money) {
      formatters = [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$ ',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ];
    } else if (date) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly,
        TextInputMask(mask: '99/99/9999'),
      ];
    } else if (mask != null) {
      formatters = mask;
    }

    final textField = CustomTextField(
      width: getInputWidth(context),
      enabled: enabled,
      labelText: label,
      controller: controller,
      keyboardType: money
          ? TextInputType.number
          : (date ? TextInputType.datetime : TextInputType.text),
      inputFormatters: formatters,
    );

    if (tooltip) {
      return Tooltip(
        message: 'Este campo é calculado automaticamente.',
        child: textField,
      );
    }
    return textField;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(
              context,
              orderController,
              'Ordem da medição',
              enabled: false,
              tooltip: true,
            ),
            _input(
              context,
              processNumberController,
              'Nº processo da medição',
              enabled: isEditable,
              mask: [processoMaskFormatter],
            ),
            CustomDateField(
              width: getInputWidth(context),
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedReportMeasurement?.date,
              labelText: 'Data da Medição',
              onChanged: (date) {
                if (selectedReportMeasurement != null) {
                  selectedReportMeasurement!.date = date;
                }
              },
            ),
            _input(
              context,
              valueController,
              'Valor da medição',
              enabled: isEditable,
              money: true,
            ),
            // Botão para abrir o modal de detalhamento
            SizedBox(
              width: getInputWidth(context),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Detalhar medição'),
                  onPressed: isEditable ? () => _openDetalhamentoModal(context) : null,
                ),
              ),
            ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(currentReportMeasurementId != null ? 'Atualizar' : 'Salvar'),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentReportMeasurementId != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: onClear,
              ),
          ],
        );

        final corpo = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            camposWrap,
            const SizedBox(height: 12),
            botoes,
          ],
        );

        final leftPdf = (currentReportMeasurementId != null && selectedReportMeasurement != null)
            ? _buildPdfWidget()
            : const SizedBox();

        final container = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftPdf,
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftPdf,
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );

        return container;
      },
    );
  }

  void _openDetalhamentoModal(BuildContext context) async {
    await Navigator.of(context).push<MeasurementBudgetPage>(
      MaterialPageRoute(
        builder: (_) => MeasurementBudgetPage(
          contractData: contractData,
        ),
        fullscreenDialog: true, // opcional: efeito de "página de edição"
      ),
    );
  }


  Widget _buildPdfWidget() {
    return WebPdfWidgetGeneric(
      key: Key(currentReportMeasurementId!), // 👈 usa o ID de report
      type: PDFType.report, // 👈 tipo de report
      contractData: contractData,
      specificData: selectedReportMeasurement!, // 👈 objeto de report
      reportMeasurementStorageBloc: reportMeasurementStorageBloc,
    );
  }
}
