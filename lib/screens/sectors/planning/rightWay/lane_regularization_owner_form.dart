// lib/screens/sectors/planning/rightWay/property/lane_regularization_owner_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/laneRegularization/lane_regularization_controller.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class LaneRegularizationOwnerForm extends StatefulWidget {
  const LaneRegularizationOwnerForm({super.key, required this.controller});
  final LaneRegularizationController controller;

  @override
  State<LaneRegularizationOwnerForm> createState() => _LaneRegularizationOwnerFormState();
}

class _LaneRegularizationOwnerFormState extends State<LaneRegularizationOwnerForm> {
  late final ScrollController _scrollCtrl;
  LaneRegularizationController get controller => widget.controller;

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

  Widget _input(BuildContext context, TextEditingController ctrl, String label,
      {required double width, bool enabled = true, TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters, int? maxLines, String? hintText}) {
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
                _input(context, controller.ownerCtrl, 'Proprietário/Posseiro', width: w),
                _input(context, controller.cpfCnpjCtrl, 'CPF/CNPJ', width: w,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-\/]'))]),
                _input(context, controller.phoneCtrl, 'Telefone', width: w,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\(\)\s\-\+]'))]),
                _input(context, controller.emailCtrl, 'E-mail', width: w, keyboardType: TextInputType.emailAddress),
                DropDownButtonChange(
                  width: w,
                  enabled: controller.isEditable,
                  labelText: 'Uso do Imóvel',
                  items: const ['Residencial', 'Comercial', 'Rural', 'Misto'],
                  controller: controller.useOfLandCtrl,
                ),
                _input(context, controller.improvementsCtrl, 'Benfeitorias (resumo)', width: w, maxLines: 2),
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
