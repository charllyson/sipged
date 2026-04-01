import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_core.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/rules/layer_rule_data.dart';

class LayerRuleEditor extends StatefulWidget {
  final LayerRuleData value;
  final List<String> availableFields;
  final ValueChanged<LayerRuleData> onChanged;
  final Widget? preview;
  final Widget child;

  const LayerRuleEditor({
    super.key,
    required this.value,
    required this.availableFields,
    required this.onChanged,
    required this.child,
    this.preview,
  });

  @override
  State<LayerRuleEditor> createState() => _LayerRuleEditorState();
}

class _LayerRuleEditorState extends State<LayerRuleEditor> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _fieldCtrl;
  late final TextEditingController _operatorCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _minZoomCtrl;
  late final TextEditingController _maxZoomCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController();
    _fieldCtrl = TextEditingController();
    _operatorCtrl = TextEditingController();
    _valueCtrl = TextEditingController();
    _minZoomCtrl = TextEditingController();
    _maxZoomCtrl = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant LayerRuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    _labelCtrl.text = widget.value.label;
    _fieldCtrl.text = widget.value.field;
    _operatorCtrl.text = LayerRuleCore.operatorLabel(widget.value.operatorType);
    _valueCtrl.text = widget.value.value;
    _minZoomCtrl.text = widget.value.minZoom?.toString() ?? '';
    _maxZoomCtrl.text = widget.value.maxZoom?.toString() ?? '';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _fieldCtrl.dispose();
    _operatorCtrl.dispose();
    _valueCtrl.dispose();
    _minZoomCtrl.dispose();
    _maxZoomCtrl.dispose();
    super.dispose();
  }

  void _emit(LayerRuleData next) {
    _operatorCtrl.text = LayerRuleCore.operatorLabel(next.operatorType);
    widget.onChanged(next);
  }

  bool get _hideValueField =>
      LayerRuleCore.hidesValueField(widget.value.operatorType);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;
        final fieldWidth = isSmall ? constraints.maxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.preview != null) ...[
              SizedBox(
                height: 150,
                child: widget.preview!,
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: isSmall
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 150).clamp(220.0, 9999.0),
                  child: CustomTextField(
                    controller: _labelCtrl,
                    labelText: 'Rótulo',
                    onChanged: (value) {
                      _emit(widget.value.copyWith(label: value));
                    },
                  ),
                ),
                Container(
                  width: isSmall ? constraints.maxWidth : 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativa'),
                    value: widget.value.enabled,
                    onChanged: (value) {
                      _emit(
                        widget.value.copyWith(enabled: value ?? true),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: DropDownChange(
                    controller: _fieldCtrl,
                    labelText: 'Campo',
                    width: double.infinity,
                    items: widget.availableFields,
                    enabled: widget.availableFields.isNotEmpty,
                    onChanged: (value) {
                      _emit(widget.value.copyWith(field: value ?? ''));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropDownChange(
                    controller: _operatorCtrl,
                    labelText: 'Operador',
                    width: double.infinity,
                    items: LayerRuleOperator.values
                        .map(LayerRuleCore.operatorLabel)
                        .toList(growable: false),
                    onChanged: (value) {
                      _emit(
                        widget.value.copyWith(
                          operatorType: LayerRuleCore.operatorFromLabel(value),
                        ),
                      );
                    },
                  ),
                ),
                if (!_hideValueField)
                  SizedBox(
                    width: fieldWidth,
                    child: CustomTextField(
                      controller: _valueCtrl,
                      labelText: 'Valor',
                      onChanged: (value) {
                        _emit(widget.value.copyWith(value: value));
                      },
                    ),
                  ),
              ],
            ),
            if (widget.availableFields.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Nenhum campo disponível. Carregue a tabela de atributos da camada para usar regras por campo.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 260,
                  child: CustomTextField(
                    controller: _minZoomCtrl,
                    labelText: 'Escala mínima / zoom mínimo',
                    onChanged: (value) {
                      final parsed = double.tryParse(
                        value.replaceAll(',', '.'),
                      );

                      _emit(
                        value.trim().isEmpty
                            ? widget.value.copyWith(clearMinZoom: true)
                            : widget.value.copyWith(minZoom: parsed),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 260,
                  child: CustomTextField(
                    controller: _maxZoomCtrl,
                    labelText: 'Escala máxima / zoom máximo',
                    onChanged: (value) {
                      final parsed = double.tryParse(
                        value.replaceAll(',', '.'),
                      );

                      _emit(
                        value.trim().isEmpty
                            ? widget.value.copyWith(clearMaxZoom: true)
                            : widget.value.copyWith(maxZoom: parsed),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.child,
          ],
        );
      },
    );
  }
}