// lib/screens/modules/contracts/hiring/2Etp/section_5_cronograma_indicadores.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionCronogramaIndicadores extends StatefulWidget {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  const SectionCronogramaIndicadores({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionCronogramaIndicadores> createState() =>
      _SectionCronogramaIndicadoresState();
}

class _SectionCronogramaIndicadoresState
    extends State<SectionCronogramaIndicadores> {
  late final TextEditingController _vigenciaMesesCtrl;
  late final TextEditingController _prazoDiasCtrl;
  late final TextEditingController _criteriosAceiteCtrl;
  late final TextEditingController _indicadoresCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _vigenciaMesesCtrl =
        TextEditingController(text: d.tempoVigenciaMeses ?? '');
    _prazoDiasCtrl =
        TextEditingController(text: d.prazoExecucaoDias ?? '');
    _criteriosAceiteCtrl =
        TextEditingController(text: d.criteriosAceite ?? '');
    _indicadoresCtrl =
        TextEditingController(text: d.indicadoresDesempenho ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionCronogramaIndicadores oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void _sync(TextEditingController c, String? v) {
        final s = v ?? '';
        if (c.text != s) c.text = s;
      }

      final d = widget.data;
      _sync(_vigenciaMesesCtrl, d.tempoVigenciaMeses);
      _sync(_prazoDiasCtrl, d.prazoExecucaoDias);
      _sync(_criteriosAceiteCtrl, d.criteriosAceite);
      _sync(_indicadoresCtrl, d.indicadoresDesempenho);
    }
  }

  @override
  void dispose() {
    _vigenciaMesesCtrl.dispose();
    _prazoDiasCtrl.dispose();
    _criteriosAceiteCtrl.dispose();
    _indicadoresCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        tempoVigenciaMeses: _vigenciaMesesCtrl.text,
        prazoExecucaoDias: _prazoDiasCtrl.text,
        criteriosAceite: _criteriosAceiteCtrl.text,
        indicadoresDesempenho: _indicadoresCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);
        inputW1(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              text: '5) Cronograma, indicadores e aceite (preliminares)',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: _vigenciaMesesCtrl,
                          enabled: widget.isEditable,
                          labelText: 'Vigência estimada (meses)',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: _prazoDiasCtrl,
                          enabled: widget.isEditable,
                          labelText: 'Prazo estimado (dias)',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _criteriosAceiteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Critérios de medição e aceite',
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _indicadoresCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Indicadores de desempenho',
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
