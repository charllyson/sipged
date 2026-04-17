import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.autofillHints,
    this.stream,
    this.initialValue,
    this.valueColor,

    // ✅ prefixos (texto ou widget)
    this.prefixText,
    this.prefixStyle,

    // ✅ se quiser ícone, use prefixIcon
    this.prefixIcon,

    this.suffix,
    this.inputFormatters,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.onSaved,
    this.enabled,
    this.controller,
    this.validator,
    this.labelText,
    this.textAlign = TextAlign.start,
    this.fontSize = 14.0,
    this.textStyle,
    this.textFontSize,
    this.maxLength,
    this.textInputAction,
    this.focusNode,
    this.autoCorrect = true,
    this.onSubmitted,
    this.fillCollor,
    this.width,
    this.height,
    this.hintText,
    this.maxLines = 1,
    this.readOnly = false,

    // Aparência da borda
    this.outlined = true,
    this.borderRadius = 10.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor = Colors.red,
    this.borderWidth = 1.0,

    // Layout extra
    this.textAlignVertical,
    this.isDense,
    this.isCollapsed,
    this.contentPadding,
    this.hintStyle,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
  });

  final List<String>? autofillHints;
  final Stream<String>? stream;

  final TextEditingController? controller;
  final String? initialValue;

  final String? hintText;

  // ✅ prefixos
  final String? prefixText;          // vai para InputDecoration.prefixText (RECOMENDADO p/ "R$")
  final TextStyle? prefixStyle;      // estilo do prefixText
  final Widget? prefixIcon;          // vai para InputDecoration.prefixIcon (ícone)

  final Widget? suffix;

  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FormFieldSetter<String>? onSaved;
  final bool? enabled;
  final Color? valueColor;
  final String? labelText;
  final TextAlign? textAlign;

  final double fontSize;

  final TextStyle? textStyle;
  final double? textFontSize;

  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autoCorrect;
  final ValueChanged<String>? onSubmitted;
  final Color? fillCollor;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool readOnly;

  final bool outlined;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color errorBorderColor;
  final double borderWidth;

  final TextAlignVertical? textAlignVertical;
  final bool? isDense;
  final bool? isCollapsed;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled ?? true;

    final base = (textStyle ?? const TextStyle());
    final effectiveStyle = base.copyWith(
      fontSize: textFontSize ?? base.fontSize,
      color: valueColor ?? base.color,
    );

    final effectiveBorderColor = borderColor ?? Colors.grey.shade500;
    final effectiveFocusedColor = focusedBorderColor ?? Colors.blue;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: effectiveBorderColor, width: borderWidth),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: effectiveFocusedColor, width: borderWidth),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: errorBorderColor, width: borderWidth),
    );

    final effectivePrefixTextStyle = prefixStyle ??
        effectiveStyle.copyWith(
          color: Colors.grey.shade700,
        );

    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        readOnly: readOnly,
        maxLines: maxLines,
        onFieldSubmitted: onSubmitted,
        autocorrect: autoCorrect,
        textInputAction: textInputAction,
        focusNode: focusNode,
        maxLength: maxLength,
        obscureText: obscure,
        enabled: effectiveEnabled,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: textAlign ?? TextAlign.start,
        style: effectiveStyle,
        textAlignVertical: textAlignVertical ?? TextAlignVertical.center,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.grey, fontSize: fontSize),
          filled: true,
          fillColor: fillCollor ?? Colors.white,
          labelText: labelText,
          hintText: hintText,
          hintStyle: hintStyle,
          isDense: isDense,
          isCollapsed: isCollapsed,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          prefixText: prefixText,
          prefixStyle: prefixText != null ? effectivePrefixTextStyle : null,
          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIconConstraints,
          suffixIcon: suffix,
          suffixIconConstraints: suffixIconConstraints,
          enabledBorder: outlined ? border : InputBorder.none,
          focusedBorder: outlined ? focusedBorder : InputBorder.none,
          errorBorder: outlined ? errorBorder : InputBorder.none,
          focusedErrorBorder: outlined ? errorBorder : InputBorder.none,
          disabledBorder: outlined
              ? border.copyWith(
            borderSide:
            BorderSide(color: Colors.grey.shade400, width: borderWidth),
          )
              : InputBorder.none,
        ),
      ),
    );
  }
}
