import 'package:flutter/material.dart';

import 'package:siged/_blocs/sectors/planning/lane_regularization/lane_regularization_controller.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

class LaneRegularizationNotificationForm extends StatefulWidget {
  const LaneRegularizationNotificationForm({super.key, required this.controller});
  final LaneRegularizationController controller;

  @override
  State<LaneRegularizationNotificationForm> createState() => _LaneRegularizationNotificationFormState();
}

class _LaneRegularizationNotificationFormState extends State<LaneRegularizationNotificationForm> {
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
                  width: w, controller: controller.dupNumberCtrl,
                  enabled: controller.isEditable, labelText: 'Nº do DUP',
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.dupDateCtrl,
                  initialValue: controller.selected?.dupDate,
                  labelText: 'Data do DUP',
                  onChanged: (_) {},
                ),
                CustomTextField(
                  width: w, controller: controller.doPublicationCtrl,
                  enabled: controller.isEditable, labelText: 'DO/Seção/Página',
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.doPublicationDateCtrl,
                  initialValue: controller.selected?.doPublicationDate,
                  labelText: 'Data Publicação DO',
                  onChanged: (_) {},
                ),
                CustomTextField(
                  width: w, controller: controller.arCtrl,
                  enabled: controller.isEditable, labelText: 'AR (Aviso de Recebimento)',
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.notifDateCtrl,
                  initialValue: controller.selected?.notificationDate,
                  labelText: 'Data de Notificação',
                  onChanged: (_) {},
                ),
                CustomDateField(
                  width: w, enabled: controller.isEditable,
                  controller: controller.inspDateCtrl,
                  initialValue: controller.selected?.inspectionDate,
                  labelText: 'Data da Vistoria',
                  onChanged: (_) {},
                ),
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
                onTap: (i) => controller.openDocAt(context, i), // <- dialog interno
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
