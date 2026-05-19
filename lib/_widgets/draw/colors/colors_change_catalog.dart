// lib/_widgets/draw/colors/colors_change_catalog.dart

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/draw/colors/colors_catalog_dialog.dart';

class ColorsChangeCatalog extends StatefulWidget {
  const ColorsChangeCatalog({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.title,
    this.hintText,
    this.width,
    this.height,
    this.showHexValue = true,
    this.showDropdownIcon = true,
    this.compactPreview = false,
    this.readOnly = false,
    this.outlined = true,
    this.borderRadius = 10.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor = Colors.red,
    this.borderWidth = 1.0,
    this.fillCollor,
    this.fontSize = 14.0,
    this.textStyle,
    this.textFontSize,
    this.valueColor,
    this.isDense,
    this.isCollapsed,
    this.contentPadding,
    this.hintStyle,
  });

  static const double compactWidth = 74.0;
  static const double compactHeight = 52.0;
  static const double compactColorWidth = 46.0;
  static const double compactColorHeight = 30.0;

  final int selectedColorValue;
  final ValueChanged<int> onChanged;

  final String? title;
  final String? hintText;

  final double? width;
  final double? height;

  final bool showHexValue;
  final bool showDropdownIcon;

  /// Visual compacto:
  /// label superior + box contendo apenas a cor.
  final bool compactPreview;

  /// Quando true, bloqueia abertura do catálogo.
  final bool readOnly;

  final bool outlined;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color errorBorderColor;
  final double borderWidth;
  final Color? fillCollor;

  final double fontSize;
  final TextStyle? textStyle;
  final double? textFontSize;
  final Color? valueColor;
  final bool? isDense;
  final bool? isCollapsed;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;

  @override
  State<ColorsChangeCatalog> createState() => _ColorsChangeCatalogState();
}

class _ColorsChangeCatalogState extends State<ColorsChangeCatalog> {
  late int _selectedColorValue;

  String get _dialogTitle {
    final clean = widget.title?.trim();

    if (clean == null || clean.isEmpty) {
      return 'Selecionar cor';
    }

    return clean;
  }

  bool get _hasTitle {
    final clean = widget.title?.trim();
    return clean != null && clean.isNotEmpty;
  }

  VoidCallback? get _onTap {
    if (widget.readOnly) return null;
    return _openColorPickerDialog;
  }

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
        return ColorsCatalogDialog(
          initialColorValue: _selectedColorValue,
          title: _dialogTitle,
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
    if (widget.compactPreview) {
      return _buildCompactPreview(context);
    }

    return _buildInputDecoratorPreview(context);
  }

  Widget _buildCompactPreview(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    final effectiveWidth = widget.width ?? ColorsChangeCatalog.compactWidth;
    final effectiveHeight = widget.height ?? ColorsChangeCatalog.compactHeight;

    final effectiveFillColor = widget.fillCollor ?? Colors.white;
    final effectiveBorderColor = widget.borderColor ?? Colors.grey.shade500;
    final effectiveLabel = _hasTitle ? widget.title!.trim() : 'Cor';

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: _onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(9, 10, 9, 8),
                  decoration: BoxDecoration(
                    color: effectiveFillColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: widget.outlined
                          ? effectiveBorderColor
                          : Colors.transparent,
                      width: widget.outlined ? widget.borderWidth : 0,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: ColorsChangeCatalog.compactColorWidth,
                      height: ColorsChangeCatalog.compactColorHeight,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveFillColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    effectiveLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: widget.fontSize,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputDecoratorPreview(BuildContext context) {
    final selectedColor = Color(_selectedColorValue);

    final base = widget.textStyle ?? const TextStyle();

    final effectiveStyle = base.copyWith(
      fontSize: widget.textFontSize ?? base.fontSize ?? 14,
      color: widget.valueColor ?? base.color,
      fontWeight: base.fontWeight ?? FontWeight.w700,
    );

    final effectiveBorderColor = widget.borderColor ?? Colors.grey.shade500;
    final effectiveFocusedColor = widget.focusedBorderColor ?? Colors.blue;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: effectiveBorderColor,
        width: widget.borderWidth,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: effectiveFocusedColor,
        width: widget.borderWidth,
      ),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: widget.errorBorderColor,
        width: widget.borderWidth,
      ),
    );

    final disabledBorder = border.copyWith(
      borderSide: BorderSide(
        color: Colors.grey.shade400,
        width: widget.borderWidth,
      ),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: _onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelStyle: TextStyle(
              color: Colors.grey,
              fontSize: widget.fontSize,
            ),
            filled: true,
            fillColor: widget.fillCollor ?? Colors.white,
            labelText: _hasTitle ? widget.title!.trim() : null,
            hintText: widget.hintText,
            hintStyle: widget.hintStyle,
            isDense: widget.isDense,
            isCollapsed: widget.isCollapsed,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
            enabledBorder: widget.outlined ? border : InputBorder.none,
            focusedBorder: widget.outlined ? focusedBorder : InputBorder.none,
            errorBorder: widget.outlined ? errorBorder : InputBorder.none,
            focusedErrorBorder: widget.outlined ? errorBorder : InputBorder.none,
            disabledBorder: widget.outlined ? disabledBorder : InputBorder.none,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 30,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (widget.showHexValue) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hexArgb(selectedColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: effectiveStyle,
                  ),
                ),
              ] else
                const Spacer(),
              if (widget.showDropdownIcon && !widget.readOnly)
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }
}