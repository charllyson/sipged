import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/input/custom_date_field.dart';
import '../../../../_widgets/input/custom_text_field.dart';

class InfractionsFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final String? currentInfractionId;

  // Controllers principais
  final TextEditingController orderCtrl;
  final TextEditingController aitNumberCtrl;
  final TextEditingController dateCtrl; // Data (dd/MM/yyyy) – CustomDateField
  final TextEditingController timeCtrl; // Hora (HH:mm)
  final TextEditingController codeCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController organCodeCtrl;
  final TextEditingController organAuthorityCtrl;

  // Localização / endereço
  final TextEditingController addressCtrl;
  final TextEditingController bairroCtrl;
  final TextEditingController latitudeCtrl;
  final TextEditingController longitudeCtrl;

  final Future<void> Function() onClear;
  final VoidCallback onSave;
  final VoidCallback onGetLocation;

  const InfractionsFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.currentInfractionId,
    required this.orderCtrl,
    required this.aitNumberCtrl,
    required this.dateCtrl,
    required this.timeCtrl,
    required this.codeCtrl,
    required this.descriptionCtrl,
    required this.organCodeCtrl,
    required this.organAuthorityCtrl,
    required this.addressCtrl,
    required this.bairroCtrl,
    required this.latitudeCtrl,
    required this.longitudeCtrl,
    required this.onClear,
    required this.onSave,
    required this.onGetLocation,
  });

  double _w(BuildContext c) =>
      responsiveInputWidth(context: c, itemsPerLine: 4, extraPadding: 12, reservedWidth: 12);

  Widget _text(
      BuildContext c,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        int maxLines = 1,
        List<TextInputFormatter>? mask,
        TextInputType? keyboardType,
        String? hintText,
      }) {
    return SizedBox(
      width: _w(c),
      child: CustomTextField(
        enabled: enabled,
        controller: ctrl,
        labelText: label,
        hintText: hintText,
        inputFormatters: mask,
        keyboardType: keyboardType,
        maxLength: maxLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campos = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Localização
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: const [
              Expanded(child: Divider(thickness: 1, endIndent: 12, color: Colors.grey)),
              Text('Localização', style: TextStyle(fontSize: 16)),
              Expanded(child: Divider(thickness: 1, indent: 12, color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(
          width: _w(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: 'Usar localização atual do usuário',
                child: InkWell(
                  onTap: onGetLocation,
                  child: Column(
                    children: const [
                      Icon(Icons.my_location, color: Colors.blueAccent),
                      Text(
                        'Obter\nlocalização',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blueAccent, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _text(
                        context,
                        latitudeCtrl,
                        'Latitude',
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _text(
                        context,
                        longitudeCtrl,
                        'Longitude',
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _text(context, addressCtrl, 'Endereço da infração', maxLines: 2),
        _text(context, bairroCtrl, 'Bairro'),

        // Dados da infração
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: const [
              Expanded(child: Divider(thickness: 1, endIndent: 12, color: Colors.grey)),
              Text('Dados da infração', style: TextStyle(fontSize: 16)),
              Expanded(child: Divider(thickness: 1, indent: 12, color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(
          width: _w(context),
          child: Tooltip(
            message: 'Este campo é calculado automaticamente.',
            child: CustomTextField(
              enabled: false,
              controller: orderCtrl,
              labelText: 'Ordem da infração',
            ),
          ),
        ),
        _text(
          context,
          aitNumberCtrl,
          'Nº AIT',
          mask: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          width: _w(context),
          child: CustomDateField(
            enabled: isEditable,
            controller: dateCtrl,
            labelText: 'Data da infração',
          ),
        ),
        _text(
          context,
          timeCtrl,
          'Hora da infração',
          hintText: 'HH:MM',
          mask: [MaskedInputFormatter('##:##')],
          keyboardType: TextInputType.datetime,
        ),
        _text(context, codeCtrl, 'Código da infração'),
        _text(context, organCodeCtrl, 'Órgão (código)'),
        _text(context, organAuthorityCtrl, 'Autoridade'),
        _text(context, descriptionCtrl, 'Descrição da infração', maxLines: 3),
      ],
    );

    final botoes = Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 12,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: Text(currentInfractionId != null ? 'Atualizar' : 'Salvar'),
            onPressed: formValidated && isEditable ? onSave : null,
          ),
          if (currentInfractionId != null)
            TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Limpar'),
              onPressed: () async => onClear(),
            ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          campos,
          const SizedBox(height: 16),
          botoes,
        ],
      ),
    );
  }
}
