// lib/screens/modules/contracts/hiring/2Etp/section_6_premissas_restricoes_licenciamento.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionPremissasRestricoesLicenciamento extends StatefulWidget {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  const SectionPremissasRestricoesLicenciamento({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionPremissasRestricoesLicenciamento> createState() =>
      _SectionPremissasRestricoesLicenciamentoState();
}

class _SectionPremissasRestricoesLicenciamentoState
    extends State<SectionPremissasRestricoesLicenciamento> {
  late final TextEditingController _licenciamentoCtrl;
  late final TextEditingController _obsAmbientaisCtrl;
  late final TextEditingController _premissasCtrl;
  late final TextEditingController _restricoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _licenciamentoCtrl =
        TextEditingController(text: d.licenciamentoAmbiental ?? '');
    _obsAmbientaisCtrl =
        TextEditingController(text: d.observacoesAmbientais ?? '');
    _premissasCtrl = TextEditingController(text: d.premissas ?? '');
    _restricoesCtrl = TextEditingController(text: d.restricoes ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionPremissasRestricoesLicenciamento oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void sync(TextEditingController c, String? v) {
        final s = v ?? '';
        if (c.text != s) c.text = s;
      }

      final d = widget.data;
      sync(_licenciamentoCtrl, d.licenciamentoAmbiental);
      sync(_obsAmbientaisCtrl, d.observacoesAmbientais);
      sync(_premissasCtrl, d.premissas);
      sync(_restricoesCtrl, d.restricoes);
    }
  }

  @override
  void dispose() {
    _licenciamentoCtrl.dispose();
    _obsAmbientaisCtrl.dispose();
    _premissasCtrl.dispose();
    _restricoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        licenciamentoAmbiental: _licenciamentoCtrl.text,
        observacoesAmbientais: _obsAmbientaisCtrl.text,
        premissas: _premissasCtrl.text,
        restricoes: _restricoesCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '6) Premissas, restrições e licenciamento'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: w3,
                      child: DropDownButtonChange(
                        enabled: widget.isEditable,
                        labelText: 'Licenciamento ambiental necessário?',
                        controller: _licenciamentoCtrl,
                        items: const ['Sim', 'Não', 'A confirmar'],
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: w3,
                      child: CustomTextField(
                        controller: _obsAmbientaisCtrl,
                        enabled: widget.isEditable,
                        labelText: 'Observações ambientais',
                        maxLines: 1,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _premissasCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Premissas',
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _restricoesCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Restrições',
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
