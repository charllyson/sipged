import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import '../../../../_widgets/layout/responsive_utils.dart';
import '../../../../_widgets/input/date_field_change.dart';
import '../../../../_widgets/input/text_field_change.dart';

class InfractionsFormSection extends StatelessWidget {
  final bool isEditable;
  final bool formValidated;
  final String? currentInfractionId;

  /// Força número de itens por linha (ex.: 2 no desktop, 1 no mobile)
  final int? itemsPerLineOverride;

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
    this.itemsPerLineOverride,
  });

  // Campo de texto padrão
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
    return CustomTextField(
      enabled: enabled,
      controller: ctrl,
      labelText: label,
      hintText: hintText,
      inputFormatters: mask,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

      // 2 por linha no desktop; pode forçar 1 no mobile (outra tela decide)
      final itemsPerLine = itemsPerLineOverride ?? 2;
      const spacing = 12.0;

      final fieldW = responsiveInputWidth(
        context: context,
        itemsPerLine: itemsPerLine,
        containerWidth: maxW,
        spacing: spacing,
        margin: 13, // mesmo ajuste do padrão dos acidentes
        forceItemsPerLineOnSmall: true,
      );

      // -------- GRID --------
      final gridWrap = Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          // ===== Localização (FULL WIDTH) =====
          _sectionHeader(maxW, 'Localização'),
          _localizacaoBlock(context, maxW),

          // ===== Endereço (2 por linha) =====
          _gridItem(fieldW, _text(context, addressCtrl, 'Endereço da infração', maxLines: 2)),
          _gridItem(fieldW, _text(context, bairroCtrl, 'Bairro')),

          // ===== Dados da infração =====
          _sectionHeader(maxW, 'Dados da infração'),

          _gridItem(
            fieldW,
            Tooltip(
              message: 'Este campo é calculado automaticamente.',
              child: CustomTextField(
                enabled: false,
                controller: orderCtrl,
                labelText: 'Ordem da infração',
              ),
            ),
          ),
          _gridItem(
            fieldW,
            _text(
              context,
              aitNumberCtrl,
              'Nº AIT',
              mask: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
            ),
          ),
          _gridItem(
            fieldW,
            DateFieldChange(
              enabled: isEditable,
              controller: dateCtrl,
              labelText: 'Data da infração',
            ),
          ),
          _gridItem(
            fieldW,
            _text(
              context,
              timeCtrl,
              'Hora da infração',
              hintText: 'HH:MM',
              mask: [MaskedInputFormatter('##:##')],
              keyboardType: TextInputType.datetime,
            ),
          ),
          _gridItem(fieldW, _text(context, codeCtrl, 'Código da infração')),
          _gridItem(fieldW, _text(context, organCodeCtrl, 'Órgão (código)')),
          _gridItem(fieldW, _text(context, organAuthorityCtrl, 'Autoridade')),
          _gridItem(fieldW, _text(context, descriptionCtrl, 'Descrição da infração', maxLines: 3)),
        ],
      );

      final actions = Align(
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
