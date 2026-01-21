import 'package:flutter/material.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart';

class SectionCronograma extends StatefulWidget {
  final DotacaoData data;
  final bool isEditable;
  final void Function(DotacaoData updated) onChanged;

  const SectionCronograma({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionCronograma> createState() => _SectionCronogramaState();
}

class _SectionCronogramaState extends State<SectionCronograma> {
  late final TextEditingController _desembolsoPeriodicidadeCtrl;
  late final TextEditingController _desembolsoMesesCtrl;
  late final TextEditingController _desembolsoObservacoesCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _desembolsoPeriodicidadeCtrl =
        TextEditingController(text: d.desembolsoPeriodicidade ?? '');
    _desembolsoMesesCtrl =
        TextEditingController(text: d.desembolsoMeses ?? '');
    _desembolsoObservacoesCtrl =
        TextEditingController(text: d.desembolsoObservacoes ?? '');
  }

  @override
  void didUpdateWidget(covariant SectionCronograma oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_desembolsoPeriodicidadeCtrl, d.desembolsoPeriodicidade);
      _sync(_desembolsoMesesCtrl, d.desembolsoMeses);
      _sync(_desembolsoObservacoesCtrl, d.desembolsoObservacoes);
    }
  }

  @override
  void dispose() {
    _desembolsoPeriodicidadeCtrl.dispose();
    _desembolsoMesesCtrl.dispose();
    _desembolsoObservacoesCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      desembolsoPeriodicidade: _desembolsoPeriodicidadeCtrl.text,
      desembolsoMeses: _desembolsoMesesCtrl.text,
      desembolsoObservacoes: _desembolsoObservacoesCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    const periodicidades = ['Mensal', 'Bimestral', 'Trimestral', 'Outro'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '6) Cronograma de Desembolso (resumo)'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);
            final w2 = inputW2(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Periodicidade',
                    controller: _desembolsoPeriodicidadeCtrl,
                    items: periodicidades,
                    onChanged: (v) {
                      _desembolsoPeriodicidadeCtrl.text = v ?? '';
                      _emitChange();
                    },
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _desembolsoMesesCtrl,
                    labelText: 'Meses/Marcos (ex.: Jan–Jun)',
                    enabled: widget.isEditable,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w2,
                  child: CustomTextField(
                    controller: _desembolsoObservacoesCtrl,
                    labelText: 'Observações / condicionantes',
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
