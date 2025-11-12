import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart' show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_controller.dart';

class SectionVeiculoPublicacao extends StatefulWidget {
  final PublicacaoExtratoController controller;
  const SectionVeiculoPublicacao({super.key, required this.controller});

  @override
  State<SectionVeiculoPublicacao> createState() => _SectionVeiculoPublicacaoState();
}

class _SectionVeiculoPublicacaoState extends State<SectionVeiculoPublicacao>
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('3) Veículo de Publicação'),
      Wrap(spacing: 12, runSpacing: 12, children: [
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            enabled: c.isEditable,
            labelText: 'Veículo',
            controller: c.peVeiculoCtrl,
            items: const [
              'DOE/Estadual','DOU','Diário Municipal','PNCP','Site Oficial','Outro'
            ],
            onChanged: (v) => setState(() => c.peVeiculoCtrl.text = v ?? ''),
            validator: validateRequired,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peEdicaoNumeroCtrl,
            labelText: 'Edição/Nº',
            enabled: c.isEditable,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peDataEnvioCtrl,
            labelText: 'Data de envio',
            hintText: 'dd/mm/aaaa',
            enabled: c.isEditable,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              TextInputMask(mask: '99/99/9999'),
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomTextField(
            controller: c.peDataPublicacaoCtrl,
            labelText: 'Data da publicação',
            hintText: 'dd/mm/aaaa',
            enabled: c.isEditable,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              TextInputMask(mask: '99/99/9999'),
            ],
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: _w(context, itemsPerLine: 1),
          child: CustomTextField(
            controller: c.peLinkPublicacaoCtrl,
            labelText: 'Link da publicação (URL/PNCP/arquivo)',
            enabled: c.isEditable,
          ),
        ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}
