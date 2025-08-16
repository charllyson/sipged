import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/input/custom_date_field.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/formats/format_field.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_datas/sectors/transit/accidents/accidents_data.dart';

class AccidentsFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final String? currentAccidentId;

  final TextEditingController orderCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController highwayCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController typeOfAccidentCtrl;
  final TextEditingController deathCtrl;
  final TextEditingController scoresVictimsCtrl;
  final TextEditingController transportInvolvedCtrl;

  final TextEditingController latitudeCtrl;
  final TextEditingController longitudeCtrl;
  final TextEditingController postalCodeCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController city2Ctrl;
  final TextEditingController subLocalityCtrl;
  final TextEditingController administrativeAreaCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController isoCountryCodeCtrl;

  final Future<void> Function() onClear;
  final VoidCallback onSave;
  final VoidCallback onGetLocation;

  const AccidentsFormSection({
    super.key,
    required this.isEditable,
    required this.formValidated,
    required this.currentAccidentId,
    required this.orderCtrl,
    required this.dateCtrl,
    required this.highwayCtrl,
    required this.cityCtrl,
    required this.typeOfAccidentCtrl,
    required this.deathCtrl,
    required this.scoresVictimsCtrl,
    required this.transportInvolvedCtrl,
    required this.latitudeCtrl,
    required this.longitudeCtrl,
    required this.postalCodeCtrl,
    required this.streetCtrl,
    required this.city2Ctrl,
    required this.subLocalityCtrl,
    required this.administrativeAreaCtrl,
    required this.countryCtrl,
    required this.isoCountryCodeCtrl,
    required this.onClear,
    required this.onSave,
    required this.onGetLocation,
  });

  double _w(BuildContext c) => responsiveInputWidth(context: c, itemsPerLine: 4, extraPadding: 12, reservedWidth: 12);

  Widget _text(BuildContext c, TextEditingController ctrl, String label,
      {bool enabled = true, List<TextInputFormatter>? mask, TextInputType? keyboardType}) {
    return SizedBox(
      width: _w(c),
      child: CustomTextField(
        enabled: enabled,
        controller: ctrl,
        labelText: label,
        inputFormatters: mask,
        keyboardType: keyboardType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campos = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // localização
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
                      Text('Obter\nlocalização', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _text(context, latitudeCtrl, 'Latitude', enabled: false)),
                    const SizedBox(width: 8),
                    Expanded(child: _text(context, longitudeCtrl, 'Longitude', enabled: false)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _text(context, postalCodeCtrl, 'CEP'),
        _text(context, streetCtrl, 'Rua'),
        _text(context, cityCtrl, 'Cidade'),
        _text(context, subLocalityCtrl, 'Bairro'),
        _text(context, administrativeAreaCtrl, 'Estado'),
        _text(context, countryCtrl, 'País'),
        _text(context, isoCountryCodeCtrl, 'Código do País'),

        // descrição
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: const [
              Expanded(child: Divider(thickness: 1, endIndent: 12, color: Colors.grey)),
              Text('Descrições do acidente', style: TextStyle(fontSize: 16)),
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
              labelText: 'Ordem do acidente',
            ),
          ),
        ),
        SizedBox(
          width: _w(context),
          child: CustomDateField(
            enabled: isEditable,
            controller: dateCtrl,
            labelText: 'Data do acidente',
          ),
        ),
        SizedBox(
          width: _w(context),
          child: DropDownButtonChange(
            validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            enabled: isEditable,
            labelText: 'Tipo de acidente',
            items: AccidentsData.accidentTypes,
            controller: typeOfAccidentCtrl,
          ),
        ),
        _text(context, deathCtrl, 'Mortes', keyboardType: TextInputType.number, mask: [FilteringTextInputFormatter.digitsOnly]),
        _text(context, scoresVictimsCtrl, 'Vítimas envolvidas', keyboardType: TextInputType.number, mask: [FilteringTextInputFormatter.digitsOnly]),
        _text(context, transportInvolvedCtrl, 'Transportes envolvidos'),
        _text(context, highwayCtrl, 'Rodovias'),
      ],
    );

    final botoes = Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 12,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: Text(currentAccidentId != null ? 'Atualizar' : 'Salvar'),
            onPressed: formValidated && isEditable ? onSave : null,
          ),
          if (currentAccidentId != null)
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
