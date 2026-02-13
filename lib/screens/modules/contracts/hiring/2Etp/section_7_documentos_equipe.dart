// lib/screens/modules/contracts/hiring/2Etp/section_7_documentos_equipe.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionDocumentosEquipe extends StatefulWidget {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  const SectionDocumentosEquipe({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionDocumentosEquipe> createState() =>
      _SectionDocumentosEquipeState();
}

class _SectionDocumentosEquipeState extends State<SectionDocumentosEquipe> {
  late final TextEditingController _levantamentosCtrl;
  late final TextEditingController _projetoExistenteCtrl;
  late final TextEditingController _linksEvidenciasCtrl;
  late final TextEditingController _equipeCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _levantamentosCtrl =
        TextEditingController(text: d.levantamentosCampo ?? '');
    _projetoExistenteCtrl =
        TextEditingController(text: d.projetoExistente ?? '');
    _linksEvidenciasCtrl =
        TextEditingController(text: d.linksEvidencias ?? '');
    _equipeCtrl = TextEditingController(text: d.equipeEnvolvida ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionDocumentosEquipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void sync(TextEditingController c, String? v) {
        final s = v ?? '';
        if (c.text != s) c.text = s;
      }

      final d = widget.data;
      sync(_levantamentosCtrl, d.levantamentosCampo);
      sync(_projetoExistenteCtrl, d.projetoExistente);
      sync(_linksEvidenciasCtrl, d.linksEvidencias);
      sync(_equipeCtrl, d.equipeEnvolvida);
    }
  }

  @override
  void dispose() {
    _levantamentosCtrl.dispose();
    _projetoExistenteCtrl.dispose();
    _linksEvidenciasCtrl.dispose();
    _equipeCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        levantamentosCampo: _levantamentosCtrl.text,
        projetoExistente: _projetoExistenteCtrl.text,
        linksEvidencias: _linksEvidenciasCtrl.text,
        equipeEnvolvida: _equipeCtrl.text,
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
            const SectionTitle(text: '7) Documentos, evidências e equipe'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Levantamentos de campo',
                    controller: _levantamentosCtrl,
                    items: const ['Sim', 'Não'],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Projeto básico/executivo existente?',
                    controller: _projetoExistenteCtrl,
                    items: const ['Sim', 'Não'],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _linksEvidenciasCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Links / referências de evidências',
                    maxLines: 2,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _equipeCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Equipe envolvida (nomes/cargos)',
                    maxLines: 3,
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
