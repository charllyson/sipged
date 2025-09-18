import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_controller.dart';
import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_data.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class PlanningRightWayPropertyForm extends StatefulWidget {
  const PlanningRightWayPropertyForm({super.key, required this.controller});
  final PlanningRightWayPropertyController controller;

  @override
  State<PlanningRightWayPropertyForm> createState() => _PlanningRightWayPropertyFormState();
}

class _PlanningRightWayPropertyFormState extends State<PlanningRightWayPropertyForm> {
  late final ScrollController _scrollCtrl;

  PlanningRightWayPropertyController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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

  Widget _input(
      BuildContext context,
      TextEditingController ctrl,
      String label, {
        required double width,
        bool enabled = true,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
        int? maxLines,
        String? hintText,
      }) {
    return CustomTextField(
      width: width,
      controller: ctrl,
      enabled: enabled && controller.isEditable,
      labelText: label,
      hintText: hintText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 920;
            final sideWidth = isSmall ? constraints.maxWidth : 300.0;
            final reserved = isSmall ? 0.0 : (sideWidth + 12.0);
            final w = _responsiveWidth(context, reserved);

            // ---------- campos ----------
            final campos = <Widget>[
              _input(context, controller.ownerCtrl, 'Proprietário/Posseiro *', width: w),
              _input(
                context,
                controller.cpfCnpjCtrl,
                'CPF/CNPJ',
                width: w,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-\/]'))],
              ),
              DropDownButtonChange(
                width: w,
                enabled: controller.isEditable,
                labelText: 'Tipo do Imóvel',
                items: PlanningRightWayPropertyData.typeItems,
                controller: controller.typeCtrl,
              ),
              DropDownButtonChange(
                width: w,
                enabled: controller.isEditable,
                labelText: 'Status *',
                items: PlanningRightWayPropertyData.statusItems,
                controller: controller.statusCtrl,
              ),
              _input(context, controller.registryCtrl, 'Nº Matrícula *', width: w),
              _input(context, controller.officeCtrl, 'Cartório', width: w),
              _input(context, controller.addressCtrl, 'Endereço/Descrição', width: w),
              _input(context, controller.cityCtrl, 'Município', width: w),
              _input(
                context,
                controller.ufCtrl,
                'UF',
                width: w,
                inputFormatters: [UpperCaseTextFormatter(), LengthLimitingTextInputFormatter(2)],
              ),
              _input(
                context,
                controller.processCtrl,
                'Nº do Processo',
                width: w,
                inputFormatters: [processoMaskFormatter],
              ),
              CustomDateField(
                width: w,
                enabled: controller.isEditable,
                controller: controller.notifDateCtrl,
                initialValue: controller.selected?.notificationDate,
                labelText: 'Data de Notificação',
                onChanged: (_) {},
              ),
              CustomDateField(
                width: w,
                enabled: controller.isEditable,
                controller: controller.inspDateCtrl,
                initialValue: controller.selected?.inspectionDate,
                labelText: 'Data da Vistoria',
                onChanged: (_) {},
              ),
              CustomDateField(
                width: w,
                enabled: controller.isEditable,
                controller: controller.agreeDateCtrl,
                initialValue: controller.selected?.agreementDate,
                labelText: 'Data do Acordo/Indenização',
                onChanged: (_) {},
              ),
              _input(
                context,
                controller.totalAreaCtrl,
                'Área Total (m²)',
                width: w,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))],
              ),
              _input(
                context,
                controller.affectedAreaCtrl,
                'Área Atingida (m²)',
                width: w,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))],
              ),
              CustomTextField(
                width: w,
                controller: controller.indemnityCtrl,
                enabled: controller.isEditable,
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
              _input(
                context,
                controller.phoneCtrl,
                'Telefone',
                width: w,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\(\)\s\-\+]'))],
              ),
              _input(
                context,
                controller.emailCtrl,
                'E-mail',
                width: w,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                width: w,
                controller: controller.notesCtrl,
                enabled: controller.isEditable,
                labelText: 'Observações',
                maxLines: 3,
              ),
            ];

            // ---------- ações ----------
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
                Wrap(spacing: 12, runSpacing: 12, children: campos),
                const SizedBox(height: 12),
                botoes,
              ],
            );

            // ---------- coluna esquerda (arquivos) ----------
            final leftColumn = Column(
              children: [
                SideListBox(
                  title: 'Arquivo Georreferenciado',
                  items: controller.geoNames,
                  selectedIndex: controller.selectedGeoIndex,
                  onAddPressed: (controller.selected != null && controller.isEditable)
                      ? () => controller.addGeoFile(context)
                      : null,
                  onTap: (i) => controller.openGeoAt(i),
                  onDelete: (i) => controller.removeGeoAt(context, i),
                  width: sideWidth,
                  leadingBuilder: (_) => const Icon(Icons.public),
                ),
                const SizedBox(height: 12),
                SideListBox(
                  title: 'Arquivos do Imóvel',
                  items: controller.docNames,
                  selectedIndex: controller.selectedDocIndex,
                  onAddPressed: (controller.selected != null && controller.isEditable)
                      ? () => controller.addDocFile(context)
                      : null,
                  onTap: (i) => controller.openDocAt(i),
                  onDelete: (i) => controller.removeDocAt(context, i),
                  width: sideWidth,
                ),
              ],
            );

            // ========== CONTAINER BRANCO COM SCROLL INTERNO ==========
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
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftColumn,
                      const SizedBox(height: 12),
                      corpo,
                    ],
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // fixa a largura da coluna esquerda
                      SizedBox(width: sideWidth, child: leftColumn),
                      const SizedBox(width: 12),
                      // ocupa o restante sem estourar
                      Expanded(child: corpo),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// UpperCase helper
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}
