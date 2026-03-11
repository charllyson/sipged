import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/colors_catalog.dart';
import 'package:sipged/_widgets/geo/layer/editor/symbology/icons_catalog.dart';
import 'package:sipged/_widgets/geo/layer/simple_marker_shapes_catalog.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class SymbolMarkerForm extends StatefulWidget {
  final LayerSimpleSymbolData symbol;
  final ValueChanged<LayerSimpleSymbolData> onChanged;

  const SymbolMarkerForm({
    super.key,
    required this.symbol,
    required this.onChanged,
  });

  @override
  State<SymbolMarkerForm> createState() => _SymbolMarkerFormState();
}

class _SymbolMarkerFormState extends State<SymbolMarkerForm> {
  late LayerSimpleSymbolData _local;
  late final TextEditingController _symbolTypeCtrl;

  static const String _svgMarkerLabel = 'Marcador SVG';
  static const String _simpleMarkerLabel = 'Marcador Simples';

  @override
  void initState() {
    super.initState();
    _local = widget.symbol;
    _symbolTypeCtrl = TextEditingController(
      text: _labelFromSymbolType(_local.type),
    );
  }

  @override
  void didUpdateWidget(covariant SymbolMarkerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _local = widget.symbol;
      _symbolTypeCtrl.text = _labelFromSymbolType(_local.type);
    }
  }

  @override
  void dispose() {
    _symbolTypeCtrl.dispose();
    super.dispose();
  }

  void _emit(LayerSimpleSymbolData value) {
    setState(() {
      _local = value;
      _symbolTypeCtrl.text = _labelFromSymbolType(value.type);
    });
    widget.onChanged(value);
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

  @override
  Widget build(BuildContext context) {
    final fillColor = Color(_local.fillColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                label: 'Largura (x)',
                value: _local.width,
                onChanged: _updateWidth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                label: 'Altura (y)',
                value: _local.height,
                onChanged: _updateHeight,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'X vs Y',
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(0),

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
                    _local.keepAspectRatio ? Icons.lock : Icons.lock_open, size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                label: 'Largura do traçado',
                value: _local.strokeWidth,
                onChanged: (value) =>
                    _emit(_local.copyWith(strokeWidth: value)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
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
        const SizedBox(height: 6),
        ColorsCatalog(
          title: 'Cor do preenchimento',
          selectedColorValue: _local.fillColorValue,
          onChanged: (value) => _emit(_local.copyWith(fillColorValue: value)),
        ),
        const SizedBox(height: 6),
        ColorsCatalog(
          title: 'Cor do traçado',
          selectedColorValue: _local.strokeColorValue,
          onChanged: (value) => _emit(_local.copyWith(strokeColorValue: value)),
        ),
        const SizedBox(height: 12),
        if (_local.type == LayerSimpleSymbolType.svgMarker) ...[
          LayerIcon(
            options: IconsCatalog.options,
            selectedKey: _local.iconKey,
            previewColor: fillColor,
            onChanged: (value) => _emit(_local.copyWith(iconKey: value)),
          ),
        ] else ...[
          SimpleMarkerShapePicker(
            selectedShape: _local.shapeType,
            fillColorValue: _local.fillColorValue,
            strokeColorValue: _local.strokeColorValue,
            strokeWidth: _local.strokeWidth,
            onChanged: (value) => _emit(_local.copyWith(shapeType: value)),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value.toStringAsFixed(1),
    );

    return CustomTextField(
      controller: controller,
      labelText: label,
      suffix: suffix == null
          ? null
          : Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Center(
          widthFactor: 1,
          child: Text(
            suffix!,
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
          onChanged(parsed);
        }
      },
    );
  }
}