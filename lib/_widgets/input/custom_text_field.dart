import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.autofillHints,
    this.stream,
    this.initialValue,
    this.valueColor,
    this.prefix,
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
    this.fontSize = 14.0,                // <-- tamanho do rótulo (label)
    this.textStyle,                      // <-- estilo do texto digitado
    this.textFontSize,                   // <-- atalho para tamanho do texto digitado
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
    this.outlined = true,                // <-- escolhe outline ou não
    this.borderRadius = 10.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor = Colors.red,
    this.borderWidth = 1.0,

    // Opções extras de layout
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
  final String? hintText;
  final String? initialValue;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Function(String?)? onSaved;
  final bool? enabled;
  final Color? valueColor;
  final String? labelText;
  final TextAlign? textAlign;

  // Label
  final double fontSize;

  // Texto digitado
  final TextStyle? textStyle;
  final double? textFontSize;

  final int? maxLength;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autoCorrect;
  final Function(String)? onSubmitted;
  final Color? fillCollor;
  final double? width;
  final double? height;
  final int? maxLines;
  final bool readOnly;

  // Aparência da borda
  final bool outlined;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color errorBorderColor;
  final double borderWidth;

  // Layout extra
  final TextAlignVertical? textAlignVertical;
  final bool? isDense;
  final bool? isCollapsed;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        readOnly: readOnly,
        maxLines: maxLines,
        onFieldSubmitted: onSubmitted,
        autocorrect: autoCorrect,
        textInputAction: textInputAction,
        focusNode: focusNode,
        maxLength: maxLength,
        controller: controller,
        obscureText: obscure,
        initialValue: initialValue,
        enabled: enabled,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: textAlign ?? TextAlign.start,
        // estilo do texto digitado
        style: (textStyle ?? const TextStyle()).copyWith(
          fontSize: textFontSize ?? textStyle?.fontSize,
          color: valueColor ?? textStyle?.color,
        ),

        textAlignVertical: textAlignVertical,

        decoration: InputDecoration(
          labelStyle: TextStyle(color: Colors.grey, fontSize: fontSize,),
          filled: true,
          fillColor: fillCollor ?? Colors.white,
          labelText: labelText,

          hintText: hintText,
          hintStyle: hintStyle,

          isDense: isDense,
          isCollapsed: isCollapsed,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

          prefixIcon: prefix,
          prefixIconConstraints: prefixIconConstraints,
          suffixIcon: suffix,
          suffixIconConstraints: suffixIconConstraints,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade500),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
