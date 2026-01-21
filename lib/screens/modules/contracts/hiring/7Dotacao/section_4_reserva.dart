import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionReserva extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionReserva({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionReserva> createState() => _SectionReservaState();
}

class _SectionReservaState extends State<SectionReserva> {
  late final TextEditingController _reservaNumeroCtrl;
  late final TextEditingController _reservaDataCtrl;
  late final TextEditingController _reservaValorCtrl;
  late final TextEditingController _reservaObservacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _reservaNumeroCtrl =
        TextEditingController(text: d.reservaNumero ?? '');
    _reservaDataCtrl =
        TextEditingController(text: d.reservaData ?? '');
    _reservaValorCtrl =
        TextEditingController(text: d.reservaValor ?? '');
    _reservaObservacoesCtrl =
        TextEditingController(text: d.reservaObservacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionReserva oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_reservaNumeroCtrl, d.reservaNumero);
      _sync(_reservaDataCtrl, d.reservaData);
      _sync(_reservaValorCtrl, d.reservaValor);
      _sync(_reservaObservacoesCtrl, d.reservaObservacoes);
    }
  }

  @override
  void dispose() {
    _reservaNumeroCtrl.dispose();
    _reservaDataCtrl.dispose();
    _reservaValorCtrl.dispose();
    _reservaObservacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      reservaNumero: _reservaNumeroCtrl.text,
      reservaData: _reservaDataCtrl.text,
      reservaValor: _reservaValorCtrl.text,
      reservaObservacoes: _reservaObservacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '4) Reserva Orçamentária / Planejamento'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _reservaNumeroCtrl,
                    labelText: 'Nº da Reserva',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _reservaDataCtrl,
                    labelText: 'Data da Reserva',
                    hintText: 'dd/mm/aaaa',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _reservaValorCtrl,
                    labelText: 'Valor Reservado (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _reservaObservacoesCtrl,
                    labelText: 'Observações da reserva',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
