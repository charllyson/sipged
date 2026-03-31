import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart'
    show DropDownChange;
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

class SectionVeiculoPublicacao extends StatefulWidget {
  final bool isEditable;
  final PublicacaoExtratoData data;
  final void Function(PublicacaoExtratoData updated) onChanged;

  const SectionVeiculoPublicacao({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionVeiculoPublicacao> createState() =>
      _SectionVeiculoPublicacaoState();
}

class _SectionVeiculoPublicacaoState extends State<SectionVeiculoPublicacao>
    with SipGedValidation {
  late final TextEditingController _veiculoCtrl;
  late final TextEditingController _edicaoNumeroCtrl;
  late final TextEditingController _dataEnvioCtrl;
  late final TextEditingController _dataPublicacaoCtrl;
  late final TextEditingController _linkPublicacaoCtrl;

  @override
  void initState() {
    super.initState();
    _veiculoCtrl = TextEditingController(text: widget.data.veiculo ?? '');
    _edicaoNumeroCtrl =
        TextEditingController(text: widget.data.edicaoNumero ?? '');
    _dataEnvioCtrl =
        TextEditingController(text: _formatDate(widget.data.dataEnvio));
    _dataPublicacaoCtrl =
        TextEditingController(text: _formatDate(widget.data.dataPublicacao));
    _linkPublicacaoCtrl =
        TextEditingController(text: widget.data.linkPublicacao ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionVeiculoPublicacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      final veiculo = d.veiculo ?? '';
      final edicao = d.edicaoNumero ?? '';
      final dataEnvio = _formatDate(d.dataEnvio);
      final dataPublicacao = _formatDate(d.dataPublicacao);
      final link = d.linkPublicacao ?? '';

      if (_veiculoCtrl.text != veiculo) {
        _veiculoCtrl.text = veiculo;
      }
      if (_edicaoNumeroCtrl.text != edicao) {
        _edicaoNumeroCtrl.text = edicao;
      }
      if (_dataEnvioCtrl.text != dataEnvio) {
        _dataEnvioCtrl.text = dataEnvio;
      }
      if (_dataPublicacaoCtrl.text != dataPublicacao) {
        _dataPublicacaoCtrl.text = dataPublicacao;
      }
      if (_linkPublicacaoCtrl.text != link) {
        _linkPublicacaoCtrl.text = link;
      }
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  DateTime? _parseDate(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(s);
    if (m == null) return null;
    try {
      final day = int.parse(m.group(1)!);
      final month = int.parse(m.group(2)!);
      final year = int.parse(m.group(3)!);
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      veiculo: _veiculoCtrl.text,
      edicaoNumero: _edicaoNumeroCtrl.text,
      dataEnvio: _parseDate(_dataEnvioCtrl.text),
      dataPublicacao: _parseDate(_dataPublicacaoCtrl.text),
      linkPublicacao: _linkPublicacaoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _veiculoCtrl.dispose();
    _edicaoNumeroCtrl.dispose();
    _dataEnvioCtrl.dispose();
    _dataPublicacaoCtrl.dispose();
    _linkPublicacaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.isEditable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '3) Veículo de Publicação'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w5 = inputW5(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w5,
                  child: DropDownChange(
                    enabled: isEditable,
                    labelText: 'Veículo',
                    controller: _veiculoCtrl,
                    items: HiringData.veiculoDivulgacao,
                    onChanged: (v) {
                      final text = v ?? '';
                      if (_veiculoCtrl.text != text) {
                        _veiculoCtrl.text = text;
                      }
                      _emitChange();
                      setState(() {});
                    },
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _edicaoNumeroCtrl,
                    labelText: 'Edição/Nº',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DateFieldChange(
                    controller: _dataEnvioCtrl,
                    labelText: 'Data de envio',
                    enabled: isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: DateFieldChange(
                    controller: _dataPublicacaoCtrl,
                    labelText: 'Data da publicação',
                    enabled: isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w5,
                  child: CustomTextField(
                    controller: _linkPublicacaoCtrl,
                    labelText: 'Link da publicação (URL/PNCP/arquivo)',
                    enabled: isEditable,
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
