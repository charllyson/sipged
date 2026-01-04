// lib/screens/process/hiring/5Edital/section_5_parecer_recursos.dart
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/drop_down_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

class SectionParecerRecursos extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;

  const SectionParecerRecursos({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionParecerRecursos> createState() =>
      _SectionParecerRecursosState();
}

class _SectionParecerRecursosState extends State<SectionParecerRecursos> {
  late final TextEditingController _criterioAplicadoCtrl;
  late final TextEditingController _linkAtaCtrl;
  late final TextEditingController _recursosHouveCtrl;
  late final TextEditingController _parecerCtrl;
  late final TextEditingController _decisaoRecursosCtrl;
  late final TextEditingController _linksRecursosCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _criterioAplicadoCtrl =
        TextEditingController(text: d.criterioAplicado ?? '');
    _linkAtaCtrl = TextEditingController(text: d.linkAta ?? '');
    _recursosHouveCtrl =
        TextEditingController(text: d.recursosHouve ?? '');
    _parecerCtrl = TextEditingController(text: d.parecer ?? '');
    _decisaoRecursosCtrl =
        TextEditingController(text: d.decisaoRecursos ?? '');
    _linksRecursosCtrl =
        TextEditingController(text: d.linksRecursos ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionParecerRecursos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      final criterioAplicado = d.criterioAplicado ?? '';
      final linkAta = d.linkAta ?? '';
      final recursosHouve = d.recursosHouve ?? '';
      final parecer = d.parecer ?? '';
      final decisaoRecursos = d.decisaoRecursos ?? '';
      final linksRecursos = d.linksRecursos ?? '';

      if (_criterioAplicadoCtrl.text != criterioAplicado) {
        _criterioAplicadoCtrl.text = criterioAplicado;
      }
      if (_linkAtaCtrl.text != linkAta) {
        _linkAtaCtrl.text = linkAta;
      }
      if (_recursosHouveCtrl.text != recursosHouve) {
        _recursosHouveCtrl.text = recursosHouve;
      }
      if (_parecerCtrl.text != parecer) {
        _parecerCtrl.text = parecer;
      }
      if (_decisaoRecursosCtrl.text != decisaoRecursos) {
        _decisaoRecursosCtrl.text = decisaoRecursos;
      }
      if (_linksRecursosCtrl.text != linksRecursos) {
        _linksRecursosCtrl.text = linksRecursos;
      }
    }
  }

  @override
  void dispose() {
    _criterioAplicadoCtrl.dispose();
    _linkAtaCtrl.dispose();
    _recursosHouveCtrl.dispose();
    _parecerCtrl.dispose();
    _decisaoRecursosCtrl.dispose();
    _linksRecursosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      criterioAplicado: _criterioAplicadoCtrl.text,
      linkAta: _linkAtaCtrl.text,
      recursosHouve: _recursosHouveCtrl.text,
      parecer: _parecerCtrl.text,
      decisaoRecursos: _decisaoRecursosCtrl.text,
      linksRecursos: _linksRecursosCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputW4(context, constraints);
        final w1 = inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: 'Julgamento / Ata / Recursos'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w4,
                        child: DropDownButtonChange(
                          enabled: isEditable,
                          labelText: 'Critério aplicado (confirmação)',
                          controller: _criterioAplicadoCtrl,
                          items: HiringData.criterioJulgamento,
                          onChanged: (v) {
                            final text = v ?? '';
                            if (_criterioAplicadoCtrl.text != text) {
                              _criterioAplicadoCtrl.text = text;
                            }
                            _emitChange();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w4,
                        child: CustomTextField(
                          controller: _linkAtaCtrl,
                          labelText: 'Link da Ata da Sessão',
                          enabled: isEditable,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w4,
                        child: YesNoDrop(
                          enabled: isEditable,
                          labelText: 'Houve recursos?',
                          value: _recursosHouveCtrl.text,
                          controller: (v) {
                            final text = v ?? '';
                            if (_recursosHouveCtrl.text != text) {
                              _recursosHouveCtrl.text = text;
                            }
                            _emitChange();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _parecerCtrl,
                    labelText: 'Parecer/Justificativas do julgamento',
                    maxLines: 7,
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _decisaoRecursosCtrl,
                    labelText: 'Decisão dos recursos (se houver)',
                    maxLines: 7,
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _linksRecursosCtrl,
                    labelText: 'Links dos recursos/decisões',
                    maxLines: 7,
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
