import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/input/drop_down_botton_change.dart';
import 'package:sisged/_widgets/formats/input_formatters.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_widgets/archives/pdf/pdf_icon_action.dart';

class AdditiveFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final AdditiveData? selectedAdditive;
  final String? currentAdditiveId;
  final ContractData contractData;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController typeOfAdditiveCtrl;
  final TextEditingController valueController;
  final TextEditingController additionalDaysExecutionController;
  final TextEditingController additionalDaysContractController;

  final VoidCallback onSave;
  final VoidCallback onClear;
  final Future<void> Function(String url) onUploadSaveToFirestore;

  const AdditiveFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selectedAdditive,
    required this.currentAdditiveId,
    required this.contractData,
    required this.orderController,
    required this.processController,
    required this.dateController,
    required this.typeOfAdditiveCtrl,
    required this.valueController,
    required this.additionalDaysExecutionController,
    required this.additionalDaysContractController,
    required this.onSave,
    required this.onClear,
    required this.onUploadSaveToFirestore,
  });

  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());
  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());

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
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool tooltip = false,
        TextInputFormatter? mask,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é calculado automaticamente e não pode ser editado.' : '',
      child: CustomTextField(
        width: getInputWidth(context),
        controller: ctrl,
        enabled: enabled && isEditable,
        labelText: label,
        keyboardType: date
            ? TextInputType.datetime
            : money
            ? TextInputType.number
            : null,
        inputFormatters: [
          if (date) FilteringTextInputFormatter.digitsOnly,
          if (date) TextInputMask(mask: '99/99/9999'),
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: 'R\$',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (mask != null) mask,
        ],
      ),
    );
  }

  Widget _buildPdfWidget() {
    if (currentAdditiveId == null || selectedAdditive == null) return const SizedBox.shrink();
    return PdfFileIconActionGeneric(
      key: Key(currentAdditiveId!),
      type: PDFType.additives,
      contractData: contractData,
      specificData: selectedAdditive!,
      onUploadSaveToFirestore: onUploadSaveToFirestore,
    );
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
            _input(context, orderController, 'Ordem do aditivo', enabled: false, tooltip: true),
            _input(context, processController, 'Processo do Aditivo', mask: processoMaskFormatter),
            CustomDateField(
              width: getInputWidth(context),
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedAdditive?.additiveDate,
              labelText: 'Data do Aditivo',
              onChanged: (date) => selectedAdditive?.additiveDate = date,
            ),
            DropDownButtonChange(
              width: getInputWidth(context),
              enabled: isEditable,
              labelText: 'Tipo de Aditivo',
              items: AdditiveData.type,
              controller: typeOfAdditiveCtrl,
              onChanged: (value) {
                if (selectedAdditive != null) {
                  selectedAdditive!.typeOfAdditive = value ?? '';
                }
              },
            ),
            if (exibeValor()) _input(context, valueController, 'Valor do aditivo', money: true),
            if (exibePrazo()) _input(context, additionalDaysContractController, 'Dias adicionais ao prazo do contrato'),
            if (exibePrazo()) _input(context, additionalDaysExecutionController, 'Dias adicionais ao prazo de execução'),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(editingMode ? 'Atualizar' : 'Salvar'),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (editingMode)
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

        return Container(
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
              if (currentAdditiveId != null && selectedAdditive != null) _buildPdfWidget(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentAdditiveId != null && selectedAdditive != null) _buildPdfWidget(),
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );
      },
    );
  }
}
