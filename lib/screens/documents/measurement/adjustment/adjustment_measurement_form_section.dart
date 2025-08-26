import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_utils/mask_class.dart';

import 'package:sisged/_widgets/archives/pdf/web_pdf_widget.dart';
import 'package:sisged/_utils/formats/input_formatters.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:sisged/_widgets/archives/pdf/web_pdf_controller.dart';

class AdjustmentMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final ReportMeasurementData? selectedAdjustmentMeasurement;
  final String? currentAdjustmentMeasurementId;
  final ContractData contractData;

  final TextEditingController orderAdjustmentController;
  final TextEditingController processNumberAdjustmentController;
  final TextEditingController dateAdjustmentController;
  final TextEditingController valueAdjustmentController;

  final VoidCallback onSave;
  final VoidCallback onClear; // ✅ agora é VoidCallback

  const AdjustmentMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedAdjustmentMeasurement,
    required this.currentAdjustmentMeasurementId,
    required this.contractData,
    required this.orderAdjustmentController,
    required this.processNumberAdjustmentController,
    required this.dateAdjustmentController,
    required this.valueAdjustmentController,
    required this.onSave,
    required this.onClear, // ✅
  });

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
              orderAdjustmentController,
              'Ordem da medição',
              enabled: false,
              tooltip: true,
            ),
            _input(
              context,
              processNumberAdjustmentController,
              'Nº processo da medição',
              enabled: isEditable, // ✅ respeita permissão
              mask: [processoMaskFormatter],
            ),
            CustomDateField(
              width: getInputWidth(context),
              enabled: isEditable, // ✅ respeita permissão
              controller: dateAdjustmentController,
              initialValue: selectedAdjustmentMeasurement?.dateAdjustmentMeasurement,
              labelText: 'Data da Medição',
              onChanged: (date) {
                if (selectedAdjustmentMeasurement != null) {
                  selectedAdjustmentMeasurement!.dateAdjustmentMeasurement = date;
                }
              },
            ),
            _input(
              context,
              valueAdjustmentController,
              'Valor da medição',
              enabled: isEditable, // ✅ respeita permissão
              money: true,
            ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(currentAdjustmentMeasurementId != null ? 'Atualizar' : 'Salvar'),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentAdjustmentMeasurementId != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: onClear, // ✅ sem async/await
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
              if (currentAdjustmentMeasurementId != null &&
                  selectedAdjustmentMeasurement != null)
                _buildPdfWidget(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentAdjustmentMeasurementId != null &&
                  selectedAdjustmentMeasurement != null)
                _buildPdfWidget(),
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );

        return container;
      },
    );
  }

  Widget _buildPdfWidget() {
    return WebPdfWidgetGeneric(
      key: Key(currentAdjustmentMeasurementId!),
      type: PDFType.report,
      contractData: contractData,
      specificData: selectedAdjustmentMeasurement!,
      // Se seu WebPdfWidgetGeneric exigir callback de upload, adicione:
      // onUploadSaveToFirestore: (url) async => await onUploadSaveToFirestore(url),
    );
  }
}
