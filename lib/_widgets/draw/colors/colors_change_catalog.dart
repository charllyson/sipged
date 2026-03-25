import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorsChangeCatalog extends StatefulWidget {
  final int selectedColorValue;
  final ValueChanged<int> onChanged;
  final String title;

  const ColorsChangeCatalog({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.title = 'Cor do ícone',
  });

  @override
  State<ColorsChangeCatalog> createState() => _ColorsChangeCatalogState();
}

class _ColorsChangeCatalogState extends State<ColorsChangeCatalog> {
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _selectedColorValue = widget.selectedColorValue;
  }

  @override
  void didUpdateWidget(covariant ColorsChangeCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedColorValue != widget.selectedColorValue) {
      _selectedColorValue = widget.selectedColorValue;
    }
  }

  Future<void> _openColorPickerDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) {
        return _ColorsCatalogDialog(
          initialColorValue: _selectedColorValue,
          title: widget.title,
        );
      },
    );

    if (result != null && result != _selectedColorValue) {
      setState(() => _selectedColorValue = result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _openColorPickerDialog,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade500),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withAlpha(56),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _hexArgb(selectedColor),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorsCatalogDialog extends StatefulWidget {
  final int initialColorValue;
  final String title;

  const _ColorsCatalogDialog({
    required this.initialColorValue,
    required this.title,
  });

  @override
  State<_ColorsCatalogDialog> createState() => _ColorsCatalogDialogState();
}

class _ColorsCatalogDialogState extends State<_ColorsCatalogDialog> {
  late HSVColor _hsvColor;
  late double _alpha;

  late final TextEditingController _hCtrl;
  late final TextEditingController _sCtrl;
  late final TextEditingController _vCtrl;
  late final TextEditingController _rCtrl;
  late final TextEditingController _gCtrl;
  late final TextEditingController _bCtrl;
  late final TextEditingController _aCtrl;
  late final TextEditingController _hexCtrl;

  bool _isUpdatingTextFields = false;

  @override
  void initState() {
    super.initState();
    final initialColor = Color(widget.initialColorValue);
    _hsvColor = HSVColor.fromColor(initialColor);
    _alpha = initialColor.alpha / 255.0;

    _hCtrl = TextEditingController();
    _sCtrl = TextEditingController();
    _vCtrl = TextEditingController();
    _rCtrl = TextEditingController();
    _gCtrl = TextEditingController();
    _bCtrl = TextEditingController();
    _aCtrl = TextEditingController();
    _hexCtrl = TextEditingController();

    _syncControllersFromColor();
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _sCtrl.dispose();
    _vCtrl.dispose();
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    _aCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color get _selectedColor {
    final base = _hsvColor.toColor();
    return Color.fromARGB(
      (_alpha * 255).round().clamp(0, 255),
      base.red,
      base.green,
      base.blue,
    );
  }

  void _syncControllersFromColor() {
    _isUpdatingTextFields = true;
    final color = _selectedColor;

    _hCtrl.text = _hsvColor.hue.round().toString();
    _sCtrl.text = (_hsvColor.saturation * 100).round().toString();
    _vCtrl.text = (_hsvColor.value * 100).round().toString();

    _rCtrl.text = color.red.toString();
    _gCtrl.text = color.green.toString();
    _bCtrl.text = color.blue.toString();
    _aCtrl.text = (_alpha * 100).round().toString();
    _hexCtrl.text = _hexRgb(color);

    _isUpdatingTextFields = false;
  }

  void _updateFromHsv({
    double? hue,
    double? saturation,
    double? value,
    double? alpha,
  }) {
    setState(() {
      _hsvColor = _hsvColor.withHue((hue ?? _hsvColor.hue).clamp(0.0, 360.0));
      _hsvColor = _hsvColor.withSaturation(
        (saturation ?? _hsvColor.saturation).clamp(0.0, 1.0),
      );
      _hsvColor = _hsvColor.withValue((value ?? _hsvColor.value).clamp(0.0, 1.0));
      _alpha = (alpha ?? _alpha).clamp(0.0, 1.0);
      _syncControllersFromColor();
    });
  }

  void _updateFromRgb({
    int? red,
    int? green,
    int? blue,
    double? alpha,
  }) {
    final current = _selectedColor;
    final next = Color.fromARGB(
      (((alpha ?? _alpha) * 255).round()).clamp(0, 255),
      (red ?? current.red).clamp(0, 255),
      (green ?? current.green).clamp(0, 255),
      (blue ?? current.blue).clamp(0, 255),
    );

    setState(() {
      _hsvColor = HSVColor.fromColor(next).withAlpha(1);
      _alpha = next.alpha / 255.0;
      _syncControllersFromColor();
    });
  }

  void _updateFromHex(String raw) {
    final sanitized = raw
        .trim()
        .replaceAll('#', '')
        .replaceAll('0x', '')
        .replaceAll('0X', '')
        .toUpperCase();

    if (sanitized.length != 6 && sanitized.length != 8) return;

    final parsed = int.tryParse(sanitized, radix: 16);
    if (parsed == null) return;

    Color color;
    if (sanitized.length == 6) {
      color = Color(0xFF000000 | parsed);
    } else {
      color = Color(parsed);
    }

    setState(() {
      _hsvColor = HSVColor.fromColor(color).withAlpha(1);
      _alpha = color.alpha / 255.0;
      _syncControllersFromColor();
    });
  }

  void _onTextFieldChanged(VoidCallback action) {
    if (_isUpdatingTextFields) return;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _selectedColor;
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 980,
          maxHeight: 760,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 760;

                    if (isCompact) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPickerPanel(compact: true),
                            const SizedBox(height: 16),
                            _buildControlsPanel(theme, selectedColor),
                          ],
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 11,
                          child: _buildPickerPanel(compact: false),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 12,
                          child: _buildControlsPanel(theme, selectedColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selectedColor.value),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerPanel({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: AspectRatio(
        aspectRatio: compact ? 1.1 : 1.22,
        child: Row(
          children: [
            Expanded(
              child: _SaturationValueBox(
                hue: _hsvColor.hue,
                saturation: _hsvColor.saturation,
                value: _hsvColor.value,
                onChanged: (saturation, value) {
                  _updateFromHsv(
                    saturation: saturation,
                    value: value,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 28,
              child: _VerticalHueSlider(
                hue: _hsvColor.hue,
                onChanged: (hue) {
                  _updateFromHsv(hue: hue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel(ThemeData theme, Color selectedColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildPreview(selectedColor),
            const SizedBox(height: 16),
            _buildSliderRow(
              label: 'H',
              valueText: '${_hsvColor.hue.round()}°',
              child: _HorizontalGradientSlider(
                value: _hsvColor.hue / 360.0,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(hue: t * 360.0),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'S',
              valueText: '${(_hsvColor.saturation * 100).round()}%',
              child: _HorizontalGradientSlider(
                value: _hsvColor.saturation,
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1, _hsvColor.hue, 0, _hsvColor.value)
                        .toColor(),
                    HSVColor.fromAHSV(1, _hsvColor.hue, 1, _hsvColor.value)
                        .toColor(),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(saturation: t),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'V',
              valueText: '${(_hsvColor.value * 100).round()}%',
              child: _HorizontalGradientSlider(
                value: _hsvColor.value,
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    HSVColor.fromAHSV(1, _hsvColor.hue, _hsvColor.saturation, 1)
                        .toColor(),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(value: t),
              ),
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: 'Opacidade',
              valueText: '${(_alpha * 100).round()}%',
              child: _HorizontalGradientSlider(
                value: _alpha,
                checkerboard: true,
                gradient: LinearGradient(
                  colors: [
                    selectedColor.withAlpha(0),
                    selectedColor.withAlpha(255),
                  ],
                ),
                onChanged: (t) => _updateFromHsv(alpha: t),
              ),
            ),
            const SizedBox(height: 18),
            _buildNumericSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(Color selectedColor) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _CheckerboardBackground(),
                ColoredBox(color: selectedColor),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cor selecionada',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                _hexArgb(selectedColor),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'RGB(${selectedColor.red}, ${selectedColor.green}, ${selectedColor.blue})  •  α ${(100 * _alpha).round()}%',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: child),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumericSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _hCtrl,
                label: 'H',
                suffix: '°',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(hue: value.toDouble());
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _sCtrl,
                label: 'S',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(saturation: value / 100.0);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _vCtrl,
                label: 'V',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(value: value / 100.0);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _rCtrl,
                label: 'R',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(red: value);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _gCtrl,
                label: 'G',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(green: value);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _bCtrl,
                label: 'B',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromRgb(blue: value);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _NumberField(
                controller: _aCtrl,
                label: 'Opacidade',
                suffix: '%',
                onChanged: (text) => _onTextFieldChanged(() {
                  final value = int.tryParse(text);
                  if (value == null) return;
                  _updateFromHsv(alpha: value / 100.0);
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _hexCtrl,
                decoration: InputDecoration(
                  labelText: 'HEX',
                  prefixText: '#',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (text) => _onTextFieldChanged(() {
                  if (text.length == 6 || text.length == 8) {
                    _updateFromHex(text);
                  }
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SaturationValueBox extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  const _SaturationValueBox({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  void _handleOffset(BoxConstraints constraints, Offset localPosition) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    final s = (localPosition.dx / width).clamp(0.0, 1.0);
    final v = (1.0 - (localPosition.dy / height)).clamp(0.0, 1.0);

    onChanged(s, v);
  }

  @override
  Widget build(BuildContext context) {
    final pureHue = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    return LayoutBuilder(
      builder: (context, constraints) {
        final handleLeft = saturation * constraints.maxWidth;
        final handleTop = (1 - value) * constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) => _handleOffset(constraints, details.localPosition),
          onPanUpdate: (details) =>
              _handleOffset(constraints, details.localPosition),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, pureHue],
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade500),
                  ),
                ),
              ),
              Positioned(
                left: handleLeft - 9,
                top: handleTop - 9,
                child: IgnorePointer(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerticalHueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _VerticalHueSlider({
    required this.hue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final handleTop = (hue / 360.0) * constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (details) {
            final t = (details.localPosition.dy / constraints.maxHeight)
                .clamp(0.0, 1.0);
            onChanged(t * 360.0);
          },
          onPanUpdate: (details) {
            final t = (details.localPosition.dy / constraints.maxHeight)
                .clamp(0.0, 1.0);
            onChanged(t * 360.0);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade500),
                  ),
                ),
              ),
              Positioned(
                top: handleTop - 2,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HorizontalGradientSlider extends StatelessWidget {
  final double value;
  final Gradient gradient;
  final ValueChanged<double> onChanged;
  final bool checkerboard;

  const _HorizontalGradientSlider({
    required this.value,
    required this.gradient,
    required this.onChanged,
    this.checkerboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final handleLeft = value * constraints.maxWidth;

        void update(Offset localPosition) {
          final t = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
          onChanged(t);
        }

        return SizedBox(
          height: 24,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) => update(details.localPosition),
            onPanUpdate: (details) => update(details.localPosition),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (checkerboard) const _CheckerboardBackground(),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: gradient,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.grey.shade500),
                    ),
                  ),
                ),
                Positioned(
                  left: handleLeft - 6,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black54),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 8.0;
    final light = Paint()..color = const Color(0xFFF3F3F3);
    final dark = Paint()..color = const Color(0xFFD7D7D7);

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final isDark = ((x / cell).floor() + (y / cell).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          isDark ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

String _hexRgb(Color color) {
  final hex = (color.red << 16) | (color.green << 8) | color.blue;
  return hex.toRadixString(16).padLeft(6, '0').toUpperCase();
}

String _hexArgb(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}