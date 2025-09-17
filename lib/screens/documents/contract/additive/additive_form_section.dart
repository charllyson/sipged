// ==============================
// lib/screens/contracts/additives/additive_form_section.dart
// ==============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:siged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_rules.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_data.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

// ✅ caminho em minúsculas
import '../../../../_widgets/list/files/side_list_box.dart';

class AdditiveFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final AdditiveData? selectedAdditive;
  final String? currentAdditiveId;
  final ContractData contractData;
  final AdditivesStorageBloc additivesStorageBloc;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController typeOfAdditiveCtrl;
  final TextEditingController valueController;
  final TextEditingController additionalDaysExecutionController;
  final TextEditingController additionalDaysContractController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // 🆕 props do SideListBox
  final List<String> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  const AdditiveFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selectedAdditive,
    required this.currentAdditiveId,
    required this.contractData,
    required this.additivesStorageBloc,
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
  });

  bool exibeValor() =>
      ['VALOR', 'REEQUILÍBRIO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());

  bool exibePrazo() =>
      ['PRAZO', 'RATIFICAÇÃO', 'RENOVAÇÃO']
          .contains(typeOfAdditiveCtrl.text.toUpperCase());

  // Agora `_input` recebe a largura já calculada
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
      message:
      tooltip ? 'Este campo é calculado automaticamente e não pode ser editado.' : '',
      child: CustomTextField(
        width: width,
        controller: ctrl,
        enabled: enabled && isEditable,
        labelText: label,
        keyboardType:
        date ? TextInputType.datetime : (money ? TextInputType.number : null),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 700;

        // 👉 largura do SideListBox (100% no mobile; 300 em telas largas)
        final double sideWidth = isSmallScreen ? constraints.maxWidth : 300.0;

        // 👉 largura dos inputs levando em conta o sideWidth quando em duas colunas
        //  - reservedWidth "base" = 100
        //  - quando não é small screen, reservamos também o sideWidth + espaçamento (12)
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
            _input(
              inputsWidth,
              orderController,
              'Ordem do aditivo',
              enabled: false,
              tooltip: true,
              isEditable: isEditable,
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

        // ✅ SideListBox SEMPRE visível; "+" desabilita se nada selecionado
        final side = SideListBox(
          title: 'Arquivos do Aditivo',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed: (selectedAdditive != null) ? onAddSideItem : null,
          onTap: onTapSideItem,
          onDelete: onDeleteSideItem,
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
