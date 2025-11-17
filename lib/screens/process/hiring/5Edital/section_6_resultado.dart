// lib/screens/process/hiring/5Edital/section_6_resultado.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_data.dart';

class SectionResultado extends StatefulWidget {
  final bool isEditable;
  final EditalData data;
  final void Function(EditalData updated) onChanged;
  final GlobalKey? keyResultado;

  const SectionResultado({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
    this.keyResultado,
  });

  @override
  State<SectionResultado> createState() => _SectionResultadoState();
}

class _SectionResultadoState extends State<SectionResultado> {
  late final TextEditingController _vencedorCtrl;
  late final TextEditingController _vencedorCnpjCtrl;
  late final TextEditingController _valorVencedorCtrl;
  late final TextEditingController _dataResultadoCtrl;
  late final TextEditingController _adjudicacaoDataCtrl;
  late final TextEditingController _homologacaoDataCtrl;
  late final TextEditingController _adjudicacaoLinkCtrl;
  late final TextEditingController _homologacaoLinkCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _vencedorCtrl = TextEditingController(text: d.vencedor);
    _vencedorCnpjCtrl = TextEditingController(text: d.vencedorCnpj);
    _valorVencedorCtrl = TextEditingController(text: d.valorVencedor);
    _dataResultadoCtrl = TextEditingController(text: d.dataResultado);
    _adjudicacaoDataCtrl = TextEditingController(text: d.adjudicacaoData);
    _homologacaoDataCtrl = TextEditingController(text: d.homologacaoData);
    _adjudicacaoLinkCtrl = TextEditingController(text: d.adjudicacaoLink);
    _homologacaoLinkCtrl = TextEditingController(text: d.homologacaoLink);
  }

  @override
  void didUpdateWidget(covariant SectionResultado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _vencedorCtrl.text = d.vencedor;
      _vencedorCnpjCtrl.text = d.vencedorCnpj;
      _valorVencedorCtrl.text = d.valorVencedor;
      _dataResultadoCtrl.text = d.dataResultado;
      _adjudicacaoDataCtrl.text = d.adjudicacaoData;
      _homologacaoDataCtrl.text = d.homologacaoData;
      _adjudicacaoLinkCtrl.text = d.adjudicacaoLink;
      _homologacaoLinkCtrl.text = d.homologacaoLink;
    }
  }

  @override
  void dispose() {
    _vencedorCtrl.dispose();
    _vencedorCnpjCtrl.dispose();
    _valorVencedorCtrl.dispose();
    _dataResultadoCtrl.dispose();
    _adjudicacaoDataCtrl.dispose();
    _homologacaoDataCtrl.dispose();
    _adjudicacaoLinkCtrl.dispose();
    _homologacaoLinkCtrl.dispose();
    super.dispose();
  }

  void _emitChange({bool? highlightWinner}) {
    final updated = widget.data.copyWith(
      vencedor: _vencedorCtrl.text,
      vencedorCnpj: _vencedorCnpjCtrl.text,
      valorVencedor: _valorVencedorCtrl.text,
      dataResultado: _dataResultadoCtrl.text,
      adjudicacaoData: _adjudicacaoDataCtrl.text,
      homologacaoData: _homologacaoDataCtrl.text,
      adjudicacaoLink: _adjudicacaoLinkCtrl.text,
      homologacaoLink: _homologacaoLinkCtrl.text,
      highlightWinner: highlightWinner ?? widget.data.highlightWinner,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isEditable = widget.isEditable;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasWinner =
        d.vencedor.trim().isNotEmpty && d.highlightWinner == true;

    final baseBg =
    isDark ? cs.surfaceVariant.withOpacity(0.6) : Colors.grey.shade100;
    final baseBorder = cs.outlineVariant;

    final winnerBg = Colors.green.shade50;
    final winnerBorder = Colors.green.shade600;

    final cardBg = hasWinner ? winnerBg : baseBg;
    final cardBorder = hasWinner ? winnerBorder : baseBorder;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w4 = inputWidth(
          context: context,
          inner: constraints,
          perLine: 4,
          minItemWidth: 260,
          extraPadding: 32,
          spacing: 12,
        );

        return KeyedSubtree(
          key: widget.keyResultado,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cardBorder,
                width: hasWinner ? 2 : 1,
              ),
              boxShadow: hasWinner
                  ? [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  color: Colors.green.withOpacity(0.18),
                ),
              ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SectionTitle(
                      'Resultado / Adjudicação / Homologação',
                    ),
                    const SizedBox(width: 8),
                    if (hasWinner)
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 18,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vencedor definido',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (isEditable)
                      Row(
                        children: [
                          const Text('Destacar vencedor'),
                          Switch(
                            value: d.highlightWinner,
                            onChanged: (v) => _emitChange(
                              highlightWinner: v,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _vencedorCtrl,
                        labelText: 'Vencedor',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _vencedorCnpjCtrl,
                        labelText: 'CNPJ do vencedor',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _valorVencedorCtrl,
                        labelText: 'Valor vencedor (R\$)',
                        enabled: isEditable,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomDateField(
                        controller: _dataResultadoCtrl,
                        labelText: 'Data do resultado',
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
                        controller: _adjudicacaoDataCtrl,
                        labelText: 'Data da adjudicação',
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
                        controller: _homologacaoDataCtrl,
                        labelText: 'Data da homologação',
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
                        controller: _adjudicacaoLinkCtrl,
                        labelText: 'Link da adjudicação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                    SizedBox(
                      width: w4,
                      child: CustomTextField(
                        controller: _homologacaoLinkCtrl,
                        labelText: 'Link da homologação',
                        enabled: isEditable,
                        onChanged: (_) => _emitChange(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
