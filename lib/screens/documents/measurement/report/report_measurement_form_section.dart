import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:siged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';

// ✅ lista lateral de arquivos (mesmo componente usado em Additives/Apostilles)
import '../../../../_widgets/list/files/side_list_box.dart';

class ReportMeasurementFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;

  final ReportMeasurementData? selectedReportMeasurement;
  final String? currentReportMeasurementId;

  final ContractData contractData;
  final ReportMeasurementStorageBloc reportMeasurementStorageBloc;

  final TextEditingController orderController;
  final TextEditingController processNumberController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  // ▶️ SideListBox props
  final List<String> sideItems;
  final int? selectedSideIndex;
  final VoidCallback? onAddSideItem;
  final void Function(int index)? onTapSideItem;
  final void Function(int index)? onDeleteSideItem;

  const ReportMeasurementFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.selectedReportMeasurement,
    required this.currentReportMeasurementId,
    required this.contractData,
    required this.reportMeasurementStorageBloc,
    required this.orderController,
    required this.processNumberController,
    required this.dateController,
    required this.valueController,
    required this.onSave,
    required this.onClear,
    // side list
    required this.sideItems,
    this.selectedSideIndex,
    this.onAddSideItem,
    this.onTapSideItem,
    this.onDeleteSideItem,
  });

  // `_input` recebe a largura já calculada (como nos outros módulos)
  Widget _input(
      double width,
      TextEditingController controller,
      String label, {
        required bool isEditable,
        bool enabled = true,
        bool money = false,
        bool date = false,
        bool tooltip = false,
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

        // 👉 largura dos inputs levando em conta o sideWidth quando em duas colunas
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
              'Ordem da medição',
              isEditable: isEditable,
              enabled: false,
              tooltip: true,
            ),
            _input(
              inputsWidth,
              processNumberController,
              'Nº processo da medição',
              isEditable: isEditable,
              mask: processoMaskFormatter,
            ),
            CustomDateField(
              width: inputsWidth,
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedReportMeasurement?.date,
              labelText: 'Data da Medição',
              onChanged: (date) {
                if (selectedReportMeasurement != null) {
                  selectedReportMeasurement!.date = date;
                }
              },
            ),
            _input(
              inputsWidth,
              valueController,
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
                currentReportMeasurementId != null ? 'Atualizar' : 'Salvar',
              ),
              onPressed: formValidated ? (isEditable ? onSave : null) : null,
            ),
            const SizedBox(width: 12),
            if (currentReportMeasurementId != null)
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

        // ✅ SideListBox SEMPRE visível; botão "+" só habilita com um item selecionado
        final side = SideListBox(
          title: 'Arquivos da Medição',
          items: sideItems,
          selectedIndex: selectedSideIndex,
          onAddPressed:
          (selectedReportMeasurement != null) ? onAddSideItem : null,
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
