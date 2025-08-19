import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/formats/input_formatters.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import 'package:sisged/_widgets/archives/pdf/web_pdf_widget.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../_datas/documents/contracts/apostilles/apostilles_data.dart';
import '../../../../_datas/documents/contracts/contracts/contract_data.dart';
import '../../../../_widgets/archives/pdf/web_pdf_controller.dart';

class ApostilleFormSection extends StatelessWidget {
  final bool isEditable;
  final bool editingMode;
  final bool formValidated;
  final ApostillesData? selectedApostille;
  final String? currentApostilleId;
  final ContractData contractData;
  final ApostillesStorageBloc apostillesStorageBloc;

  final TextEditingController orderController;
  final TextEditingController processController;
  final TextEditingController dateController;
  final TextEditingController valueController;

  final VoidCallback onSave;
  final VoidCallback onClear;

  const ApostilleFormSection({
    super.key,
    required this.isEditable,
    required this.editingMode,
    required this.formValidated,
    required this.selectedApostille,
    required this.currentApostilleId,
    required this.contractData,
    required this.apostillesStorageBloc,
    required this.orderController,
    required this.processController,
    required this.dateController,
    required this.valueController,
    required this.onSave,
    required this.onClear,
  });

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(
      BuildContext context,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool tooltip = false,
        TextInputFormatter? mask,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é gerado automaticamente.' : '',
      child: CustomTextField(
        width: getInputWidth(context),
        controller: ctrl,
        enabled: enabled && isEditable,
        labelText: label,
        keyboardType: date
            ? TextInputType.datetime
            : money
            ? TextInputType.number
            : null,
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

  Widget _buildPdfWidget() {
    if (currentApostilleId == null || selectedApostille == null) return const SizedBox.shrink();
    return WebPdfWidgetGeneric(
      key: Key(currentApostilleId!),
      type: PDFType.apostilles,
      contractData: contractData,
      specificData: selectedApostille!,
      apostillesStorageBloc: apostillesStorageBloc,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(context, orderController, 'Ordem do apostilamento', enabled: false, tooltip: true),
            _input(context, processController, 'Nº do processo', mask: processoMaskFormatter),
            CustomDateField(
              width: getInputWidth(context),
              enabled: isEditable,
              controller: dateController,
              initialValue: selectedApostille?.apostilleData,
              labelText: 'Data do apostilamento',
              onChanged: (date) => selectedApostille?.apostilleData = date,
            ),
            _input(context, valueController, 'Valor do apostilamento', money: true),
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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentApostilleId != null && selectedApostille != null) _buildPdfWidget(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentApostilleId != null && selectedApostille != null) _buildPdfWidget(),
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );
      },
    );
  }
}
