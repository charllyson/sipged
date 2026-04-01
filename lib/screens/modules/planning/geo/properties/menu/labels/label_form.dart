import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_widgets/draw/colors/colors_change_catalog.dart';
import 'package:sipged/_widgets/draw/icons/icon_picker_grid.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shape_picker.dart';
import 'package:sipged/_utils/number_field.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/screens/modules/planning/geo/properties/menu/share/layer_type/layer_type_section.dart';

class LabelsForm extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final LayerDataLabel label;
  final List<String> availableFields;
  final ValueChanged<LayerDataLabel> onChanged;

  const LabelsForm({
    super.key,
    required this.geometryKind,
    required this.label,
    required this.availableFields,
    required this.onChanged,
  });

  @override
  State<LabelsForm> createState() => _LabelsFormState();
}

class _LabelsFormState extends State<LabelsForm> {
  late LayerDataLabel _local;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _fieldCtrl;

  static const Map<String, FontWeight> _fontWeightMap = {
    'Normal': FontWeight.w400,
    'Médio': FontWeight.w500,
    'Semi-negrito': FontWeight.w600,
    'Negrito': FontWeight.w700,
  };

  @override
  void initState() {
    super.initState();
    _local = widget.label;
    _typeCtrl = TextEditingController(
      text: LayerTypeSection.labelFromType(_local.type),
    );
    _titleCtrl = TextEditingController(text: _local.title);
    _fieldCtrl = TextEditingController(text: _local.text);
  }

  @override
  void didUpdateWidget(covariant LabelsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label ||
        oldWidget.geometryKind != widget.geometryKind ||
        oldWidget.availableFields != widget.availableFields) {
      _local = widget.label;
      _typeCtrl.text = LayerTypeSection.labelFromType(_local.type);
      _titleCtrl.text = _local.title;
      _fieldCtrl.text = _local.text;
    }
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _titleCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  bool get _isTextType => _local.type == LayerSimpleSymbolType.textLayer;

  bool get _showPointLikeControls =>
      _local.type == LayerSimpleSymbolType.svgMarker ||
          _local.type == LayerSimpleSymbolType.simpleMarker;

  void _emit(LayerDataLabel value) {
    _local = value;
    _typeCtrl.text = LayerTypeSection.labelFromType(value.type);
    _titleCtrl.text = value.title;
    _fieldCtrl.text = value.text;
    widget.onChanged(value);
  }

  String _fontWeightLabel(FontWeight weight) {
    for (final entry in _fontWeightMap.entries) {
      if (entry.value == weight) return entry.key;
    }
    return 'Semi-negrito';
  }

  void _updateWidth(double value) {
    if (_local.keepAspectRatio) {
      final ratio = _local.height == 0 ? 1.0 : (_local.width / _local.height);
      final newHeight = ratio == 0 ? _local.height : value / ratio;
      _emit(_local.copyWith(width: value, height: newHeight));
      return;
    }
    _emit(_local.copyWith(width: value));
  }

  void _updateHeight(double value) {
    if (_local.keepAspectRatio) {
      final ratio = _local.width == 0 ? 1.0 : (_local.height / _local.width);
      final newWidth = ratio == 0 ? _local.width : value / ratio;
      _emit(_local.copyWith(height: value, width: newWidth));
      return;
    }
    _emit(_local.copyWith(height: value));
  }

  Widget _buildTextSection(BoxConstraints constraints) {
    final isSmall = constraints.maxWidth < 760;
    final fieldWidth = isSmall ? constraints.maxWidth : 220.0;
    final weightCtrl = TextEditingController(
      text: _fontWeightLabel(_local.fontWeight),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isSmall ? constraints.maxWidth : 320,
              child: CustomTextField(
                controller: _titleCtrl,
                labelText: 'Nome da camada',
                onChanged: (value) {
                  _emit(_local.copyWith(title: value));
                },
              ),
            ),
            Container(
              width: isSmall ? constraints.maxWidth : 140,
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
                value: _local.enabled,
                onChanged: (value) {
                  _emit(_local.copyWith(enabled: value ?? true));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: isSmall ? constraints.maxWidth : 320,
          child: DropDownChange(
            controller: _fieldCtrl,
            labelText: 'Campo do rótulo',
            width: double.infinity,
            items: widget.availableFields,
            enabled: widget.availableFields.isNotEmpty,
            onChanged: (value) {
              _emit(_local.copyWith(text: value ?? ''));
            },
          ),
        ),
        if (widget.availableFields.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Nenhum campo disponível. Carregue a tabela de atributos da camada para vincular o rótulo a um campo.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Tamanho da fonte',
                value: _local.fontSize,
                onChanged: (value) => _emit(_local.copyWith(fontSize: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: DropDownChange(
                controller: weightCtrl,
                labelText: 'Peso da fonte',
                width: double.infinity,
                items: _fontWeightMap.keys.toList(growable: false),
                onChanged: (value) {
                  final weight = _fontWeightMap[value] ?? FontWeight.w600;
                  _emit(_local.copyWith(fontWeight: weight));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ColorsChangeCatalog(
          title: 'Cor do texto',
          selectedColorValue: _local.colorValue,
          onChanged: (value) {
            _emit(_local.copyWith(colorValue: value));
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Offset horizontal (X)',
                value: _local.offsetX,
                onChanged: (value) => _emit(_local.copyWith(offsetX: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Offset vertical (Y)',
                value: _local.offsetY,
                onChanged: (value) => _emit(_local.copyWith(offsetY: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSymbolSection(BoxConstraints constraints) {
    final fillColor = Color(_local.fillColorValue);
    final isSmall = constraints.maxWidth < 760;
    final fieldWidth = isSmall ? constraints.maxWidth : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showPointLikeControls) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: fieldWidth,
                child: NumberField(
                  label: 'Largura (X)',
                  value: _local.width,
                  onChanged: _updateWidth,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: NumberField(
                  label: 'Altura (Y)',
                  value: _local.height,
                  onChanged: _updateHeight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Manter X/Y',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      onPressed: () {
                        _emit(
                          _local.copyWith(
                            keepAspectRatio: !_local.keepAspectRatio,
                          ),
                        );
                      },
                      icon: Icon(
                        _local.keepAspectRatio
                            ? Icons.lock
                            : Icons.lock_open,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Largura do traçado',
                value: _local.strokeWidth,
                onChanged: (value) =>
                    _emit(_local.copyWith(strokeWidth: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Rotação',
                suffix: '°',
                value: _local.rotationDegrees,
                onChanged: (value) =>
                    _emit(_local.copyWith(rotationDegrees: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: NumberField(
                label: 'Offset',
                value: _local.geometryOffset,
                onChanged: (value) =>
                    _emit(_local.copyWith(geometryOffset: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ColorsChangeCatalog(
          title: 'Cor do preenchimento',
          selectedColorValue: _local.fillColorValue,
          onChanged: (value) {
            _emit(_local.copyWith(fillColorValue: value));
          },
        ),
        const SizedBox(height: 10),
        ColorsChangeCatalog(
          title: 'Cor do traçado',
          selectedColorValue: _local.strokeColorValue,
          onChanged: (value) {
            _emit(_local.copyWith(strokeColorValue: value));
          },
        ),
        const SizedBox(height: 12),
        if (_local.type == LayerSimpleSymbolType.svgMarker)
          IconPickerGrid(
            options: IconsCatalog.options,
            selectedKey: _local.iconKey,
            previewColor: fillColor,
            onChanged: (value) => _emit(_local.copyWith(iconKey: value)),
          )
        else
          ShapePicker(
            selectedShape: _local.shapeType,
            fillColorValue: _local.fillColorValue,
            strokeColorValue: _local.strokeColorValue,
            strokeWidth: _local.strokeWidth,
            onChanged: (value) => _emit(_local.copyWith(shapeType: value)),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = LayerTypeSection.itemsForGeometry(
      widget.geometryKind,
      context: LayerTypeUsageContext.labels,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropDownChange(
              controller: _typeCtrl,
              labelText: 'Tipo da camada',
              width: double.infinity,
              items: items,
              onChanged: (value) {
                final nextType = LayerTypeSection.typeFromLabel(value);

                if (nextType == LayerSimpleSymbolType.svgMarker &&
                    !LayerTypeSection.supportsSvg(
                      widget.geometryKind,
                      context: LayerTypeUsageContext.labels,
                    )) {
                  return;
                }

                _emit(_local.copyWith(type: nextType));
              },
            ),
            const SizedBox(height: 12),
            if (_isTextType)
              _buildTextSection(constraints)
            else
              _buildSymbolSection(constraints),
          ],
        );
      },
    );
  }
}