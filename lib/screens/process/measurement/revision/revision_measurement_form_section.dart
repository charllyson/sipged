// lib/screens/process/revision/revision_measurement_form_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_data.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

// ✅ mesma lista lateral usada em Additives/Apostilles/Reports/Adjustments
import '../../../../_widgets/list/files/side_list_box.dart';

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
  final VoidCallback onClear;

  // ▶️ SideListBox (compat: String OU Attachment)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  // (compat) antes usado pelo WebPdfWidget — não é utilizado aqui
  final Future<void> Function(String url)? onUploadSaveToFirestore;

  // ▶️ NOVOS: props do dropdown de ordem
  final List<String> orderOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrder;

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
    required this.onClear,
    // side list
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
    this.onUploadSaveToFirestore, // (compat)
    // dropdown
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  // `_input` recebe a largura já calculada
  Widget _input(
      double width,
      TextEditingController controller,
      String label, {
        required bool isEditable,
        bool enabled = true,
        bool tooltip = false,
        bool money = false,
        bool date = false,
        TextInputFormatter? mask,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é calculado automaticamente.' : '',
      child: CustomTextField(
        width: width,
        enabled: enabled && isEditable,
        labelText: label,
        controller: controller,
        keyboardType: money
            ? TextInputType.number
            : (date ? TextInputType.datetime : TextInputType.text),
        inputFormatters: [
          if (date) FilteringTextInputFormatter.digitsOnly,
          if (date) TextInputMask(mask: '99/99/9999'),
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: 'R\$ ',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (mask != null) mask,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 700;

        // 👉 largura do SideListBox (100% no mobile; 300 em telas largas)
        final double sideWidth = isSmallScreen ? constraints.maxWidth : 300.0;

        // 👉 inputs levando em conta o sideWidth quando em 2 colunas
        final double inputsWidth = responsiveInputWidth(
          context: context,
          itemsPerLine: 4,
          reservedWidth: isSmallScreen ? 0.0 : (sideWidth + 12.0),
          spacing: 12.0,
          margin: 12.0,
          extraPadding: 24.0,
          spaceBetweenReserved: 12.0,
        );

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 🔄 Substituição do campo por dropdown de ordem
            DropDownButtonChange(
              width: inputsWidth,
              controller: orderRevisionController,
              labelText: 'Ordem da medição',
              items: orderOptions,          // 1..(max+1)
              greyItems: greyOrderItems,    // existentes => cinza
              enabled: true,                // permite selecionar/filtrar
              onChanged: onChangedOrder,
            ),
            _input(
              inputsWidth,
              processNumberRevisionController,
              'Nº processo da medição',
              isEditable: isEditable,
              mask: processoMaskFormatter,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: isEditable,
              controller: dateRevisionController,
              initialValue: selectedRevisionMeasurement?.date,
              labelText: 'Data da Medição',
              onChanged: (date) {
                if (selectedRevisionMeasurement != null) {
                  selectedRevisionMeasurement!.date = date;
                }
              },
            ),
            _input(
              inputsWidth,
              valueRevisionController,
              'Valor da medição',
              isEditable: isEditable,
              money: true,
            ),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: Text(
                currentRevisionMeasurementId != null ? 'Atualizar' : 'Salvar',
              ),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentRevisionMeasurementId != null)
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

        // ✅ SideListBox SEMPRE visível; "+" desabilita se nada selecionado
        final side = SideListBox(
          title: 'Arquivos da Medição (Revisão)',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed:
          (selectedRevisionMeasurement != null && isEditable) ? onAddSideItem : null,
          onTap: onTapSideItem,
          onDelete: isEditable ? onDeleteSideItem : null,
          onEditLabel: isEditable ? onEditLabelSideItem : null,
          width: sideWidth, // 🔥 ocupa 100% no mobile
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              side,
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              side,
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );
      },
    );
  }
}
