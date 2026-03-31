// lib/screens/modules/contracts/hiring/2Etp/section_4_mercado_estimativa.dart
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart'
    show DropDownChange;
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_data.dart';

class SectionMercadoEstimativa extends StatefulWidget {
  final EtpData data;
  final bool isEditable;
  final void Function(EtpData updated) onChanged;

  const SectionMercadoEstimativa({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionMercadoEstimativa> createState() =>
      _SectionMercadoEstimativaState();
}

class _SectionMercadoEstimativaState
    extends State<SectionMercadoEstimativa> {
  late final TextEditingController _metodoCtrl;
  late final TextEditingController _estimativaValorCtrl;
  late final TextEditingController _analiseMercadoCtrl;
  late final TextEditingController _beneficiosCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _metodoCtrl = TextEditingController(text: d.metodoEstimativa ?? '');
    _estimativaValorCtrl =
        TextEditingController(text: d.estimativaValor ?? '');
    _analiseMercadoCtrl =
        TextEditingController(text: d.analiseMercado ?? '');
    _beneficiosCtrl =
        TextEditingController(text: d.beneficiosEsperados ?? '');
  }

  @override
  void didUpdateWidget(
      covariant SectionMercadoEstimativa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      void sync(TextEditingController c, String? v) {
        final s = v ?? '';
        if (c.text != s) c.text = s;
      }

      final d = widget.data;
      sync(_metodoCtrl, d.metodoEstimativa);
      sync(_estimativaValorCtrl, d.estimativaValor);
      sync(_analiseMercadoCtrl, d.analiseMercado);
      sync(_beneficiosCtrl, d.beneficiosEsperados);
    }
  }

  @override
  void dispose() {
    _metodoCtrl.dispose();
    _estimativaValorCtrl.dispose();
    _analiseMercadoCtrl.dispose();
    _beneficiosCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    widget.onChanged(
      widget.data.copyWith(
        metodoEstimativa: _metodoCtrl.text,
        estimativaValor: _estimativaValorCtrl.text,
        analiseMercado: _analiseMercadoCtrl.text,
        beneficiosEsperados: _beneficiosCtrl.text,
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
            const SectionTitle(
                text: '4) Mercado e estimativa de custos/benefícios'),
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
                        child: DropDownChange(
                          enabled: widget.isEditable,
                          labelText: 'Metodologia',
                          controller: _metodoCtrl,
                          items: HiringData.metodologia,
                          onChanged: (_) => _emitChange(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: w3,
                        child: CustomTextField(
                          controller: _estimativaValorCtrl,
                          enabled: widget.isEditable,
                          labelText: 'Estimativa de valor (R\$)',
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
                    controller: _analiseMercadoCtrl,
                    enabled: widget.isEditable,
                    labelText:
                    'Análise de mercado / fornecedores potenciais',
                    maxLines: 5,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _beneficiosCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Benefícios esperados',
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
