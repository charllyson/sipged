import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/input/drop_down_botton_change.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import '../../../../../_widgets/archives/pdf/pdf_icon_action.dart';
import '../../../../../_widgets/formats/format_field.dart';
import '../../../../../_widgets/validates/form_validation_mixin.dart';
import '../../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/documents/contracts/validity/validity_data.dart';

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
  final ContractsBloc contractsBloc;
  final ValidityBloc validityBloc;

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
    required this.contractsBloc,
    required this.validityBloc,
  });

  @override
  State<ValidityFormSection> createState() => _ValidityFormSectionState();
}

class _ValidityFormSectionState extends State<ValidityFormSection> with FormValidationMixin {

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 3,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
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
            Tooltip(
              message: 'Este campo é calculado automaticamente e não pode ser editado.',
              child: CustomTextField(
                width: getInputWidth(context),
                enabled: false,
                fillCollor: Colors.grey.shade200,
                labelText: 'Ordem',
                controller: widget.orderCtrl,
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            DropDownButtonChange(
              width: getInputWidth(context),
              labelText: 'Tipo da ordem',
              items: widget.availableOrders.isEmpty ? [] : widget.availableOrders,
              controller: widget.orderTypeCtrl,
              enabled: widget.availableOrders.isNotEmpty && widget.isEditable,
            ),
            CustomDateField(
              width: getInputWidth(context),
              controller: widget.orderDateCtrl,
              initialValue: widget.selectedValidityData?.orderdate,
              labelText: 'Data da ordem',
              enabled: widget.isEditable,
              validator: (_) => validateDate(stringToDate(widget.orderDateCtrl.text)),
              onChanged: widget.onChangeDate,
            ),
          ],
        );

        final pdfWidget = widget.selectedValidityData?.id != null
            ? SizedBox(
          width: 100,
          child: PdfFileIconActionGeneric<ValidityData>(
            key: Key(widget.selectedValidityData!.id!),
            type: PDFType.validity,
            contractData: widget.contractData!,
            specificData: widget.selectedValidityData,
            validityBloc: widget.validityBloc,
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
              onPressed: widget.formValidated && !widget.isSaving ? widget.onSaveOrUpdate : null,
              icon: const Icon(Icons.save),
              label: Text(widget.selectedValidityData?.id != null ? 'Atualizar' : 'Salvar'),
            ),
          ],
        );

        final body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedValidityData?.id != null) pdfWidget,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  camposWrap,
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
            child: isSmallScreen
                ? body
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
} 