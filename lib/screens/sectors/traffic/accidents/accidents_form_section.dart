// lib/screens/sectors/traffic/accidents/accidents_form_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/input/custom_date_field.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../../../../_blocs/sectors/transit/accidents/accidents_data.dart';

class AccidentsFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final String? currentAccidentId;
  final int? itemsPerLineOverride; // força número de itens por linha

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
    this.itemsPerLineOverride,
  });

  // Campo de texto padrão
  Widget _text(
      BuildContext c,
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        List<TextInputFormatter>? mask,
        TextInputType? keyboardType,
      }) {
    return CustomTextField(
      enabled: enabled,
      controller: ctrl,
      labelText: label,
      inputFormatters: mask,
      keyboardType: keyboardType,
    );
  }

  // Envolve um campo para respeitar a largura calculada do grid
  Widget _gridItem(double width, Widget child) => ConstrainedBox(
    constraints: BoxConstraints.tightFor(width: width),
    child: child,
  );

  // Cabeçalho de seção (linha inteira)
  Widget _sectionHeader(double maxW, String title) {
    return SizedBox(
      width: maxW,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Expanded(child: Divider(thickness: 1, endIndent: 12, color: Colors.grey)),
            Text(title, style: const TextStyle(fontSize: 16)),
            const Expanded(child: Divider(thickness: 1, indent: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Bloco Localização (linha inteira)
  Widget _localizacaoBlock(BuildContext context, double maxW) {
    return SizedBox(
      width: maxW,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Usar localização atual do usuário',
            child: InkWell(
              onTap: onGetLocation,
              child: const Column(
                children: [
                  Icon(Icons.my_location, color: Colors.blueAccent),
                  SizedBox(height: 2),
                  Text(
                    'Obter\nlocalização',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueAccent, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // lat/long lado a lado usando largura disponível
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;

      // força 2 por linha sempre (se null, usa 2)
      final itemsPerLine = itemsPerLineOverride ?? 2;
      const spacing = 12.0;

      // usa o helper para calcular a largura de cada input
      final fieldW = responsiveInputWidth(
        context: context,
        itemsPerLine: itemsPerLine,
        containerWidth: maxW,
        spacing: spacing,
        margin: 13, // container do form já tem padding externo
        forceItemsPerLineOnSmall: true, // mantém 2 colunas no mobile
      );

      // --------- GRID DE CAMPOS (2 por linha) ---------
      final gridWrap = Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          // ===== Localização (FULL WIDTH) =====
          _sectionHeader(maxW, 'Localização'),
          _localizacaoBlock(context, maxW),
          // ===== Endereço e Metadados (2 por linha) =====
          _gridItem(fieldW, _text(context, postalCodeCtrl, 'CEP')),
          _gridItem(fieldW, _text(context, streetCtrl, 'Rua')),
          _gridItem(fieldW, _text(context, cityCtrl, 'Cidade')),
          _gridItem(fieldW, _text(context, subLocalityCtrl, 'Bairro')),
          _gridItem(fieldW, _text(context, administrativeAreaCtrl, 'Estado')),
          _gridItem(fieldW, _text(context, countryCtrl, 'País')),
          _gridItem(fieldW, _text(context, isoCountryCodeCtrl, 'Código do País')),

          // ===== Descrição (FULL WIDTH header + 2 por linha nos campos) =====
          _sectionHeader(maxW, 'Descrições do acidente'),

          _gridItem(
            fieldW,
            Tooltip(
              message: 'Este campo é calculado automaticamente.',
              child: CustomTextField(
                enabled: false,
                controller: orderCtrl,
                labelText: 'Ordem do acidente',
              ),
            ),
          ),
          _gridItem(
            fieldW,
            CustomDateField(
              enabled: isEditable,
              controller: dateCtrl,
              labelText: 'Data do acidente',
            ),
          ),
          _gridItem(
            fieldW,
            DropDownButtonChange(
              validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              enabled: isEditable,
              labelText: 'Tipo de acidente',
              items: AccidentsData.accidentTypes,
              controller: typeOfAccidentCtrl,
            ),
          ),
          _gridItem(
            fieldW,
            _text(
              context,
              deathCtrl,
              'Mortes',
              keyboardType: TextInputType.number,
              mask: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          _gridItem(
            fieldW,
            _text(
              context,
              scoresVictimsCtrl,
              'Vítimas envolvidas',
              keyboardType: TextInputType.number,
              mask: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          _gridItem(fieldW, _text(context, transportInvolvedCtrl, 'Transportes envolvidos')),
          _gridItem(fieldW, _text(context, highwayCtrl, 'Rodovias')),
        ],
      );

      final actions = Align(
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
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            gridWrap,
            const SizedBox(height: 16),
            actions,
          ],
        ),
      );
    });
  }
}
