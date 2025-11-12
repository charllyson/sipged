import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

// controller + contracts cno
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';
import 'package:provider/provider.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

class SectionPartesValoresVigencia extends StatefulWidget {
  final PublicacaoExtratoController controller;
  const SectionPartesValoresVigencia({super.key, required this.controller});

  @override
  State<SectionPartesValoresVigencia> createState() => _SectionPartesValoresVigenciaState();
}

class _SectionPartesValoresVigenciaState extends State<SectionPartesValoresVigencia>
    with FormValidationMixin {
  double _w(BuildContext ctx, {int itemsPerLine = 4}) => responsiveInputWidth(
    context: ctx,
    itemsPerLine: itemsPerLine,
    spacing: 12,
    margin: 12,
    extraPadding: 24,
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final contracts = context.watch<ProcessController>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('2) Partes, Valores e Vigência'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peContratadaRazaoCtrl,
            labelText: 'Contratada (Razão Social)',
            enabled: c.isEditable,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peContratadaCnpjCtrl,
            labelText: 'CNPJ',
            enabled: c.isEditable,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(14),
              TextInputMask(mask: '99.999.999/9999-99'),
            ],
            keyboardType: TextInputType.number,
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: contracts.cnoNumberCtrl,
            labelText: 'CNO',
            enabled: c.isEditable,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peValorCtrl,
            labelText: 'Valor (R\$)',
            enabled: c.isEditable,
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peVigenciaCtrl,
            labelText: 'Vigência (ex.: 12 meses ou 24/09/2025 a 23/09/2026)',
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
