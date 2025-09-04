import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_data.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';

import 'package:siged/_widgets/archives/pdf/web_pdf_widget.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_widgets/archives/pdf/web_pdf_controller.dart';

class RevisionMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final RevisionMeasurementData? selectedRevisionMeasurement;
  final String? currentRevisionMeasurementId;
  final ContractData contractData;

  final TextEditingController orderRevisionController;
  final TextEditingController processNumberRevisionController;
  final TextEditingController dateRevisionController;
  final TextEditingController valueRevisionController;

  final VoidCallback onSave;
  final VoidCallback onClear; // ✅ agora é VoidCallback (combina com createNew)
  final Future<void> Function(String url) onUploadSaveToFirestore;

  const RevisionMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedRevisionMeasurement,
    required this.currentRevisionMeasurementId,
    required this.contractData,
    required this.orderRevisionController,
    required this.processNumberRevisionController,
    required this.dateRevisionController,
    required this.valueRevisionController,
    required this.onSave,
    required this.onClear, // ✅
    required this.onUploadSaveToFirestore,
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
              orderRevisionController,
              'Ordem da medição',
              enabled: false,
              tooltip: true,
            ),
            _input(
              context,
              processNumberRevisionController,
              'Nº processo da medição',
              enabled: isEditable, // ✅ respeita permissão
              mask: [processoMaskFormatter],
            ),
            CustomDateField(
              width: getInputWidth(context),
              enabled: isEditable, // ✅ respeita permissão
              controller: dateRevisionController,
              // usa o mesmo campo do controller/model
              initialValue: selectedRevisionMeasurement?.date,
              labelText: 'Data da Medição',
              onChanged: (date) {
                // mantém sincronizado no item selecionado
                if (selectedRevisionMeasurement != null) {
                  selectedRevisionMeasurement!.date = date;
                }
              },
            ),
            _input(
              context,
              valueRevisionController,
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
              label: Text(currentRevisionMeasurementId != null ? 'Atualizar' : 'Salvar'),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentRevisionMeasurementId != null)
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Limpar'),
                onPressed: onClear, // ✅ chama direto (é VoidCallback)
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
              if (currentRevisionMeasurementId != null &&
                  selectedRevisionMeasurement != null)
                _buildPdfWidget(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentRevisionMeasurementId != null &&
                  selectedRevisionMeasurement != null)
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
      key: Key(currentRevisionMeasurementId!),
      type: PDFType.report,
      contractData: contractData,
      specificData: selectedRevisionMeasurement!,
      onUploadSaveToFirestore: onUploadSaveToFirestore,
    );
    // Observação: o widget PDF é exibido apenas quando há ID selecionado.
  }
}
