import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';

import 'package:sipged/_blocs/modules/planning/highway_domain/lane_regularization_controller.dart';
import 'package:sipged/_blocs/modules/planning/highway_domain/lane_regularization_data.dart';

class LaneRegularizationPropertyForm extends StatefulWidget {
  const LaneRegularizationPropertyForm({super.key, required this.controller});
  final LaneRegularizationController controller;

  @override
  State<LaneRegularizationPropertyForm> createState() =>
      _LaneRegularizationPropertyFormState();
}

class _LaneRegularizationPropertyFormState
    extends State<LaneRegularizationPropertyForm> {
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    DropDownButtonChange(
                      width: w,
                      enabled: controller.isEditable,
                      labelText: 'Etapa (pipeline)',
                      items: LaneRegularizationData.stageItems,
                      controller: controller.stageCtrl,
                    ),
                    DropDownButtonChange(
                      width: w,
                      enabled: controller.isEditable,
                      labelText: 'Status *',
                      items: LaneRegularizationData.statusItems,
                      controller: controller.statusCtrl,
                    ),
                    DropDownButtonChange(
                      width: w,
                      enabled: controller.isEditable,
                      labelText: 'Tipo do Imóvel',
                      items: LaneRegularizationData.typeItems,
                      controller: controller.typeCtrl,
                    ),
                    DropDownButtonChange(
                      width: w,
                      enabled: controller.isEditable,
                      labelText: 'Situação da Negociação',
                      items: LaneRegularizationData.negotiationItems,
                      controller: controller.negotiationCtrl,
                    ),
                    _input(context, controller.registryCtrl, 'Nº Matrícula *',
                        width: w),
                    _input(context, controller.officeCtrl, 'Cartório', width: w),
                    _input(context, controller.addressCtrl, 'Endereço/Descrição',
                        width: w),
                    _input(context, controller.cityCtrl, 'Município', width: w),
                    _input(
                      context,
                      controller.ufCtrl,
                      'UF',
                      width: w,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                    _input(context, controller.roadNameCtrl, 'Rodovia/Trecho',
                        width: w),
                    DropDownButtonChange(
                      width: w,
                      enabled: controller.isEditable,
                      labelText: 'Lado da Via',
                      items: LaneRegularizationData.laneSideItems,
                      controller: controller.laneSideCtrl,
                    ),
                    _input(
                      context,
                      controller.kmStartCtrl,
                      'KM Inicial',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))
                      ],
                    ),
                    _input(
                      context,
                      controller.kmEndCtrl,
                      'KM Final',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))
                      ],
                    ),
                    _input(
                      context,
                      controller.corridorWidthCtrl,
                      'Largura de Corredor (m)',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))
                      ],
                    ),
                    _input(
                      context,
                      controller.totalAreaCtrl,
                      'Área Total (m²)',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))
                      ],
                    ),
                    _input(
                      context,
                      controller.affectedAreaCtrl,
                      'Área Atingida (m²)',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.,]'))
                      ],
                    ),
                    _input(context, controller.carCtrl, 'CAR', width: w),
                    _input(context, controller.ccirCtrl, 'CCIR', width: w),
                    _input(context, controller.nirfCtrl, 'NIRF', width: w),
                    _input(context, controller.sncrCtrl, 'SNCR/INCRA', width: w),
                    _input(
                      context,
                      controller.centroidLatCtrl,
                      'Centroid Lat',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-]'))
                      ],
                    ),
                    _input(
                      context,
                      controller.centroidLngCtrl,
                      'Centroid Lng',
                      width: w,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.\-]'))
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                botoes,
              ],
            );

            final leftColumn = Column(
              children: [
                SideListBox(
                  title: 'Arquivo Georreferenciado',
                  items: controller.geoItems,
                  selectedIndex: controller.selectedGeoIndex,
                  onAddPressed:
                  (controller.selected != null && controller.isEditable)
                      ? () => controller.addGeoFile(context)
                      : null,
                  onTap: (i) => controller.openGeoAt(i),
                  onDelete: (i) => controller.removeGeoAt(context, i),

                  // ✅ NOVO: rename persist + sync lista
                  onRenamePersist: ({required index, required oldItem, required newItem}) {
                    return controller.persistRenameGeo(
                      index: index,
                      oldItem: oldItem,
                      newItem: newItem,
                    );
                  },
                  onItemsChanged: controller.setGeoItems,

                  width: sideWidth,
                ),
                const SizedBox(height: 12),
                SideListBox(
                  title: 'Arquivos do Imóvel',
                  items: controller.docItems,
                  selectedIndex: controller.selectedDocIndex,
                  onAddPressed:
                  (controller.selected != null && controller.isEditable)
                      ? () => controller.addDocFile(context)
                      : null,
                  onTap: (i) => controller.openDocAt(context, i),
                  onDelete: (i) => controller.removeDocAt(context, i),

                  // ✅ NOVO: rename persist + sync lista
                  onRenamePersist: ({required index, required oldItem, required newItem}) {
                    return controller.persistRenameDoc(
                      index: index,
                      oldItem: oldItem,
                      newItem: newItem,
                    );
                  },
                  onItemsChanged: controller.setDocItems,

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
                      SizedBox(width: sideWidth, child: leftColumn),
                      const SizedBox(width: 12),
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
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}
