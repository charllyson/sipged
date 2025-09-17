import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_data.dart';

// Side list
import '../../../../_widgets/list/files/side_list_box.dart';

class ValidityFormSection extends StatelessWidget {
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

  // SideListBox
  final List<String> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

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
    // side
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 700;
      final sideWidth = isSmall ? constraints.maxWidth : 300.0;

      // Inputs calculados reservando o painel lateral
      final inputWidth = responsiveInputWidth(
        context: context,
        itemsPerLine: 3,
        reservedWidth: isSmall ? 0.0 : (sideWidth + 12.0),
        spacing: 12.0,
        margin: 12.0,
        extraPadding: 24.0,
        spaceBetweenReserved: 12.0,
      );

      final camposWrap = Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Tooltip(
            message: 'Este campo é calculado automaticamente e não pode ser editado.',
            child: CustomTextField(
              width: inputWidth,
              enabled: false,
              fillCollor: Colors.grey.shade200,
              labelText: 'Ordem',
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          DropDownButtonChange(
            width: inputWidth,
            labelText: 'Tipo da ordem',
            items: availableOrders.isEmpty ? [] : availableOrders,
            controller: orderTypeCtrl,
            enabled: availableOrders.isNotEmpty && isEditable,
          ),
          CustomDateField(
            width: inputWidth,
            controller: orderDateCtrl,
            initialValue: selectedValidityData?.orderdate,
            labelText: 'Data da ordem',
            enabled: isEditable,
            // validação inline: usa stringToDate do format_field.dart
            validator: (_) {
              final d = stringToDate(orderDateCtrl.text);
              return d == null ? 'Data inválida' : null;
            },
            onChanged: onChangeDate,
          ),
        ],
      );

      final botoes = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selectedValidityData?.id != null)
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Limpar'),
              onPressed: onClear,
            ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: formValidated && !isSaving ? onSaveOrUpdate : null,
            icon: const Icon(Icons.save),
            label: Text(
              selectedValidityData?.id != null ? 'Atualizar' : 'Salvar',
            ),
          ),
        ],
      );

      final corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          camposWrap,
          const SizedBox(height: 12),
          botoes,
        ],
      );

      final side = SideListBox(
        title: 'Documento da validade',
        items: sideItems,
        selectedIndex: selectedSideIndex,
        onAddPressed: (selectedValidityData != null) ? onAddSideItem : null,
        onTap: onTapSideItem,
        onDelete: onDeleteSideItem,
        width: sideWidth,
      );

      final content = isSmall
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
