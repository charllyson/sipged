import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_data.dart';

class SectionPartesValoresVigencia extends StatefulWidget {
  final bool isEditable;
  final PublicacaoExtratoData data;
  final void Function(PublicacaoExtratoData updated) onChanged;

  const SectionPartesValoresVigencia({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionPartesValoresVigencia> createState() =>
      _SectionPartesValoresVigenciaState();
}

class _SectionPartesValoresVigenciaState
    extends State<SectionPartesValoresVigencia> with FormValidationMixin {
  late final TextEditingController _contratadaRazaoCtrl;
  late final TextEditingController _contratadaCnpjCtrl;
  late final TextEditingController _cnoCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _vigenciaCtrl;

  @override
  void initState() {
    super.initState();
    _contratadaRazaoCtrl =
        TextEditingController(text: widget.data.contratadaRazao ?? '');
    _contratadaCnpjCtrl =
        TextEditingController(text: widget.data.contratadaCnpj ?? '');
    _cnoCtrl = TextEditingController(text: widget.data.cnoRef ?? '');
    _valorCtrl = TextEditingController(
      text: widget.data.valor?.toString() ?? '',
    );
    _vigenciaCtrl = TextEditingController(
      text: widget.data.vigencia?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant SectionPartesValoresVigencia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _contratadaRazaoCtrl.text = widget.data.contratadaRazao ?? '';
      _contratadaCnpjCtrl.text = widget.data.contratadaCnpj ?? '';
      _cnoCtrl.text = widget.data.cnoRef ?? '';
      _valorCtrl.text = widget.data.valor?.toString() ?? '';
      _vigenciaCtrl.text = widget.data.vigencia?.toString() ?? '';
    }
  }

  double? _parseValor(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    // aceita "1.234,56" ou "1234.56"
    final normalized =
    raw.replaceAll('.', '').replaceAll(',', '.'); // pt-BR → padrão
    return double.tryParse(normalized);
  }

  int? _parseVigencia(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    // extrai apenas dígitos (permite "12 meses" -> 12)
    final digits =
    RegExp(r'\d+').allMatches(raw).map((m) => m.group(0)!).join();
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      contratadaRazao: _contratadaRazaoCtrl.text,
      contratadaCnpj: _contratadaCnpjCtrl.text,
      cnoRef: _cnoCtrl.text.isEmpty ? null : _cnoCtrl.text,
      valor: _parseValor(_valorCtrl.text),
      vigencia: _parseVigencia(_vigenciaCtrl.text),
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _contratadaRazaoCtrl.dispose();
    _contratadaCnpjCtrl.dispose();
    _cnoCtrl.dispose();
    _valorCtrl.dispose();
    _vigenciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Partes, Valores e Vigência'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w5 = inputW5(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _contratadaRazaoCtrl,
                    labelText: 'Contratada (Razão Social)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _contratadaCnpjCtrl,
                    labelText: 'CNPJ',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                      TextInputMask(mask: '99.999.999/9999-99'),
                    ],
                    keyboardType: TextInputType.number,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _cnoCtrl,
                    labelText: 'CNO',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _valorCtrl,
                    labelText: 'Valor (R\$)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _vigenciaCtrl,
                    labelText: 'Vigência (dias)',
                    enabled: widget.isEditable,
                    keyboardType: TextInputType.number,
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
