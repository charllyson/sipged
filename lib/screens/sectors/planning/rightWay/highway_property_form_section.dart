import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/highway_property_data.dart';
import 'package:siged/_utils/formats/input_formatters.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/responsive_utils.dart';

class RightWayPropertyFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;

  final RightWayPropertyData? selected;
  final String? currentId;

  // controllers
  final TextEditingController ownerCtrl;
  final TextEditingController cpfCnpjCtrl;
  final TextEditingController typeCtrl;
  final TextEditingController statusCtrl;

  final TextEditingController registryCtrl;
  final TextEditingController officeCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController ufCtrl;

  final TextEditingController processCtrl;
  final TextEditingController notifDateCtrl;
  final TextEditingController inspDateCtrl;
  final TextEditingController agreeDateCtrl;

  final TextEditingController totalAreaCtrl;
  final TextEditingController affectedAreaCtrl;
  final TextEditingController indemnityCtrl;

  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController notesCtrl;

  final VoidCallback onSave;
  final VoidCallback onClear;

  const RightWayPropertyFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selected,
    required this.currentId,
    required this.ownerCtrl,
    required this.cpfCnpjCtrl,
    required this.typeCtrl,
    required this.statusCtrl,
    required this.registryCtrl,
    required this.officeCtrl,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.ufCtrl,
    required this.processCtrl,
    required this.notifDateCtrl,
    required this.inspDateCtrl,
    required this.agreeDateCtrl,
    required this.totalAreaCtrl,
    required this.affectedAreaCtrl,
    required this.indemnityCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.notesCtrl,
    required this.onSave,
    required this.onClear,
  });

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: 100,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  Widget _input(
      BuildContext context,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
        int? maxLines,
        String? hintText,
      }) {
    return CustomTextField(
      width: getInputWidth(context),
      controller: ctrl,
      enabled: enabled && isEditable,
      labelText: label,
      hintText: hintText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeItems = const ['URBANO', 'RURAL'];
    final statusItems = const ['A NEGOCIAR', 'INDENIZADO', 'JUDICIALIZADO'];

    final campos = <Widget>[
      // Identificação
      _input(context, ownerCtrl, 'Proprietário/Posseiro'),
      _input(context, cpfCnpjCtrl, 'CPF/CNPJ', inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-\/]')),
      ]),
      DropDownButtonChange(
        width: getInputWidth(context),
        enabled: isEditable,
        labelText: 'Tipo do Imóvel',
        items: typeItems,
        controller: typeCtrl,
      ),
      DropDownButtonChange(
        width: getInputWidth(context),
        enabled: isEditable,
        labelText: 'Status',
        items: statusItems,
        controller: statusCtrl,
      ),

      // Registro/Localização
      _input(context, registryCtrl, 'Nº Matrícula'),
      _input(context, officeCtrl, 'Cartório'),
      _input(context, addressCtrl, 'Endereço/Descrição'),
      _input(context, cityCtrl, 'Município'),
      _input(context, ufCtrl, 'UF', inputFormatters: [
        UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(2),
      ]),

      // Processos e datas
      _input(context, processCtrl, 'Nº do Processo', inputFormatters: [processoMaskFormatter]),
      CustomDateField(
        width: getInputWidth(context),
        enabled: isEditable,
        controller: notifDateCtrl,
        initialValue: selected?.notificationDate,
        labelText: 'Data de Notificação',
        onChanged: (_) {},
      ),
      CustomDateField(
        width: getInputWidth(context),
        enabled: isEditable,
        controller: inspDateCtrl,
        initialValue: selected?.inspectionDate,
        labelText: 'Data da Vistoria',
        onChanged: (_) {},
      ),
      CustomDateField(
        width: getInputWidth(context),
        enabled: isEditable,
        controller: agreeDateCtrl,
        initialValue: selected?.agreementDate,
        labelText: 'Data do Acordo/Indenização',
        onChanged: (_) {},
      ),

      // Áreas e valores
      _input(context, totalAreaCtrl, 'Área Total (m²)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))]),
      _input(context, affectedAreaCtrl, 'Área Atingida (m²)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))]),
      CustomTextField(
        width: getInputWidth(context),
        controller: indemnityCtrl,
        enabled: isEditable,
        labelText: 'Valor da Indenização',
        keyboardType: TextInputType.number,
        inputFormatters: [
          CurrencyInputFormatter(
            leadingSymbol: 'R\$',
            useSymbolPadding: true,
            thousandSeparator: ThousandSeparator.Period,
            mantissaLength: 2,
          ),
        ],
      ),

      // Contato + Observações
      _input(context, phoneCtrl, 'Telefone', inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\(\)\s\-\+]')),
      ]),
      _input(context, emailCtrl, 'E-mail', keyboardType: TextInputType.emailAddress),
      CustomTextField(
        width: getInputWidth(context),
        controller: notesCtrl,
        enabled: isEditable,
        labelText: 'Observações',
        maxLines: 3,
      ),
    ];

    final botoes = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.save),
          label: Text(editingMode ? 'Atualizar' : 'Salvar'),
          onPressed: formValidated && isEditable ? onSave : null,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wrap = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: campos,
          );
          final corpo = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              wrap,
              const SizedBox(height: 12),
              botoes,
            ],
          );
          final showAside = constraints.maxWidth >= 920;
          return showAside
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentId != null && selected != null)
                const SizedBox.shrink(), // (lugar para PDF/preview futuro)
              if (currentId != null && selected != null) const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          )
              : corpo;
        },
      ),
    );
  }
}

/// UpperCase helper (igual ao que você já usa em outros pontos)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}
