// lib/screens/process/hiring/4Cotacao/section_2_objeto_itens.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_data.dart';

class SectionObjetoItens extends StatefulWidget {
  final CotacaoData data;
  final bool isEditable;
  final void Function(CotacaoData updated) onChanged;

  const SectionObjetoItens({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionObjetoItens> createState() => _SectionObjetoItensState();
}

class _SectionObjetoItensState extends State<SectionObjetoItens>
    with FormValidationMixin {
  late final TextEditingController _unidadeMedidaCtrl;
  late final TextEditingController _quantidadeCtrl;
  late final TextEditingController _objetoCtrl;
  late final TextEditingController _especificacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _unidadeMedidaCtrl =
        TextEditingController(text: d.unidadeMedida ?? '');
    _quantidadeCtrl = TextEditingController(text: d.quantidade ?? '');
    _objetoCtrl = TextEditingController(text: d.objeto ?? '');
    _especificacoesCtrl =
        TextEditingController(text: d.especificacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionObjetoItens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_unidadeMedidaCtrl, d.unidadeMedida);
      _sync(_quantidadeCtrl, d.quantidade);
      _sync(_objetoCtrl, d.objeto);
      _sync(_especificacoesCtrl, d.especificacoes);
    }
  }

  @override
  void dispose() {
    _unidadeMedidaCtrl.dispose();
    _quantidadeCtrl.dispose();
    _objetoCtrl.dispose();
    _especificacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      unidadeMedida: _unidadeMedidaCtrl.text,
      quantidade: _quantidadeCtrl.text,
      objeto: _objetoCtrl.text,
      especificacoes: _especificacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w3 = inputW3(context, constraints);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(text: '2) Objeto/Itens (resumo)'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: Column(
                    children: [
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: _unidadeMedidaCtrl,
                          labelText: 'Unidade de medida',
                          enabled: widget.isEditable,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: _quantidadeCtrl,
                          labelText: 'Quantidade estimada',
                          enabled: widget.isEditable,
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
                    controller: _objetoCtrl,
                    labelText: 'Objeto/escopo resumido da cotação',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _especificacoesCtrl,
                    labelText: 'Especificações técnicas relevantes',
                    maxLines: 4,
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
