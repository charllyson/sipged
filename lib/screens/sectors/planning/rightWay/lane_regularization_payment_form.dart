// lib/screens/sectors/planning/rightWay/property/lane_regularization_payment_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

import 'package:siged/_blocs/process/laneRegularization/lane_regularization_controller.dart';
import 'package:siged/_blocs/process/laneRegularization/lane_regularization_data.dart';

class LaneRegularizationPaymentForm extends StatefulWidget {
  const LaneRegularizationPaymentForm({super.key, required this.controller});
  final LaneRegularizationController controller;

  @override
  State<LaneRegularizationPaymentForm> createState() => _LaneRegularizationPaymentFormState();
}

class _LaneRegularizationPaymentFormState extends State<LaneRegularizationPaymentForm> {
  late final ScrollController _scrollCtrl;
  LaneRegularizationController get controller => widget.controller;

  @override
  void initState() { super.initState(); _scrollCtrl = ScrollController(); }
  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  double _responsiveWidth(BuildContext context, double reserved) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: reserved,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 920;
          final sideWidth = isSmall ? constraints.maxWidth : 300.0;
          final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
          final w = _responsiveWidth(context, reserved);

          final botoes = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: Text(controller.editingMode ? 'Atualizar' : 'Salvar'),
                onPressed: (controller.formValidated && controller.isEditable)
                    ? () => controller.saveOrUpdate(context)
                    : null,
              ),
              const SizedBox(width: 12),
              if (controller.editingMode)
                TextButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text('Limpar'),
                  onPressed: controller.clearForm,
                ),
            ],
          );

          final corpo = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Wrap(spacing: 12, runSpacing: 12, children: [
                CustomTextField(
                  width: w,
                  controller: controller.indemnityCtrl,
                  enabled: controller.isEditable,
                  labelText: 'Valor da Indenização (R\$)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CurrencyInputFormatter(
                      leadingSymbol: 'R\$ ',
                      useSymbolPadding: true,
                      thousandSeparator: ThousandSeparator.Period,
                      mantissaLength: 2,
                    ),
                  ],
                ),
                DropDownButtonChange(
                  width: w,
                  enabled: controller.isEditable,
                  labelText: 'Tipo de Indenização',
                  items: LaneRegularizationData.indemnityTypeItems,
                  controller: controller.indemnityTypeCtrl,
                ),
                DropDownButtonChange(
                  width: w,
                  enabled: controller.isEditable,
                  labelText: 'Forma de Pagamento',
                  items: LaneRegularizationData.paymentFormItems,
                  controller: controller.paymentFormCtrl,
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.paymentDateCtrl,
                  initialValue: controller.selected?.paymentDate,
                  labelText: 'Data de Pagamento',
                  onChanged: (_) {},
                ),

                // Dados bancários
                CustomTextField(width: w, controller: controller.bankNameCtrl,
                    enabled: controller.isEditable, labelText: 'Banco'),
                CustomTextField(width: w, controller: controller.bankAgencyCtrl,
                    enabled: controller.isEditable, labelText: 'Agência'),
                CustomTextField(width: w, controller: controller.bankAccountCtrl,
                    enabled: controller.isEditable, labelText: 'Conta'),
                CustomTextField(width: w, controller: controller.pixKeyCtrl,
                    enabled: controller.isEditable, labelText: 'Chave PIX'),

                // Judicial
                CustomTextField(width: w, controller: controller.courtCtrl,
                    enabled: controller.isEditable, labelText: 'Vara/Comarca'),
                CustomTextField(width: w, controller: controller.caseNumberCtrl,
                    enabled: controller.isEditable, labelText: 'Nº Processo'),
                CustomTextField(width: w, controller: controller.rpvPrecCtrl,
                    enabled: controller.isEditable, labelText: 'RPV/Precatório'),
                CustomTextField(width: w, controller: controller.depositInCourtCtrl,
                  enabled: controller.isEditable, labelText: 'Depósito em Juízo (R\$)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CurrencyInputFormatter(
                      leadingSymbol: 'R\$ ',
                      useSymbolPadding: true,
                      thousandSeparator: ThousandSeparator.Period,
                      mantissaLength: 2,
                    ),
                  ],
                ),

                // Pós-pagamento
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.possessionDateCtrl,
                  initialValue: controller.selected?.possessionDate,
                  labelText: 'Imissão de Posse',
                  onChanged: (_) {},
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.evictionDateCtrl,
                  initialValue: controller.selected?.evictionDate,
                  labelText: 'Desocupação',
                  onChanged: (_) {},
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.registryUpdateDateCtrl,
                  initialValue: controller.selected?.registryUpdateDate,
                  labelText: 'Baixa/Averbação Cartorial',
                  onChanged: (_) {},
                ),

                // Social
                CustomTextField(width: w, controller: controller.ressettlementCtrl,
                    enabled: controller.isEditable, labelText: 'Reassentamento necessário? (Sim/Não)'),
                CustomTextField(width: w, controller: controller.familyCountCtrl,
                    enabled: controller.isEditable, labelText: 'Nº de Famílias',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                CustomTextField(width: w, controller: controller.socialNotesCtrl,
                    enabled: controller.isEditable, labelText: 'Observações Sociais', maxLines: 2),
              ]),
              const SizedBox(height: 12),
              botoes,
            ],
          );

          final leftColumn = Column(
            children: [
              SideListBox(
                title: 'Arquivos do Imóvel',
                items: controller.docItems,
                selectedIndex: controller.selectedDocIndex,
                onAddPressed: (controller.selected != null && controller.isEditable)
                    ? () => controller.addDocFile(context)
                    : null,
                onTap: (i) => controller.openDocAt(context, i),
                onDelete: (i) => controller.removeDocAt(context, i),
                onEditLabel: (i) => controller.editDocLabel(context, i),
                width: sideWidth,
              ),
            ],
          );

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              controller: _scrollCtrl,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: isSmall
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  leftColumn, const SizedBox(height: 12), corpo,
                ])
                    : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: sideWidth, child: leftColumn),
                  const SizedBox(width: 12),
                  Expanded(child: corpo),
                ]),
              ),
            ),
          );
        });
      },
    );
  }
}
