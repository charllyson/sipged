import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_rule.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/single/single_symbology.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class RuleDetails extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final GeoLayersDataRule rule;
  final List<String> availableFields;
  final String Function(LayerRuleOperator op) operatorLabel;
  final LayerRuleOperator Function(String? label) operatorFromLabel;
  final ValueChanged<GeoLayersDataRule> onChanged;

  const RuleDetails({
    super.key,
    required this.geometryKind,
    required this.rule,
    required this.availableFields,
    required this.operatorLabel,
    required this.operatorFromLabel,
    required this.onChanged,
  });

  @override
  State<RuleDetails> createState() => _RuleDetailsState();
}

class _RuleDetailsState extends State<RuleDetails> {
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
    _syncFromRule();
  }

  @override
  void didUpdateWidget(covariant RuleDetails oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.rule != widget.rule) {
      _syncFromRule();
    }
  }

  void _syncFromRule() {
    _labelCtrl.text = widget.rule.label;
    _fieldCtrl.text = widget.rule.field;
    _operatorCtrl.text = widget.operatorLabel(widget.rule.operatorType);
    _valueCtrl.text = widget.rule.value;
    _minZoomCtrl.text = widget.rule.minZoom?.toString() ?? '';
    _maxZoomCtrl.text = widget.rule.maxZoom?.toString() ?? '';
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

  void _emit(GeoLayersDataRule value) {
    widget.onChanged(value);
  }

  bool get _hideValueField {
    return widget.rule.operatorType == LayerRuleOperator.isEmpty ||
        widget.rule.operatorType == LayerRuleOperator.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 760;
        final fieldWidth = isSmall ? constraints.maxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    onChanged: (v) => _emit(rule.copyWith(label: v)),
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
                    value: rule.enabled,
                    onChanged: (v) => _emit(rule.copyWith(enabled: v ?? true)),
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
                  child: DropDownButtonChange(
                    controller: _fieldCtrl,
                    labelText: 'Campo',
                    width: double.infinity,
                    items: widget.availableFields,
                    enabled: widget.availableFields.isNotEmpty,
                    onChanged: (v) {
                      _emit(rule.copyWith(field: v ?? ''));
                    },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropDownButtonChange(
                    controller: _operatorCtrl,
                    labelText: 'Operador',
                    width: double.infinity,
                    items: LayerRuleOperator.values
                        .map(widget.operatorLabel)
                        .toList(growable: false),
                    onChanged: (v) {
                      _emit(
                        rule.copyWith(
                          operatorType: widget.operatorFromLabel(v),
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
                      onChanged: (v) => _emit(rule.copyWith(value: v)),
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
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      _emit(
                        v.trim().isEmpty
                            ? rule.copyWith(clearMinZoom: true)
                            : rule.copyWith(minZoom: parsed),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: isSmall ? constraints.maxWidth : 260,
                  child: CustomTextField(
                    controller: _maxZoomCtrl,
                    labelText: 'Escala máxima / zoom máximo',
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      _emit(
                        v.trim().isEmpty
                            ? rule.copyWith(clearMaxZoom: true)
                            : rule.copyWith(maxZoom: parsed),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleSymbology(
              geometryKind: widget.geometryKind,
              symbolLayers: rule.symbolLayers,
              onChanged: (layers) {
                _emit(rule.copyWith(symbolLayers: layers));
              },
            ),
          ],
        );
      },
    );
  }
}