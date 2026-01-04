// lib/screens/process/hiring/5Edital/section_1_divulgacao_recebimento.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart'
    show DropDownButtonChange;
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

class SectionDivulgacaoRecebimento extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;

  const SectionDivulgacaoRecebimento({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionDivulgacaoRecebimento> createState() =>
      _SectionDivulgacaoRecebimentoState();
}

class _SectionDivulgacaoRecebimentoState
    extends State<SectionDivulgacaoRecebimento>
    with FormValidationMixin {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _modalidadeCtrl;
  late final TextEditingController _criterioCtrl;
  late final TextEditingController _dataPublicacaoCtrl;
  late final TextEditingController _prazoImpugnacaoCtrl;
  late final TextEditingController _idPncpCtrl;
  late final TextEditingController _linkPncpCtrl;
  late final TextEditingController _prazoPropostasCtrl;
  late final TextEditingController _observacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.numero ?? '');
    _modalidadeCtrl = TextEditingController(text: d.modalidade ?? '');
    _criterioCtrl = TextEditingController(text: d.criterio ?? '');
    _dataPublicacaoCtrl =
        TextEditingController(text: d.dataPublicacao ?? '');
    _prazoImpugnacaoCtrl =
        TextEditingController(text: d.prazoImpugnacao ?? '');
    _idPncpCtrl = TextEditingController(text: d.idPncp ?? '');
    _linkPncpCtrl = TextEditingController(text: d.linkPncp ?? '');
    _prazoPropostasCtrl =
        TextEditingController(text: d.prazoPropostas ?? '');
    _observacoesCtrl =
        TextEditingController(text: d.observacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionDivulgacaoRecebimento oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      final numero = d.numero ?? '';
      final modalidade = d.modalidade ?? '';
      final criterio = d.criterio ?? '';
      final dataPub = d.dataPublicacao ?? '';
      final prazoImp = d.prazoImpugnacao ?? '';
      final idPncp = d.idPncp ?? '';
      final linkPncp = d.linkPncp ?? '';
      final prazoProp = d.prazoPropostas ?? '';
      final obs = d.observacoes ?? '';

      if (_numeroCtrl.text != numero) {
        _numeroCtrl.text = numero;
      }
      if (_modalidadeCtrl.text != modalidade) {
        _modalidadeCtrl.text = modalidade;
      }
      if (_criterioCtrl.text != criterio) {
        _criterioCtrl.text = criterio;
      }
      if (_dataPublicacaoCtrl.text != dataPub) {
        _dataPublicacaoCtrl.text = dataPub;
      }
      if (_prazoImpugnacaoCtrl.text != prazoImp) {
        _prazoImpugnacaoCtrl.text = prazoImp;
      }
      if (_idPncpCtrl.text != idPncp) {
        _idPncpCtrl.text = idPncp;
      }
      if (_linkPncpCtrl.text != linkPncp) {
        _linkPncpCtrl.text = linkPncp;
      }
      if (_prazoPropostasCtrl.text != prazoProp) {
        _prazoPropostasCtrl.text = prazoProp;
      }
      if (_observacoesCtrl.text != obs) {
        _observacoesCtrl.text = obs;
      }
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _modalidadeCtrl.dispose();
    _criterioCtrl.dispose();
    _dataPublicacaoCtrl.dispose();
    _prazoImpugnacaoCtrl.dispose();
    _idPncpCtrl.dispose();
    _linkPncpCtrl.dispose();
    _prazoPropostasCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numero: _numeroCtrl.text,
      modalidade: _modalidadeCtrl.text,
      criterio: _criterioCtrl.text,
      dataPublicacao: _dataPublicacaoCtrl.text,
      prazoImpugnacao: _prazoImpugnacaoCtrl.text,
      idPncp: _idPncpCtrl.text,
      linkPncp: _linkPncpCtrl.text,
      prazoPropostas: _prazoPropostasCtrl.text,
      observacoes: _observacoesCtrl.text,
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
            const SectionTitle(
              text: '1) Divulgação do Edital & Recebimento',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _numeroCtrl,
                    labelText: 'Nº do edital/processo',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: isEditable,
                    labelText: 'Modalidade',
                    controller: _modalidadeCtrl,
                    items: HiringData.modalidadeDeContratacao,
                    onChanged: (v) {
                      final text = v ?? '';
                      if (_modalidadeCtrl.text != text) {
                        _modalidadeCtrl.text = text;
                      }
                      _emitChange();
                    },
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: isEditable,
                    labelText: 'Critério de julgamento',
                    controller: _criterioCtrl,
                    items: HiringData.criterioJulgamento,
                    onChanged: (v) {
                      final text = v ?? '';
                      if (_criterioCtrl.text != text) {
                        _criterioCtrl.text = text;
                      }
                      _emitChange();
                    },
                    validator: validateRequired,
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataPublicacaoCtrl,
                    labelText: 'Data publicação',
                    enabled: isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _prazoImpugnacaoCtrl,
                    labelText: 'Prazo impugnação',
                    enabled: isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      TextInputMask(mask: '99/99/9999'),
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _idPncpCtrl,
                    labelText: 'ID PNCP',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _linkPncpCtrl,
                    labelText: 'Link PNCP',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _prazoPropostasCtrl,
                    labelText: 'Limite para propostas dd/mm/aaaa hh:mm',
                    enabled: isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _observacoesCtrl,
                    labelText: 'Observações',
                    enabled: isEditable,
                    maxLines: 2,
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
