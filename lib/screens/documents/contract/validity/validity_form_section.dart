import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/responsive_utils.dart';

import 'package:siged/_services/pdf/web_pdf_widget.dart';
import 'package:siged/_services/pdf/web_pdf_controller.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_data.dart';

class ValidityFormSection extends StatefulWidget {
  final TextEditingController orderCtrl;
  final TextEditingController orderTypeCtrl;
  final TextEditingController orderDateCtrl;
  final List<String> availableOrders;
  final ValidityData? selectedValidityData;
  final bool isEditable;
  final bool isSaving;
  final bool formValidated;
  final VoidCallback onSaveOrUpdate;
  final VoidCallback onClear;
  final Function(DateTime?) onChangeDate;
  final ContractData? contractData;
  final ValidityStorageBloc validityStorageBloc;

  const ValidityFormSection({
    super.key,
    required this.orderCtrl,
    required this.orderTypeCtrl,
    required this.orderDateCtrl,
    required this.availableOrders,
    required this.selectedValidityData,
    required this.isEditable,
    required this.isSaving,
    required this.formValidated,
    required this.onSaveOrUpdate,
    required this.onClear,
    required this.onChangeDate,
    required this.contractData,
    required this.validityStorageBloc,
  });

  @override
  State<ValidityFormSection> createState() => _ValidityFormSectionState();
}

class _ValidityFormSectionState extends State<ValidityFormSection>
    with FormValidationMixin {
  static const double _pdfPanelWidth = 98.0; // largura fixa do painel do PDF
  static const double _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      final hasPdf = widget.selectedValidityData?.id != null && widget.contractData != null;

      // quando o PDF aparece ao lado, reservamos a largura dele para o cálculo dos inputs
      final reservedForPdf = (!isSmall && hasPdf) ? _pdfPanelWidth + _gap : 0.0;

      final inputWidth = responsiveInputWidth(
        context: context,
        itemsPerLine: 3,
        reservedWidth: reservedForPdf,
        spacing: 12.0,
        margin: 12.0,
        extraPadding: 24.0,
        spaceBetweenReserved: _gap,
      );

      Widget camposWrap = Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Tooltip(
            message:
            'Este campo é calculado automaticamente e não pode ser editado.',
            child: CustomTextField(
              width: inputWidth,
              enabled: false,
              fillCollor: Colors.grey.shade200,
              labelText: 'Ordem',
              controller: widget.orderCtrl,
              keyboardType: TextInputType.text,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          DropDownButtonChange(
            width: inputWidth,
            labelText: 'Tipo da ordem',
            items: widget.availableOrders.isEmpty ? [] : widget.availableOrders,
            controller: widget.orderTypeCtrl,
            enabled: widget.availableOrders.isNotEmpty && widget.isEditable,
          ),
          CustomDateField(
            width: inputWidth,
            controller: widget.orderDateCtrl,
            initialValue: widget.selectedValidityData?.orderdate,
            labelText: 'Data da ordem',
            enabled: widget.isEditable,
            validator: (_) => validateDate(
              stringToDate(widget.orderDateCtrl.text),
            ),
            onChanged: widget.onChangeDate,
          ),
        ],
      );

      Widget pdfWidget = hasPdf
          ? SizedBox(
        width: _pdfPanelWidth,
        child: WebPdfWidgetGeneric<ValidityData>(
          key: ValueKey(widget.selectedValidityData!.id!),
          type: PDFType.validity,
          contractData: widget.contractData!,
          specificData: widget.selectedValidityData,
          validityStorageBloc: widget.validityStorageBloc,
        ),
      )
          : const SizedBox.shrink();

      final botoes = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.selectedValidityData?.id != null)
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Limpar'),
              onPressed: widget.onClear,
            ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed:
            widget.formValidated && !widget.isSaving ? widget.onSaveOrUpdate : null,
            icon: const Icon(Icons.save),
            label: Text(
              widget.selectedValidityData?.id != null ? 'Atualizar' : 'Salvar',
            ),
          ),
        ],
      );

      // Layout: PDF ao lado em telas largas; PDF acima (centralizado) em telas pequenas
      final content = isSmall
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPdf) Center(child: pdfWidget),
          if (hasPdf) const SizedBox(height: 12),
          camposWrap,
          const SizedBox(height: 12),
          botoes,
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPdf) pdfWidget,
          if (hasPdf) const SizedBox(width: _gap),
          // Campos + botões ocupam o resto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                camposWrap,
                const SizedBox(height: 12),
                botoes,
              ],
            ),
          ),
        ],
      );

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(12),
          child: content,
        ),
      );
    });
  }
}
