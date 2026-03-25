import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data_simple.dart';
import 'package:sipged/_widgets/draw/colors/colors_change_catalog.dart';
import 'package:sipged/_widgets/draw/icons/icon_picker_grid.dart';
import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';
import 'package:sipged/_widgets/draw/shapes/shapes_change_catalog.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class FormSymbologyMenu extends StatefulWidget {
  final LayerGeometryKind geometryKind;
  final GeoLayersDataSimple symbol;
  final ValueChanged<GeoLayersDataSimple> onChanged;

  const FormSymbologyMenu({
    super.key,
    required this.geometryKind,
    required this.symbol,
    required this.onChanged,
  });

  @override
  State<FormSymbologyMenu> createState() => _FormSymbologyMenuState();
}

class _FormSymbologyMenuState extends State<FormSymbologyMenu> {
  late GeoLayersDataSimple _local;
  late final TextEditingController _symbolTypeCtrl;
  late final TextEditingController _strokePatternCtrl;
  late final TextEditingController _dashArrayCtrl;
  late final TextEditingController _strokeJoinCtrl;
  late final TextEditingController _strokeCapCtrl;

  static const String _svgMarkerLabel = 'Marcador SVG';
  static const String _simpleMarkerLabel = 'Marcador simples';

  @override
  void initState() {
    super.initState();
    _local = widget.symbol;
    _symbolTypeCtrl = TextEditingController(
      text: _labelFromSymbolType(_local.type),
    );
    _strokePatternCtrl = TextEditingController(
      text: _labelFromStrokePattern(_local.strokePattern),
    );
    _dashArrayCtrl = TextEditingController(
      text: _local.dashArray.join(', '),
    );
    _strokeJoinCtrl = TextEditingController(
      text: _labelFromStrokeJoin(_local.strokeJoin),
    );
    _strokeCapCtrl = TextEditingController(
      text: _labelFromStrokeCap(_local.strokeCap),
    );
  }

  @override
  void didUpdateWidget(covariant FormSymbologyMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol ||
        oldWidget.geometryKind != widget.geometryKind) {
      _local = widget.symbol;
      _symbolTypeCtrl.text = _labelFromSymbolType(_local.type);
      _strokePatternCtrl.text = _labelFromStrokePattern(_local.strokePattern);
      _dashArrayCtrl.text = _local.dashArray.join(', ');
      _strokeJoinCtrl.text = _labelFromStrokeJoin(_local.strokeJoin);
      _strokeCapCtrl.text = _labelFromStrokeCap(_local.strokeCap);
    }
  }

  @override
  void dispose() {
    _symbolTypeCtrl.dispose();
    _strokePatternCtrl.dispose();
    _dashArrayCtrl.dispose();
    _strokeJoinCtrl.dispose();
    _strokeCapCtrl.dispose();
    super.dispose();
  }

  bool get _isPointFamily => widget.geometryKind == LayerGeometryKind.point ||
      widget.geometryKind == LayerGeometryKind.mixed ||
      widget.geometryKind == LayerGeometryKind.unknown;

  bool get _isLineFamily => widget.geometryKind == LayerGeometryKind.line;
  bool get _isPolygonFamily => widget.geometryKind == LayerGeometryKind.polygon;

  LayerSymbolFamily get _family {
    if (_isLineFamily) return LayerSymbolFamily.line;
    if (_isPolygonFamily) return LayerSymbolFamily.polygon;
    return LayerSymbolFamily.point;
  }

  void _emit(GeoLayersDataSimple value) {
    final normalized = value.copyWith(family: _family);

    _local = normalized;
    _symbolTypeCtrl.text = _labelFromSymbolType(normalized.type);
    _strokePatternCtrl.text =
        _labelFromStrokePattern(normalized.strokePattern);
    _dashArrayCtrl.text = normalized.dashArray.join(', ');
    _strokeJoinCtrl.text = _labelFromStrokeJoin(normalized.strokeJoin);
    _strokeCapCtrl.text = _labelFromStrokeCap(normalized.strokeCap);

    widget.onChanged(normalized);
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

  String _labelFromSymbolType(LayerSimpleSymbolType type) {
    switch (type) {
      case LayerSimpleSymbolType.svgMarker:
        return _svgMarkerLabel;
      case LayerSimpleSymbolType.simpleMarker:
        return _simpleMarkerLabel;
    }
  }

  LayerSimpleSymbolType _symbolTypeFromLabel(String? value) {
    switch (value) {
      case _simpleMarkerLabel:
        return LayerSimpleSymbolType.simpleMarker;
      case _svgMarkerLabel:
      default:
        return LayerSimpleSymbolType.svgMarker;
    }
  }

  String _labelFromStrokePattern(LayerStrokePattern type) {
    switch (type) {
      case LayerStrokePattern.solid:
        return 'Sólido';
      case LayerStrokePattern.dashed:
        return 'Tracejado';
      case LayerStrokePattern.dotted:
        return 'Pontilhado';
    }
  }

  LayerStrokePattern _strokePatternFromLabel(String? value) {
    switch (value) {
      case 'Tracejado':
        return LayerStrokePattern.dashed;
      case 'Pontilhado':
        return LayerStrokePattern.dotted;
      case 'Sólido':
      default:
        return LayerStrokePattern.solid;
    }
  }

  String _labelFromStrokeJoin(LayerStrokeJoinType type) {
    switch (type) {
      case LayerStrokeJoinType.miter:
        return 'Chanfrado';
      case LayerStrokeJoinType.bevel:
        return 'Pontiagudo';
      case LayerStrokeJoinType.round:
        return 'Arredondado';
    }
  }

  LayerStrokeJoinType _strokeJoinFromLabel(String? value) {
    switch (value) {
      case 'Pontiagudo':
        return LayerStrokeJoinType.bevel;
      case 'Arredondado':
        return LayerStrokeJoinType.round;
      case 'Chanfrado':
      default:
        return LayerStrokeJoinType.miter;
    }
  }

  String _labelFromStrokeCap(LayerStrokeCapType type) {
    switch (type) {
      case LayerStrokeCapType.butt:
        return 'Quadrado';
      case LayerStrokeCapType.square:
        return 'Plano';
      case LayerStrokeCapType.round:
        return 'Arredondado';
    }
  }

  LayerStrokeCapType _strokeCapFromLabel(String? value) {
    switch (value) {
      case 'Plano':
        return LayerStrokeCapType.square;
      case 'Arredondado':
        return LayerStrokeCapType.round;
      case 'Quadrado':
      default:
        return LayerStrokeCapType.butt;
    }
  }

  List<double> _parseDashArray(String raw) {
    return raw
        .split(',')
        .map((e) => double.tryParse(e.trim().replaceAll(',', '.')))
        .whereType<double>()
        .where((e) => e > 0)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = Color(_local.fillColorValue);

    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 700;
        final fieldWidth = small ? constraints.maxWidth : 220.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPointFamily) ...[
              DropDownButtonChange(
                controller: _symbolTypeCtrl,
                labelText: 'Tipo da camada símbolo',
                width: double.infinity,
                items: const [
                  _svgMarkerLabel,
                  _simpleMarkerLabel,
                ],
                onChanged: (value) {
                  final newType = _symbolTypeFromLabel(value);
                  if (newType == _local.type) return;
                  _emit(_local.copyWith(type: newType));
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      label: 'Largura (x)',
                      value: _local.width,
                      onChanged: _updateWidth,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      label: 'Altura (y)',
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
                          tooltip: _local.keepAspectRatio
                              ? 'Desbloquear proporção'
                              : 'Bloquear proporção',
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: small ? constraints.maxWidth : 220,
                    child: _NumberField(
                      label: 'Largura do traçado',
                      value: _local.strokeWidth,
                      onChanged: (value) =>
                          _emit(_local.copyWith(strokeWidth: value)),
                    ),
                  ),
                  SizedBox(
                    width: small ? constraints.maxWidth : 220,
                    child: _NumberField(
                      label: 'Rotação',
                      suffix: '°',
                      value: _local.rotationDegrees,
                      onChanged: (value) =>
                          _emit(_local.copyWith(rotationDegrees: value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ColorsChangeCatalog(
                title: 'Cor do preenchimento',
                selectedColorValue: _local.fillColorValue,
                onChanged: (value) =>
                    _emit(_local.copyWith(fillColorValue: value)),
              ),
              const SizedBox(height: 10),
              ColorsChangeCatalog(
                title: 'Cor do traçado',
                selectedColorValue: _local.strokeColorValue,
                onChanged: (value) =>
                    _emit(_local.copyWith(strokeColorValue: value)),
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
                SimpleMarkerShapePicker(
                  selectedShape: _local.shapeType,
                  fillColorValue: _local.fillColorValue,
                  strokeColorValue: _local.strokeColorValue,
                  strokeWidth: _local.strokeWidth,
                  onChanged: (value) =>
                      _emit(_local.copyWith(shapeType: value)),
                ),
            ] else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      label: _isLineFamily
                          ? 'Espessura da linha'
                          : 'Espessura da borda',
                      value: _local.strokeWidth,
                      onChanged: (value) =>
                          _emit(_local.copyWith(strokeWidth: value)),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      label: 'Rotação',
                      suffix: '°',
                      value: _local.rotationDegrees,
                      onChanged: (value) =>
                          _emit(_local.copyWith(rotationDegrees: value)),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _NumberField(
                      label: 'Offset',
                      value: _local.offset,
                      onChanged: (value) =>
                          _emit(_local.copyWith(offset: value)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropDownButtonChange(
                controller: _strokePatternCtrl,
                labelText: _isLineFamily
                    ? 'Padrão da linha'
                    : 'Padrão da borda',
                width: double.infinity,
                items: const ['Sólido', 'Tracejado', 'Pontilhado'],
                onChanged: (value) {
                  _emit(
                    _local.copyWith(
                      strokePattern: _strokePatternFromLabel(value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropDownButtonChange(
                controller: _strokeJoinCtrl,
                labelText: 'Estilo da união',
                width: double.infinity,
                items: const ['Chanfrado', 'Pontiagudo', 'Arredondado'],
                onChanged: (value) {
                  _emit(
                    _local.copyWith(
                      strokeJoin: _strokeJoinFromLabel(value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropDownButtonChange(
                controller: _strokeCapCtrl,
                labelText: 'Estilo da cobertura',
                width: double.infinity,
                items: const ['Quadrado', 'Plano', 'Arredondado'],
                onChanged: (value) {
                  _emit(
                    _local.copyWith(
                      strokeCap: _strokeCapFromLabel(value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Usar padrão personalizado tracejado'),
                  value: _local.useCustomDashPattern,
                  onChanged: (value) {
                    _emit(
                      _local.copyWith(
                        useCustomDashPattern: value ?? false,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (_local.useCustomDashPattern) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: _NumberField(
                        label: 'Largura do traço',
                        suffix: 'px',
                        value: _local.dashWidth,
                        onChanged: (value) =>
                            _emit(_local.copyWith(dashWidth: value)),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _NumberField(
                        label: 'Espaço vazio',
                        suffix: 'px',
                        value: _local.dashGap,
                        onChanged: (value) =>
                            _emit(_local.copyWith(dashGap: value)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                CustomTextField(
                  controller: _dashArrayCtrl,
                  labelText: 'Dash array (ex: 10, 6)',
                  onChanged: (value) {
                    _emit(_local.copyWith(dashArray: _parseDashArray(value)));
                  },
                ),
              ],
              const SizedBox(height: 10),
              if (_isLineFamily)
                ColorsChangeCatalog(
                  title: 'Cor da linha',
                  selectedColorValue: _local.strokeColorValue,
                  onChanged: (value) =>
                      _emit(_local.copyWith(strokeColorValue: value)),
                ),
              if (_isPolygonFamily) ...[
                ColorsChangeCatalog(
                  title: 'Cor do preenchimento',
                  selectedColorValue: _local.fillColorValue,
                  onChanged: (value) =>
                      _emit(_local.copyWith(fillColorValue: value)),
                ),
                const SizedBox(height: 10),
                ColorsChangeCatalog(
                  title: 'Cor da borda',
                  selectedColorValue: _local.strokeColorValue,
                  onChanged: (value) =>
                      _emit(_local.copyWith(strokeColorValue: value)),
                ),
              ],
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final double value;
  final String? suffix;
  final ValueChanged<double> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final text = _format(widget.value);
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: _controller,
      labelText: widget.label,
      suffix: widget.suffix == null
          ? null
          : Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Center(
          widthFactor: 1,
          child: Text(
            widget.suffix!,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
      ],
      onChanged: (v) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed != null) {
          widget.onChanged(parsed);
        }
      },
    );
  }
}