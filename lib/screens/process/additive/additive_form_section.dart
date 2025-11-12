// ==============================
// lib/screens/contracts/additives/additive_form_section.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/process/additives/additive_rules.dart';
import 'package:siged/_blocs/process/additives/additive_data.dart';
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class AdditiveFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final AdditiveData? selectedAdditive;
  final String? currentAdditiveId;
  final ProcessData contractData;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController typeOfAdditiveCtrl;
  final TextEditingController valueController;
  final TextEditingController additionalDaysExecutionController;
  final TextEditingController additionalDaysContractController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // 🆕 SideListBox (compat: String ou Attachment)
  final List<dynamic> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;
  final void Function(int index)? onEditLabelSideItem;

  // ▶️ NOVOS: props do dropdown de ordem
  final List<String> orderOptions;
  final Set<String> greyOrderItems;
  final void Function(String?) onChangedOrder;

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
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
    this.onEditLabelSideItem,
    // dropdown ordem
    required this.orderOptions,
    required this.greyOrderItems,
    required this.onChangedOrder,
  });

  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());

  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());

  Widget _input(
      double width,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool tooltip = false,
        TextInputFormatter? mask,
        required bool isEditable,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é calculado automaticamente e não pode ser editado.' : '',
      child: CustomTextField(
        width: width,
        controller: ctrl,
        enabled: enabled && isEditable,
        labelText: label,
        keyboardType: date
            ? TextInputType.datetime
            : (money ? TextInputType.number : null),
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
        final double sideWidth = isSmallScreen ? constraints.maxWidth : 300.0;

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
            // 🔄 ORDEM COM DROPDOWN (mesma lógica: cinza = existente; preto = livre)
            DropDownButtonChange(
              width: inputsWidth,
              enabled: true, // sempre interativo para filtrar/selecionar
              labelText: 'Ordem do aditivo',
              items: orderOptions,
              greyItems: greyOrderItems,
              controller: orderController,
              onChanged: onChangedOrder,
            ),
            _input(
              inputsWidth,
              processController,
              'Processo do Aditivo',
              mask: processoMaskFormatter,
              isEditable: isEditable,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedAdditive?.additiveDate,
              labelText: 'Data do Aditivo',
              onChanged: (date) => selectedAdditive?.additiveDate = date,
            ),
            DropDownButtonChange(
              width: inputsWidth,
              enabled: isEditable,
              labelText: 'Tipo de Aditivo',
              items: AdditiveRules.type,
              controller: typeOfAdditiveCtrl,
              onChanged: (value) {
                if (selectedAdditive != null) {
                  selectedAdditive!.typeOfAdditive = value ?? '';
                }
              },
            ),
            if (exibeValor())
              _input(
                inputsWidth,
                valueController,
                'Valor do aditivo',
                money: true,
                isEditable: isEditable,
              ),
            if (exibePrazo())
              _input(
                inputsWidth,
                additionalDaysContractController,
                'Dias adicionais ao prazo do contrato',
                isEditable: isEditable,
              ),
            if (exibePrazo())
              _input(
                inputsWidth,
                additionalDaysExecutionController,
                'Dias adicionais ao prazo de execução',
                isEditable: isEditable,
              ),
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

        // ✅ SideListBox com renomear rótulo
        final side = SideListBox(
          title: 'Arquivos do Aditivo',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed: (selectedAdditive != null && isEditable) ? onAddSideItem : null,
          // IMPORTANTE: passar o context
          onTap: onTapSideItem == null ? null : (i) => onTapSideItem!(i),
          onDelete: isEditable ? onDeleteSideItem : null,
          onEditLabel: isEditable ? onEditLabelSideItem : null,
          width: sideWidth,
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
